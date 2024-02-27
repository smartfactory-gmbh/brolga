defmodule BrolgaWeb.MonitorLive.Show do
  alias Phoenix.PubSub
  use BrolgaWeb, :live_view

  alias Brolga.Monitoring
  alias BrolgaWeb.IncidentsListComponent
  alias BrolgaWeb.MonitorLive.MonitorLastResultsComponent

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Brolga.PubSub, "monitor:#{id}:new-result")
    end

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

  @impl true
  def handle_info({:result_created, result}, socket) do
    send_update(MonitorLastResultsComponent, id: "ticker-#{result.monitor_id}", result: result)

    {
      :noreply,
      socket
    }
  end

  def handle_info(_params, socket) do
    {
      :noreply,
      socket
    }
  end
end
