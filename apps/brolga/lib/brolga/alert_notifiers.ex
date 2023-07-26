defmodule Brolga.AlertNotifiers do
  @moduledoc """
  Central logic to be called when a notification should be sent through
  the configured notifiers (i.e. `Brolga.AlertNotifiers.EmailNotifier`).

  You can configure the active notifiers in the config like follow:

  ```ex
  config :brolga, Brolga.AlertNotifiers,
    notifiers: [
      Brolga.AlertNotifiers.EmailNotifier,
      Brolga.AlertNotifiers.SlackNotifier,
      # Whatever other notifiers could be available
    ]
  ```
  """

  @notifiers Application.compile_env(:brolga, [__MODULE__, :notifiers], [
               Brolga.AlertNotifiers.EmailNotifier,
               Brolga.AlertNotifiers.SlackNotifier
             ])

  def new_incident(incident) do
    Enum.map(@notifiers, fn notifier -> {notifier, notifier.new_incident(incident)} end)
  end

  def incident_resolved(incident) do
    Enum.map(@notifiers, fn notifier -> {notifier, notifier.incident_resolved(incident)} end)
  end

  def test_notification() do
    Enum.map(@notifiers, fn notifier -> {notifier, notifier.test_notification()} end)
  end

  def log_enabled_notifiers() do
    notifiers =
      @notifiers
      |> Enum.map(&Atom.to_string(&1))
      |> Enum.map_join(", ", &String.trim_leading(&1, "Elixir."))

    :logger.info("Enabled notifiers: #{notifiers}")
  end
end
