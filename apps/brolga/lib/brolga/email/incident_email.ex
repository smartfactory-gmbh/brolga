defmodule Brolga.Email.IncidentEmail do
  @moduledoc """
  Email module responsible for generating ready-to-send emails for
  both when a monitor is up or down
  """

  import Swoosh.Email
  alias Brolga.Alerting.Incident

  defp get_config do
    Application.get_env(:brolga, :email_notifier)
  end

  @html_body_down """
  <h2>__NAME__ is down</h2>
  """

  @text_body_down """
  __NAME__ is down
  """

  @html_body_up """
  <h2>__NAME__ is up</h2>
  """

  @text_body_up """
  __NAME__ is up
  """

  @spec new_incident(incident :: Incident.t()) :: Swoosh.Email.t()
  def new_incident(incident) do
    config = get_config()

    Brolga.Mailer.new()
    |> to(config[:to])
    |> from(config[:from])
    |> subject("A new incident occurred")
    |> html_body(@html_body_down |> String.replace("__NAME__", incident.monitor.name))
    |> text_body(@text_body_down |> String.replace("__NAME__", incident.monitor.name))
  end

  @spec incident_resolved(incident :: Incident.t()) :: Swoosh.Email.t()
  def incident_resolved(incident) do
    config = get_config()

    Brolga.Mailer.new()
    |> to(config[:to])
    |> from(config[:from])
    |> subject("An incident has been resolved")
    |> html_body(@html_body_up |> String.replace("__NAME__", incident.monitor.name))
    |> text_body(@text_body_up |> String.replace("__NAME__", incident.monitor.name))
  end
end
