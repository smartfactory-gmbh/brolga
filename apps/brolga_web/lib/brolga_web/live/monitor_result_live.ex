defmodule BrolgaWeb.MonitorResultLive do
  use BrolgaWeb, :live_view

  import Brolga.Utils

  alias Brolga.Monitoring
  alias Brolga.Monitoring.MonitorResult

  @page_length 15
  @fetch_opts [with_monitors: true, length: @page_length]

  @impl true
  def mount(params, _session, socket) do
    {
      :ok,
      socket
      |> assign_monitor(params)
      |> assign(:live_mode, false)
      |> assign(:live_mode_timer, nil)
      |> assign_live_mode_timer()
      |> assign_new_page()
      |> assign(:update_type, "stream")
    }
  end

  defp fetch(last_number, socket) do
    live_mode = socket.assigns.live_mode
    cutoff_date = socket.assigns.cutoff_date

    opts =
      if live_mode do
        @fetch_opts
      else
        [{:cutoff_date, cutoff_date} | @fetch_opts]
      end

    case socket do
      %{assigns: %{monitor: nil}} ->
        Monitoring.get_previous_monitor_results(last_number, opts)

      %{assigns: %{monitor: monitor}} ->
        Monitoring.get_previous_monitor_results_for(monitor.id, last_number, opts)
    end
  end

  defp assign_monitor(socket, params) do
    case params do
      %{"id" => id} ->
        monitor = Monitoring.get_monitor!(id)
        assign(socket, :monitor, monitor)

      _ ->
        assign(socket, :monitor, nil)
    end
  end

  defp assign_new_page(socket) do
    # Only used on first load
    cutoff_date = Timex.now()
    socket = assign(socket, :cutoff_date, cutoff_date)
    results = fetch(0, socket)

    socket
    |> assign(:last_number, @page_length)
    |> stream(:monitor_results, results, reset: true)
  end

  defp assign_next_page(%{assigns: %{last_number: last_number}} = socket) do
    results = fetch(last_number, socket)

    socket
    |> assign(:last_number, last_number + @page_length)
    |> stream_batch_insert(:monitor_results, results, at: -1)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Monitor results")
    |> assign(:test, nil)
  end

  defp assign_live_mode_timer(
         %{assigns: %{live_mode: live_mode, live_mode_timer: live_mode_timer}} = socket
       ) do
    if live_mode_timer do
      Process.cancel_timer(live_mode_timer)
    end

    new_timer =
      if live_mode do
        Process.send_after(self(), :live_update, 10_000)
      else
        nil
      end

    assign(socket, :live_mode_timer, new_timer)
  end

  @impl true
  def handle_event("enable-live-mode", _params, socket) do
    Process.send_after(self(), :live_update, 10_000)

    socket =
      socket
      |> assign_new_page()
      |> assign(:update_type, "replace")
      |> assign(:live_mode, true)
      |> assign_live_mode_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_event("disable-live-mode", _params, socket) do
    socket =
      socket
      |> assign(:update_type, "stream")
      |> assign(:live_mode, false)
      |> assign_live_mode_timer()

    {:noreply, socket}
  end

  def handle_event("next-page", _params, socket) do
    socket =
      if socket.assigns.live_mode do
        socket
      else
        socket |> assign_next_page()
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:live_update, socket) do
    socket =
      if socket.assigns.live_mode do
        Process.send_after(self(), :live_update, 10_000)
        socket |> assign_new_page()
      else
        socket
      end

    {:noreply, socket}
  end

  attr :result, MonitorResult, required: true
  attr :id, :string, required: true

  def monitor_result(%{result: %{reached: reached}} = assigns) do
    classes =
      if reached do
        "bg-green-200 border-green-800 text-green-800"
      else
        "bg-red-200 border-red-800 text-red-800"
      end

    assigns = assign(assigns, :classes, classes)

    ~H"""
    <div id={@id} class={"flex flex-col gap-4 min-h-16 border rounded p-4 #{@classes}"}>
      <div class="flex gap-4 italic">
        <div><%= format_datetime!(@result.inserted_at) %></div>
        <div><%= @result.monitor.name %></div>
      </div>
      <div><%= @result.message %></div>
    </div>
    """
  end
end
