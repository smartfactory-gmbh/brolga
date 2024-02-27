defmodule BrolgaWeb.PublicMonitorLiveTest do
  alias Brolga.Dashboards
  use BrolgaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Brolga.MonitoringFixtures
  import Brolga.DashboardsFixtures

  setup :register_and_log_in_user

  defp create_monitors(_) do
    monitors = [
      monitor_fixture(%{name: "test monitor"}),
      monitor_fixture(%{name: "test inactive monitor", active: false})
    ]

    %{monitor: monitors}
  end

  defp create_default_dashboard(_) do
    dashboard = dashboard_fixture(%{default: true})
    %{dashboard: dashboard}
  end

  describe "default dasbhoard" do
    setup [:create_default_dashboard, :create_monitors]

    test "is reachable without id", %{conn: conn} do
      {result, _lv, _html} = live(conn, ~p"/")

      assert result == :ok
    end

    test "contains all monitors if empty", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "test monitor"
      assert html =~ "test inactive monitor"
    end

    test "contains only active monitors if setting accordingly", %{
      conn: conn,
      dashboard: dashboard
    } do
      Dashboards.update_dashboard(dashboard, %{hide_inactives: true})

      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "test monitor"
      refute html =~ "test inactive monitor"
    end
  end

  describe "dashboard by id" do
    setup [:create_default_dashboard, :create_monitors]

    test "redirects if not found", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/dashboard/non-existent")
        |> follow_redirect(conn, ~p"/")

      assert html =~ "Dashboard not found, falling back to default"
    end

    test "renders the chosen dashboard", %{conn: conn, dashboard: dashboard} do
      {:ok, _lv, html} =
        live(conn, ~p"/dashboard/#{dashboard}")

      refute html =~ "Dashboard not found, falling back to default"
    end
  end
end
