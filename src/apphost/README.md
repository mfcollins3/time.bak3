# Aspire AppHost

This directory contains the source code for the [Aspire](https://aspire.dev)
AppHost for the Naked Time product. Aspire is a code-first tool for composing
software programs with the resources that they need and running them locally.
The AppHost is a code-first specification of what software components make up
the Naked Time product and what resources they need to run. The AppHost will
build the Naked Time programs, download and run the services that they need,
and then run the Naked Time programs and link them together with the resources
to get Naked Time running locally on the developer's computer.

The main file of interest is [`apphost.mts`](apphost.mts). This is the AppHost
specification.

## AppHost layout

```plain
src/apphost/                    Root directory for the AppHost
|-- .node-version               Stores the version number of Node.js to use. Used by fnm to install and activate the correct version of Node.js when working with the AppHost.
|-- apphost.mts                 The AppHost specification that is used to build and run Naked Time locally
|-- aspire.config.js            Configuration settings used by Aspire to run Naked Time
|-- eslint.config.mjs           Configuration settings for ESLint to use when scanning the AppHost for issues
|-- package.json                The Node.js package manifest for the AppHost
|-- pnpm-lock.yaml              Version information for dependencies that are being used by the AppHost so that pnpm can restore the exact versions
|-- pnpm-workspace.yaml         pnpm configuration settings for the AppHost
|-- README.md                   (This file.) Documentation for the AppHost
|-- tsconfig.apphost.json       Configuration settings for the TypeScript compiler to use when compiling the AppHost source code
```

## Starting the AppHost

To start the AppHost, use the `run.sh` or `Run-Time.ps1` scripts from the root
directory of the Naked Time repository. After the AppHost starts, it will
display the URL of the [Aspire Dashboard](https://aspire.dev/dashboard/) that
you can use to see all of the executing components and obtain the URLs to use
to access the web applications, APIs, and services.

## Deploying to Azure

When the AppHost is published (`aspire publish` or `aspire deploy`), it adds
an Azure Container Apps environment and deploys the web application as a
container app, with the Ecto migrations as a Container Apps job. The web
application and the migration job authenticate to Azure Database for
PostgreSQL with the `web-identity` user-assigned managed identity. Local
runs (`aspire run`) are not affected.

The deployment uses these inputs:

| Name | Kind | Description |
| ---- | ---- | ----------- |
| `secret-key-base` | Secret parameter (`Parameters__secret_key_base`) | The Phoenix secret key base |
| `WEB_RUNTIME_IMAGE` | Environment variable (optional) | A prebuilt web application image to deploy, instead of building the release from source |
| `Azure__SubscriptionId`, `Azure__Location`, `Azure__ResourceGroup` | Environment variables | The Azure deployment target |

See [Deploying Naked Time](../../docs/deployment.md) for details.
