defmodule Brolga.Alerting.Incident do
  use Ecto.Schema
  import Ecto.Changeset
  alias Brolga.Monitoring.Monitor

  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    monitor: Monitor.t(),
    updated_at: DateTime.t(),
    inserted_at: DateTime.t(),
    started_at: DateTime.t(),
    ended_at: DateTime.t(),
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
end
