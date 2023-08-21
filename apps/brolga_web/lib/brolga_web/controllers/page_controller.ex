defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller

  alias Brolga.Monitoring

  def dashboard(conn, _params) do
    monitors = Monitoring.list_monitors()

    conn
    |> put_root_layout(false)
    |> put_layout(html: :fullscreen)
    |> render(:dashboard, monitors: monitors)
  end
end
