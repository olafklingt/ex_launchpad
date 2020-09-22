defmodule Launchpad.PushButton do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:onPushLED, integer, enforce: true)
    field(:onReleaseLED, integer, enforce: true)
    field(:onPushFunction, fun, enforce: true)
    field(:onReleaseFunction, fun, enforce: true)
    field(:value, any, default: 0)
  end

  @spec new(integer, integer, integer, fun, fun, integer) :: Launchpad.PushButton.t()
  def new(
        pad_ids,
        onPushLED,
        onReleaseLED,
        onPushFunction,
        # \\ &(&1 / 3),
        onReleaseFunction,
        value \\ 0
      ) do
    IO.inspect(%Launchpad.PushButton{
      value: value,
      pad_ids: pad_ids,
      onPushLED: onPushLED,
      onReleaseLED: onReleaseLED,
      onPushFunction: onPushFunction,
      onReleaseFunction: onReleaseFunction
    })
  end

  @spec responseOn(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, view, pad_id) do
    view = %{view | value: 1}
    r = view.onPushFunction.(launchpad, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.PushButton onPushFunction result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, view, pad_id) do
    view = %{view | value: 0}
    r = view.onReleaseFunction.(launchpad, view, pad_id)

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
