defmodule BrolgaCron.Task.StaticProviderTest do
  use Brolga.DataCase
  import ExUnit.CaptureLog
  require Logger
  import Mox

  describe "tasks/0" do
    test "returns the expected job lists" do
      tasks = BrolgaCron.Task.StaticProvider.tasks()

      assert tasks == [
               %BrolgaCron.Task{
                 id: :cleanup_monitoring_results,
                 interval_in_seconds: 86_400,
                 action: &Brolga.Monitoring.cleanup_monitor_results/0
               }
             ]
    end
  end
end
