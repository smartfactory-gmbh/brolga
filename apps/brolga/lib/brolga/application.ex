defmodule Brolga.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Brolga.Monitoring

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Brolga.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Brolga.PubSub},
      # Start Finch
      {Finch, name: Brolga.Finch},
      # Start a worker by calling: Brolga.Worker.start_link(arg)
      # {Brolga.Worker, arg}
      {DynamicSupervisor, strategy: :one_for_one, name: Brolga.Watcher.DynamicSupervisor},
      Brolga.Watcher.Redix
    ]

    results = Supervisor.start_link(children, strategy: :one_for_one, name: Brolga.Supervisor)

    start_all_watchers()

    Brolga.AlertNotifiers.log_enabled_notifiers()

    results
  end

  defp start_all_watchers() do
    Monitoring.list_active_monitor_ids()
    |> Enum.each(fn monitor_id ->
      Brolga.Watcher.Worker.start(monitor_id)
    end)
  end
end
