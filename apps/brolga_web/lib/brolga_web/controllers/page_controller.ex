defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller
  alias Brolga.{Monitor,Repo}

  def dashboard(conn, _params) do
    monitors = Monitor |> Repo.all
    render(conn, :dashboard, monitors: monitors)
  end
end
