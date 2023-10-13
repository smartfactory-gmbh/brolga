defmodule Brolga.UtilsTest do
  use Brolga.DataCase

  alias Brolga.Utils

  describe "format_datetime!/1" do
    test "formats with default formatting" do
      dt = ~U"2023-05-25T12:00:00Z"
      result = Utils.format_datetime!(dt)

      assert result == "12:00 25.05.2023"
    end

    test "takes timezone in account with default formatting" do
      old_timezone = Application.fetch_env!(:brolga, :utils)[:default_timezone]
      Application.put_env(:brolga, :utils, default_timezone: "Europe/Zurich")
      dt = ~U"2023-05-25T12:00:00Z"
      result = Utils.format_datetime!(dt)
      Application.put_env(:brolga, :utils, default_timezone: old_timezone)

      assert result == "14:00 25.05.2023"
    end
  end

  describe "float_to_percentage/1" do
    test "keeps only one decimal place" do
      result = Utils.float_to_percentage_format(0.3454)
      assert result == "34.5%"
    end

    test "accepts both floats and decimals" do
      result = Utils.float_to_percentage_format(0.3454)
      assert result == "34.5%"

      input = Decimal.new("0.3454")
      result = Utils.float_to_percentage_format(input)
      assert result == "34.5%"
    end

    test "floors when decimal part is below .5" do
      result = Utils.float_to_percentage_format(0.3432)
      assert result == "34.3%"
    end

    test "ceils when decimal part is above .5" do
      result = Utils.float_to_percentage_format(0.3438)
      assert result == "34.4%"
    end
  end
end
