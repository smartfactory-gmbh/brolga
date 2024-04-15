defmodule BrolgaWeb.MonitorController do
  use BrolgaWeb, :controller

  alias Brolga.Monitoring

  def export(conn, _params) do
    monitors = Monitoring.list_monitors() |> Jason.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("content-disposition", "attachement; filename=\"monitors-export.json\"")
    |> put_root_layout(false)
    |> send_resp(200, monitors)
  end
end
