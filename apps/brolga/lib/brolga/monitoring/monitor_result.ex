defmodule Brolga.Monitoring.MonitorResult do
  use Ecto.Schema
  import Ecto.Changeset

  alias Brolga.Monitoring.Monitor

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monitor_results" do
    field :reached, :boolean, default: false
    field :message, :string, default: ""
    belongs_to :monitor, Monitor

    timestamps()
  end

  @doc false
  def changeset(monitor_result, attrs) do
    monitor_result
    |> cast(attrs, [:reached, :monitor_id, :message])
    |> validate_required([:reached, :monitor_id])
  end
end
