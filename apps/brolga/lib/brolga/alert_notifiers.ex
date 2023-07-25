defmodule Brolga.AlertNotifiers do
  @notifiers [
    Brolga.AlertNotifiers.EmailNotifier,
  ]

  def new_incident(incident) do
    Enum.map(@notifiers, fn notifier -> notifier.new_incident(incident) end)
  end

  def incident_resolved(incident) do
    Enum.map(@notifiers, fn notifier -> notifier.new_incident(incident) end)
  end
end
