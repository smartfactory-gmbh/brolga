defmodule BrolgaWeb.MonitorHTML do
  use BrolgaWeb, :html
  import BrolgaWeb.IncidentComponents
  import BrolgaWeb.MonitorComponents

  embed_templates "monitor_html/*"

  @doc """
  Renders a monitor form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :tags, :list, required: true

  def monitor_form(assigns)
end
