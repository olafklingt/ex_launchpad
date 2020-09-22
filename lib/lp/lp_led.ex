defmodule Launchpad.LED do
  # use TypedStruct

  # typedstruct do
  #   field(:green, integer, enforce: false)
  #   field(:red, integer, enforce: false)
  #   field(:clear, integer, enforce: false)
  #   field(:copy, integer, enforce: false)
  # end

  def new(green \\ 0, red \\ 0, clear \\ 1, copy \\ 1) do
    {green, red, clear, copy}
  end

  def black() do
    vel(Launchpad.LED.new())
  end

  def green(s \\ 3) do
    s = min(s, 3)
    vel(Launchpad.LED.new(s))
  end

  def red(s \\ 3) do
    s = min(s, 3)
    vel(Launchpad.LED.new(0, s))
  end

  def amber(s \\ 3) do
    s = min(s, 3)
    vel(Launchpad.LED.new(s, s))
  end

  def yellow(s \\ 2) do
    s = min(s, 2)
    vel(Launchpad.LED.new(s + 1, s))
  end

  def orange(s \\ 2) do
    s = min(s, 2)
    vel(Launchpad.LED.new(s, s + 1))
  end

  def vel(green, red, clear \\ 1, copy \\ 1) do
    vel({green, red, clear, copy})
  end

  def vel({green, red, clear, copy}) do
    g = :math.pow(2, 4) * green
    c = :math.pow(2, 3) * clear
    l = :math.pow(2, 2) * copy
    r = red

    trunc(g + c + l + r)
  end
end
