# brainstorm about better launchpad
# state: leds[] funcs[]
# the problem is that in that case everything i solved allready is than now part of the func that is assigned to a button
# the launchpad pushbutton would in that case not have a struct but simply one function that would assign the release function to the funcs for the release message ...
# but whats the benefit of this?
# the question is much more how could one deal better with context

lp = Launchpad.setup("Launchpad MIDI 1", "Launchpad MIDI 1")

c =
  Launchpad.PushButton.new(
    Launchpad.pads(1..2, 1..2),
    Launchpad.LED.orange(),
    Launchpad.LED.yellow(),
    # onPushFunction
    fn launchpad, _view, id ->
      IO.puts("push c")
      IO.inspect(id)
      # IO.inspect(view)
      launchpad
    end,
    # onReleaseFunction
    fn launchpad, _view, id ->
      IO.puts("release c")
      IO.inspect(id)
      # _launchpad = Launchpad.State.remove_view(launchpad, :extrabutton)
      launchpad
    end
  )

d =
  Launchpad.PushButton.new(
    Launchpad.pads(2..3, 1..2),
    Launchpad.LED.red(),
    Launchpad.LED.green(),
    # onPushFunction
    fn launchpad, _view, id ->
      IO.puts("push d: #{inspect(id)}")
      launchpad
    end,
    # onReleaseFunction
    fn launchpad, _view, id ->
      IO.puts("release d: #{inspect(id)}")
      launchpad
    end
  )

e =
  Launchpad.Button.new(
    Launchpad.pads(7..8, 1),
    [
      Launchpad.LED.green(),
      Launchpad.LED.yellow(),
      Launchpad.LED.orange(),
      Launchpad.LED.red()
    ],
    fn launchpad, view, id ->
      IO.puts("push d")
      IO.inspect(id)
      IO.inspect(view.value)
      launchpad
    end
  )

b =
  Launchpad.PushButton.new(
    Launchpad.pad(0, 0),
    Launchpad.LED.red(),
    Launchpad.LED.green(),
    fn launchpad, _view, id ->
      IO.puts("push b: #{inspect(id)}")
      _launchpad = Launchpad.State.add_view(launchpad, c, {:extrabutton, 2})
    end,
    fn launchpad, _view, id ->
      IO.puts("release b: #{inspect(id)}")
      _launchpad = Launchpad.State.remove_view(launchpad, {:extrabutton, 2})
    end
  )

f =
  Launchpad.ButtonArray.new(
    Launchpad.pads(0..3, 3),
    [Launchpad.LED.red(1), Launchpad.LED.red(2), Launchpad.LED.red(3), Launchpad.LED.red(2)],
    [
      Launchpad.LED.green(1),
      Launchpad.LED.green(2),
      Launchpad.LED.green(3),
      Launchpad.LED.green(3)
    ],
    fn lp, v, _id ->
      IO.puts("value is: #{v.value}")
      lp
    end
  )

g =
  Launchpad.Slider.new(
    Launchpad.pads(0..6, 4),
    [-1 / 80, -1 / 160, -1 / 400, nil, 1 / 400, 1 / 160, 1 / 80],
    Launchpad.LED.green(1),
    fn val -> IO.inspect({:from_r, val}) end,
    0.66,
    0.5
  )

Launchpad.add_view(b)
Launchpad.add_view(d)
Launchpad.add_view(e)
Launchpad.add_view(f)
# just as a reminder of add_view/3
Launchpad.add_view(g, :g)
