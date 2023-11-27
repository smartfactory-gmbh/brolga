defmodule Brolga.Alerting.Incident.Query do
  @moduledoc """
  Gather all query abstractions related to the Incident entity
  """

  import Ecto.Query
  alias Brolga.Alerting.Incident

  def base() do
    from i in Incident, as: :incidents
  end

  @doc """
  Order by latest incident (most recent first)
  """
  def order_by_latest(query \\ base()) do
    from query,
      order_by: [desc: :inserted_at]
  end

  @doc """
  Filter out closed incident
  """
  def filter_open(query \\ base()) do
    from query,
      where: is_nil(as(:incidents).ended_at)
  end

  @doc """
  Pluck a distinct list of monitor ids from the incident query
  """
  def to_monitor_ids(query \\ base()) do
    from query,
      distinct: :monitor_id,
      select: [:monitor_id]
  end
end
