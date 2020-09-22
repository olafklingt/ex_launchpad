defmodule Launchpad.ButtonArray do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:on_leds, list, enforce: true)
    field(:off_leds, list, enforce: true)
    field(:action, fun, enforce: true)
    field(:value, integer, default: 0)
  end

  @spec new(list, list, list, fun, integer) :: Launchpad.ButtonArray.t()
  def new(
        pad_ids,
        on_leds,
        off_leds,
        action \\ &(&1 / 3),
        value \\ 0
      ) do
    if(length(pad_ids) == length(on_leds) && length(pad_ids) == length(off_leds)) do
      %Launchpad.ButtonArray{
        pad_ids: pad_ids,
        on_leds: on_leds,
        off_leds: off_leds,
        action: action,
        value: value
      }
    else
      raise "number of leds and pads is not the same but should be: pad_ids: #{length(pad_ids)} on_leds: #{
              length(on_leds)
            } off_leds: #{length(off_leds)}"
    end
  end

  @spec responseOn(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, view, pad_id) do
    # value = Enum.find_index(view.pad_ids, fn x -> x == pad_id end)
    value = Enum.find_index(view.pad_ids, &(&1 == pad_id))
    view = %{view | value: value}
    r = view.action.(launchpad, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.ButtonArray action result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, view, _pad_id) do
    {view, launchpad}
  end

  @spec getLEDs(Launchpad.State.t(), map) :: list
  def getLEDs(_launchpad, view) do
    on_pad_id = Enum.at(view.pad_ids, view.value)

    view.pad_ids
    |> Enum.with_index()
    |> Enum.map(fn {pad_id, index} ->
      if(pad_id == on_pad_id) do
        {pad_id, Enum.at(view.on_leds, index)}
      else
        {pad_id, Enum.at(view.off_leds, index)}
      end
    end)
  end
end
