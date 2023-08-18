Mox.defmock(
  Brolga.Watcher.WorkerMock,
  for: Brolga.Watcher.Worker.WorkerBehaviour
)

Application.put_env(:brolga, :adapters, watcher_worker: Brolga.Watcher.WorkerMock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Brolga.Repo, :manual)
