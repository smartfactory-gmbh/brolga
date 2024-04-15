defmodule BrolgaWeb.IncidentsListComponent do
  @moduledoc """
  Provides an incident list component
  """
  use BrolgaWeb, :live_component

  alias Brolga.Alerting
  import BrolgaWeb.CoreComponents

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(monitor: assigns.monitor)
      |> assign_incidents()
    }
  end

  def assign_incidents(%{assigns: %{monitor: monitor}} = socket) do
    incidents = Alerting.get_last_incidents!(monitor.id)

    socket
    |> stream(:incidents, incidents)
  end

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="font-bold text-lg mt-8">Incidents</h3>
      <div class="mt-4 flex flex-col gap-4">
        <%= for {id, incident} <- @streams.incidents do %>
          <div
            id={id}
            class={[
              "border p-4 rounded drop-shadow",
              incident.ended_at && "border-green-500 bg-green-100 text-green-950",
              !incident.ended_at && "border-red-500 bg-red-100 text-red-950"
            ]}
          >
            Incident started at <.time id={"started_at-#{incident.id}"} value={incident.started_at} />
            <%= if incident.ended_at do %>
              <p>
                The issue has been resolved at
                <.time id={"ended_at-#{incident.id}"} value={incident.ended_at} />
              </p>
            <% else %>
              <p>
                <a phx-click="solve_incident" phx-value-id={incident.id} phx-target={@myself}>
                  Mark as solved
                </a>
              </p>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("solve_incident", %{"id" => id}, socket) do
    id
    |> Alerting.get_incident!()
    |> Alerting.update_incident(%{ended_at: Timex.now()})

    {:noreply, socket |> assign_incidents()}
  end
end
