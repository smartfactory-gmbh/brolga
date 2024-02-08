defmodule Brolga.AlertingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brolga.Alerting` context.
  """

  @doc """
  Generate a incident.
  """
  def incident_fixture(attrs \\ %{}) do
    {:ok, incident} =
      attrs
      |> Enum.into(%{
        started_at: ~N[2023-07-24 09:21:00],
        ended_at: ~N[2023-07-24 09:21:00]
      })
      |> Brolga.Alerting.create_incident()

    incident
  end

  @doc """
  Generate an open incident.
  """
  def open_incident_fixture(attrs \\ %{}) do
    {:ok, incident} =
      attrs
      |> Enum.into(%{
        started_at: ~N[2023-07-24 09:21:00]
      })
      |> Brolga.Alerting.create_incident()

    incident
  end
end
