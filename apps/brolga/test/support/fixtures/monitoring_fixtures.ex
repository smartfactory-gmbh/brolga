defmodule Brolga.MonitoringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brolga.Monitoring` context.
  """

  @doc """
  Generate a monitor.
  """
  def monitor_fixture(attrs \\ %{}) do
    {:ok, monitor} =
      attrs
      |> Enum.into(%{
        name: "some name",
        url: "some url",
        interval_in_minutes: 42
      })
      |> Brolga.Monitoring.create_monitor()

    monitor
  end
end
