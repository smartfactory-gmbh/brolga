defmodule Brolga.Watcher.Worker.WorkerAdapter do
  @moduledoc """
  This module contains the logic for the woker in charge of
  periodically ping a target and correctly report the result.

  They are spawned under a DynamicSupervisor so they can be
  started and stopped on the fly. This will happen when a monitor
  is updated.
  """

  @behaviour Brolga.Watcher.Worker.WorkerBehaviour

  use Task
  require Logger
  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  defp get_http_client do
    Application.fetch_env!(:brolga, :adapters) |> Keyword.get(:http, HTTPoison)
  end

  defp get_redis_client do
    Application.fetch_env!(:brolga, :adapters) |> Keyword.get(:redis, Brolga.Watcher.Redix)
  end

  def start_link(monitor_id) do
    Task.start_link(__MODULE__, :run, [monitor_id, true])
  end

  @spec run_once(monitor_id :: Ecto.UUID.t()) :: no_return
  def run_once(monitor_id), do: run(monitor_id, false)

  @spec run(monitor_id :: Ecto.UUID.t(), repeat :: boolean) :: no_return
  defp run(monitor_id, repeat) do
    start_time = DateTime.now!("Etc/UTC")
    monitor = refresh_monitor(monitor_id)
    process(monitor)
    end_time = DateTime.now!("Etc/UTC")

    elapsed = DateTime.diff(start_time, end_time)

    if repeat do
      Process.sleep(1000 * 60 * monitor.interval_in_minutes - elapsed)
      run(monitor_id, true)
    end
  end

  @spec validate_response(HTTPoison.Response.t(), Monitor.t()) :: no_return
  defp validate_response(response, monitor) do
    {success, message} =
      if response.status_code in 200..300 do
        {true, "Successful hit: #{response.status_code}"}
      else
        {false, "Error: #{response.body}"}
      end

    Monitoring.create_monitor_result(%{
      reached: success,
      monitor_id: monitor.id,
      message: String.slice(message, 0..254)
    })
  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, timeout_in_seconds: timeout} = monitor) do
    client = get_http_client()
    client.start()

    headers = []

    options = [
      timeout: timeout * 1000,
      follow_redirect: true
    ]

    case client.get(url, headers, options) do
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

  @spec get_pid(monitor_id :: Ecto.UUID) :: {:ok, pid()} | {:error, :not_running}
  def get_pid(monitor_id) do
    redis_client = get_redis_client()
    pid = redis_client.get!("monitor-#{monitor_id}")

    if pid do
      result = :erlang.list_to_pid(to_charlist(pid))
      {:ok, result}
    else
      {:error, :not_running}
    end
  end

  @impl Brolga.Watcher.Worker.WorkerBehaviour
  def start(monitor_id) do
    redis_client = get_redis_client()

    # If it was running, kill it first
    stop(monitor_id)

    spec = {__MODULE__, monitor_id}
    {:ok, worker_id} = DynamicSupervisor.start_child(Brolga.Watcher.DynamicSupervisor, spec)

    redis_client.store!(
      "monitor-#{monitor_id}",
      to_string(:erlang.pid_to_list(worker_id))
    )

    :logger.debug("Monitor #{monitor_id} has been started")
    :ok
  end

  @impl Brolga.Watcher.Worker.WorkerBehaviour
  def stop(monitor_id) do
    case get_pid(monitor_id) do
      {:ok, watcher_pid} ->
        DynamicSupervisor.terminate_child(
          Brolga.Watcher.DynamicSupervisor,
          watcher_pid
        )

        Logger.debug("Monitor #{monitor_id} has been stopped")

      {:error, :not_running} ->
        Logger.debug("Monitor #{monitor_id} was already stopped")
    end

    :ok
  end
end
