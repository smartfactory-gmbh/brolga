defmodule Brolga.EmailNotifierTest do
  use Brolga.DataCase

  alias Brolga.AlertNotifiers.EmailNotifier

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  import Swoosh.TestAssertions

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

  describe "new_incident/1" do
    test "injects the monitor name in the content", context do
      EmailNotifier.new_incident(context[:open])

      assert_email_sent(fn email ->
        assert email.text_body =~ "Test down monitor"
        assert email.html_body =~ "Test down monitor"
      end)
    end

    test "injects the time of alert", context do
      EmailNotifier.new_incident(context[:open])

      assert_email_sent(fn email ->
        assert email.text_body =~ "13:00 02.01.2022"
        assert email.html_body =~ "13:00 02.01.2022"
      end)
    end
  end

  describe "incident_resolved/1" do
    test "injects the monitor name in the content", context do
      EmailNotifier.incident_resolved(context[:closed])

      assert_email_sent(fn email ->
        assert email.text_body =~ "Test up monitor"
        assert email.html_body =~ "Test up monitor"
      end)
    end

    test "injects the time of alert", context do
      EmailNotifier.incident_resolved(context[:closed])

      assert_email_sent(fn email ->
        assert email.text_body =~ "13:00 02.01.2022"
        assert email.html_body =~ "13:00 02.01.2022"
      end)
    end
  end

  describe "test_notification" do
    test "can be sent", _context do
      EmailNotifier.test_notification()

      assert_email_sent(fn email ->
        assert email.text_body =~ "This is a test email from Brolga"
        assert email.html_body =~ "This is a test email from Brolga"
      end)
    end
  end

  describe "enabled?" do
    test "can be changed through the configuration" do
      base_config = Application.fetch_env!(:brolga, :email_notifier)
      assert EmailNotifier.enabled?() == true

      Application.put_env(:brolga, :email_notifier, enabled: false)
      assert EmailNotifier.enabled?() == false

      Application.put_env(:brolga, :email_notifier, base_config)
    end
  end
end
