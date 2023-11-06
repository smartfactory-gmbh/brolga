defmodule Mix.Tasks.CleanupOldResults do
  @moduledoc """
  Cleans up the monitor results older than one month

  Usage:

  mix cleanup_old_results
  """
  alias Brolga.Monitoring
  use Mix.Task

  @shortdoc "Cleans up the monitor results older than one month"
  def run(_) do
    Monitoring.cleanup_monitor_results()
  end
end
