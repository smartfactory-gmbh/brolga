defmodule BrolgaWeb.MonitorTagLive.Index do
  use BrolgaWeb, :live_view

  alias Brolga.Monitoring
  alias Brolga.Monitoring.MonitorTag

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :monitor_tags, Monitoring.list_monitor_tags())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Monitor tag")
    |> assign(:monitor_tag, Monitoring.get_monitor_tag!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Monitor tag")
    |> assign(:monitor_tag, %MonitorTag{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Monitor tags")
    |> assign(:monitor_tag, nil)
  end

  @impl true
  def handle_info({BrolgaWeb.MonitorTagLive.FormComponent, {:saved, monitor_tag}}, socket) do
    {:noreply, stream_insert(socket, :monitor_tags, monitor_tag)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    monitor_tag = Monitoring.get_monitor_tag!(id)
    {:ok, _} = Monitoring.delete_monitor_tag(monitor_tag)

    {:noreply, stream_delete(socket, :monitor_tags, monitor_tag)}
  end
end
