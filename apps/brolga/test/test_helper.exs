Mox.defmock(
  Brolga.HttpClientMock,
  for: HTTPoison.Base
)

Application.put_env(
  :brolga,
  :adapters,
  http: Brolga.HttpClientMock
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Brolga.Repo, :manual)
