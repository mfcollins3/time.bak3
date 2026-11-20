defmodule NakedTime.AzurePostgresToken do
  @moduledoc """
  Provides Microsoft Entra ID access tokens that are used as the password
  when connecting to Azure Database for PostgreSQL.

  When the web application runs in Azure Container Apps, it authenticates to
  the database with its user-assigned managed identity. Azure Container Apps
  exposes a managed identity endpoint to the container through the
  `IDENTITY_ENDPOINT` and `IDENTITY_HEADER` environment variables, and
  Aspire provides the client ID of the user-assigned identity through
  `AZURE_CLIENT_ID`.

  `configure/1` is used as the Postgrex `:configure` callback, which is
  called before every new database connection. Tokens are cached until
  shortly before they expire, so new connections always receive a valid
  token. Azure Database for PostgreSQL only validates the token when a
  connection is established, so open connections are not affected when the
  token expires.
  """

  @resource "https://ossrdbms-aad.database.windows.net"
  @api_version "2019-08-01"
  @cache_key {__MODULE__, :token}

  # Tokens are refreshed when they expire within this many seconds.
  @refresh_margin_seconds 300

  @doc """
  The Postgrex `:configure` callback. Returns `opts` with the `:password`
  set to a current Microsoft Entra ID access token.
  """
  @spec configure(keyword()) :: keyword()
  def configure(opts) do
    Keyword.put(opts, :password, token!())
  end

  @doc """
  Returns a current access token for Azure Database for PostgreSQL, fetching
  a new token from the managed identity endpoint when the cached token is
  missing or about to expire.
  """
  @spec token!() :: String.t()
  def token! do
    now = System.os_time(:second)

    case :persistent_term.get(@cache_key, nil) do
      {token, expires_on} when expires_on - @refresh_margin_seconds > now ->
        token

      _ ->
        {token, expires_on} = fetch_token!()
        :persistent_term.put(@cache_key, {token, expires_on})
        token
    end
  end

  @doc false
  # Removes the cached token. Used by the tests.
  def clear_cache do
    :persistent_term.erase(@cache_key)
    :ok
  end

  defp fetch_token! do
    endpoint = System.fetch_env!("IDENTITY_ENDPOINT")
    header = System.fetch_env!("IDENTITY_HEADER")

    params =
      [resource: @resource, "api-version": @api_version]
      |> maybe_put_client_id(System.get_env("AZURE_CLIENT_ID"))

    options =
      [
        url: endpoint,
        params: params,
        headers: [{"x-identity-header", header}],
        retry: :transient
      ]
      |> Keyword.merge(Application.get_env(:web, __MODULE__, [])[:req_options] || [])

    case Req.get!(options) do
      %Req.Response{status: 200, body: %{"access_token" => token, "expires_on" => expires_on}} ->
        {token, to_integer(expires_on)}

      %Req.Response{status: status, body: body} ->
        raise "failed to get a Microsoft Entra ID token for Azure Database for " <>
                "PostgreSQL from the managed identity endpoint " <>
                "(status #{status}): #{inspect(body)}"
    end
  end

  defp maybe_put_client_id(params, nil), do: params
  defp maybe_put_client_id(params, ""), do: params
  defp maybe_put_client_id(params, client_id), do: Keyword.put(params, :client_id, client_id)

  defp to_integer(value) when is_integer(value), do: value
  defp to_integer(value) when is_binary(value), do: String.to_integer(value)
end
