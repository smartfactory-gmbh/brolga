defmodule Brolga.Email.IncidentEmail do
  import Swoosh.Email
  alias Brolga.Alerting.Incident

  @mail_config Application.compile_env!(:brolga, :incident_mail_config)

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

  def new_incident(incident) do
    [from: from, to: to] = @mail_config
    new()
    |> to(to)
    |> from(from)
    |> subject("A new incident occurred")
    |> html_body(@html_body_down |> String.replace("__NAME__", incident.monitor.name))
    |> text_body(@text_body_down |> String.replace("__NAME__", incident.monitor.name))
  end

  def incident_resolved(incident) do
    [from: from, to: to] = @mail_config
    new()
    |> to(to)
    |> from(from)
    |> subject("An incident has been resolved")
    |> html_body(@html_body_up |> String.replace("__NAME__", incident.monitor.name))
    |> text_body(@text_body_up |> String.replace("__NAME__", incident.monitor.name))
  end
end
