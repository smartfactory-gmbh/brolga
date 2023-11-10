defmodule BrolgaCron.Runner do
  @moduledoc """
  Regularly execute actions based on their configuration (see Task struct).
  Can be configured to use a specific provider, currently a static provider is used
  """
  use GenServer

  alias BrolgaCron.Task
  alias BrolgaCron.Task.Provider

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    tasks = Provider.tasks()
    tasks |> Enum.each(&setup_task(&1))
    {:ok, tasks}
  end

  @impl true
  def handle_info({:execute, %Task{action: action, args: args}}, tasks) do
    apply(action, args)
    {:noreply, tasks}
  end

  defp setup_task(%Task{interval_in_seconds: interval_in_seconds} = task) do
    :timer.send_interval(interval_in_seconds * 1000, {:execute, task})
  end

  def execute_now(id) do
    task =
      Provider.tasks()
      |> Enum.find(fn %Task{id: task_id} -> task_id == id end)

    case task do
      nil -> :not_found
      %Task{action: action, args: args} -> apply(action, args)
    end
  end
end
