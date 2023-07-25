defmodule Brolga.Monitoring.Monitor do
  alias Brolga.Monitoring
  alias Brolga.Monitoring.{MonitorResult,MonitorTag}
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t(),
    url: String.t(),
    interval_in_minutes: non_neg_integer(),
    updated_at: DateTime.t(),
    inserted_at: DateTime.t(),
    timeout_in_seconds: non_neg_integer(),
    active: boolean(),
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monitors" do
    field :name, :string
    field :url, :string
    field :interval_in_minutes, :integer
    field :active, :boolean, default: true
    field :timeout_in_seconds, :integer, default: 10

    has_many :monitor_results, MonitorResult, preload_order: [desc: :inserted_at]
    many_to_many :monitor_tags, MonitorTag, join_through: "monitors_tags", on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(monitor, attrs) do
    monitor
    |> cast(attrs, [:name, :url, :timeout_in_seconds, :active, :interval_in_minutes])
    |> validate_required([:name, :url, :interval_in_minutes])
    |> validate_length(:name, min: 5)
    |> validate_length(:url, min: 5)
    |> validate_number(:interval_in_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:timeout_in_seconds, greater_than_or_equal_to: 1)
    |> check_constraint(:timeout_in_seconds, name: :timout_lower_than_interval, message: "Timout cannot exceed the interval timing")
  end
end