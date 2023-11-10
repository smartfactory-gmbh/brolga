defmodule BrolgaWeb.MonitorTagComponentsTest do
  use BrolgaWeb.ConnCase
  import Phoenix.LiveViewTest

  import Brolga.MonitoringFixtures

  alias BrolgaWeb.MonitorTagComponents

  describe "tags" do
    test "tags/1 renders a list of tags" do
      tags = [
        monitor_tag_fixture(%{name: "tag1"}),
        monitor_tag_fixture(%{name: "tag2"})
      ]

      rendered = render_component(&MonitorTagComponents.tags/1, tags: tags)

      assert rendered =~ "tag1"
      assert rendered =~ "tag2"
    end
  end
end
