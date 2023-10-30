defmodule BrolgaWeb.MonitorControllerTest do
  use BrolgaWeb.ConnCase

  import Brolga.MonitoringFixtures
  import Mox

  @create_attrs %{name: "some name", url: "some url", interval_in_minutes: 42}
  @update_attrs %{name: "some updated name", url: "some updated url", interval_in_minutes: 43}
  @invalid_attrs %{name: nil, url: nil, interval_in_minutes: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all monitors", %{conn: conn} do
      conn = get(conn, ~p"/admin/monitors")
      assert html_response(conn, 200) =~ "Listing Monitors"
    end
  end

  describe "new monitor" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/monitors/new")
      assert html_response(conn, 200) =~ "New Monitor"
    end
  end

  describe "create monitor" do
    test "redirects to show when data is valid", %{conn: conn} do
      expect(Brolga.Watcher.WorkerMock, :start, fn _id, _immediate -> :ok end)

      conn = post(conn, ~p"/admin/monitors", monitor: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/monitors/#{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/monitors", monitor: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Monitor"
    end
  end

  describe "edit monitor" do
    setup [:create_monitor]

    test "renders form for editing chosen monitor", %{conn: conn, monitor: monitor} do
      conn = get(conn, ~p"/admin/monitors/#{monitor}/edit")
      assert html_response(conn, 200) =~ "Edit Monitor"
    end
  end

  describe "update monitor" do
    setup [:create_monitor]

    test "redirects when data is valid", %{conn: conn, monitor: monitor} do
      expect(Brolga.Watcher.WorkerMock, :start, fn _id, _immediate -> :ok end)

      conn = put(conn, ~p"/admin/monitors/#{monitor}", monitor: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/monitors/#{monitor}"

      conn = get(conn, ~p"/admin/monitors/#{monitor}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, monitor: monitor} do
      conn = put(conn, ~p"/admin/monitors/#{monitor}", monitor: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Monitor"
    end
  end

  describe "delete monitor" do
    setup [:create_monitor]

    test "deletes chosen monitor", %{conn: conn, monitor: monitor} do
      expect(Brolga.Watcher.WorkerMock, :stop, fn monitor_id ->
        assert monitor_id == monitor.id
        :ok
      end)

      conn = delete(conn, ~p"/admin/monitors/#{monitor}")
      assert redirected_to(conn) == ~p"/admin/monitors"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/monitors/#{monitor}")
      end
    end
  end

  defp create_monitor(_) do
    monitor = monitor_fixture()
    %{monitor: monitor}
  end
end
