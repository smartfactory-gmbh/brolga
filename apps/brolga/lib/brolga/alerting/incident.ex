defmodule Brolga.Alerting.Incident do
  @moduledoc """
  Represents an event where a monitor could not be reached.

  Implicitly, it can only be in two states:

  - `ended_at` is `nil`, so the target is still not responding
  - `ended_at` contains a value, so the target is up again and the incident is closed
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Brolga.Monitoring.Monitor

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          monitor: Monitor.t(),
          updated_at: DateTime.t(),
          inserted_at: DateTime.t(),
          started_at: DateTime.t(),
          ended_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "incidents" do
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime
    belongs_to :monitor, Monitor

    timestamps()
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:started_at, :ended_at, :monitor_id])
    |> validate_required([:started_at])
  end

  @spec duration(t()) :: {hours :: integer, minutes :: integer}
  def duration(incident) do
    {hours, minutes, _, _} =
      Timex.diff(incident.started_at, incident.ended_at, :duration)
      |> Timex.Duration.abs()
      |> Timex.Duration.to_clock()

    {hours, minutes}
  end

  @spec formatted_duration(t()) :: String.t()
  def formatted_duration(incident) do
    {hours, minutes} = duration(incident)
    "#{hours}h #{minutes}m"
  end
end
