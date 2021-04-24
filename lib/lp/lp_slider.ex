defmodule Launchpad.Slider do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:incrementArray, list, enforce: true)
    field(:background, integer, enforce: true)
    field(:action, fun, enforce: true)
    field(:onfront, fun, enforce: true)
    field(:onhide, fun, enforce: true)
    field(:value, integer | nil, default: nil)
    field(:default, integer, default: 0)
    field(:statevarroutine, pid | nil, default: nil)
  end

  @spec new(list, list, integer, fun, fun, integer | nil, integer) :: Launchpad.Slider.t()
  def new(
        pad_ids,
        incrementArray,
        background_color,
        action,
        init_value \\ nil,
        default_value \\ 0,
        options \\ []
      )
      when is_number(default_value) and (is_nil(init_value) or is_number(init_value)) do
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
      onfront: options[:onfront] || fn lp, _v -> lp end,
      onhide: options[:onhide] || fn lp, _v -> lp end,
      value: init_value,
      default: default_value,
      statevarroutine: nil
    }
  end

  @spec responseOn(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, button_id, view, _pad_id) do
    if !is_nil(view.statevarroutine) do
      IO.puts("statevarroutine should be nil")
      GenServer.call(view.statevarroutine, :return)
    end

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
          val = max(min(val + incr, 1), 0)
          view.action.(val)
          {val, incr}
        end,
        {value, incr},
        100
      )

    {%{view | value: value, statevarroutine: statevarroutine}, launchpad}
  end

  @spec on_front(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_front(launchpad, view) do
    r = view.onfront.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.Slider onfront result is not a Launchpad.State"
    end
  end

  @spec on_hide(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_hide(launchpad, view) do
    r = view.onhide.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.Slider onhide result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, _button_id, view, _pad_id) do
    {value, _incr} =
      if !is_nil(view.statevarroutine) do
        GenServer.call(view.statevarroutine, :return)
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
