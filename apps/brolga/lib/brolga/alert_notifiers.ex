defmodule Brolga.AlertNotifiers do
  @moduledoc """
  Central logic to be called when a notification should be sent through
  the configured notifiers (i.e. `Brolga.AlertNotifiers.EmailNotifier`).
  """

  require Logger

  @default_notifiers [
    Brolga.AlertNotifiers.EmailNotifier,
    Brolga.AlertNotifiers.SlackNotifier
  ]

  defp get_notifiers do
    case Application.fetch_env(:brolga, __MODULE__) do
      {:ok, value} ->
        case Keyword.get(value, :notifiers, :default) do
          :default -> @default_notifiers
          other -> other
        end

      :error ->
        @default_notifiers
    end
  end

  defp enabled_notifiers do
    get_notifiers()
    |> Enum.filter(fn notifier -> notifier.enabled? end)
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

    Logger.info("Enabled notifiers: #{notifiers}")
  end
end
