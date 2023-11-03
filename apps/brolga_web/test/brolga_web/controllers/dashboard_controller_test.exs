defmodule BrolgaWeb.DashboardControllerTest do
  use BrolgaWeb.ConnCase

  import Brolga.DashboardsFixtures

  @create_attrs %{name: "some name", tags: [], monitors: []}
  @update_attrs %{name: "some updated name", tags: [], monitors: []}
  @invalid_attrs %{name: nil, tags: [], monitors: []}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all dashboards", %{conn: conn} do
      conn = get(conn, ~p"/admin/dashboards")
      assert html_response(conn, 200) =~ "Listing Dashboards"
    end
  end

  describe "new dashboard" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/dashboards/new")
      assert html_response(conn, 200) =~ "New Dashboard"
    end
  end

  describe "create dashboard" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/dashboards", dashboard: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/dashboards/#{id}"

      conn = get(conn, ~p"/admin/dashboards/#{id}")
      assert html_response(conn, 200) =~ "Dashboard #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/dashboards", dashboard: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Dashboard"
    end
  end

  describe "edit dashboard" do
    setup [:create_dashboard]

    test "renders form for editing chosen dashboard", %{conn: conn, dashboard: dashboard} do
      conn = get(conn, ~p"/admin/dashboards/#{dashboard}/edit")
      assert html_response(conn, 200) =~ "Edit Dashboard"
    end
  end

  describe "update dashboard" do
    setup [:create_dashboard]

    test "redirects when data is valid", %{conn: conn, dashboard: dashboard} do
      conn = put(conn, ~p"/admin/dashboards/#{dashboard}", dashboard: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/dashboards/#{dashboard}"

      conn = get(conn, ~p"/admin/dashboards/#{dashboard}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, dashboard: dashboard} do
      conn = put(conn, ~p"/admin/dashboards/#{dashboard}", dashboard: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Dashboard"
    end
  end

  describe "delete dashboard" do
    setup [:create_dashboard]

    test "deletes chosen dashboard", %{conn: conn, dashboard: dashboard} do
      conn = delete(conn, ~p"/admin/dashboards/#{dashboard}")
      assert redirected_to(conn) == ~p"/admin/dashboards"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/dashboards/#{dashboard}")
      end
    end
  end

  defp create_dashboard(_) do
    dashboard = dashboard_fixture()
    %{dashboard: dashboard}
  end
end
