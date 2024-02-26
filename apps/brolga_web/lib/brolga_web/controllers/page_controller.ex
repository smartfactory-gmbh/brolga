defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller

  alias Brolga.Dashboards

  def dashboard(conn, params) do
    dashboard_id = Map.get(params, "id")

    dashboard =
      case Dashboards.get_dashboard(dashboard_id) do
        {:error, _error} -> nil
        {:ok, dashboard} -> dashboard
      end

    if is_nil(dashboard) and not is_nil(dashboard_id) do
      conn
      |> put_flash(:error, "Dashboard not found, falling back to default")
      |> redirect(to: "/")
    else
      conn
      |> put_root_layout(false)
      |> put_layout(html: :fullscreen)
      |> render(:dashboard, dashboard: dashboard)
    end
  end
end
