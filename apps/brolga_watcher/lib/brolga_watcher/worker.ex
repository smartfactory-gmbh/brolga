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

  @spec validate_response(HTTPoison.Response.t(), Monitor.t()) :: no_return
  defp validate_response(response, monitor) do
    {success, _message} = if response.status_code in 200..300 do
      {true, "Successful hit: #{response.status_code}"}
    else
      {false, "Error: #{response.body}"}
    end
    Monitoring.create_monitor_result(%{reached: success, monitor_id: monitor.id})

  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, timeout_in_seconds: timeout} = monitor) do
    HTTPoison.start()
    case HTTPoison.get(url, timeout: timeout * 1000) do
      {:ok, response} ->
        validate_response(response, monitor)
      {:error, _error} ->
        Monitoring.create_monitor_result(%{reached: false, monitor_id: monitor.id})
    end
  end

  @spec refresh_monitor(Ecto.UUID.t()) :: Monitor.t()
  defp refresh_monitor(monitor_id) do
    Monitoring.get_active_monitor!(monitor_id)
  end
end
