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
        start: ~N[2023-07-24 09:21:00],
        end: ~N[2023-07-24 09:21:00]
      })
      |> Brolga.Alerting.create_incident()

    incident
  end
end
