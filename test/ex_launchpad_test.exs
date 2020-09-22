defmodule ExLaunchpadTest do
  use ExUnit.Case
  doctest ExLaunchpad

  test "greets the world" do
    assert ExLaunchpad.hello() == :world
  end
end
