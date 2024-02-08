defmodule BrolgaWeb.MonitorLive.Index do
  use BrolgaWeb, :live_view

  import BrolgaWeb.MonitorTagComponents

  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  @impl true
  def mount(_params, _session, socket) do
    monitors =
      Monitoring.list_monitors_with_latest_results(with_tags: true) |> Monitor.populate_hosts()

    {:ok, stream(socket, :monitors, monitors)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Monitor")
    |> assign(:monitor, Monitoring.get_monitor_with_details!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Monitor")
    |> assign(:monitor, %Monitor{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Monitors")
    |> assign(:monitor, nil)
  end

  @impl true
  def handle_info({BrolgaWeb.MonitorLive.FormComponent, {:saved, monitor}}, socket) do
    monitor = Monitoring.get_monitor_with_details!(monitor.id)
    {:noreply, stream_insert(socket, :monitors, monitor)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    monitor = Monitoring.get_monitor!(id)
    {:ok, _} = Monitoring.delete_monitor(monitor)

    {:noreply, stream_delete(socket, :monitors, monitor)}
  end
end
