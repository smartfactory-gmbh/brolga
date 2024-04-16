defmodule Brolga.Monitoring.Monitor.Query do
  @moduledoc """
  Gather all query abstractions related to the Monitor entity
  """

  import Ecto.Query
  import Brolga.CustomSql
  alias Brolga.Monitoring.{Monitor, MonitorResult}
  alias Brolga.Alerting.Incident.Query, as: IncidentQuery

  def base() do
    from m in Monitor, as: :monitors
  end

  @doc """
  Preload the monitor tags
  """
  def with_monitor_tags(query \\ base()) do
    from query,
      preload: [:monitor_tags]
  end

  @doc """
  Preload the `incidents` relation with the `nb` latest incidents
  """
  def with_latest_incidents(query \\ base(), nb) do
    incidents_query =
      IncidentQuery.base()
      |> IncidentQuery.order_by_latest()
      |> limit(^nb)

    from query,
      preload: [incidents: ^incidents_query]
  end

  @doc """
  Add the uptime value to the monitor records
  """
  def with_uptime(query \\ base(), lookback_days) do
    lookback_start = Timex.now() |> Timex.shift(days: -lookback_days)

    uptime_query =
      from mr in MonitorResult,
        as: :results,
        where: mr.inserted_at >= ^lookback_start,
        group_by: mr.monitor_id,
        select: %{monitor_id: mr.monitor_id, uptime: avg(case_when(mr.reached, 1, 0))}

    from query,
      left_join: up in subquery(uptime_query),
      as: :uptime,
      on: up.monitor_id == as(:monitors).id,
      select_merge: %{
        uptime: up.uptime |> coalesce(0)
      }
  end

  @doc """
  Add a `is_down` property that tells for each monitor if it's down
  based on the related Incident models
  """
  def with_down_state(query \\ base()) do
    down_monitor_ids =
      IncidentQuery.base()
      |> IncidentQuery.filter_open()
      |> IncidentQuery.to_monitor_ids()

    from query,
      select_merge: %{
        is_down: case_when(as(:monitors).id in subquery(down_monitor_ids), true, false)
      }
  end

  def where_dashboard(query \\ base(), dashboard_id) do
    # Possibly at some point: use this as a subquery to avoid
    # polluting with joins as side effects
    from m in query,
      left_join: tag in assoc(m, :monitor_tags),
      left_join: tag_dashboard in assoc(tag, :dashboards),
      left_join: m_dashboard in assoc(m, :dashboards),
      where: tag_dashboard.id == ^dashboard_id,
      or_where: m_dashboard.id == ^dashboard_id
  end

  def filter_active(query \\ base(), active?) do
    from query,
      where: as(:monitors).active == ^active?
  end

  @doc """
  Converts the query to only return the ids of the monitors
  """
  def to_ids(query \\ base()) do
    from query,
      select: as(:monitors).id
  end

  @doc """
  Order the monitors alphabetically
  """
  def order_by_name(query \\ base()) do
    from query,
      order_by: as(:monitors).name
  end

  def search(query \\ base(), search) do
    from query,
      where: ilike(as(:monitors).name, ^"%#{search}%")
  end
end
