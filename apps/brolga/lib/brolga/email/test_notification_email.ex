defmodule Brolga.Email.TestNotificationEmail do
  @moduledoc """
  Simplistic email sent for testing the email client config
  """

  import Swoosh.Email

  defp get_config do
    Application.get_env(:brolga, :email_notifier)
  end

  @html_body """
  <h2>This is a test email from Brolga</h2>
  """

  @text_body """
  This is a test email from Brolga
  """

  def test_notification() do
    config = get_config()

    new()
    |> to(config[:to])
    |> from(config[:from])
    |> subject("Brolga: test notification")
    |> html_body(@html_body)
    |> text_body(@text_body)
  end
end
