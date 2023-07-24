defmodule Brolga.MonitoringTest do
  use Brolga.DataCase

  alias Brolga.Monitoring

  describe "monitors" do
    alias Brolga.Monitoring.Monitor

    import Brolga.MonitoringFixtures

    @invalid_attrs %{name: nil, url: nil, interval_in_minutes: nil}

    test "list_monitors/0 returns all monitors" do
      monitor = monitor_fixture()
      assert Monitoring.list_monitors() == [monitor]
    end

    test "get_monitor!/1 returns the monitor with given id" do
      monitor = monitor_fixture()
      assert Monitoring.get_monitor!(monitor.id) == monitor
    end

    test "create_monitor/1 with valid data creates a monitor" do
      valid_attrs = %{name: "some name", url: "some url", interval_in_minutes: 42}

      assert {:ok, %Monitor{} = monitor} = Monitoring.create_monitor(valid_attrs)
      assert monitor.name == "some name"
      assert monitor.url == "some url"
      assert monitor.interval_in_minutes == 42
    end

    test "create_monitor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_monitor(@invalid_attrs)
    end

    test "update_monitor/2 with valid data updates the monitor" do
      monitor = monitor_fixture()
      update_attrs = %{name: "some updated name", url: "some updated url", interval_in_minutes: 43}

      assert {:ok, %Monitor{} = monitor} = Monitoring.update_monitor(monitor, update_attrs)
      assert monitor.name == "some updated name"
      assert monitor.url == "some updated url"
      assert monitor.interval_in_minutes == 43
    end

    test "update_monitor/2 with invalid data returns error changeset" do
      monitor = monitor_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_monitor(monitor, @invalid_attrs)
      assert monitor == Monitoring.get_monitor!(monitor.id)
    end

    test "delete_monitor/1 deletes the monitor" do
      monitor = monitor_fixture()
      assert {:ok, %Monitor{}} = Monitoring.delete_monitor(monitor)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_monitor!(monitor.id) end
    end

    test "change_monitor/1 returns a monitor changeset" do
      monitor = monitor_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_monitor(monitor)
    end
  end

  describe "monitor_results" do
    alias Brolga.Monitoring.MonitorResult

    import Brolga.MonitoringFixtures

    @invalid_attrs %{reached: nil}

    test "list_monitor_results/0 returns all monitor_results" do
      monitor_result = monitor_result_fixture()
      assert Monitoring.list_monitor_results() == [monitor_result]
    end

    test "get_monitor_result!/1 returns the monitor_result with given id" do
      monitor_result = monitor_result_fixture()
      assert Monitoring.get_monitor_result!(monitor_result.id) == monitor_result
    end

    test "create_monitor_result/1 with valid data creates a monitor_result" do
      valid_attrs = %{reached: true}

      assert {:ok, %MonitorResult{} = monitor_result} = Monitoring.create_monitor_result(valid_attrs)
      assert monitor_result.reached == true
    end

    test "create_monitor_result/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_monitor_result(@invalid_attrs)
    end

    test "update_monitor_result/2 with valid data updates the monitor_result" do
      monitor_result = monitor_result_fixture()
      update_attrs = %{reached: false}

      assert {:ok, %MonitorResult{} = monitor_result} = Monitoring.update_monitor_result(monitor_result, update_attrs)
      assert monitor_result.reached == false
    end

    test "update_monitor_result/2 with invalid data returns error changeset" do
      monitor_result = monitor_result_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_monitor_result(monitor_result, @invalid_attrs)
      assert monitor_result == Monitoring.get_monitor_result!(monitor_result.id)
    end

    test "delete_monitor_result/1 deletes the monitor_result" do
      monitor_result = monitor_result_fixture()
      assert {:ok, %MonitorResult{}} = Monitoring.delete_monitor_result(monitor_result)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_monitor_result!(monitor_result.id) end
    end

    test "change_monitor_result/1 returns a monitor_result changeset" do
      monitor_result = monitor_result_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_monitor_result(monitor_result)
    end
  end
end
