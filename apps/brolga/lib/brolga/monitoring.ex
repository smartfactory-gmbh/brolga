defmodule Brolga.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Brolga.CustomSql
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Brolga.Repo
  alias Brolga.Monitoring.{Monitor, MonitorResult, MonitorTag}
  alias Brolga.Alerting
  alias Brolga.Alerting.Incident

  @last_results_count 25
  # keeping a bit more than a month to be sure
  @retention_days 32

  defp get_config do
    Application.get_env(:brolga, :monitoring)
  end

  defp get_base_monitor_query() do
    config = get_config()
    lookback_start = Timex.now() |> Timex.shift(days: -config[:uptime_lookback_days])

    down_monitor_ids =
      from i in Incident,
        where: is_nil(i.ended_at),
        select: i.monitor_id

    uptime_query =
      from mr in MonitorResult,
        where: mr.inserted_at >= ^lookback_start,
        group_by: mr.monitor_id,
        select: %{monitor_id: mr.monitor_id, uptime: avg(case_when(mr.reached, 1, 0))}

    from m in Monitor,
      as: :monitor,
      left_join: up in subquery(uptime_query),
      on: up.monitor_id == m.id,
      order_by: m.name,
      # The select below populates the virtual field(s), since they are not persisted
      select_merge: %{
        is_down: case_when(m.id in subquery(down_monitor_ids), true, false),
        uptime: up.uptime |> coalesce(0)
      }
  end

  @doc """
  Returns the list of monitors.

  ## Examples

      iex> list_monitors()
      [%Monitor{}, ...]

  """
  def list_monitors do
    Repo.all(get_base_monitor_query())
  end

  def list_monitors_for_dashboard(dashboard_id) do
    query = get_base_monitor_query()

    direct_monitors =
      from m in Monitor,
        select: m.id,
        # check the dashboards through the direct relationship
        join: d in assoc(m, :dashboards),
        where: d.id == ^dashboard_id

    all_monitors =
      from m in Monitor,
        select: m.id,
        join: t in assoc(m, :monitor_tags),
        # check the dashboards through the tags relationship
        join: td in assoc(t, :dashboards),
        where: td.id == ^dashboard_id,
        union: ^direct_monitors

    monitors = Repo.all(from m in query, where: m.id in subquery(all_monitors))

    if monitors == [] do
      list_monitors()
    else
      monitors
    end
  end

  def list_monitors_with_latest_results(opts \\ []) do
    with_tags = opts |> Keyword.get(:with_tags, false)

    result_partition_query =
      from result in MonitorResult,
        order_by: [desc: :inserted_at],
        select: %{
          id: result.id,
          reached: result.reached,
          row_number: over(row_number(), :results_partition)
        },
        windows: [results_partition: [partition_by: :monitor_id, order_by: [desc: :inserted_at]]]

    results_query =
      from result in MonitorResult,
        join: r in subquery(result_partition_query),
        on: result.id == r.id and r.row_number <= @last_results_count

    monitor_query =
      from m in Monitor,
        as: :monitor,
        preload: [monitor_results: ^results_query],
        order_by: m.name

    monitor_query =
      if with_tags do
        monitor_query |> preload(:monitor_tags)
      else
        monitor_query
      end

    Repo.all(monitor_query)
  end

  def list_active_monitor_ids do
    Repo.all(from m in Monitor, select: m.id, where: m.active == true)
  end

  @doc """
  Gets a single monitor.

  Raises `Ecto.NoResultsError` if the Monitor does not exist.

  ## Examples

      iex> get_monitor!(123)
      %Monitor{}

      iex> get_monitor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor!(id), do: Repo.get!(Monitor, id)
  def get_monitors!(ids), do: Repo.all(from m in Monitor, where: m.id in ^ids)

  def get_monitor_with_details!(id) do
    config = get_config()
    lookback_start = Timex.now() |> Timex.shift(days: -config[:uptime_lookback_days])

    down_monitor_ids =
      from i in Incident,
        where: is_nil(i.ended_at),
        select: i.monitor_id

    uptime_query =
      from mr in MonitorResult,
        where: mr.inserted_at >= ^lookback_start,
        group_by: mr.monitor_id,
        select: %{monitor_id: mr.monitor_id, uptime: avg(case_when(mr.reached, 1, 0))}

    results_query = from r in MonitorResult, order_by: [desc: r.inserted_at], limit: 25
    incidents_query = from i in Incident, order_by: [desc: i.started_at], limit: 5

    monitor_query =
      from m in Monitor,
        where: m.id == ^id,
        preload: [
          :monitor_tags,
          incidents: ^incidents_query,
          monitor_results: ^results_query
        ],
        left_join: up in subquery(uptime_query),
        on: up.monitor_id == m.id,
        select_merge: %{
          is_down: case_when(m.id in subquery(down_monitor_ids), true, false),
          uptime: up.uptime
        }

    Repo.one!(monitor_query)
  end

  def get_active_monitor!(id), do: Repo.get_by!(Monitor, id: id, active: true)

  @doc """
  Creates a monitor.

  ## Examples

      iex> create_monitor(%{field: value})
      {:ok, %Monitor{}}

      iex> create_monitor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor(attrs \\ %{}) do
    tags =
      if attrs["monitor_tags"] do
        get_monitor_tags!(attrs["monitor_tags"])
      else
        []
      end

    result =
      %Monitor{}
      |> Monitor.changeset(attrs)
      |> put_assoc(:monitor_tags, tags)
      |> Repo.insert()

    case result do
      {:ok, monitor} ->
        # An new worker is started, matching this new monitor
        Brolga.Watcher.Worker.start(monitor.id)

      _ ->
        nil
    end

    result
  end

  @spec update_monitor(
          Brolga.Monitoring.Monitor.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  @doc """
  Updates a monitor.
  If "active" is set to "true", then a worker is fired up to ping the target

  ## Examples

      iex> update_monitor(monitor, %{field: new_value})
      {:ok, %Monitor{}}

      iex> update_monitor(monitor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor(%Monitor{} = monitor, attrs) do
    tags =
      if attrs["monitor_tags"] do
        get_monitor_tags!(attrs["monitor_tags"])
      else
        []
      end

    result =
      monitor
      |> Monitor.changeset(attrs)
      |> put_assoc(:monitor_tags, tags)
      |> Repo.update()

    case result do
      {:ok, monitor} ->
        # Note: we start it *even* if active = false, because it will cleanup previous workers as well
        # if active is false, it will stop directly anyway
        Brolga.Watcher.Worker.start(monitor.id)

      _ ->
        nil
    end

    result
  end

  @doc """
  Deletes a monitor.

  ## Examples

      iex> delete_monitor(monitor)
      {:ok, %Monitor{}}

      iex> delete_monitor(monitor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor(%Monitor{} = monitor) do
    Brolga.Watcher.Worker.stop(monitor.id)
    Repo.delete(monitor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor changes.

  ## Examples

      iex> change_monitor(monitor)
      %Ecto.Changeset{data: %Monitor{}}

  """
  def change_monitor(%Monitor{} = monitor, attrs \\ %{}) do
    Monitor.changeset(monitor, attrs)
  end

  alias Brolga.Monitoring.MonitorResult

  @doc """
  Returns the list of monitor_results.

  ## Options

  * `:with_monitors` - Preloads the related monitors
  * `:order` - Specifies the order to use

  ## Examples

      iex> list_monitor_results()
      [%MonitorResult{}, ...]

  """
  def list_monitor_results(options \\ []) do
    with_monitors = options |> Keyword.get(:with_monitors, false)
    query = from(m in MonitorResult)
    order = options |> Keyword.get(:order, nil)

    query =
      if with_monitors do
        query |> preload(:monitor)
      else
        query
      end

    query =
      if order do
        query |> order_by(^order)
      else
        query
      end

    Repo.all(query)
  end

  defp get_previous_monitor_results_query(options) do
    length = options |> Keyword.get(:length, 15)
    cutoff_date = options |> Keyword.get(:cutoff_date, nil)

    query = from(m in MonitorResult)

    query =
      if is_nil(cutoff_date) do
        query
      else
        query |> where([m], m.inserted_at <= ^cutoff_date)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(^length)
    |> preload(:monitor)
  end

  @doc """
  Returns the previous result related to the row number given in the param

  ## Options

  * `:length` - Specifies how many records should be returned
  * `:cutoff_date` - from which date it should count (should reuse the attribute used for order)

  ## Examples

      iex> get_previous_monitor_results(5, length: 10)
      [%MonitorResult{}, ...]

  """
  def get_previous_monitor_results(last_number, options \\ [])
  def get_previous_monitor_results(nil, options), do: get_previous_monitor_results(0, options)

  def get_previous_monitor_results(last_number, options) do
    query = get_previous_monitor_results_query(options)
    Repo.all(query |> offset(^last_number))
  end

  @doc """
  Returns the previous result related to the row number given in the param.
  Only fetches results for a specific monitor

  ## Options

  * `:length` - Specifies how many records should be returned
  * `:cutoff_date` - from which date it should count (should reuse the attribute used for order)

  ## Examples

      iex> get_previous_monitor_results_for("id", 5, length: 10)
      [%MonitorResult{}, ...]

  """
  def get_previous_monitor_results_for(monitor_id, last_number, options \\ [])

  def get_previous_monitor_results_for(monitor_id, nil, options),
    do: get_previous_monitor_results_for(monitor_id, 0, options)

  def get_previous_monitor_results_for(monitor_id, last_number, options) do
    query =
      get_previous_monitor_results_query(options)
      |> where(monitor_id: ^monitor_id)

    Repo.all(query |> offset(^last_number))
  end

  @doc """
  Deletes all the monitor results that are older than the retention threshold.
  This should be run regularly to avoid clutering the database with data that is not
  relevant anymore

  ## Examples

      iex> cleanup_monitor_results()
      {1, [%MonitorResult{}]}

      iex> cleanup_monitor_results()
      {0, nil}

  """
  @spec cleanup_monitor_results() ::
          {count :: non_neg_integer(), results :: [MonitorResult.t()] | nil}
  def cleanup_monitor_results do
    threshold = Timex.now() |> Timex.shift(days: -@retention_days)

    Repo.delete_all(
      from r in MonitorResult,
        where: r.inserted_at <= ^threshold
    )
  end

  @doc """
  Gets a single monitor_result.

  Raises `Ecto.NoResultsError` if the Monitor result does not exist.

  ## Examples

      iex> get_monitor_result!(123)
      %MonitorResult{}

      iex> get_monitor_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor_result!(id), do: Repo.get!(MonitorResult, id)

  defp get_closed_incident_pattern do
    config = get_config()
    (0..(config[:attempts_before_notification] - 1) |> Enum.map(fn _i -> true end)) ++ [false]
  end

  @doc """
  Creates a monitor_result.

  ## Examples

      iex> create_monitor_result(%{field: value})
      {:ok, %MonitorResult{}}

      iex> create_monitor_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor_result(attrs \\ %{}) do
    config = get_config()

    result =
      %MonitorResult{}
      |> MonitorResult.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, monitor_result} ->
        monitor = get_monitor_with_details!(monitor_result.monitor_id)

        last_results =
          monitor.monitor_results
          |> Enum.slice(0..config[:attempts_before_notification])
          |> Enum.map(fn monitor_result -> monitor_result.reached end)

        closed_incident = get_closed_incident_pattern()
        open_incident = closed_incident |> Enum.map(fn value -> not value end)

        case last_results do
          ^closed_incident ->
            # If reached correctly twice, we close the incident
            Alerting.close_incident(monitor)

          ^open_incident ->
            # If reached incorrectly twice, we open an incident
            Alerting.open_incident(monitor)

          _ ->
            nil
        end

      _ ->
        nil
    end

    result
  end

  @doc """
  Updates a monitor_result.

  ## Examples

      iex> update_monitor_result(monitor_result, %{field: new_value})
      {:ok, %MonitorResult{}}

      iex> update_monitor_result(monitor_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor_result(%MonitorResult{} = monitor_result, attrs) do
    monitor_result
    |> MonitorResult.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monitor_result.

  ## Examples

      iex> delete_monitor_result(monitor_result)
      {:ok, %MonitorResult{}}

      iex> delete_monitor_result(monitor_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor_result(%MonitorResult{} = monitor_result) do
    Repo.delete(monitor_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor_result changes.

  ## Examples

      iex> change_monitor_result(monitor_result)
      %Ecto.Changeset{data: %MonitorResult{}}

  """
  def change_monitor_result(%MonitorResult{} = monitor_result, attrs \\ %{}) do
    MonitorResult.changeset(monitor_result, attrs)
  end

  alias Brolga.Monitoring.MonitorTag

  @doc """
  Returns the list of monitor_tags.

  ## Examples

      iex> list_monitor_tags()
      [%MonitorTag{}, ...]

  """
  def list_monitor_tags do
    Repo.all(MonitorTag)
  end

  @doc """
  Gets a single monitor_tag.

  Raises `Ecto.NoResultsError` if the Monitor tag does not exist.

  ## Examples

      iex> get_monitor_tag!(123)
      %MonitorTag{}

      iex> get_monitor_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor_tag!(id), do: Repo.get!(MonitorTag, id)

  def get_monitor_tags!(ids), do: Repo.all(from t in MonitorTag, where: t.id in ^ids)

  @doc """
  Creates a monitor_tag.

  ## Examples

      iex> create_monitor_tag(%{field: value})
      {:ok, %MonitorTag{}}

      iex> create_monitor_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor_tag(attrs \\ %{}) do
    %MonitorTag{}
    |> MonitorTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a monitor_tag.

  ## Examples

      iex> update_monitor_tag(monitor_tag, %{field: new_value})
      {:ok, %MonitorTag{}}

      iex> update_monitor_tag(monitor_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor_tag(%MonitorTag{} = monitor_tag, attrs) do
    monitor_tag
    |> MonitorTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monitor_tag.

  ## Examples

      iex> delete_monitor_tag(monitor_tag)
      {:ok, %MonitorTag{}}

      iex> delete_monitor_tag(monitor_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor_tag(%MonitorTag{} = monitor_tag) do
    Repo.delete(monitor_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor_tag changes.

  ## Examples

      iex> change_monitor_tag(monitor_tag)
      %Ecto.Changeset{data: %MonitorTag{}}

  """
  def change_monitor_tag(%MonitorTag{} = monitor_tag, attrs \\ %{}) do
    MonitorTag.changeset(monitor_tag, attrs)
  end
end
