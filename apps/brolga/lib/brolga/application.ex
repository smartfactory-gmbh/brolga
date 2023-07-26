defmodule Brolga.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Brolga.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Brolga.PubSub},
      # Start Finch
      {Finch, name: Brolga.Finch}
      # Start a worker by calling: Brolga.Worker.start_link(arg)
      # {Brolga.Worker, arg}
    ]

    results = Supervisor.start_link(children, strategy: :one_for_one, name: Brolga.Supervisor)

    Brolga.AlertNotifiers.log_enabled_notifiers()

    results
  end
end
