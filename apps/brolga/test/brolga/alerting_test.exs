defmodule Brolga.AlertingTest do
  use Brolga.DataCase

  alias Brolga.Alerting

  describe "incidents" do
    alias Brolga.Alerting.Incident

    import Brolga.AlertingFixtures

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
  end
end
