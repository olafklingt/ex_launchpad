defmodule Launchpad.Slider do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:incrementArray, list, enforce: true)
    field(:background, integer, enforce: true)
    field(:action, fun, enforce: true)
    field(:value, integer | nil, default: nil)
    field(:default, integer, default: 0)
    field(:statevarroutine, pid | nil, default: nil)
  end

  def new(
        pad_ids,
        incrementArray,
        background_color,
        action,
        init_value \\ nil,
        default_value \\ 0
      ) do
    if length(pad_ids) != length(incrementArray) do
      raise "Launchpad.Slider can not be initalized with different number of pads and increments. pad_ids size: #{
              length(pad_ids)
            } incrementArray size: #{length(incrementArray)}"
    end

    %Launchpad.Slider{
      pad_ids: pad_ids,
      incrementArray: incrementArray,
      background: background_color,
      action: action,
      value: init_value,
      default: default_value,
      statevarroutine: nil
    }
  end

  @spec responseOn(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, view, pad_id) do
    IO.inspect(view)

    if !is_nil(view.statevarroutine) do
      IO.puts("statevarroutine should be nil")
      GenServer.call(view.statevarroutine, :return)
    end

    button_id = Enum.find_index(view.pad_ids, fn x -> x == pad_id end)
    incr = Enum.at(view.incrementArray, button_id)

    value =
      if(is_nil(incr)) do
        view.default
      else
        view.value || view.default
      end

    incr = incr || 0

    {:ok, statevarroutine} =
      Launchpad.RepeatingRoutine.start_link(
        fn {val, incr} ->
          val = IO.inspect(max(min(val + incr, 1), 0))
          view.action.(val)
          {val, incr}
        end,
        {value, incr},
        100
      )

    {%{view | value: value, statevarroutine: statevarroutine}, launchpad}
  end

  @spec responseOff(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, view, _pad_id) do
    {value, _incr} =
      if !is_nil(view.statevarroutine) do
        IO.inspect(GenServer.call(view.statevarroutine, :return))
      end

    {%{view | value: value, statevarroutine: nil}, launchpad}
  end

  @spec getLEDs(Launchpad.State.t(), map) :: list
  def getLEDs(_launchpad, view) do
    num = length(view.pad_ids)
    val = view.value || view.default
    on_f = num * val
    on = trunc(on_f)
    frac = Integer.mod(trunc(on_f * 2), 2) + 1

    Enum.map(
      0..(num - 1),
      fn i ->
        if(on < i) do
          {Enum.at(view.pad_ids, i), view.background}
        else
          if(on == i) do
            {Enum.at(view.pad_ids, i), Launchpad.LED.red(frac)}
          else
            {Enum.at(view.pad_ids, i), Launchpad.LED.red()}
          end
        end
      end
    )
  end
end
