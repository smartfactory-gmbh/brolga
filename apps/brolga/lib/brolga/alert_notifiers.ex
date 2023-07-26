defmodule Brolga.AlertNotifiers do
  @notifiers Application.compile_env(:brolga, [__MODULE__, :notifiers], [
    Brolga.AlertNotifiers.EmailNotifier,
    Brolga.AlertNotifiers.SlackNotifier,
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
    notifiers = @notifiers
    |> Enum.map(&Atom.to_string(&1))
    |> Enum.map(&String.trim_leading(&1, "Elixir."))
    |> Enum.join(", ")

    :logger.info("Enabled notifiers: #{notifiers}")
  end
end
