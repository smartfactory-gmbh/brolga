defmodule Brolga.AlertingTest do
  alias Brolga.Monitoring
  use Brolga.DataCase

  alias Brolga.Alerting

  describe "incidents" do
    alias Brolga.Alerting.Incident

    import Brolga.AlertingFixtures
    import Brolga.MonitoringFixtures

    import Mox

    @invalid_attrs %{started_at: nil, ended_at: nil}

    test "list_incidents/0 returns all incidents" do
      incident = incident_fixture()
      assert Alerting.list_incidents() == [incident]
    end

    test "get_incident!/1 returns the incident with given id" do
      incident = incident_fixture()
      assert Alerting.get_incident!(incident.id) == incident
    end

    test "create_incident/1 with valid data creates a incident" do
      valid_attrs = %{started_at: ~N[2023-07-24 09:21:00], ended_at: ~N[2023-07-24 09:21:00]}

      assert {:ok, %Incident{} = incident} = Alerting.create_incident(valid_attrs)
      assert incident.started_at == ~U[2023-07-24 09:21:00Z]
      assert incident.ended_at == ~U[2023-07-24 09:21:00Z]
    end

    test "create_incident/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Alerting.create_incident(@invalid_attrs)
    end

    test "update_incident/2 with valid data updates the incident" do
      incident = incident_fixture()
      update_attrs = %{start: ~N[2023-07-25 09:21:00], end: ~N[2023-07-25 09:21:00]}

      assert {:ok, %Incident{} = incident} = Alerting.update_incident(incident, update_attrs)
      assert incident.started_at == ~U[2023-07-24 09:21:00Z]
      assert incident.ended_at == ~U[2023-07-24 09:21:00Z]
    end

    test "update_incident/2 with invalid data returns error changeset" do
      incident = incident_fixture()
      assert {:error, %Ecto.Changeset{}} = Alerting.update_incident(incident, @invalid_attrs)
      assert incident == Alerting.get_incident!(incident.id)
    end

    test "delete_incident/1 deletes the incident" do
      incident = incident_fixture()
      assert {:ok, %Incident{}} = Alerting.delete_incident(incident)
      assert_raise Ecto.NoResultsError, fn -> Alerting.get_incident!(incident.id) end
    end

    test "change_incident/1 returns a incident changeset" do
      incident = incident_fixture()
      assert %Ecto.Changeset{} = Alerting.change_incident(incident)
    end

    test "open_incident/1 creates a new incident for the given monitor" do
      monitor = monitor_fixture()

      expect(Brolga.HttpClientMock, :post, fn _url, _data, _headers ->
        # Sending to slack by default
        {:ok, %{status_code: 200}}
      end)

      Alerting.open_incident(monitor)

      monitor = Monitoring.get_monitor_with_details!(monitor.id)
      assert length(monitor.incidents) == 1

      incident = monitor.incidents |> Enum.at(0)
      assert incident.ended_at == nil
    end

    test "close_incident/1 modifies the existing incident" do
      monitor = monitor_fixture()
      incident_fixture(%{ended_at: nil, monitor_id: monitor.id})

      expect(Brolga.HttpClientMock, :post, fn _url, _data, _headers ->
        # Sending to slack by default
        {:ok, %{status_code: 200}}
      end)

      Alerting.close_incident(monitor)

      monitor = Monitoring.get_monitor_with_details!(monitor.id)
      assert length(monitor.incidents) == 1

      incident = monitor.incidents |> Enum.at(0)
      assert incident.ended_at != nil
    end
  end
end
