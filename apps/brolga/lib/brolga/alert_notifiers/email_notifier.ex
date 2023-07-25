
defmodule Brolga.AlertNotifiers.EmailNotifier do
  @moduledoc false
  alias Brolga.Mailer
  alias Brolga.Email.IncidentEmail

  @spec new_incident(Brolga.Alerting.Incident.t()) :: :ok | :error
  def new_incident(incident) do
    results = incident
    |> IncidentEmail.new_incident()
    |> Mailer.deliver

    case results do
      :ok -> :ok
      _ -> :error
    end
  end

  @spec incident_resolved(Brolga.Alerting.Incident.t()) :: :ok | :error
  def incident_resolved(incident) do
    results = incident
    |> IncidentEmail.incidient_resolved()
    |> Mailer.deliver

    case results do
      :ok -> :ok
      _ -> :error
    end
  end
end
