defmodule NakedTimeWeb.HealthControllerTest do
  use NakedTimeWeb.ConnCase

  test "GET /health", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert response(conn, 200) == "ok"
  end
end
