defmodule Brolga.SlackNotifierTest do
  use Brolga.DataCase

  alias Brolga.AlertNotifiers.SlackNotifier

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  import Mox

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
    test "injects the monitor name in the content", context do
      expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
        main_text =
          extract_main_blocks(data)
          |> Enum.at(0)
          |> Map.get("text")
          |> Map.get("text")

        assert main_text =~ "Test down monitor"
        {:ok, %{status_code: 200}}
      end)

      SlackNotifier.new_incident(context[:open])
    end

    test "injects the time of alert", context do
      expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
        main_text =
          extract_main_blocks(data)
          # Date field
          |> Enum.at(1)
          |> Map.get("text")
          |> Map.get("text")

        # Timestamp of started_at
        assert main_text =~ "1641128400"
        {:ok, %{status_code: 200}}
      end)

      SlackNotifier.new_incident(context[:open])
    end
  end

  describe "incident_resolved/1" do
    test "injects the monitor name in the content", context do
      expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
        main_text =
          extract_main_blocks(data)
          |> Enum.at(0)
          |> Map.get("text")
          |> Map.get("text")

        assert main_text =~ "Test up monitor"
        {:ok, %{status_code: 200}}
      end)

      SlackNotifier.incident_resolved(context[:closed])
    end

    test "injects the time of alert", context do
      expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
        main_text =
          extract_main_blocks(data)
          # Date field
          |> Enum.at(1)
          |> Map.get("text")
          |> Map.get("text")

        # Timestamp of started_at
        assert main_text =~ "1641128400"
        {:ok, %{status_code: 200}}
      end)

      SlackNotifier.incident_resolved(context[:closed])
    end
  end

  describe "test_notifications/0" do
    expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
      decoded = Jason.decode!(data)

      text =
        decoded["blocks"]
        |> Enum.at(0)
        |> Map.get("text")
        |> Map.get("text")

      assert text == "This is a test notification"

      {:ok, %{status_code: 200}}
    end)

    SlackNotifier.test_notification()
  end

  describe "send/1" do
    test "injects the configured user and channel", context do
      # Testing through a public method, since send is private
      expect(Brolga.HttpClientMock, :post, fn _url, data, _headers ->
        decoded = Jason.decode!(data)

        assert decoded["username"] == "Brolga"
        assert decoded["channel"] == "#sysops"
        {:ok, %{status_code: 200}}
      end)

      SlackNotifier.new_incident(context[:open])
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
