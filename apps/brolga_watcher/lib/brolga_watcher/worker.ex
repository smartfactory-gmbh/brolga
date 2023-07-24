defmodule BrolgaWatcher.Worker do
  use Task
  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  def start_link(monitor_id) do
    Task.start_link(__MODULE__, :run, [monitor_id])
  end

  @spec run(Ecto.UUID.t()) :: no_return
  def run(monitor_id) do
    start_time = DateTime.now!("Etc/UTC")
    monitor = refresh_monitor(monitor_id)
    process(monitor)
    end_time = DateTime.now!("Etc/UTC")

    elapsed = DateTime.diff(start_time, end_time)

    Process.sleep(1000 * 60 * monitor.interval_in_minutes - elapsed)
    run(monitor_id)
  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, name: name, timeout_in_seconds: timeout}) do
    HTTPoison.start()
    case HTTPoison.get(url, timeout: timeout * 1000) do
      {:ok, _response} ->
        :logger.info("Ping to #{name} suceeded")
      {:error, error} ->
        :logger.error("Ping to #{name} failed")
        IO.inspect(error)
    end
  end

  @spec refresh_monitor(Ecto.UUID.t()) :: Monitor.t()
  defp refresh_monitor(monitor_id) do
    Monitoring.get_active_monitor!(monitor_id)
  end
end
