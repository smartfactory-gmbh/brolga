defmodule BrolgaWeb.IncidentComponents do
  @moduledoc """
  Provides incident specific UI components.
  """
  use Phoenix.Component

  import BrolgaWeb.CoreComponents
  import Brolga.Utils

  attr :monitor, Brolga.Monitoring.Monitor, required: true

  def incidents_list(assigns) do
    ~H"""
    <h3 class="font-bold text-lg mt-8">Incidents</h3>
    <div class="mt-4 flex flex-col gap-4">
      <%= for incident <- @monitor.incidents do %>
        <div class={[
          "border p-4 rounded drop-shadow",
          incident.ended_at && "border-green-500 bg-green-100 text-green-950",
          !incident.ended_at && "border-red-500 bg-red-100 text-red-950"
        ]}>
          Incident started at <.time id={"started-at__#{incident.id}"} value={incident.started_at} />
          <%= if incident.ended_at do %>
            <p>The issue has been resolved at <%= format_datetime!(incident.ended_at) %></p>
          <% else %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
