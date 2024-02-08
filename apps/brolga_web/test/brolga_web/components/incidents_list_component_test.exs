defmodule BrolgaWeb.IncidentsListComponentTest do
  use BrolgaWeb.ConnCase
  import Phoenix.LiveViewTest

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  alias BrolgaWeb.IncidentsListComponent

  setup :register_and_log_in_user

  describe "render/1" do
    test "renders a list of incidents" do
      monitor = monitor_fixture()
      incident_fixture(%{monitor_id: monitor.id})
      incident_fixture(%{monitor_id: monitor.id})
      incident_fixture(%{monitor_id: monitor.id})
      incident_fixture(%{monitor_id: monitor.id})
      incident_fixture(%{monitor_id: monitor.id})
      incident_fixture(%{monitor_id: monitor.id})
      open_incident_fixture(%{monitor_id: monitor.id})

      rendered = render_component(IncidentsListComponent, id: "incidents-list", monitor: monitor)
      assert rendered =~ "Incident started at"
    end

    test "can aribtrarily close an incident", %{conn: conn} do
      monitor = monitor_fixture()
      open_incident_fixture(%{monitor_id: monitor.id})

      {:ok, view, html} = live(conn, "/admin/monitors/#{monitor.id}/")
      assert html =~ "Mark as solved"

      rendered = view |> element("a", "Mark as solved") |> render_click()
      refute rendered =~ "Mark as solved"
    end
  end
end
