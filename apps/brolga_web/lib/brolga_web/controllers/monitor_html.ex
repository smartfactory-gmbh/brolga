defmodule BrolgaWeb.MonitorHTML do
  use BrolgaWeb, :html

  embed_templates "monitor_html/*"

  @doc """
  Renders a monitor form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def monitor_form(assigns)
end
