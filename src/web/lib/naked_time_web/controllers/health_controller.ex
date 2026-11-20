defmodule NakedTimeWeb.HealthController do
  @moduledoc """
  Reports that the web application is running. Azure Container Apps uses
  this endpoint for its health probes.
  """
  use NakedTimeWeb, :controller

  def show(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
