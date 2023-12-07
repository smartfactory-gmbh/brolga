defmodule Brolga.SchedulerTest do
  use Brolga.DataCase

  alias Brolga.Scheduler
  import Brolga.MonitoringFixtures

  setup :stop_scheduled_timers

  describe "start_monitor/1" do
    test "should always return ok" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      result = Scheduler.start_monitor(monitor.id)

      assert result == :ok
    end

    test "should reset the timer for the monitor" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})
      initial_state = %{}

      {:noreply, new_state} = Scheduler.handle_cast({:start, monitor.id}, initial_state)
      assert Map.has_key?(new_state, monitor.id)

      # Re-adding
      {:noreply, new_state} = Scheduler.handle_cast({:start, monitor.id}, initial_state)
      assert Map.has_key?(new_state, monitor.id)
    end
  end

  describe "stop_all/0" do
    test "should always return ok" do
      result = Scheduler.stop_all()

      assert result == :ok
    end
  end

  describe "get_monitored_ids/0" do
    test "should return the list of running monitors" do
      result = Scheduler.get_monitored_ids()
      assert result == []

      monitor1 = monitor_fixture()
      monitor2 = monitor_fixture()

      initial_state = %{
        monitor1.id => make_ref(),
        monitor2.id => make_ref()
      }

      {:reply, result, ^initial_state} = Scheduler.handle_call(:list_ids, self(), initial_state)

      assert Enum.sort(result) == Enum.sort([monitor1.id, monitor2.id])
    end
  end

  describe "stop_monitor/1" do
    test "should always return ok" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      result = Scheduler.stop_monitor(monitor.id)

      assert result == :ok
    end

    test "should try to delete non-monitored timer without issue" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})
      initial_state = %{}

      {:noreply, new_state} = Scheduler.handle_cast({:stop, monitor.id}, initial_state)

      assert Map.keys(new_state) == []
    end

    test "should delete existing timers without issue" do
      monitor1 = monitor_fixture(%{name: "Test monitor 1", url: "http://test.unknown/"})
      monitor2 = monitor_fixture(%{name: "Test monitor 2", url: "http://test.unknown/"})
      initial_state = %{monitor1.id => make_ref(), monitor2.id => make_ref()}

      {:noreply, new_state} = Scheduler.handle_cast({:stop, monitor2.id}, initial_state)

      assert Map.has_key?(new_state, monitor1.id)
      refute Map.has_key?(new_state, monitor2.id)
    end
  end
end
