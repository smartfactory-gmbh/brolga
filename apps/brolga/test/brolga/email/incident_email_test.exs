defmodule Brolga.Email.IncidentEmailTest do
  use Brolga.DataCase

  alias Brolga.Email.IncidentEmail

  import Brolga.MonitoringFixtures
  import Brolga.AlertingFixtures

  describe "new_incident/1" do
    test "injects the monitor name in the content" do
      monitor = monitor_fixture(%{name: "Test monitor"})
      incident = incident_fixture(%{monitor_id: monitor.id}) |> Repo.preload(:monitor)

      email = IncidentEmail.new_incident(incident)

      assert email.text_body =~ "Test monitor is down\n"
      assert email.html_body =~ "<h2>Test monitor is down</h2>\n"
    end

    test "uses the configured sender and recipient" do
      monitor = monitor_fixture(%{name: "Test monitor"})
      incident = incident_fixture(%{monitor_id: monitor.id}) |> Repo.preload(:monitor)

      email = IncidentEmail.new_incident(incident)

      assert email.from == {"Exemple admin", "admin@example.com"}
      assert email.to == [{"Example recipient", "recipient@example.com"}]
    end
  end

  describe "incident_resolved/1" do
    test "injects the monitor name in the content" do
      monitor = monitor_fixture(%{name: "Test monitor"})
      incident = incident_fixture(%{monitor_id: monitor.id}) |> Repo.preload(:monitor)

      email = IncidentEmail.incident_resolved(incident)

      assert email.text_body =~ "Test monitor is up\n"
      assert email.html_body =~ "<h2>Test monitor is up</h2>\n"
    end

    test "uses the configured sender and recipient" do
      monitor = monitor_fixture(%{name: "Test monitor"})
      incident = incident_fixture(%{monitor_id: monitor.id}) |> Repo.preload(:monitor)

      email = IncidentEmail.incident_resolved(incident)

      assert email.from == {"Exemple admin", "admin@example.com"}
      assert email.to == [{"Example recipient", "recipient@example.com"}]
    end
  end
end
