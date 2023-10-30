defmodule BrolgaWeb.MonitorComponents do
  @moduledoc """
  Provides incident specific UI components.
  """
  use Phoenix.Component
  import BrolgaWeb.CoreComponents, only: [input: 1]
  alias Brolga.Monitoring
  alias Brolga.Monitoring.{MonitorTag, Monitor}

  def monitor_tags_select(assigns) do
    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    assigns
    |> Map.put(:type, "select")
    |> Map.put(:options, tags)
    |> input()
  end

  def monitors_select(assigns) do
    monitors =
      Monitoring.list_monitors()
      |> Enum.reduce([], fn %Monitor{id: id, name: name}, acc -> [{name, id} | acc] end)

    assigns
    |> Map.put(:type, "select")
    |> Map.put(:options, monitors)
    |> input()
  end
end
