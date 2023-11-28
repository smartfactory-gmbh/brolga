defmodule Brolga.Watcher.CheckTaskTest do
  alias Ecto.Repo
  use Brolga.DataCase

  alias Brolga.Watcher.CheckTask
  import Brolga.MonitoringFixtures

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

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == true
      assert result.status_code == 200
      assert result.message == "Successful hit"
    end

    test "should truncate the status message" do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://test.unknown/"})

      expect(Brolga.HttpClientMock, :start, fn -> :ok end)

      expect(Brolga.HttpClientMock, :get, fn url, _data, _header ->
        assert url == "http://test.unknown/"

        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: String.pad_trailing("All is broken", 300)
         }}
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == 400
      assert String.length(result.message) == 232
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

      CheckTask.run(monitor.id)

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
        {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == nil
      assert result.message == "Something went wrong: timeout"
    end
  end
end
