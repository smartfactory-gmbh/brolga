defmodule BrolgaWeb.DashboardHTML do
  use BrolgaWeb, :html

  embed_templates "dashboard_html/*"

  @doc """
  Renders a dashboard form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def dashboard_form(assigns)
end
