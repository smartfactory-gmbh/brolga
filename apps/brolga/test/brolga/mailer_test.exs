defmodule Brolga.MailerTest do
  use Brolga.DataCase

  alias Brolga.Mailer
  alias Swoosh.Email

  @default_email Email.new()

  describe "new" do
    test "gets default config" do
      mail = Mailer.new()
      assert mail == @default_email
    end

    test "grabs provider options if any" do
      old_options = Application.fetch_env!(:brolga, Brolga.Mailer)
      Application.put_env(:brolga, Brolga.Mailer, provider_options: [x_api_key: "123456"])
      mail = Mailer.new()
      Application.put_env(:brolga, Brolga.Mailer, old_options)

      assert mail == %Email{@default_email | provider_options: %{x_api_key: "123456"}}
    end
  end
end
