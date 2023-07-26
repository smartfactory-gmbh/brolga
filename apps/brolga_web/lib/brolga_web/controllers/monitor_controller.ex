defmodule BrolgaWeb.MonitorController do
  use BrolgaWeb, :controller

  alias Brolga.Monitoring
  alias Brolga.Monitoring.{Monitor, MonitorTag}

  def index(conn, _params) do
    monitors = Monitoring.list_monitors()
    render(conn, :index, monitors: monitors)
  end

  def new(conn, _params) do
    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    changeset = Monitoring.change_monitor(%Monitor{})
    render(conn, :new, changeset: changeset, tags: tags)
  end

  def create(conn, %{"monitor" => monitor_params}) do
    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    case Monitoring.create_monitor(monitor_params) do
      {:ok, monitor} ->
        conn
        |> put_flash(:info, "Monitor created successfully.")
        |> redirect(to: ~p"/monitors/#{monitor}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, tags: tags)
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

    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    changeset = Monitoring.change_monitor(monitor)
    render(conn, :edit, monitor: monitor, changeset: changeset, tags: tags)
  end

  def update(conn, %{"id" => id, "monitor" => monitor_params}) do
    monitor =
      Monitoring.get_monitor!(id)
      |> Brolga.Repo.preload(:monitor_tags)

    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    case Monitoring.update_monitor(monitor, monitor_params) do
      {:ok, monitor} ->
        conn
        |> put_flash(:info, "Monitor updated successfully.")
        |> redirect(to: ~p"/monitors/#{monitor}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, monitor: monitor, changeset: changeset, tags: tags)
    end
  end

  def delete(conn, %{"id" => id}) do
    monitor = Monitoring.get_monitor!(id)
    {:ok, _monitor} = Monitoring.delete_monitor(monitor)

    conn
    |> put_flash(:info, "Monitor deleted successfully.")
    |> redirect(to: ~p"/monitors")
  end
end
