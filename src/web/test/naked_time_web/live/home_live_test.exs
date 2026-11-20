defmodule NakedTimeWeb.HomeLiveTest do
  use NakedTimeWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET / mounts the React Home component", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ ~s(data-name="Home")
    assert has_element?(view, ~s([data-name="Home"]))
  end
end
