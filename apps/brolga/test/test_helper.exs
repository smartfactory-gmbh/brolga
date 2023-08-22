Mox.defmock(
  Brolga.Watcher.WorkerMock,
  for: Brolga.Watcher.Worker.WorkerBehaviour
)

Mox.defmock(
  Brolga.HttpClientMock,
  for: HTTPoison.Base
)

Mox.defmock(
  Brolga.RedixMock,
  for: Brolga.Watcher.Redix.RedixBehaviour
)

Application.put_env(
  :brolga,
  :adapters,
  watcher_worker: Brolga.Watcher.WorkerMock,
  http: Brolga.HttpClientMock,
  redis: Brolga.RedixMock
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Brolga.Repo, :manual)
