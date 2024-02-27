defmodule BrolgaWeb.MonitorComponents do
  @moduledoc """
  Provides incident specific UI components.
  """
  use Phoenix.Component
  import BrolgaWeb.CoreComponents, only: [input: 1]
  import Brolga.Utils
  alias Brolga.Monitoring
  alias Brolga.Monitoring.{MonitorTag, Monitor}

  use Phoenix.VerifiedRoutes,
    endpoint: BrolgaWeb.Endpoint,
    router: BrolgaWeb.Router

  def monitor_tags_select(assigns) do
    tags =
      Monitoring.list_monitor_tags()
      |> Enum.reduce([], fn %MonitorTag{id: id, name: name}, acc -> [{name, id} | acc] end)

    assigns
    |> Map.put(:type, "select")
    |> Map.put(:options, tags)
    |> input()
  end

  def monitors_select(assigns) do
    monitors =
      Monitoring.list_monitors()
      |> Enum.reduce([], fn %Monitor{id: id, name: name}, acc -> [{name, id} | acc] end)

    assigns
    |> Map.put(:type, "select")
    |> Map.put(:options, monitors)
    |> input()
  end

  attr :monitor, Monitor, required: true

  def monitor_state_card(%{monitor: monitor} = assigns) do
    {border_class, background_class} =
      cond do
        not monitor.active -> {"border-state-inactive", "bg-state-inactive"}
        monitor.is_down -> {"border-state-down", "bg-state-down"}
        true -> {"border-state-up", "bg-state-up"}
      end

    assigns =
      assigns
      |> assign(:background_class, background_class)
      |> assign(:border_class, border_class)

    ~H"""
    <.link target="_blank" navigate={~p"/admin/monitors/#{@monitor.id}"}>
      <div class={[
        "border h-full pb-1 md:pb-2 rounded flex flex-col items-center justify-top text-center gap-1 bg-black/25",
        @border_class
      ]}>
        <div class={[
          "rounded-t-sm px-2 py-0.5 flex-0 font-bold text-base md:text-lg min-w-full",
          @background_class
        ]}>
          <%= if @monitor.active do %>
            <%= float_to_percentage_format(@monitor.uptime) %><span class="text-xs"> %</span>
          <% else %>
            <span class="text-sm">Inactive</span>
          <% end %>
        </div>
        <div class="flex-1 flex items-center">
          <div class="text-xs md:text-[13px] lg:text-sm font-semibold line-clamp-2 leading-3 md:leading-4">
            <%= @monitor.name %>
          </div>
        </div>
      </div>
    </.link>
    """
  end
end
