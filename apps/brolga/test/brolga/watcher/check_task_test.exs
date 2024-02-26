defmodule Brolga.Watcher.CheckTaskTest do
  alias Ecto.Repo
  use Brolga.DataCase, async: false

  alias Brolga.Watcher.CheckTask
  import Brolga.MonitoringFixtures

  describe "validate_response/1" do
    test "should create an entry with success state", %{target_bypass: bypass} do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://localhost:8888/"})

      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "All good!")
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == true
      assert result.status_code == 200
      assert result.message == "Successful hit"
    end

    test "should truncate the status message", %{
      target_bypass: bypass,
      slack_bypass: slack_bypass
    } do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://localhost:8888/"})

      Bypass.expect(slack_bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 400, String.pad_trailing("All is broken", 300))
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == 400
      assert String.length(result.message) == 232
    end

    test "should create an entry with error state", %{
      target_bypass: bypass,
      slack_bypass: slack_bypass
    } do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://localhost:8888/"})

      Bypass.expect(slack_bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      Bypass.expect(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 500, "Broken!")
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == 500
      assert result.message == "Error: Broken!"
    end

    test "should create an entry with error state if http client fails", %{
      slack_bypass: slack_bypass
    } do
      monitor = monitor_fixture(%{name: "Test monitor", url: "http://localhost:8889/"})

      Bypass.expect(slack_bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      CheckTask.run(monitor.id)

      monitor = monitor |> Repo.preload(:monitor_results)
      assert length(monitor.monitor_results) == 1

      result = monitor.monitor_results |> Enum.at(0)

      assert result.reached == false
      assert result.status_code == nil
      assert result.message == "Something went wrong: econnrefused"
    end
  end
end
