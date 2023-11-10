defmodule BrolgaCron.Task.Provider do
  @moduledoc """
  Implements the BrolgaCron.Task.ProviderBehaviour
  Always use this outside of this module, as it acts as a proxy
  module for any configured Provider
  """
  @behaviour BrolgaCron.Task.ProviderBehaviour

  defp impl, do: Application.get_env(:brolga_cron, :adapters)[:tasks_provider]

  @impl true
  def tasks(), do: impl().tasks()
end
