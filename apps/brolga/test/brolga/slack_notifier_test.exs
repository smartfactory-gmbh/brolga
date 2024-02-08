defmodule Brolga.SlackNotifierTest do
  use Brolga.DataCase

  alias Brolga.AlertNotifiers.SlackNotifier

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  setup [:open_incident, :closed_incident]

  defp open_incident(_context) do
    monitor = monitor_fixture(%{name: "Test down monitor"})

    incident =
      incident_fixture(%{
        monitor_id: monitor.id,
        started_at: ~U"2022-01-02T13:00:00Z"
      })
      |> Repo.preload(:monitor)

    [open: incident]
  end

  defp closed_incident(_context) do
    monitor = monitor_fixture(%{name: "Test up monitor"})

    incident =
      incident_fixture(%{
        monitor_id: monitor.id,
        started_at: ~U"2022-01-02T13:00:00Z",
        ended_at: ~U"2022-01-02T13:21:00Z"
      })
      |> Repo.preload(:monitor)

    [closed: incident]
  end

  defp extract_main_blocks(data) do
    Jason.decode!(data)
    |> Map.get("attachments")
    |> Enum.at(0)
    |> Map.get("blocks")
  end

  describe "new_incident/1" do
    test "injects the monitor name in the content", %{slack_bypass: bypass, open: open} do
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        main_text =
          extract_main_blocks(body)
          |> Enum.at(0)
          |> Map.get("text")
          |> Map.get("text")

        assert main_text =~ "Test down monitor"

        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.new_incident(open)
    end

    test "injects the time of alert", %{slack_bypass: bypass, open: open} do
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        main_text =
          extract_main_blocks(body)
          # Date field
          |> Enum.at(1)
          |> Map.get("text")
          |> Map.get("text")

        # Timestamp of started_at
        assert main_text =~ "1641128400"

        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.new_incident(open)
    end
  end

  describe "incident_resolved/1" do
    test "injects the monitor name in the content", %{slack_bypass: bypass, closed: closed} do
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        main_text =
          extract_main_blocks(body)
          |> Enum.at(0)
          |> Map.get("text")
          |> Map.get("text")

        assert main_text =~ "Test up monitor"
        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.incident_resolved(closed)
    end

    test "injects the time of alert", %{slack_bypass: bypass, closed: closed} do
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        main_text =
          extract_main_blocks(body)
          # Date field
          |> Enum.at(1)
          |> Map.get("text")
          |> Map.get("text")

        # Timestamp of started_at
        assert main_text =~ "1641128400"
        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.incident_resolved(closed)
    end
  end

  describe "test_notifications/0" do
    test "sends a test notification", %{slack_bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        decoded = Jason.decode!(body)

        text =
          decoded["blocks"]
          |> Enum.at(0)
          |> Map.get("text")
          |> Map.get("text")

        assert text == "This is a test notification"

        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.test_notification()
    end
  end

  describe "send/1" do
    test "injects the configured user and channel", %{slack_bypass: bypass, open: open} do
      # Testing through a public method, since send is private
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} =
          conn
          |> Plug.Conn.read_body()

        decoded = Jason.decode!(body)

        assert decoded["username"] == "slack_user"
        assert decoded["channel"] == "#slack_channel"
        Plug.Conn.resp(conn, 200, "")
      end)

      SlackNotifier.new_incident(open)
    end
  end

  describe "enabled?" do
    test "can be changed through the configuration" do
      assert SlackNotifier.enabled?() == true

      Application.put_env(:brolga, :slack_notifier, enabled: false)
      assert SlackNotifier.enabled?() == false

      Application.put_env(:brolga, :slack_notifier, enabled: true)
    end
  end
end
