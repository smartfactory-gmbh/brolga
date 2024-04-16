defmodule BrolgaWeb.MonitorLiveTest do
  alias Brolga.Monitoring
  use BrolgaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Brolga.MonitoringFixtures

  @create_attrs %{
    name: "Test monitor",
    url: "https://test.local/",
    interval_in_minutes: 5
  }
  @update_attrs %{
    name: "Updated name",
    url: "https://test.local/",
    interval_in_minutes: 5
  }
  @invalid_attrs %{
    name: "",
    url: "",
    interval_in_minutes: nil
  }

  setup :register_and_log_in_user

  defp create_monitor(_) do
    monitor = monitor_fixture()
    %{monitor: monitor}
  end

  describe "Index" do
    setup [:create_monitor]

    test "lists all monitors", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/monitors")

      assert html =~ "Listing Monitors"
    end

    test "saves new monitor", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitors")

      assert index_live |> element("a", "New Monitor") |> render_click() =~
               "New Monitor"

      assert_patch(index_live, ~p"/admin/monitors/new")

      assert index_live
             |> form("#monitor-form", monitor: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monitor-form", monitor: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monitors")

      html = render(index_live)
      assert html =~ "Monitor created successfully"
    end

    test "imports new monitor", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitors/import")

      sample_json =
        [
          %{
            id: "c9b4f2a9-085a-4f53-ad8a-97480c167c0d",
            name: "test",
            url: "https://test.local",
            interval_in_minutes: 1,
            active: true,
            timeout_in_seconds: 10,
            inserted_at: ~N"2023-10-26T09:15:18",
            updated_at: ~N"2024-02-27T10:22:38"
          }
        ]
        |> Jason.encode!()

      assert Monitoring.get_monitor("c9b4f2a9-085a-4f53-ad8a-97480c167c0d") == nil

      index_live
      |> file_input("#monitor-import-form", :import_file, [
        %{
          last_modified: 1_594_171_879_000,
          name: "test.json",
          content: sample_json,
          size: String.length(sample_json),
          type: "application/json"
        }
      ])
      |> render_upload("test.json")

      assert index_live
             |> form("#monitor-import-modal #monitor-import-form")
             |> render_submit() =~ "test.json"

      refute Monitoring.get_monitor("c9b4f2a9-085a-4f53-ad8a-97480c167c0d") == nil
    end

    test "updates monitor in listing", %{conn: conn, monitor: monitor} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitors")

      assert index_live |> element("#monitors-#{monitor.id} a", "Edit") |> render_click() =~
               "Edit Monitor"

      assert_patch(index_live, ~p"/admin/monitors/#{monitor}/edit")

      assert index_live
             |> form("#monitor-form", monitor: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monitor-form", monitor: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monitors")

      html = render(index_live)
      assert html =~ "Monitor updated successfully"
    end

    test "deletes monitor in listing", %{conn: conn, monitor: monitor} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitors")

      assert index_live |> element("#monitors-#{monitor.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#monitors-#{monitor.id}")
    end
  end

  describe "Show" do
    setup [:create_monitor]

    test "displays monitor", %{conn: conn, monitor: monitor} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/monitors/#{monitor}")

      assert html =~ "Show Monitor"
    end

    test "updates monitor within modal", %{conn: conn, monitor: monitor} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/monitors/#{monitor}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Monitor"

      assert_patch(show_live, ~p"/admin/monitors/#{monitor}/show/edit")

      assert show_live
             |> form("#monitor-form", monitor: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#monitor-form", monitor: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/monitors/#{monitor}")

      html = render(show_live)
      assert html =~ "Monitor updated successfully"
    end
  end
end
