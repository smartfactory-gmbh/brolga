defmodule BrolgaWeb.MonitorController do
  use BrolgaWeb, :controller

  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  def index(conn, _params) do
    monitors =
      Monitoring.list_monitors_with_latest_results(with_tags: true) |> Monitor.populate_hosts()

    render(conn, :index, monitors: monitors)
  end

  def new(conn, _params) do
    changeset = Monitoring.change_monitor(%Monitor{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"monitor" => monitor_params}) do
    case Monitoring.create_monitor(monitor_params) do
      {:ok, monitor} ->
        conn
        |> put_flash(:info, "Monitor created successfully.")
        |> redirect(to: ~p"/admin/monitors/#{monitor}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    monitor = Monitoring.get_monitor_with_details!(id)
    render(conn, :show, monitor: monitor)
  end

  def edit(conn, %{"id" => id}) do
    monitor =
      Monitoring.get_monitor!(id)
      |> Brolga.Repo.preload(:monitor_tags)

    changeset = Monitoring.change_monitor(monitor)
    render(conn, :edit, monitor: monitor, changeset: changeset)
  end

  def update(conn, %{"id" => id, "monitor" => monitor_params}) do
    monitor =
      Monitoring.get_monitor!(id)
      |> Brolga.Repo.preload(:monitor_tags)

    case Monitoring.update_monitor(monitor, monitor_params) do
      {:ok, monitor} ->
        conn
        |> put_flash(:info, "Monitor updated successfully.")
        |> redirect(to: ~p"/admin/monitors/#{monitor}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, monitor: monitor, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    monitor = Monitoring.get_monitor!(id)
    {:ok, _monitor} = Monitoring.delete_monitor(monitor)

    conn
    |> put_flash(:info, "Monitor deleted successfully.")
    |> redirect(to: ~p"/admin/monitors")
  end

  def admin(conn, _params) do
    redirect(conn, to: ~p"/admin/monitors")
  end
end
