defmodule Brolga.DashboardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brolga.Dashboards` context.
  """

  @doc """
  Generate a dashboard.
  """
  def dashboard_fixture(attrs \\ %{}) do
    {:ok, dashboard} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Brolga.Dashboards.create_dashboard()

    Brolga.Repo.preload(dashboard, [:monitor_tags, :monitors])
  end
end
