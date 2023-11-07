defmodule BrolgaCron.RunnerTest do
  use Brolga.DataCase
  import ExUnit.CaptureLog
  require Logger
  import Mox

  defp mock_tasks(),
    do: [
      %BrolgaCron.Task{
        id: :test,
        interval_in_seconds: 1,
        action: fn -> :called end,
        args: []
      }
    ]

  defp mock_logging_tasks(),
    do: [
      %BrolgaCron.Task{
        id: :test,
        interval_in_seconds: 1,
        action: fn -> Logger.warning("Called") end,
        args: []
      }
    ]

  defp mock_sending_tasks(pid),
    do: [
      %BrolgaCron.Task{
        id: :test,
        interval_in_seconds: 1,
        action: fn -> send(pid, :called) end,
        args: []
      }
    ]

  describe "execute_now/1" do
    test "executes existing action" do
      tasks = mock_tasks()
      expect(BrolgaCron.Task.ProviderMock, :tasks, fn -> tasks end)

      result = BrolgaCron.Runner.execute_now(:test)

      assert result == :called
    end

    test "returns flag when action is not found" do
      tasks = mock_tasks()
      expect(BrolgaCron.Task.ProviderMock, :tasks, fn -> tasks end)

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
