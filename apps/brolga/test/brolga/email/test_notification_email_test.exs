defmodule Brolga.Email.TestNotificationEmailTest do
  use Brolga.DataCase

  alias Brolga.Email.TestNotificationEmail

  describe "test_notification/0" do
    test "contains the default text" do
      email = TestNotificationEmail.test_notification()

      assert email.text_body == "This is a test email from Brolga\n"
      assert email.html_body == "<h2>This is a test email from Brolga</h2>\n"
    end

    test "uses the configured sender and recipient" do
      email = TestNotificationEmail.test_notification()

      assert email.from == {"Exemple admin", "admin@example.com"}
      assert email.to == [{"Example recipient", "recipient@example.com"}]
    end
  end
end
