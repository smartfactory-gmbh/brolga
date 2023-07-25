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
    {success, message} = if response.status_code in 200..300 do
      {true, "Successful hit: #{response.status_code}"}
    else
      {false, "Error: #{response.body}"}
    end
    Monitoring.create_monitor_result(%{
      reached: success,
      monitor_id: monitor.id,
      message: String.slice(message, 0..255)
    })

  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, timeout_in_seconds: timeout} = monitor) do
    HTTPoison.start()

    headers = []
    options = [
      timeout: timeout * 1000,
      follow_redirect: true
    ]

    case HTTPoison.get(url, headers, options) do
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

  def start(monitor_id) do

    # If it was running, kill it first
    stop(monitor_id)

    spec = {__MODULE__, monitor_id}
    {:ok, worker_id} = DynamicSupervisor.start_child(BrolgaWatcher.DynamicSupervisor, spec)


    BrolgaWatcher.Redix.store!("monitor-#{monitor_id}", to_string(:erlang.pid_to_list(worker_id)))
    :logger.debug("Monitor #{monitor_id} has been started")
  end

  def stop(monitor_id) do
    pid = BrolgaWatcher.Redix.get!("monitor-#{monitor_id}")
    if pid do
      DynamicSupervisor.terminate_child(BrolgaWatcher.DynamicSupervisor, :erlang.list_to_pid(to_charlist(pid)))
    end
    :logger.debug("Monitor #{monitor_id} has been stopped")
  end
end
