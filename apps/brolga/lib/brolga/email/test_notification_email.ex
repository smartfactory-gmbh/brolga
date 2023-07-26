defmodule Brolga.Email.TestNotificationEmail do
  import Swoosh.Email
  alias Brolga.Alerting.Incident

  @mail_config Application.compile_env!(:brolga, :incident_mail_config)

  @html_body """
  <h2>This is a test email from Brolga</h2>
  """

  @text_body """
  This is a test email from Brolga
  """

  def test_notification() do
    [from: from, to: to] = @mail_config

    new()
    |> to(to)
    |> from(from)
    |> subject("Brolga: test notification")
    |> html_body(@html_body)
    |> text_body(@text_body)
  end
end
