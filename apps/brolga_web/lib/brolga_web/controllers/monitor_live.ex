defmodule BrolgaWeb.MonitorLive do
  use Phoenix.LiveView
  alias Brolga.Monitoring
  import Brolga.Utils

  # 1 minute interval
  @refresh_interval 1000 * 60

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-3">
      <%= for monitor <- @monitors do %>
        <div class={[
          "border p-2 rounded flex flex-col items-center justify-center text-center gap-1",
          monitor.is_down && "border-[#FF3B59]",
          not monitor.is_down && "border-[#78BE20]"
        ]}>
          <div class={[
            "rounded-sm px-2 py-1",
            monitor.is_down && "bg-[#FF3B59]",
            not monitor.is_down && "bg-[#78BE20]"
          ]}>
            <%= float_to_percentage_format(monitor.uptime) %>
          </div>
          <div class="text-[14px] line-clamp-1"><%= monitor.name %></div>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @refresh_interval)

    monitors = Monitoring.list_monitors()
    {:ok, assign(socket, monitors: monitors)}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, @refresh_interval)

    monitors = Monitoring.list_monitors()
    {:noreply, assign(socket, monitors: monitors)}
  end
end
