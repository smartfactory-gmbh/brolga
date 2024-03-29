defmodule Brolga.MonitoringTest do
  use Brolga.DataCase

  alias Brolga.Monitoring

  describe "monitors" do
    alias Brolga.Monitoring.Monitor

    import Brolga.MonitoringFixtures

    @invalid_attrs %{name: nil, url: nil, interval_in_minutes: nil}

    test "list_monitors/0 returns all monitors" do
      _ = monitor_fixture()
      _ = monitor_fixture()
      _ = monitor_fixture()
      _ = monitor_fixture()
      assert length(Monitoring.list_monitors()) == 4
    end

    test "get_monitor!/1 returns the monitor with given id" do
      monitor = monitor_fixture()
      result = Monitoring.get_monitor!(monitor.id) |> Brolga.Repo.preload(:monitor_tags)
      assert result == monitor
    end

    test "create_monitor/1 with valid data creates a monitor" do
      valid_attrs = %{name: "some name", url: "https://some-url/", interval_in_minutes: 42}

      assert {:ok, %Monitor{} = monitor} = Monitoring.create_monitor(valid_attrs)
      assert monitor.name == "some name"
      assert monitor.url == "https://some-url/"
      assert monitor.interval_in_minutes == 42
    end

    test "create_monitor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_monitor(@invalid_attrs)
    end

    test "update_monitor/2 with valid data updates the monitor" do
      monitor = monitor_fixture() |> Brolga.Repo.preload(:monitor_tags)

      update_attrs = %{
        name: "some updated name",
        url: "https://some-updated-url/",
        interval_in_minutes: 43
      }

      assert {:ok, %Monitor{} = monitor} = Monitoring.update_monitor(monitor, update_attrs)
      assert monitor.name == "some updated name"
      assert monitor.url == "https://some-updated-url/"
      assert monitor.interval_in_minutes == 43
    end

    test "update_monitor/2 with invalid data returns error changeset" do
      monitor = monitor_fixture() |> Brolga.Repo.preload(:monitor_tags)
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_monitor(monitor, @invalid_attrs)
      assert monitor == Monitoring.get_monitor!(monitor.id) |> Brolga.Repo.preload(:monitor_tags)
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

    test "populate_host/1 correctly fills the host field with http" do
      monitor = monitor_fixture(url: "http://test.com/hello")

      host = monitor |> Monitor.populate_host() |> Map.get(:host)
      assert host == "test.com"
    end

    test "populate_host/1 correctly fills the host field with https" do
      monitor = monitor_fixture(url: "http://test.com/hello")

      host = monitor |> Monitor.populate_host() |> Map.get(:host)
      assert host == "test.com"
    end

    test "populate_hosts/1 correctly fills the host field of a list of monitors" do
      monitors = [
        monitor_fixture(url: "http://test.com/hello"),
        monitor_fixture(url: "https://test1.com/hello/asdfsadf"),
        monitor_fixture(url: "http://test.tld.com")
      ]

      hosts = monitors |> Monitor.populate_hosts() |> Enum.map(fn monitor -> monitor.host end)
      assert hosts == ["test.com", "test1.com", "test.tld.com"]
    end
  end

  describe "monitor_results" do
    alias Brolga.Monitoring.MonitorResult

    import Brolga.MonitoringFixtures

    @invalid_attrs %{reached: nil}

    test "list_monitor_results/0 returns all monitor_results" do
      monitor = monitor_fixture()
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      assert length(Monitoring.list_monitor_results()) == 4
    end

    test "get_previous_monitor_results/2 returns limited monitor_results" do
      monitor = monitor_fixture()
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      _ = monitor_result_fixture(%{monitor_id: monitor.id})

      assert length(Monitoring.get_previous_monitor_results(nil, length: 2)) == 2
      assert length(Monitoring.get_previous_monitor_results(0, length: 2)) == 2
      assert length(Monitoring.get_previous_monitor_results(2, length: 2)) == 2
      assert length(Monitoring.get_previous_monitor_results(4, length: 2)) == 1
    end

    test "get_previous_monitor_results/2 respects cutoff date" do
      monitor = monitor_fixture()
      _ = monitor_result_fixture(%{monitor_id: monitor.id})
      yesterday = Timex.now() |> Timex.shift(days: -1)
      tomorrow = Timex.now() |> Timex.shift(days: 1)

      assert length(Monitoring.get_previous_monitor_results(0, length: 2, cutoff_date: tomorrow)) ==
               1

      assert Monitoring.get_previous_monitor_results(0, length: 2, cutoff_date: yesterday)
             |> Enum.empty?()
    end

    test "get_previous_monitor_results_for/3 returns limited monitor_results" do
      m1 = monitor_fixture()
      m2 = monitor_fixture()
      _ = monitor_result_fixture(%{monitor_id: m1.id})
      _ = monitor_result_fixture(%{monitor_id: m1.id})
      _ = monitor_result_fixture(%{monitor_id: m1.id})
      _ = monitor_result_fixture(%{monitor_id: m2.id})
      _ = monitor_result_fixture(%{monitor_id: m2.id})

      assert length(Monitoring.get_previous_monitor_results_for(m1.id, nil, length: 2)) == 2
      assert length(Monitoring.get_previous_monitor_results_for(m1.id, 0, length: 2)) == 2
      assert length(Monitoring.get_previous_monitor_results_for(m1.id, 2, length: 2)) == 1
      assert length(Monitoring.get_previous_monitor_results_for(m2.id, 0, length: 2)) == 2
    end

    test "cleanup_monitor_results/0 respects the retention days threshold" do
      monitor = monitor_fixture()

      assert Enum.empty?(Monitoring.list_monitor_results())

      recent_date = Timex.now() |> Timex.shift(days: -32, minutes: 5)

      recent_monitor_result =
        monitor_result_fixture(%{
          monitor_id: monitor.id,
          inserted_at: recent_date,
          updated_at: recent_date
        })

      old_date = Timex.now() |> Timex.shift(days: -32, minutes: -5)

      old_monitor_result =
        monitor_result_fixture(%{
          monitor_id: monitor.id,
          inserted_at: old_date,
          updated_at: old_date
        })

      assert length(Monitoring.list_monitor_results()) == 2

      Monitoring.cleanup_monitor_results()

      assert length(Monitoring.list_monitor_results()) == 1

      assert recent_monitor_result.id ==
               Monitoring.get_monitor_result!(recent_monitor_result.id).id

      assert_raise Ecto.NoResultsError, fn ->
        Monitoring.get_monitor_result!(old_monitor_result.id)
      end
    end

    test "get_monitor_result!/1 returns the monitor_result with given id" do
      monitor = monitor_fixture()
      monitor_result = monitor_result_fixture(%{monitor_id: monitor.id})
      assert Monitoring.get_monitor_result!(monitor_result.id) == monitor_result
    end

    test "create_monitor_result/1 with valid data creates a monitor_result" do
      monitor = monitor_fixture()
      valid_attrs = %{reached: true, monitor_id: monitor.id}

      assert {:ok, %MonitorResult{} = monitor_result} =
               Monitoring.create_monitor_result(valid_attrs)

      assert monitor_result.reached == true
    end

    test "create_monitor_result/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_monitor_result(@invalid_attrs)
    end

    test "update_monitor_result/2 with valid data updates the monitor_result" do
      monitor = monitor_fixture()
      monitor_result = monitor_result_fixture(%{monitor_id: monitor.id})
      update_attrs = %{reached: false}

      assert {:ok, %MonitorResult{} = monitor_result} =
               Monitoring.update_monitor_result(monitor_result, update_attrs)

      assert monitor_result.reached == false
    end

    test "update_monitor_result/2 with invalid data returns error changeset" do
      monitor = monitor_fixture()
      monitor_result = monitor_result_fixture(%{monitor_id: monitor.id})

      assert {:error, %Ecto.Changeset{}} =
               Monitoring.update_monitor_result(monitor_result, @invalid_attrs)

      assert monitor_result == Monitoring.get_monitor_result!(monitor_result.id)
    end

    test "delete_monitor_result/1 deletes the monitor_result" do
      monitor = monitor_fixture()
      monitor_result = monitor_result_fixture(%{monitor_id: monitor.id})
      assert {:ok, %MonitorResult{}} = Monitoring.delete_monitor_result(monitor_result)

      assert_raise Ecto.NoResultsError, fn ->
        Monitoring.get_monitor_result!(monitor_result.id)
      end
    end

    test "change_monitor_result/1 returns a monitor_result changeset" do
      monitor = monitor_fixture()
      monitor_result = monitor_result_fixture(%{monitor_id: monitor.id})
      assert %Ecto.Changeset{} = Monitoring.change_monitor_result(monitor_result)
    end
  end

  describe "monitor_tags" do
    alias Brolga.Monitoring.MonitorTag

    import Brolga.MonitoringFixtures

    @invalid_attrs %{name: nil}

    test "list_monitor_tags/0 returns all monitor_tags" do
      monitor_tag = monitor_tag_fixture()
      assert Monitoring.list_monitor_tags() == [monitor_tag]
    end

    test "get_monitor_tag!/1 returns the monitor_tag with given id" do
      monitor_tag = monitor_tag_fixture()
      assert Monitoring.get_monitor_tag!(monitor_tag.id) == monitor_tag
    end

    test "create_monitor_tag/1 with valid data creates a monitor_tag" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %MonitorTag{} = monitor_tag} = Monitoring.create_monitor_tag(valid_attrs)
      assert monitor_tag.name == "some name"
    end

    test "create_monitor_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_monitor_tag(@invalid_attrs)
    end

    test "update_monitor_tag/2 with valid data updates the monitor_tag" do
      monitor_tag = monitor_tag_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %MonitorTag{} = monitor_tag} =
               Monitoring.update_monitor_tag(monitor_tag, update_attrs)

      assert monitor_tag.name == "some updated name"
    end

    test "update_monitor_tag/2 with invalid data returns error changeset" do
      monitor_tag = monitor_tag_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Monitoring.update_monitor_tag(monitor_tag, @invalid_attrs)

      assert monitor_tag == Monitoring.get_monitor_tag!(monitor_tag.id)
    end

    test "delete_monitor_tag/1 deletes the monitor_tag" do
      monitor_tag = monitor_tag_fixture()
      assert {:ok, %MonitorTag{}} = Monitoring.delete_monitor_tag(monitor_tag)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_monitor_tag!(monitor_tag.id) end
    end

    test "change_monitor_tag/1 returns a monitor_tag changeset" do
      monitor_tag = monitor_tag_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_monitor_tag(monitor_tag)
    end
  end
end
