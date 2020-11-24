defmodule Launchpad.PushButton do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:onPushLED, integer, enforce: true)
    field(:onReleaseLED, integer, enforce: true)
    field(:onPushFunction, fun, enforce: true)
    field(:onReleaseFunction, fun, enforce: true)
    field(:onfront, fun, enforce: true)
    field(:onhide, fun, enforce: true)
    field(:value, any, default: 0)
  end

  @spec new(integer, integer, integer, fun, fun, fun, integer) :: Launchpad.PushButton.t()
  def new(
        pad_ids,
        onPushLED,
        onReleaseLED,
        onPushFunction,
        # \\ &(&1 / 3),
        onReleaseFunction,
        value \\ 0,
        options \\ []
      )
      when is_number(value) do
    %Launchpad.PushButton{
      value: value,
      pad_ids: pad_ids,
      onPushLED: onPushLED,
      onReleaseLED: onReleaseLED,
      onPushFunction: onPushFunction,
      onReleaseFunction: onReleaseFunction,
      onfront: options[:onfront] || fn lp, _v -> lp end,
      onhide: options[:onhide] || fn lp, _v -> lp end
    }
  end

  @spec responseOn(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, button_id, view, pad_id) do
    view = %{view | value: 1}
    r = view.onPushFunction.(launchpad, button_id, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.PushButton onPushFunction result is not a Launchpad.State"
    end
  end

  @spec on_front(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_front(launchpad, view) do
    r = view.onfront.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.PushButton onfront result is not a Launchpad.State"
    end
  end

  @spec on_hide(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_hide(launchpad, view) do
    # IO.inspect({:pboh, view.onhide})
    r = view.onhide.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.PushButton onhide result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, button_id, view, pad_id) when is_map(view) do
    view = %{view | value: 0}
    r = view.onReleaseFunction.(launchpad, button_id, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.PushButton onReleaseFunction result is not a Launchpad.State"
    end
  end

  @spec getLEDs(Launchpad.State.t(), map) :: list
  def getLEDs(_launchpad, view) do
    vel =
      if(view.value > 0) do
        view.onPushLED
      else
        view.onReleaseLED
      end

    Enum.map(view.pad_ids, fn pad_id -> {pad_id, vel} end)
  end
end
