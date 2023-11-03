defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller

  alias Brolga.Dashboards

  def dashboard(conn, params) do
    dashboard_id = Map.get(params, "id")

    dashboard =
      if dashboard_id do
        Dashboards.get_dashboard!(dashboard_id)
      else
        nil
      end

    conn
    |> put_root_layout(false)
    |> put_layout(html: :fullscreen)
    |> render(:dashboard, dashboard: dashboard)
  end
end
