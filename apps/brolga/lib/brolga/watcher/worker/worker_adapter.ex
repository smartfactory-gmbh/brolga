defmodule Brolga.Watcher.Worker.WorkerAdapter do
  @moduledoc """
  This module contains the logic for the woker in charge of
  periodically ping a target and correctly report the result.

  They are spawned under a DynamicSupervisor so they can be
  started and stopped on the fly. This will happen when a monitor
  is updated.
  """

  @behaviour Brolga.Watcher.Worker.WorkerBehaviour

  @max_delay_in_seconds 120
  # Chrome user agent
  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"

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

  def start_link({monitor_id, immediate}) do
    delay =
      if immediate do
        0
      else
        :rand.uniform(@max_delay_in_seconds)
      end

    Task.start_link(__MODULE__, :run, [monitor_id, true, delay])
  end

  @spec run_once(monitor_id :: Ecto.UUID.t()) :: no_return
  def run_once(monitor_id), do: run(monitor_id, false)

  @spec run(monitor_id :: Ecto.UUID.t(), repeat :: boolean, delay :: non_neg_integer) :: no_return
  def run(monitor_id, repeat, delay \\ 0) do
    Process.sleep(1000 * delay)
    start_time = DateTime.now!("Etc/UTC")
    monitor = refresh_monitor(monitor_id)
    process(monitor)
    end_time = DateTime.now!("Etc/UTC")

    elapsed = DateTime.diff(start_time, end_time)

    if repeat do
      run(monitor_id, true, 60 * monitor.interval_in_minutes - elapsed)
    end
  end

  @spec validate_response(HTTPoison.Response.t(), Monitor.t()) :: no_return
  defp validate_response(response, monitor) do
    {success, message} =
      if response.status_code in 200..300 do
        {true, "Successful hit"}
      else
        {false, "Error: #{response.body}"}
      end

    Monitoring.create_monitor_result(%{
      reached: success,
      monitor_id: monitor.id,
      status_code: response.status_code,
      message: String.slice(message, 0..231)
    })
  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, timeout_in_seconds: timeout} = monitor) do
    client = get_http_client()
    client.start()

    headers = [{"User-Agent", @user_agent}]

    options = [
      timeout: timeout * 1000,
      follow_redirect: true
    ]

    case client.get(url, headers, options) do
      {:ok, response} ->
        validate_response(response, monitor)

      {:error, %HTTPoison.Error{reason: error}} ->
        message = "Something went wrong: #{error}" |> String.slice(0..231)

        Monitoring.create_monitor_result(%{
          reached: false,
          monitor_id: monitor.id,
          message: message
        })

      {:error, _} ->
        message = "An unknown error occurred"

        Monitoring.create_monitor_result(%{
          reached: false,
          monitor_id: monitor.id,
          message: message
        })
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
  def start(monitor_id, immediate \\ true) do
    redis_client = get_redis_client()

    # If it was running, kill it first
    stop(monitor_id)

    spec = {__MODULE__, {monitor_id, immediate}}
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
