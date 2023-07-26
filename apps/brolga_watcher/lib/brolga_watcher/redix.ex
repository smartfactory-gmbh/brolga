defmodule BrolgaWatcher.Redix do
  @moduledoc """
  Customer Redix module for redis management.
  Provides a small API to forward commands to a pool of redis workers
  """
  @pool_size 5

  def child_spec(_args) do
    [
      host: host,
      port: port,
      username: username,
      password: password
    ] = Application.get_env(:brolga_watcher, :redis)

    children =
      for index <- 0..(@pool_size - 1) do
        Supervisor.child_spec(
          {Redix,
           host: host, port: port, username: username, password: password, name: :"redix_#{index}"},
          id: {Redix, index}
        )
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  defp command!(command) do
    Redix.command!(:"redix_#{random_index()}", command)
  end

  defp random_index() do
    Enum.random(0..(@pool_size - 1))
  end

  def store!(key, value) do
    command!(["SET", key, value])
  end

  def get!(key) do
    command!(["GET", key])
  end
end
