defmodule Brolga.AlertNotifiersTest do
  use Brolga.DataCase
  import ExUnit.CaptureLog

  require Logger

  alias Brolga.AlertNotifiers

  import Swoosh.TestAssertions

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  describe "log_enabled_notifiers" do
    test "should only log enabled notifiers" do
      Logger.put_module_level(Brolga.AlertNotifiers, :all)

      logs =
        capture_log(fn ->
          AlertNotifiers.log_enabled_notifiers()
        end)

      Logger.put_module_level(Brolga.AlertNotifiers, :none)

      assert logs =~
               "Enabled notifiers: Brolga.AlertNotifiers.EmailNotifier, Brolga.AlertNotifiers.SlackNotifier"

      Application.put_env(:brolga, Brolga.AlertNotifiers,
        notifiers: [Brolga.AlertNotifiers.EmailNotifier]
      )

      Logger.put_module_level(Brolga.AlertNotifiers, :all)

      logs =
        capture_log(fn ->
          AlertNotifiers.log_enabled_notifiers()
        end)

      Logger.put_module_level(Brolga.AlertNotifiers, :none)
      Application.put_env(:brolga, Brolga.AlertNotifiers, notifiers: :default)

      assert logs =~ "Enabled notifiers: Brolga.AlertNotifiers.EmailNotifier"
    end
  end

  describe "new_incident/1" do
    test "should propagate to all enabled notifiers" do
      base_config = Application.fetch_env!(:brolga, :slack_notifier)

      Application.put_env(:brolga, :slack_notifier, enabled: false)

      monitor = monitor_fixture()

      incident =
        incident_fixture(%{monitor_id: monitor.id, ended_at: nil}) |> Repo.preload(:monitor)

      assert_no_email_sent()

      AlertNotifiers.new_incident(incident)

      assert_email_sent()

      Application.put_env(:brolga, :slack_notifier, base_config)
    end
  end

  describe "incident_resolved/1" do
    test "should propagate to all enabled notifiers" do
      base_config = Application.fetch_env!(:brolga, :slack_notifier)

      Application.put_env(:brolga, :slack_notifier, enabled: false)

      monitor = monitor_fixture()
      incident = incident_fixture(%{monitor_id: monitor.id}) |> Repo.preload(:monitor)

      assert_no_email_sent()

      AlertNotifiers.incident_resolved(incident)

      assert_email_sent()

      Application.put_env(:brolga, :slack_notifier, base_config)
    end
  end

  describe "test_notification/1" do
    test "should propagate to all enabled notifiers" do
      base_config = Application.fetch_env!(:brolga, :slack_notifier)

      Application.put_env(:brolga, :slack_notifier, enabled: false)

      assert_no_email_sent()

      AlertNotifiers.test_notification()

      assert_email_sent()

      Application.put_env(:brolga, :slack_notifier, base_config)
    end
  end
end
