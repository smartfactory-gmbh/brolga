defmodule Brolga.AlertNotifiers.EmailNotifier do
  @moduledoc false

  alias Brolga.Mailer
  alias Brolga.Email.IncidentEmail
  alias Brolga.Email.TestNotificationEmail

  defp get_config do
    Application.get_env(:brolga, :email_notifier)
  end

  def enabled? do
    get_config()[:enabled] == true
  end

  @spec new_incident(Brolga.Alerting.Incident.t()) :: :ok | :error
  def new_incident(incident) do
    results =
      incident
      |> IncidentEmail.new_incident()
      |> Mailer.deliver()

    case results do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @spec incident_resolved(Brolga.Alerting.Incident.t()) :: :ok | :error
  def incident_resolved(incident) do
    results =
      incident
      |> IncidentEmail.incident_resolved()
      |> Mailer.deliver()

    case results do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @spec test_notification() :: :ok | :error
  def test_notification() do
    results =
      TestNotificationEmail.test_notification()
      |> Mailer.deliver()

    case results do
      {:ok, _} -> :ok
      _ -> :error
    end
  end
end
