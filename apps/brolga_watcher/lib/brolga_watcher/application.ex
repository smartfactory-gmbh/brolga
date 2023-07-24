defmodule BrolgaWatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Brolga.Monitoring
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: BrolgaWatcher.Worker.start_link(arg)
      {DynamicSupervisor, strategy: :one_for_one, name: BrolgaWatcher.DynamicSupervisor},
      BrolgaWatcher.Redix
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    result = Supervisor.start_link(children, strategy: :one_for_one)
    start_watchers()
    result
  end

  defp start_watchers() do
    Monitoring.list_active_monitor_ids()
    |> Enum.each(fn monitor_id ->
      BrolgaWatcher.Worker.start(monitor_id)
    end)
  end
end
