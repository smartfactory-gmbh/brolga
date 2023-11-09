defmodule BrolgaWeb.MonitorResultLiveTest do
  use BrolgaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Brolga.MonitoringFixtures

  setup :register_and_log_in_user

  defp create_monitor_results(_) do
    m1 = monitor_fixture(name: "first monitor")
    m2 = monitor_fixture(name: "second monitor")

    monitor_result_fixture(%{monitor_id: m1.id})
    monitor_result_fixture(%{monitor_id: m2.id})

    %{monitors: [m1, m2]}
  end

  describe "Index" do
    setup [:create_monitor_results]

    test "lists all monitor results", %{conn: conn, monitors: [m1, m2]} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/monitor-results")

      assert html =~ "Listing Monitor results"
      assert html =~ "for all monitors"
      assert html =~ m1.name
      assert html =~ m2.name
    end

    test "correctly injects the monitor name", %{conn: conn, monitors: [m1, m2]} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/monitor-results/#{m1.id}")

      assert html =~ "Listing Monitor results"
      assert html =~ "for first monitor"
      assert html =~ m1.name
      refute html =~ m2.name
    end

    test "can enter live mode", %{conn: conn, monitors: [m1, m2]} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitor-results")

      assert index_live
             |> render_click("enable-live-mode", %{}) =~ "Stop live mode"
    end

    test "can leave live mode", %{conn: conn, monitors: [m1, m2]} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitor-results")

      assert index_live
             |> render_click("disable-live-mode", %{}) =~ "Start live mode"
    end
  end
end
