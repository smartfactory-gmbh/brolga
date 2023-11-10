defmodule Brolga.MonitoringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brolga.Monitoring` context.
  """

  import Mox

  @doc """
  Generate a monitor.
  """
  @spec monitor_fixture(attrs :: any) :: Brolga.Monitoring.Monitor.t()
  def monitor_fixture(attrs \\ %{}) do
    expect(Brolga.Watcher.WorkerMock, :start, fn _id, _immediate -> :ok end)

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

  @doc """
  Generate a monitor_result.
  """
  def monitor_result_fixture(attrs \\ %{}) do
    {:ok, monitor_result} =
      attrs
      |> Enum.into(%{
        reached: true,
        monitor_id: monitor_fixture().id
      })
      |> Brolga.Monitoring.create_monitor_result()

    monitor_result
  end

  @doc """
  Generate a unique monitor_tag name.
  """
  def unique_monitor_tag_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a monitor_tag.
  """
  def monitor_tag_fixture(attrs \\ %{}) do
    {:ok, monitor_tag} =
      attrs
      |> Enum.into(%{
        name: unique_monitor_tag_name()
      })
      |> Brolga.Monitoring.create_monitor_tag()

    monitor_tag
  end
end
