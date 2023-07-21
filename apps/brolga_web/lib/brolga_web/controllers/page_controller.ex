defmodule BrolgaWeb.PageController do
  use BrolgaWeb, :controller

  def dashboard(conn, _params) do
    render(conn, :dashboard)
  end
end
