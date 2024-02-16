defmodule BrolgaWeb.MonitorLive do
  use Phoenix.LiveView
  alias Brolga.{Monitoring, Dashboards}
  use BrolgaWeb, :html

  import BrolgaWeb.MonitorComponents

  # 1 minute interval
  @refresh_interval 1000 * 60

  def render(assigns) do
    ~H"""
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
    """
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

  def mount(_params, session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @refresh_interval)

    dashboard = session["dashboard"]
    monitors = get_monitors(dashboard)
    {:ok, assign(socket, monitors: monitors, dashboard: dashboard)}
  end

  def handle_info(:update, %{assigns: %{dashboard: dashboard}} = socket) do
    Process.send_after(self(), :update, @refresh_interval)

    monitors = get_monitors(dashboard)
    {:noreply, assign(socket, monitors: monitors)}
  end
end
