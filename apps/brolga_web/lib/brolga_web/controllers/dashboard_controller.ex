defmodule BrolgaWeb.DashboardController do
  use BrolgaWeb, :controller

  alias Brolga.Dashboards
  alias Brolga.Dashboards.Dashboard
  alias Brolga.Monitoring
  alias Brolga.Monitoring.{MonitorTag, Monitor}

  def index(conn, _params) do
    dashboards = Dashboards.list_dashboards()
    render(conn, :index, dashboards: dashboards)
  end

  def new(conn, _params) do
    changeset = Dashboards.change_dashboard(%Dashboard{})
    render(conn, :new, changeset: changeset)
  end

  def set_default(conn, %{"id" => id}) do
    dashboard = Dashboards.get_dashboard!(id)
    Dashboards.set_default_dashboard(dashboard)
    redirect(conn, to: ~p"/admin/dashboards")
  end

  def create(conn, %{"dashboard" => dashboard_params}) do
    case Dashboards.create_dashboard(dashboard_params) do
      {:ok, dashboard} ->
        conn
        |> put_flash(:info, "Dashboard created successfully.")
        |> redirect(to: ~p"/admin/dashboards/#{dashboard}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    dashboard = Dashboards.get_dashboard!(id)
    render(conn, :show, dashboard: dashboard)
  end

  def edit(conn, %{"id" => id}) do
    dashboard =
      Dashboards.get_dashboard!(id)
      |> Brolga.Repo.preload([:monitor_tags, :monitors])

    changeset = Dashboards.change_dashboard(dashboard)

    render(conn, :edit,
      dashboard: dashboard,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "dashboard" => dashboard_params}) do
    dashboard =
      Dashboards.get_dashboard!(id)
      |> Brolga.Repo.preload([:monitor_tags, :monitors])

    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    monitors =
      Monitoring.list_monitors()
      |> Enum.reduce([], fn %Monitor{id: id, name: name}, acc -> [{name, id} | acc] end)

    case Dashboards.update_dashboard(dashboard, dashboard_params) do
      {:ok, dashboard} ->
        conn
        |> put_flash(:info, "Dashboard updated successfully.")
        |> redirect(to: ~p"/admin/dashboards/#{dashboard}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          dashboard: dashboard,
          changeset: changeset,
          tags: tags,
          monitors: monitors
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    dashboard = Dashboards.get_dashboard!(id)
    {:ok, _dashboard} = Dashboards.delete_dashboard(dashboard)

    conn
    |> put_flash(:info, "Dashboard deleted successfully.")
    |> redirect(to: ~p"/admin/dashboards")
  end
end
