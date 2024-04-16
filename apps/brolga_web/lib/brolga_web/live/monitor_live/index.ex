defmodule BrolgaWeb.MonitorLive.Index do
  use BrolgaWeb, :live_view

  import BrolgaWeb.MonitorTagComponents

  alias Brolga.Monitoring
  alias Brolga.Monitoring.Monitor

  @impl true
  def mount(params, _session, socket) do
    {
      :ok,
      socket
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Monitor")
    |> assign(:monitor, Monitoring.get_monitor_with_details!(id))
    |> assign(:search, "")
  end

  defp apply_action(socket, :import, _params) do
    socket
    |> assign(:page_title, "Import")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Monitor")
    |> assign(:monitor, %Monitor{})
    |> assign(:search, "")
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Monitors")
    |> assign(:monitor, nil)
    |> assign(:search, params["search"] || "")
    |> assign_monitors(search: params["search"] || "")
  end

  @impl true
  def handle_info({BrolgaWeb.MonitorLive.FormComponent, {:saved, monitor}}, socket) do
    monitor = Monitoring.get_monitor_with_details!(monitor.id) |> Monitor.populate_host()
    {:noreply, stream_insert(socket, :monitors, monitor)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    monitor = Monitoring.get_monitor!(id)
    {:ok, _} = Monitoring.delete_monitor(monitor)

    {:noreply, stream_delete(socket, :monitors, monitor)}
  end

  def handle_event("search", params, socket) do
    %{"value" => value} = params
    {:noreply, socket |> push_patch(to: ~p"/admin/monitors/?search=#{value}", replace: true)}
  end

  def assign_monitors(socket, opts \\ []) do
    search = opts[:search] || ""

    monitors =
      Monitoring.list_monitors(with_tags: true, search: search) |> Monitor.populate_hosts()

    socket |> stream(:monitors, monitors, reset: true)
  end
end
