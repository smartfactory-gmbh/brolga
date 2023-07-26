defmodule Brolga.Utils do
  @moduledoc """
  Contains all utility functions from this project
  """

  use Timex

  @time_format "{h24}:{m}"
  @date_format "{D}.{M}.{YYYY}"
  @datetime_format "#{@time_format} #{@date_format}"

  @spec format_datetime!(DateTime.t()) :: String.t()
  def format_datetime!(datetime) do
    Timex.format!(datetime, @datetime_format)
  end
end
