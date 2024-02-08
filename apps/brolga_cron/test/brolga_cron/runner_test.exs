defmodule BrolgaCron.RunnerTest do
  use Brolga.DataCase
  import ExUnit.CaptureLog
  require Logger

  defp mock_logging_tasks(),
    do: [
      %BrolgaCron.Task{
        id: :test,
        interval_in_seconds: 1,
        action: fn -> Logger.warning("Called") end,
        args: []
      }
    ]

  describe "execute_now/1" do
    test "executes existing action" do
      result = BrolgaCron.Runner.execute_now(:cleanup_monitoring_results)

      assert result == {0, nil}
    end

    test "returns flag when action is not found" do
      result = BrolgaCron.Runner.execute_now(:nonexistent)

      assert result == :not_found
    end
  end

  describe "handle_info/2" do
    test ":execute runs the task" do
      tasks = mock_logging_tasks()
      [task | _] = tasks

      fun = fn ->
        result = BrolgaCron.Runner.handle_info({:execute, task}, tasks)
        assert result == {:noreply, tasks}
      end

      assert capture_log(fun) =~ "Called"
    end
  end
end
