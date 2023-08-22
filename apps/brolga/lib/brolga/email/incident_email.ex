defmodule Brolga.Email.IncidentEmail do
  @moduledoc """
  Email module responsible for generating ready-to-send emails for
  both when a monitor is up or down
  """

  import Swoosh.Email
  alias Brolga.Alerting.Incident
  alias Brolga.Utils

  defp get_config do
    Application.get_env(:brolga, :email_notifier)
  end

  @html_body_down """
  <h2>__NAME__ is down</h2>

  <p>Incident was detected at __START_DATE__.<p>
  """

  @text_body_down """
  __NAME__ is down

  Incident was detected at __START_DATE__.
  """

  @html_body_up """
  <h2>__NAME__ is up</h2>
  <p>Incident was detected at __START_DATE__.<p>
  <p>Incident was fixed at __END_DATE__.<p>
  """

  @text_body_up """
  __NAME__ is up

  Incident was detected at __START_DATE__.
  Incident was fixed at __END_DATE__.
  """

  @spec new_incident(incident :: Incident.t()) :: Swoosh.Email.t()
  def new_incident(incident) do
    config = get_config()

    start_date = Utils.format_datetime!(incident.started_at)

    formatted_html =
      @html_body_down
      |> String.replace("__NAME__", incident.monitor.name)
      |> String.replace("__START_DATE__", start_date)

    formatted_text =
      @text_body_down
      |> String.replace("__NAME__", incident.monitor.name)
      |> String.replace("__START_DATE__", start_date)

    Brolga.Mailer.new()
    |> to(config[:to])
    |> from(config[:from])
    |> subject("A new incident occurred")
    |> html_body(formatted_html)
    |> text_body(formatted_text)
  end

  @spec incident_resolved(incident :: Incident.t()) :: Swoosh.Email.t()
  def incident_resolved(incident) do
    config = get_config()

    start_date = Utils.format_datetime!(incident.started_at)
    end_date = Utils.format_datetime!(incident.ended_at)

    formatted_html =
      @html_body_up
      |> String.replace("__NAME__", incident.monitor.name)
      |> String.replace("__START_DATE__", start_date)
      |> String.replace("__END_DATE__", end_date)

    formatted_text =
      @text_body_up
      |> String.replace("__NAME__", incident.monitor.name)
      |> String.replace("__START_DATE__", start_date)
      |> String.replace("__END_DATE__", end_date)

    Brolga.Mailer.new()
    |> to(config[:to])
    |> from(config[:from])
    |> subject("An incident has been resolved")
    |> html_body(formatted_html)
    |> text_body(formatted_text)
  end
end
