Mox.defmock(
  BrolgaCron.Task.ProviderMock,
  for: BrolgaCron.Task.ProviderBehaviour
)

Application.put_env(
  :brolga_cron,
  :adapters,
  tasks_provider: BrolgaCron.Task.ProviderMock
)

ExUnit.start()
