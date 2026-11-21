// Copyright 2026 Michael F. Collins, III
// Licensed under the Naked Time license. See LICENSE.md for details.

import {
    ContainerLifetime,
    ContainerTargetPlatform,
    EndpointProperty,
    ProbeType,
    createBuilder,
    type ContainerResource,
} from './.aspire/modules/aspire.mjs';

const builder = await createBuilder();
const executionContext = await builder.executionContext();
const isPublishMode = await executionContext.isPublishMode();

// The port that the Phoenix web application listens on inside of its
// container image. See src/web/Dockerfile.
const webContainerPort = 4000;

// PostgreSQL: an Azure Database for PostgreSQL flexible server when deployed,
// and a local PostgreSQL container (persistent, with a data volume) during
// local development. When deployed, the web application authenticates to the
// database with Microsoft Entra ID using its user-assigned managed identity.
const postgres = await builder
    .addAzurePostgresFlexibleServer('postgres')
    .runAsContainer({
        configureContainer: async (container) => {
            await container
                .withLifetime(ContainerLifetime.Persistent)
                .withDataVolume();
        },
    });

const webdb = await postgres.addDatabase('webdb');

// Runs the Ecto migrations once the database is ready. The Phoenix app waits
// for this resource to complete successfully before it starts. When deployed,
// the migrations run as a manually triggered Azure Container Apps job that
// uses the web application's container image. The GitHub Actions deployment
// workflow starts the job after `aspire deploy` completes.
const webMigrate = await builder
    .addExecutable('web-migrate', 'mix', '../web', ['do', 'deps.get', '+', 'ecto.migrate'])
    .withReference(webdb)
    .waitFor(webdb);

// The Phoenix web application. Aspire assigns the HTTP port through PORT,
// which config/runtime.exs reads. The OTLP exporter settings send traces,
// logs, and metrics to the dashboard. The Erlang OTLP exporter does not read
// OTEL_EXPORTER_OTLP_CERTIFICATE, so Aspire provides the path of the CA
// bundle that trusts the dashboard's development certificate through
// OTEL_EXPORTER_OTLP_CACERTFILE, which config/runtime.exs reads.
const web = await builder
    .addExecutable('web', 'mix', '../web', ['phx.server'])
    .withHttpEndpoint({
        env: 'PORT',
        targetPort: isPublishMode ? webContainerPort : undefined,
    })
    .withExternalHttpEndpoints()
    .withOtlpExporter()
    .withCertificateTrustEnvironment('OTEL_EXPORTER_OTLP_CACERTFILE')
    .withReference(webdb)
    .waitFor(webdb)
    .waitForCompletion(webMigrate);

if (isPublishMode) {
    // The Azure Container Apps environment that hosts the web application.
    // Aspire also provisions the Azure Container Registry for the container
    // images, a Log Analytics workspace, and the Aspire dashboard.
    await builder.addAzureContainerAppEnvironment('aca');

    // The user-assigned managed identity that the web application and the
    // migration job use to authenticate to Azure Database for PostgreSQL.
    // The database user name is the name of the identity.
    const webIdentity = await builder.addAzureUserAssignedIdentity('web-identity');
    const webIdentityName = await webIdentity.getOutput('principalName');

    // The secret that Phoenix uses to sign and encrypt cookies. Provided
    // through the Parameters__secret_key_base environment variable.
    const secretKeyBase = await builder.addParameter('secret-key-base', { secret: true });

    // CI builds the container image once (with layer caching) and publishes
    // it to GitHub Packages. WEB_RUNTIME_IMAGE is the reference to that
    // image. The Dockerfile uses it as the final image, which skips building
    // the release again, and Aspire pushes it to Azure Container Registry.
    // Without WEB_RUNTIME_IMAGE, the release is built from source.
    const runtimeImage = process.env.WEB_RUNTIME_IMAGE;

    const configureContainer = async (container: ContainerResource) => {
        if (runtimeImage) {
            await container.withBuildArg('RUNTIME_IMAGE', runtimeImage);
        }

        await container.withContainerBuildOptions(async (options) => {
            await options.targetPlatform.set(ContainerTargetPlatform.LinuxAmd64);
        });
    };

    await webMigrate
        .publishAsDockerFile(async (container) => {
            await configureContainer(container);
            await container.withEntrypoint('/app/bin/migrate');
        })
        .withAzureUserAssignedIdentity(webIdentity)
        .withEnvironment('PGUSER', webIdentityName)
        // config/runtime.exs requires the secret key base to boot, even
        // though the migrations do not use it.
        .withEnvironment('SECRET_KEY_BASE', secretKeyBase)
        .publishAsAzureContainerAppJob();

    const webEndpoint = await web.getEndpoint('http');

    await web
        .publishAsDockerFile(configureContainer)
        .withAzureUserAssignedIdentity(webIdentity)
        .withEnvironment('PGUSER', webIdentityName)
        .withEnvironment('SECRET_KEY_BASE', secretKeyBase)
        .withEnvironment('PHX_HOST', webEndpoint.property(EndpointProperty.Host))
        // Each probe also registers a health check for the path, so only the
        // readiness probe is declared. Azure Container Apps keeps its default
        // liveness probe on the target port.
        .withHttpProbe(ProbeType.Readiness, { path: '/health', endpointName: 'http' });
}

await builder.build().run();
