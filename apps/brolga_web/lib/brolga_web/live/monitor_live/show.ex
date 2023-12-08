defmodule BrolgaWeb.MonitorLive.Show do
  use BrolgaWeb, :live_view

  alias Brolga.Monitoring
  alias BrolgaWeb.IncidentsListComponent
  import BrolgaWeb.IncidentComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:monitor, Monitoring.get_monitor_with_details!(id))}
  end

  defp page_title(:show), do: "Show Monitor"
  defp page_title(:edit), do: "Edit Monitor"
end
