defmodule BrolgaWeb.MonitorComponentsTest do
  use BrolgaWeb.ConnCase
  import Phoenix.LiveViewTest

  import Brolga.MonitoringFixtures

  alias BrolgaWeb.MonitorComponents

  describe "monitor state card" do
    test "monitor_state_card/1 renders an active and up monitor" do
      monitor =
        monitor_fixture(%{name: "foo monitor"})
        # fake query aggregation
        |> Map.put(:uptime, 0.98)
        # fake query aggregation
        |> Map.put(:is_down, false)

      rendered = render_component(&MonitorComponents.monitor_state_card/1, monitor: monitor)

      assert rendered =~ "foo monitor"
      assert rendered =~ "border-state-up"
      assert rendered =~ "bg-state-up"
    end

    test "monitor_state_card/1 renders an active and down monitor" do
      monitor =
        monitor_fixture(%{name: "foo monitor"})
        # fake query aggregation
        |> Map.put(:uptime, 0.98)
        # fake query aggregation
        |> Map.put(:is_down, true)

      rendered = render_component(&MonitorComponents.monitor_state_card/1, monitor: monitor)

      assert rendered =~ "foo monitor"
      assert rendered =~ "border-state-down"
      assert rendered =~ "bg-state-down"
    end

    test "monitor_state_card/1 renders an inactive monitor" do
      monitor =
        monitor_fixture(%{name: "foo monitor", active: false})

      rendered = render_component(&MonitorComponents.monitor_state_card/1, monitor: monitor)

      assert rendered =~ "foo monitor"
      assert rendered =~ "Inactive"
      assert rendered =~ "border-state-inactive"
      assert rendered =~ "bg-state-inactive"
    end
  end
end
