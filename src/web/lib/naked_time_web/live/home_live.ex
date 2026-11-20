defmodule NakedTimeWeb.HomeLive do
  @moduledoc """
  The home page. The UI is the React `Home` component in
  `assets/js/components/Home.tsx`.
  """
  use NakedTimeWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :phoenix_version, to_string(Application.spec(:phoenix, :vsn)))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <.react name="Home" phoenixVersion={@phoenix_version} />
    """
  end
end
