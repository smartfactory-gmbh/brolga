defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller

  alias Brolga.Monitoring

  def dashboard(conn, _params) do
    monitors = Monitoring.list_monitors()

    conn
    |> put_layout(false)
    |> render(:dashboard, monitors: monitors)
  end
end
