defmodule Brolga.DashboardsTest do
  use Brolga.DataCase

  alias Brolga.Dashboards

  describe "dashboards" do
    alias Brolga.Dashboards.Dashboard

    import Brolga.DashboardsFixtures

    @invalid_attrs %{name: nil}

    test "list_dashboards/0 returns all dashboards" do
      dashboard = dashboard_fixture()

      expected =
        Dashboards.list_dashboards()
        |> Brolga.Repo.preload([:monitor_tags, :monitors])

      assert expected == [dashboard]
    end

    test "get_dashboard!/1 returns the dashboard with given id" do
      dashboard = dashboard_fixture()

      expected =
        Dashboards.get_dashboard!(dashboard.id) |> Brolga.Repo.preload([:monitor_tags, :monitors])

      assert expected == dashboard
    end

    test "create_dashboard/1 with valid data creates a dashboard" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Dashboard{} = dashboard} = Dashboards.create_dashboard(valid_attrs)
      assert dashboard.name == "some name"
    end

    test "create_dashboard/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Dashboards.create_dashboard(@invalid_attrs)
    end

    test "update_dashboard/2 with valid data updates the dashboard" do
      dashboard = dashboard_fixture() |> Brolga.Repo.preload([:monitor_tags, :monitors])
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Dashboard{} = dashboard} =
               Dashboards.update_dashboard(dashboard, update_attrs)

      assert dashboard.name == "some updated name"
    end

    test "update_dashboard/2 with invalid data returns error changeset" do
      dashboard = dashboard_fixture() |> Brolga.Repo.preload([:monitor_tags, :monitors])
      assert {:error, %Ecto.Changeset{}} = Dashboards.update_dashboard(dashboard, @invalid_attrs)

      assert dashboard ==
               Dashboards.get_dashboard!(dashboard.id)
               |> Brolga.Repo.preload([:monitor_tags, :monitors])
    end

    test "delete_dashboard/1 deletes the dashboard" do
      dashboard = dashboard_fixture()
      assert {:ok, %Dashboard{}} = Dashboards.delete_dashboard(dashboard)
      assert_raise Ecto.NoResultsError, fn -> Dashboards.get_dashboard!(dashboard.id) end
    end

    test "change_dashboard/1 returns a dashboard changeset" do
      dashboard = dashboard_fixture()
      assert %Ecto.Changeset{} = Dashboards.change_dashboard(dashboard)
    end
  end
end
