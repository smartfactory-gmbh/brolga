defmodule Brolga.Monitoring.MonitorResult do
  @moduledoc """
  Represent the result that can be reported after a ping
  on a monitor, performed by a worker.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Brolga.Monitoring.Monitor

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @attr_casts [:reached, :monitor_id, :message, :status_code]
  @test_attr_casts [:inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          monitor: Monitor.t(),
          updated_at: DateTime.t(),
          inserted_at: DateTime.t(),
          reached: boolean(),
          message: String.t()
        }

  schema "monitor_results" do
    field :reached, :boolean, default: false
    field :message, :string, default: ""
    field :status_code, :integer, default: nil
    belongs_to :monitor, Monitor

    timestamps()
  end

  defp public_changeset(monitor_result, attrs) do
    monitor_result
    |> cast(attrs, @attr_casts)
  end

  defp test_changeset(monitor_result, attrs) do
    monitor_result
    |> cast(attrs, Enum.concat(@attr_casts, @test_attr_casts))
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:reached, :monitor_id])
  end

  @doc """
  Returns a changeset with validated data
  In test mode, allows to also setup the inserted_at and updated_at, useful for some test cases
  """
  def changeset(monitor_result, attrs, force_public \\ false) do
    config = Application.get_env(:brolga, :monitoring)

    if config[:test_mode] and not force_public do
      test_changeset(monitor_result, attrs)
    else
      public_changeset(monitor_result, attrs)
    end
    |> validate()
  end
end
