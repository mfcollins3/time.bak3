defmodule NakedTime.AzurePostgresTokenTest do
  # Not async: the tests change environment variables and the token cache,
  # which are global.
  use ExUnit.Case, async: false

  alias NakedTime.AzurePostgresToken

  setup do
    System.put_env("IDENTITY_ENDPOINT", "http://localhost:42356/msi/token")
    System.put_env("IDENTITY_HEADER", "identity-header")
    System.put_env("AZURE_CLIENT_ID", "client-id")
    AzurePostgresToken.clear_cache()

    on_exit(fn ->
      System.delete_env("IDENTITY_ENDPOINT")
      System.delete_env("IDENTITY_HEADER")
      System.delete_env("AZURE_CLIENT_ID")
      AzurePostgresToken.clear_cache()
    end)
  end

  defp stub_token(token, expires_in) do
    test_pid = self()

    Req.Test.stub(AzurePostgresToken, fn conn ->
      send(test_pid, {:token_request, conn})
      expires_on = System.os_time(:second) + expires_in

      Req.Test.json(conn, %{
        "access_token" => token,
        "expires_on" => Integer.to_string(expires_on)
      })
    end)
  end

  test "requests a token for Azure Database for PostgreSQL with the managed identity" do
    stub_token("token-1", 3600)

    assert AzurePostgresToken.token!() == "token-1"

    assert_received {:token_request, conn}
    assert Plug.Conn.get_req_header(conn, "x-identity-header") == ["identity-header"]

    params = Plug.Conn.fetch_query_params(conn).query_params
    assert params["resource"] == "https://ossrdbms-aad.database.windows.net"
    assert params["api-version"] == "2019-08-01"
    assert params["client_id"] == "client-id"
  end

  test "caches the token until it is about to expire" do
    stub_token("token-1", 3600)
    assert AzurePostgresToken.token!() == "token-1"
    assert_received {:token_request, _conn}

    assert AzurePostgresToken.token!() == "token-1"
    refute_received {:token_request, _conn}
  end

  test "fetches a new token when the cached token is about to expire" do
    stub_token("token-1", 60)
    assert AzurePostgresToken.token!() == "token-1"

    stub_token("token-2", 3600)
    assert AzurePostgresToken.token!() == "token-2"
  end

  test "configure/1 sets the token as the password" do
    stub_token("token-1", 3600)

    opts = AzurePostgresToken.configure(hostname: "db.example.com", username: "web-identity")

    assert opts[:password] == "token-1"
    assert opts[:hostname] == "db.example.com"
  end

  test "raises when the managed identity endpoint returns an error" do
    Req.Test.stub(AzurePostgresToken, fn conn ->
      conn
      |> Plug.Conn.put_status(400)
      |> Req.Test.json(%{"error" => "invalid_request"})
    end)

    assert_raise RuntimeError, ~r/status 400/, fn -> AzurePostgresToken.token!() end
  end
end
