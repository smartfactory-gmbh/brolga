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
      {DynamicSupervisor, strategy: :one_for_one, name: BrolgaWatcher.DynamicSupervisor}
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
      spec = {BrolgaWatcher.Worker, monitor_id}
      DynamicSupervisor.start_child(BrolgaWatcher.DynamicSupervisor, spec)
    end)
  end
end
