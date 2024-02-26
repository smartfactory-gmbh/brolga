defmodule BrolgaWeb.MonitorLive.MonitorLastResultsComponent do
  use BrolgaWeb, :live_component

  def update(%{result: result} = _assigns, socket) do
    {
      :ok,
      socket |> insert_new_result(result)
    }
  end

  def update(assigns, socket) do
    tick_number = assigns[:tick_number] || 25
    prefill = assigns[:prefill] || false

    {
      :ok,
      socket
      |> assign_last_results(assigns.monitor_id, prefill, tick_number)
      |> assign(:monitor_id, assigns.monitor_id)
    }
  end

  def insert_new_result(socket, result) do
    socket
    |> stream_insert(:results, result, at: 0)
  end

  def assign_last_results(socket, monitor_id, prefill, tick_number) do
    results =
      if prefill do
        Brolga.Monitoring.get_latest_results(monitor_id)
      else
        []
      end

    socket
    |> stream(:results, results, limit: tick_number)
  end

  def render(assigns) do
    ~H"""
    <div
      id={"ticker-container-#{@monitor_id}"}
      phx-update="stream"
      class="flex flex-row-reverse gap-2"
    >
      <%= for {id, result} <- @streams.results do %>
        <div
          id={id}
          class={
            ["w-[4%]", "h-8", "rounded"] ++
              [if(result.reached, do: "bg-green-500", else: "bg-red-500")]
          }
        >
          &nbsp;
        </div>
      <% end %>
    </div>
    """
  end
end
