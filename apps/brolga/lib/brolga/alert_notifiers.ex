defmodule Brolga.AlertNotifiers do
  @moduledoc """
  Central logic to be called when a notification should be sent through
  the configured notifiers (i.e. `Brolga.AlertNotifiers.EmailNotifier`).
  """

  @notifiers Application.compile_env(:brolga, [__MODULE__, :notifiers], [
               Brolga.AlertNotifiers.EmailNotifier,
               Brolga.AlertNotifiers.SlackNotifier
             ])

  defp enabled_notifiers do
    Enum.filter(@notifiers, fn notifier -> notifier.enabled? end)
  end

  def new_incident(incident) do
    enabled_notifiers()
    |> Enum.map(fn notifier -> {notifier, notifier.new_incident(incident)} end)
  end

  def incident_resolved(incident) do
    enabled_notifiers()
    |> Enum.map(fn notifier -> {notifier, notifier.incident_resolved(incident)} end)
  end

  def test_notification() do
    enabled_notifiers() |> Enum.map(fn notifier -> {notifier, notifier.test_notification()} end)
  end

  def log_enabled_notifiers() do
    notifiers =
      enabled_notifiers()
      |> Enum.map(&Atom.to_string(&1))
      |> Enum.map_join(", ", &String.trim_leading(&1, "Elixir."))

    :logger.info("Enabled notifiers: #{notifiers}")
  end
end
