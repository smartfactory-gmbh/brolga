defmodule BrolgaCron.Task.ProviderBehaviour do
  @moduledoc """
  Define a way to get a tasks list for the runner.
  Implementations could be providing hard coded tasks, or read them from a file, etc...
  """
  alias BrolgaCron.Task

  @callback tasks() :: [Task.t()]
end
