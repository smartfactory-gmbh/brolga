defmodule Brolga.Watcher.Worker do
  @moduledoc """
  This module contains the logic for the woker in charge of
  periodically ping a target and correctly report the result.

  They are spawned under a DynamicSupervisor so they can be
  started and stopped on the fly. This will happen when a monitor
  is updated.
  """
  @behaviour Brolga.Watcher.Worker.WorkerBehaviour

  defp impl, do: Application.get_env(:brolga, :adapters)[:watcher_worker]

  def start(monitor_id, immediate \\ true), do: impl().start(monitor_id, immediate)
  def stop(monitor_id), do: impl().stop(monitor_id)
end
