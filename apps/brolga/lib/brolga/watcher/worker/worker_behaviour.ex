defmodule Brolga.Watcher.Worker.WorkerBehaviour do
  @moduledoc """
  The behaviour of a watcher worker.
  It should simply be able to start and stop monitoring the
  given monitor id
  """
  alias Ecto.UUID

  @callback start(monitor_id :: UUID) :: :ok
  @callback stop(monitor_id :: UUID) :: :ok
end
