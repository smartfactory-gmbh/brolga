defmodule BrolgaWeb.PublicMonitorLive do
  use BrolgaWeb, :fullscreen_live_view
  alias Brolga.{Monitoring, Dashboards}

  import BrolgaWeb.MonitorComponents

  # 1 minute interval
  @refresh_interval 1000 * 60

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-black text-white h-screen p-8">
      <div class="h-full max-w-[1920px] mx-auto bg-no-repeat bg-[url('/images/smf-logo.svg')] bg-center bg-contain bg-opacity-50">
        <div
          class="overflow-y-auto max-h-[95vh] no-scrollbar"
          data-scroll-interval="10"
          phx-hook="MonitorDashboard"
          id="monitor-dashboard"
        >
          <div class="grid grid-cols-3 md:grid-cols-6 lg:grid-cols-9 gap-3 auto-rows-fr">
            <%= for monitor <- @monitors do %>
              <.monitor_state_card monitor={monitor} />
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def assign_dashboard(socket, dashboard) do
    monitors = get_monitors(dashboard)

    socket
    |> assign(dashboard: dashboard)
    |> assign(monitors: monitors)
  end

  defp get_monitors(dashboard) do
    dashboard =
      if dashboard == nil do
        Dashboards.get_default_dashboard()
      else
        dashboard
      end

    if dashboard do
      Monitoring.list_monitors_for_dashboard(dashboard.id)
    else
      []
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket |> assign(monitors: [])
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    id = params["id"]

    dashboard =
      if is_nil(id) do
        Dashboards.get_default_dashboard()
      else
        case Dashboards.get_dashboard(id) do
          {:ok, dashboard} -> dashboard
          {:error, _} -> nil
        end
      end

    socket =
      case dashboard do
        nil ->
          socket
          |> put_flash(:error, "Dashboard not found, falling back to default")
          |> push_patch(to: "/")

        dashboard ->
          if connected?(socket), do: Process.send_after(self(), :update, @refresh_interval)
          socket |> assign_dashboard(dashboard)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update, %{assigns: %{dashboard: dashboard}} = socket) do
    Process.send_after(self(), :update, @refresh_interval)

    monitors = get_monitors(dashboard)
    {:noreply, assign(socket, monitors: monitors)}
  end
end
