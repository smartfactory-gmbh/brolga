defmodule BrolgaWeb.MonitorTagLiveTest do
  use BrolgaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Brolga.MonitoringFixtures

  @create_attrs %{name: "valid tag"}
  @update_attrs %{name: "updated tag"}
  @invalid_attrs %{name: ""}

  setup :register_and_log_in_user

  defp create_monitor_tag(_) do
    monitor_tag = monitor_tag_fixture()
    %{monitor_tag: monitor_tag}
  end

  describe "Index" do
    setup [:create_monitor_tag]

    test "lists all monitor_tags", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/monitor-tags")

      assert html =~ "Listing Monitor tags"
    end

    test "saves new monitor_tag", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitor-tags")

      assert index_live |> element("a", "New Monitor tag") |> render_click() =~
               "New Monitor tag"

      assert_patch(index_live, ~p"/admin/monitor-tags/new")

      assert index_live
             |> form("#monitor_tag-form", monitor_tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monitor_tag-form", monitor_tag: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monitor-tags")

      html = render(index_live)
      assert html =~ "Monitor tag created successfully"
    end

    test "updates monitor_tag in listing", %{conn: conn, monitor_tag: monitor_tag} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitor-tags")

      assert index_live |> element("#monitor_tags-#{monitor_tag.id} a", "Edit") |> render_click() =~
               "Edit Monitor tag"

      assert_patch(index_live, ~p"/admin/monitor-tags/#{monitor_tag}/edit")

      assert index_live
             |> form("#monitor_tag-form", monitor_tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monitor_tag-form", monitor_tag: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monitor-tags")

      html = render(index_live)
      assert html =~ "Monitor tag updated successfully"
    end

    test "deletes monitor_tag in listing", %{conn: conn, monitor_tag: monitor_tag} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/monitor-tags")

      assert index_live
             |> element("#monitor_tags-#{monitor_tag.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#monitor_tags-#{monitor_tag.id}")
    end
  end

  describe "Show" do
    setup [:create_monitor_tag]

    test "displays monitor_tag", %{conn: conn, monitor_tag: monitor_tag} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/monitor-tags/#{monitor_tag}")

      assert html =~ "Show Monitor tag"
    end

    test "updates monitor_tag within modal", %{conn: conn, monitor_tag: monitor_tag} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/monitor-tags/#{monitor_tag}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Monitor tag"

      assert_patch(show_live, ~p"/admin/monitor-tags/#{monitor_tag}/show/edit")

      assert show_live
             |> form("#monitor_tag-form", monitor_tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#monitor_tag-form", monitor_tag: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/monitor-tags/#{monitor_tag}")

      html = render(show_live)
      assert html =~ "Monitor tag updated successfully"
    end
  end
end
