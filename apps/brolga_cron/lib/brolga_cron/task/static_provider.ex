defmodule BrolgaCron.Task.StaticProvider do
  @moduledoc """
  Implements the BrolgaCron.Task.ProviderBehaviour
  Simply provides hard-coded tasks
  """
  @behaviour BrolgaCron.Task.ProviderBehaviour

  @hourly 3600
  @daily @hourly * 24

  alias BrolgaCron.Task

  @impl true
  def tasks(),
    do: [
      %Task{
        id: :cleanup_monitoring_results,
        interval_in_seconds: @daily,
        action: &Brolga.Monitoring.cleanup_monitor_results/0
      }
    ]
end
