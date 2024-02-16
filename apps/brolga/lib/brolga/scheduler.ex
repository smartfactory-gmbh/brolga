defmodule Brolga.Scheduler do
  @moduledoc """
  A basic engine to keep track of monitors that are running and when 
  they should do their next check. Calls new CheckTasks regularly, but
  do not monitor them.
  """
  alias Brolga.Monitoring
  use GenServer

  require Logger

  # 10 seconds before starting everything on init
  @init_delay 10 * 1000
  # 1 second delay when starting a new monitor
  @monitor_start_delay 1000

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Add the monitor to the list of scheduled tasks. Will run checks periodically
  until stop_monitor(monitor_id) is called.

  ## Options

  :with_delay - bool (default false) - Whether a delay should be applied instead
  of starting the monitoring immediately. The delay time is a random value within
  the period time.

  ## Examples

  iex> Brolga.Scheduler.start_monitor("f399c25d-dc86-4742-9591-3b0c9db0d648", with_delay: true)
  :ok
  """
  @spec start_monitor(monitor_id :: Ecto.UUID.t(), opts :: Keyword.t()) :: :ok
  def start_monitor(monitor_id, opts \\ []) do
    GenServer.cast(__MODULE__, {:start, monitor_id, opts})
  end

  @spec stop_monitor(monitor_id :: Ecto.UUID.t()) :: :ok
  def stop_monitor(monitor_id) do
    GenServer.cast(__MODULE__, {:stop, monitor_id})
  end

  def stop_monitor_sync(monitor_id) do
    GenServer.call(__MODULE__, {:stop, monitor_id})
  end

  @spec get_monitored_ids() :: [Ecto.UUID.t()]
  def get_monitored_ids() do
    GenServer.call(__MODULE__, :list_ids)
  end

  @spec stop_all() :: :ok
  def stop_all() do
    get_monitored_ids()
    |> Enum.each(&stop_monitor_sync/1)

    :ok
  end

  # Server (callbacks)

  @impl true
  def init(_opts) do
    Process.send_after(self(), :init, @init_delay)
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:start, monitor_id, opts}, state) do
    with_delay = opts |> Keyword.get(:with_delay, false)

    delay_in_ms =
      if with_delay do
        case Monitoring.get_monitor(monitor_id) do
          nil -> @monitor_start_delay
          monitor -> :rand.uniform(monitor.interval_in_minutes * 60 * 1000)
        end
      else
        @monitor_start_delay
      end

    {
      :noreply,
      state
      |> remove_monitor(monitor_id)
      |> upsert_monitor(monitor_id, delay_in_ms)
    }
  end

  @impl true
  def handle_cast({:stop, monitor_id}, state) do
    {
      :noreply,
      state
      |> remove_monitor(monitor_id)
    }
  end

  @impl true
  def handle_call({:stop, monitor_id}, _from, state) do
    {
      :reply,
      :ok,
      state
      |> remove_monitor(monitor_id)
    }
  end

  @impl true
  def handle_call(:list_ids, _from, state) do
    {:reply, Map.keys(state), state}
  end

  @impl true
  def handle_info({:process, monitor_id}, state) do
    # Spawn task and schedule next run
    state =
      case Monitoring.get_active_monitor(monitor_id) do
        nil ->
          state |> remove_monitor(monitor_id)

        monitor ->
          Task.Supervisor.start_child(Brolga.Watcher, Brolga.Watcher.CheckTask, :run, [monitor_id])

          state |> upsert_monitor(monitor_id, monitor.interval_in_minutes * 60 * 1000)
      end

    {:noreply, state}
  end

  @impl true
  def handle_info(:init, state) do
    Monitoring.list_active_monitor_ids()
    |> Enum.each(fn id -> start_monitor(id, with_delay: true) end)

    {:noreply, state}
  end

  # private utils

  defp remove_monitor(state, monitor_id) do
    # Remove the id from the state
    # If it was present, also cancels the running timer
    case Map.pop(state, monitor_id) do
      {nil, state} ->
        state

      {timer, state} ->
        Process.cancel_timer(timer)
        state
    end
  end

  defp upsert_monitor(state, monitor_id, start_delay) do
    # Insert or update the given monitor id
    # NOTE: does not cancel the running timer, use remove_monitor/2 beforehand if that's the wanted behaviour

    new_timer = Process.send_after(self(), {:process, monitor_id}, start_delay)
    state |> Map.put(monitor_id, new_timer)
  end
end
