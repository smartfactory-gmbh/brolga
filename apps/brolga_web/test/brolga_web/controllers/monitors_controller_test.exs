defmodule BrolgaWeb.MonitorsControllerTest do
  use BrolgaWeb.ConnCase

  import Brolga.MonitoringFixtures

  setup :register_and_log_in_user

  describe "export" do
    test "exports all monitors", %{conn: conn} do
      monitor_fixture(%{name: "test1"})
      monitor_fixture(%{name: "test2"})

      conn = get(conn, ~p"/admin/export")

      body = json_response(conn, 200)
      assert body |> Enum.at(0) |> Map.get("name") == "test1"
      assert body |> Enum.at(1) |> Map.get("name") == "test2"
    end
  end
end
