defmodule Brolga.Monitoring.MonitorResult.Query do
  @moduledoc """
  Gather all query abstractions related to the MonitorResult entity
  """

  import Ecto.Query
  alias Brolga.Monitoring.MonitorResult

  def base() do
    from r in MonitorResult, as: :monitor_results
  end

  defp with_numbered_rows_per_monitor(query) do
    from query,
      select: %{
        id: as(:monitor_results).id,
        reached: as(:monitor_results).reached,
        row_number: over(row_number(), :results_partition)
      },
      windows: [results_partition: [partition_by: :monitor_id, order_by: [desc: :inserted_at]]]
  end

  @doc """
  Preload the `monitor` relationship
  """
  def with_monitors(query \\ base()) do
    from query,
      preload: [:monitor]
  end

  @doc """
  Filter out all result that are more recent than the cutoff date
  """
  def before_cutoff_date(query \\ base(), cutoff_date) do
    if is_nil(cutoff_date) do
      query
    else
      from query,
        where: as(:monitor_results).inserted_at <= ^cutoff_date
    end
  end

  @doc """
  Order by latest result (most recent first)
  """
  def order_by_latest(query \\ base()) do
    from query,
      order_by: [desc: :inserted_at]
  end

  @doc """
  Partition per monitor, row numbered for ordering by latest
  """
  def latest_per_monitor(query \\ base()) do
    query
    |> with_numbered_rows_per_monitor()
    |> order_by_latest()
  end

  def for_monitor(query \\ base(), monitor_id) do
    from query,
      where: as(:monitor_results).monitor_id == ^monitor_id
  end
end
