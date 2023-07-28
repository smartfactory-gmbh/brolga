defmodule Mix.Tasks.TestNotifiers do
  @moduledoc """
  Sends a test notification in order to check
  the notifiers configurations

  Usage:

  mix test_notifiers
  """
  alias Brolga.AlertNotifiers
  use Mix.Task

  @shortdoc "Sends a test notification to configured notifiers"
  def run(_) do
    Mix.Task.run("app.start")
    AlertNotifiers.test_notification()
  end
end
