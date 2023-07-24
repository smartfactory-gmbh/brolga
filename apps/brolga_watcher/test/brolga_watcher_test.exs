defmodule BrolgaWatcherTest do
  use ExUnit.Case
  doctest BrolgaWatcher

  test "greets the world" do
    assert BrolgaWatcher.hello() == :world
  end
end
