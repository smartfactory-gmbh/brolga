defmodule BrolgaWeb.MonitorLive do
  use Phoenix.LiveView
  alias Brolga.{Monitoring, Dashboards}
  import Brolga.Utils
  use BrolgaWeb, :html

  # 1 minute interval
  @refresh_interval 1000 * 60

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-3">
      <%= for monitor <- @monitors do %>
        <a target="_blank" href={~p"/admin/monitors/#{monitor.id}"}>
          <div class={[
            "border h-full p-2 rounded flex flex-col items-center justify-top text-center gap-1",
            monitor.is_down && "border-[#FF3B59]",
            not monitor.is_down && "border-[#78BE20]"
          ]}>
            <div class={[
              "rounded-sm px-2 py-1 flex-0",
              monitor.is_down && "bg-[#FF3B59]",
              not monitor.is_down && "bg-[#78BE20]"
            ]}>
              <%= float_to_percentage_format(monitor.uptime) %>
            </div>
            <div class="flex-1 flex items-center">
              <div class="text-[14px] line-clamp-2 leading-4"><%= monitor.name %></div>
            </div>
          </div>
        </a>
      <% end %>
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
