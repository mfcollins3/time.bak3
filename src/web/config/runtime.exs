import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/web start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :web, NakedTimeWeb.Endpoint, server: true
end

config :web, NakedTimeWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# OpenTelemetry. The Aspire AppHost injects the standard OTEL_* environment
# variables (endpoint, protocol, headers, service name, and resource
# attributes), which the OpenTelemetry SDK reads directly. Traces, logs, and
# metrics are only exported when an OTLP endpoint is configured.
if config_env() != :test do
  if System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT") do
    # The Erlang OTLP exporter does not support OTEL_EXPORTER_OTLP_CERTIFICATE,
    # so the CA bundle that trusts the endpoint's certificate (the Aspire
    # dashboard's development certificate) is passed through the SSL options.
    ssl_options =
      case System.get_env("OTEL_EXPORTER_OTLP_CACERTFILE") do
        nil -> []
        cacertfile -> NakedTime.OtlpCertificateTrust.ssl_options(cacertfile)
      end

    if ssl_options != [] do
      config :opentelemetry_exporter, ssl_options: ssl_options
    end

    exporter_options =
      if ssl_options == [], do: %{}, else: %{ssl_options: ssl_options}

    config :opentelemetry_experimental,
      readers: [
        %{
          module: :otel_metric_reader,
          config: %{
            export_interval_ms: 10_000,
            exporter: {:otel_exporter_metrics_otlp, exporter_options}
          }
        }
      ]

    # Exports Logger output as OpenTelemetry logs. The handler is added by
    # NakedTime.Application.start/2 through Logger.add_handlers/1.
    #
    # opentelemetry_experimental 0.6.0 sets each log record's timestamp to
    # the time that the batch is exported and puts the time of the log event
    # in the observed timestamp. Exporting every second (the default is five
    # seconds) keeps the timestamps shown by the Aspire dashboard close to
    # the time of the log events.
    config :web, :logger, [
      {:handler, :otel, :otel_log_handler,
       %{
         exporter: {:otel_exporter_logs_otlp, exporter_options},
         scheduled_delay_ms: 1_000
       }}
    ]
  else
    config :opentelemetry, traces_exporter: :none
  end
end

if config_env() == :dev do
  # When the application is launched by the Aspire AppHost, Aspire injects
  # the connection URI for the `webdb` database resource. The URI takes
  # precedence over the static settings in config/dev.exs.
  if webdb_uri = System.get_env("WEBDB_URI") do
    config :web, NakedTime.Repo, url: webdb_uri
  end

  # Reload browser tabs when matching files change.
  config :web, NakedTimeWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        # Gettext translations
        ~r"priv/gettext/.*\.po$"E,
        # Router, Controllers, LiveViews and LiveComponents
        ~r"lib/naked_time_web/router\.ex$"E,
        ~r"lib/naked_time_web/(controllers|live|components)/.*\.(ex|heex)$"E
      ]
    ]
end

if config_env() == :prod do
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :web, NakedTime.Repo,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  cond do
    # Running outside of Azure, for example when a developer runs the
    # container image from GitHub Packages against a local database.
    database_url = System.get_env("DATABASE_URL") ->
      config :web, NakedTime.Repo, url: database_url

    # Running in Azure Container Apps. The Aspire AppHost injects the
    # connection properties of the `webdb` Azure Database for PostgreSQL
    # database, and the name of the user-assigned managed identity that is
    # the database user. The password is a Microsoft Entra ID access token
    # that NakedTime.AzurePostgresToken gets for each new connection.
    database_host = System.get_env("WEBDB_HOST") ->
      config :web, NakedTime.Repo,
        hostname: database_host,
        port: String.to_integer(System.get_env("WEBDB_PORT") || "5432"),
        database: System.fetch_env!("WEBDB_DATABASENAME"),
        username: System.fetch_env!("PGUSER"),
        configure: {NakedTime.AzurePostgresToken, :configure, []},
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          server_name_indication: String.to_charlist(database_host),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]

    true ->
      raise """
      the database connection is not configured. Set DATABASE_URL (for
      example: ecto://USER:PASS@HOST/DATABASE), or set WEBDB_HOST,
      WEBDB_DATABASENAME, and PGUSER to connect to Azure Database for
      PostgreSQL with a managed identity.
      """
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :web, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :web, NakedTimeWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base,
    cache_static_manifest_latest: PhoenixVite.cache_static_manifest_latest(:web)

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :web, NakedTimeWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :web, NakedTimeWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :web, NakedTime.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://swoosh.hexdocs.pm/Swoosh.html#module-installation for details.
end
