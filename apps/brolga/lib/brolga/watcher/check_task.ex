defmodule Brolga.Watcher.CheckTask do
  @moduledoc """
  Task that contains the logic to check a monitor target
  and write back the result into database. It is spawned under
  a Task supervisor and can crash without impacting the actual
  Scheduler.
  """
  use Task
  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  require Logger

  # Chrome user agent
  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"

  def start_link(monitor_id) do
    Task.start_link(__MODULE__, :run, [monitor_id])
  end

  @spec run(monitor_id :: Ecto.UUID.t()) :: no_return
  def run(monitor_id) do
    monitor = refresh_monitor(monitor_id)
    process(monitor)
  end

  @spec refresh_monitor(Ecto.UUID.t()) :: Monitor.t()
  defp refresh_monitor(monitor_id) do
    Monitoring.get_active_monitor!(monitor_id)
  end

  @spec validate_response(HTTPoison.Response.t(), Monitor.t()) :: no_return
  defp validate_response(response, monitor) do
    {success, message} =
      cond do
        response.status in 200..300 -> {true, "Successful hit"}
        is_nil(response.body) -> {false, "Unknown Error"}
        response.body == "" -> {false, "Unknown Error"}
        true -> {false, "Error: #{response.body}"}
      end

    Monitoring.create_monitor_result(%{
      reached: success,
      monitor_id: monitor.id,
      status_code: response.status,
      message: String.slice(message, 0..231)
    })
  end

  @spec process(Monitor.t()) :: no_return
  defp process(%Monitor{url: url, timeout_in_seconds: timeout} = monitor) do
    retry = Application.get_env(:brolga, :http_client)[:no_retry] != true

    options = [
      url: url,
      headers: %{user_agent: @user_agent},
      pool_timeout: timeout * 1000,
      receive_timeout: timeout * 1000
    ]

    options =
      case retry do
        false -> options |> Keyword.put(:retry, false)
        true -> options
      end

    req = Req.new(options)

    case Req.get(req) do
      {:ok, response} ->
        validate_response(response, monitor)

      {:error, exception} ->
        message =
          case exception do
            %{message: message} -> "Something went wrong: #{message}"
            %{reason: reason} -> "Something went wrong: #{reason}"
            _ -> "Something went wrong."
          end
          |> String.slice(0..231)

        Monitoring.create_monitor_result(%{
          reached: false,
          monitor_id: monitor.id,
          message: message
        })
    end
  end
end
