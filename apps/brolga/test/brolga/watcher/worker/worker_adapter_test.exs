defmodule Brolga.Watcher.Worker.WorkerAdapterTest do
  alias Ecto.Repo
  use Brolga.DataCase

  alias Brolga.Watcher.Worker.WorkerAdapter
  import Brolga.MonitoringFixtures

  import ExUnit.CaptureLog

  import Mox

  setup :verify_on_exit!

  describe "validate_response/1" do
    test "should create an entry with success state" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.HttpClientMock, :start, fn -> :ok end)

      expect(Brolga.HttpClientMock, :get, fn url, _data, _header ->
        assert url == "http://test.unknown/"

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "All good!"
         }}
      end)

      WorkerAdapter.run_once(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == true
      assert result.status_code == 200
      assert result.message == "Successful hit"
    end

    test "should create an entry with error state" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.HttpClientMock, :start, fn -> :ok end)

      expect(Brolga.HttpClientMock, :get, fn url, _data, _header ->
        assert url == "http://test.unknown/"

        {:ok,
         %HTTPoison.Response{
           status_code: 500,
           body: "Broken!"
         }}
      end)

      WorkerAdapter.run_once(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == 500
      assert result.message == "Error: Broken!"
    end

    test "should create an entry with error state if http client fails" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.HttpClientMock, :start, fn -> :ok end)

      expect(Brolga.HttpClientMock, :get, fn url, _data, _header ->
        assert url == "http://test.unknown/"
        {:error, nil}
      end)

      WorkerAdapter.run_once(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == nil
      assert result.message == "Something went wrong: "
    end
  end

  describe "start/1" do
    test "should try to kill existing process for the monitor" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.RedixMock, :get!, fn key ->
        assert key == "monitor-#{monitor.id}"
        nil
      end)

      expect(Brolga.RedixMock, :store!, fn key, _value ->
        assert key == "monitor-#{monitor.id}"
        :ok
      end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :all)

      logs =
        capture_log(fn ->
          WorkerAdapter.start(monitor.id)
        end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :none)

      assert logs =~ "Monitor #{monitor.id} was already stopped"
    end
  end

  describe "stop/1" do
    test "should try to delete non-existing processes without issue" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.RedixMock, :get!, fn key ->
        assert key == "monitor-#{monitor.id}"
        nil
      end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :all)

      logs =
        capture_log(fn ->
          WorkerAdapter.stop(monitor.id)
        end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :none)

      assert logs =~ "Monitor #{monitor.id} was already stopped"
    end

    test "should delete existing processes without issue" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.RedixMock, :get!, fn key ->
        assert key == "monitor-#{monitor.id}"
        "<0.4.1>"
      end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :all)

      logs =
        capture_log(fn ->
          WorkerAdapter.stop(monitor.id)
        end)

      Logger.put_module_level(Brolga.Watcher.Worker.WorkerAdapter, :none)

      assert logs =~ "Monitor #{monitor.id} has been stopped"
    end
  end
end
