defmodule Launchpad.Button do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:leds, list, enforce: true)
    field(:action, fun, enforce: true)
    field(:mode, atom, default: :forward)
    field(:value, integer, default: 0)
  end

  @spec new(list, list, fun, atom, integer) :: Launchpad.Button.t()
  def new(
        pad_ids,
        leds,
        action \\ &(&1 / 3),
        mode \\ :forward,
        value \\ 0
      ) do
    %Launchpad.Button{
      pad_ids: pad_ids,
      leds: leds,
      action: action,
      mode: mode,
      value: value
    }
  end

  @spec responseOn(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, view, pad_id) do
    value =
      case view.mode do
        :forward -> Integer.mod(view.value + 1, length(view.leds))
        :backward -> Integer.mod(view.value - 1, length(view.leds))
        :stuck -> Integer.mod(view.value, length(view.leds))
        :reset -> 0
        _ -> Integer.mod(view.value + 1, length(view.leds))
      end

    view = %{view | value: value}
    r = view.action.(launchpad, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.Button action result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, view, _pad_id) do
    {view, launchpad}
  end

  @spec getLEDs(Launchpad.State.t(), map) :: list
  def getLEDs(_launchpad, view) do
    vel = Enum.at(view.leds, view.value)
    Enum.map(view.pad_ids, fn pad_id -> {pad_id, vel} end)
  end
end
