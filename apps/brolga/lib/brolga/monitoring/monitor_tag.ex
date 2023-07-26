defmodule Brolga.Monitoring.MonitorTag do
  @moduledoc """
  Represents a tag that can be attached to multiple monitors.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Brolga.Monitoring.Monitor

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monitor_tags" do
    field :name, :string
    many_to_many :monitors, Monitor, join_through: "monitors_tags"

    timestamps()
  end

  @doc false
  def changeset(monitor_tag, attrs) do
    monitor_tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
