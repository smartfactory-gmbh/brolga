defmodule BrolgaWeb.MonitorTagLive.Show do
  use BrolgaWeb, :live_view

  alias Brolga.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:monitor_tag, Monitoring.get_monitor_tag!(id))}
  end

  defp page_title(:show), do: "Show Monitor tag"
  defp page_title(:edit), do: "Edit Monitor tag"
end
