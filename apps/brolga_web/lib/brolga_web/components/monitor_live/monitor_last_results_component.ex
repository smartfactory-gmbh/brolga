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
      class="flex flex-row-reverse gap-2 z-10"
    >
      <%= for {id, result} <- @streams.results do %>
        <div
          id={id}
          class={[
            "h-8 rounded flex-1 relative",
            if(result.reached, do: "bg-green-500", else: "bg-red-500")
          ]}
          phx-hook="Popover"
          data-target={"#popover-#{result.id}"}
        >
          &nbsp;
          <div
            class={[
              "hidden absolute -bottom-24 p-4 rounded shadow",
              "bg-slate-900 text-white",
              "dark:bg-gray-50 dark:text-black"
            ]}
            id={"popover-#{result.id}"}
          >
            <.datetime value={result.inserted_at} id={"inserted_at-#{result.id}"} />
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
