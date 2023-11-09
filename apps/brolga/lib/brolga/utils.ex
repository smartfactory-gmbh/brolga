defmodule Brolga.Utils do
  @moduledoc """
  Contains all utility functions from this project
  """

  use Timex

  @time_format "{h24}:{m}"
  @date_format "{0D}.{0M}.{YYYY}"
  @datetime_format "#{@time_format} #{@date_format}"

  defp get_config do
    Application.get_env(:brolga, :utils)
  end

  @spec localize_datetime!(DateTime.t()) :: DateTime.t()
  def localize_datetime!(datetime) do
    config = get_config()
    default_tz = config[:default_timezone]
    datetime |> Timex.to_datetime("Etc/UTC") |> Timex.Timezone.convert(default_tz)
  end

  @spec format_datetime!(DateTime.t()) :: String.t()
  def format_datetime!(datetime) do
    datetime |> localize_datetime! |> Timex.format!(@datetime_format)
  end

  @spec float_to_percentage_format(float()) :: String.t()
  @spec float_to_percentage_format(Decimal.t()) :: String.t()
  def float_to_percentage_format(%Decimal{} = number),
    do: float_to_percentage_format(Decimal.to_float(number))

  def float_to_percentage_format(number) do
    rounded = Float.round(number * 100, 1)
    "#{rounded}%"
  end
end
