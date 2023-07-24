defmodule Brolga.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Ecto.Query, warn: false
  alias Brolga.Repo

  alias Brolga.Monitoring.Monitor
  alias Brolga.Monitoring.MonitorResult

  @doc """
  Returns the list of monitors.

  ## Examples

      iex> list_monitors()
      [%Monitor{}, ...]

  """
  def list_monitors do
    monitor_query = from m in Monitor, as: :monitor,
      join: r in assoc(m, :monitor_results),
      inner_lateral_join: latest_results in subquery(
        from MonitorResult,
        where: [monitor_id: parent_as(:monitor).id],
        order_by: [desc: :inserted_at],
        limit: 25,
        select: [:id, :reached]
      ), on: latest_results.id == r.id,
      preload: [monitor_results: r]
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
  def get_monitor_with_results!(id) do
    results_query = from r in MonitorResult, order_by: [desc: r.inserted_at], limit: 25
    monitor_query = from m in Monitor, where: m.id == ^id, preload: [monitor_results: ^results_query]
    Repo.one!(monitor_query)
  end
  def get_active_monitor!(id), do: Repo.get_by!(Monitor, [id: id, active: true])

  @doc """
  Creates a monitor.

  ## Examples

      iex> create_monitor(%{field: value})
      {:ok, %Monitor{}}

      iex> create_monitor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor(attrs \\ %{}) do
    result = %Monitor{}
    |> Monitor.changeset(attrs)
    |> Repo.insert()

    case result do
      {:ok, monitor} ->
        # An new worker is started, matching this new monitor
        BrolgaWatcher.Worker.start(monitor.id)
      _ -> nil
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
    result = monitor
    |> Monitor.changeset(attrs)
    |> Repo.update()

    case result do
      {:ok, monitor} ->
        # Note: we start it *even* if active = false, because it will cleanup previous workers as well
        # if active is false, it will stop directly anyway
        BrolgaWatcher.Worker.start(monitor.id)
      _ -> nil
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
    BrolgaWatcher.Worker.stop(monitor.id)
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

  ## Examples

      iex> list_monitor_results()
      [%MonitorResult{}, ...]

  """
  def list_monitor_results do
    Repo.all(MonitorResult)
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

  @doc """
  Creates a monitor_result.

  ## Examples

      iex> create_monitor_result(%{field: value})
      {:ok, %MonitorResult{}}

      iex> create_monitor_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor_result(attrs \\ %{}) do
    %MonitorResult{}
    |> MonitorResult.changeset(attrs)
    |> Repo.insert()
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
end
