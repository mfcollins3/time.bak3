# Deploying Naked Time

1. [Overview](#overview)
1. [One-time setup](#one-time-setup)
1. [What the workflow does](#what-the-workflow-does)
1. [Deploying from a developer computer](#deploying-from-a-developer-computer)
1. [Running the published image](#running-the-published-image)
1. [Database migrations](#database-migrations)

## Overview

The Naked Time web application (`src/web`) is deployed to
[Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
by the Aspire AppHost (`src/apphost/apphost.mts`) and the `Web` GitHub
Actions workflow (`.github/workflows/web.yml`). See
[ADR 0002](adrs/0002-deploy-web-to-azure-container-apps.md) for the
decisions behind this setup.

`aspire deploy` provisions these Azure resources:

| AppHost resource | Azure resource |
| ---------------- | -------------- |
| `aca` | Azure Container Apps environment, Azure Container Registry, Log Analytics workspace, and the Aspire dashboard |
| `postgres`, `webdb` | Azure Database for PostgreSQL flexible server and the `webdb` database, with Microsoft Entra authentication |
| `web-identity` | User-assigned managed identity that the web application and the migration job use for the database |
| `web` | Container app with external HTTPS ingress |
| `web-migrate` | Manually triggered Container Apps job that runs the Ecto migrations |

## One-time setup

### Azure

1. Choose a subscription, a region (for example `eastus2`), and a resource
   group name. Aspire creates the resource group if it doesn't exist.
1. Create a Microsoft Entra app registration (or a user-assigned managed
   identity) for GitHub Actions, and add a federated credential for the
   repository's `production` environment:

   ```bash
   az ad app create --display-name naked-time-github
   az ad sp create --id <app-id>
   az ad app federated-credential create --id <app-id> --parameters '{
     "name": "github-production",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:mfcollins3/time:environment:production",
     "audiences": ["api://AzureADTokenExchange"]
   }'
   ```

1. Grant the service principal permission to create resources and role
   assignments. `Owner` on the subscription, or `Contributor` and
   `Role Based Access Control Administrator` on it, is enough, because
   Aspire creates role assignments for the managed identities.

### GitHub

Create an environment named `production` in the repository settings (add
required reviewers if deployments need approval), and add:

| Kind | Name | Value |
| ---- | ---- | ----- |
| Secret | `AZURE_CLIENT_ID` | The client ID of the app registration |
| Secret | `AZURE_TENANT_ID` | The Microsoft Entra tenant ID |
| Secret | `AZURE_SUBSCRIPTION_ID` | The subscription ID |
| Secret | `SECRET_KEY_BASE` | Output of `mix phx.gen.secret` (run in `src/web`) |
| Variable | `AZURE_LOCATION` | The Azure region, for example `eastus2` |
| Variable | `AZURE_RESOURCE_GROUP` | The resource group name |

## What the workflow does

| Job | Pull requests | Pushes to `main` |
| --- | ------------- | ---------------- |
| Test | Runs `mix test` against PostgreSQL. `deps` and `_build` are cached by `mix.lock`. | Same |
| Check AppHost | Lints and type-checks the AppHost. | Same |
| Image (amd64, arm64) | Builds the image on native runners without publishing it. | Builds and pushes each architecture by digest. |
| Publish multi-platform image | Skipped | Tags `ghcr.io/mfcollins3/time-web:sha-<commit>` and `:main` |
| Deploy to Azure | Skipped | Runs `aspire deploy`, then the migration job |

The image builds use the GitHub Actions cache backend for BuildKit, with a
separate cache for each architecture. Because `src/web/Dockerfile` copies
`mix.exs`, `mix.lock`, and the compile-time configuration before the
application source, the dependency layers are rebuilt only when those files
change.

The deploy job passes the digest of the amd64 image to the AppHost in
`WEB_RUNTIME_IMAGE`. The AppHost sets it as the Dockerfile's
`RUNTIME_IMAGE` build argument, so the image build that `aspire deploy` runs
skips the build stages and only re-tags the image before pushing it to Azure
Container Registry.

## Deploying from a developer computer

Sign in with `az login`, then run from the root of the repository:

```bash
cd src/apphost
pnpm_config_allow_builds='{"esbuild":true}' \
Azure__SubscriptionId="<subscription-id>" \
Azure__Location="eastus2" \
Azure__ResourceGroup="<resource-group>" \
Parameters__secret_key_base="<secret>" \
aspire deploy --environment Production
```

Without `WEB_RUNTIME_IMAGE`, the release is built from source for
`linux/amd64`. On an Apple silicon computer that build runs under emulation
and is slow. To deploy an image that CI already published instead, set
`WEB_RUNTIME_IMAGE=ghcr.io/mfcollins3/time-web:sha-<commit>`.

`pnpm_config_allow_builds` is needed because the Aspire CLI installs the
AppHost dependencies with `pnpm install --ignore-workspace`, which ignores
the `allowBuilds` setting in `src/apphost/pnpm-workspace.yaml`. `run.sh` and
`Run-Time.ps1` set the same variable for `aspire run`.

Use `aspire publish -o <directory>` to review the generated Bicep without
deploying anything.

## Running the published image

The image runs on `linux/amd64` and `linux/arm64`. Outside of Azure, set
`DATABASE_URL` instead of the Azure database settings:

```bash
docker run --rm -p 4000:4000 \
  -e DATABASE_URL=ecto://postgres:postgres@host.docker.internal/web_dev \
  -e SECRET_KEY_BASE="$(cd src/web && mix phx.gen.secret)" \
  -e PHX_HOST=localhost \
  ghcr.io/mfcollins3/time-web:main
```

Run the migrations with the same image and the command `/app/bin/migrate`.

## Database migrations

The `web-migrate` job runs `/app/bin/migrate` with the same identity as the
web application. The workflow starts the job after `aspire deploy` deploys
the new revision of the web application, and fails if the job fails. Because
the new revision can start before the migrations finish, migrations must
work with both the previous and the new version of the application. Add
columns and tables first, and remove them in a later release.

To run the migrations by hand:

```bash
az containerapp job start --resource-group <resource-group> --name web-migrate
```
