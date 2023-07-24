defmodule BrolgaWatcher.Worker do
  use Task
  alias Brolga.Monitoring.Monitor
  alias Brolga.Repo

  def start_link(monitor_id) do
    Task.start_link(__MODULE__, :run, [monitor_id])
  end

  def run(monitor_id) do
    start_time = DateTime.now!("Etc/UTC")
    monitor = refresh_monitor(monitor_id)
    IO.puts("Pinging #{monitor.name}...")
    process(monitor)
    end_time = DateTime.now!("Etc/UTC")

    elapsed = DateTime.diff(start_time, end_time)

    Process.sleep(1000 * 60 * monitor.interval_in_minutes - elapsed)
    run(monitor_id)
  end

  @spec process(Monitor.t()) :: no_return
  defp process(monitor) do
    IO.inspect(monitor)
  end

  defp refresh_monitor(monitor_id) do
    Monitor |> Repo.get!(monitor_id)
  end
end
