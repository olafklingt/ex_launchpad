defmodule Launchpad.ButtonArray do
  use TypedStruct

  typedstruct do
    field(:pad_ids, list, enforce: true)
    field(:on_leds, list, enforce: true)
    field(:off_leds, list, enforce: true)
    field(:action, fun, enforce: true)
    field(:onfront, fun, enforce: true)
    field(:onhide, fun, enforce: true)
    field(:value, integer, default: 0)
  end

  @spec new(list, list, list, fun, fun, integer) :: Launchpad.ButtonArray.t()
  def new(
        pad_ids,
        on_leds,
        off_leds,
        action,
        value \\ 0,
        options \\ []
      )
      when is_number(value) do
    if(length(pad_ids) == length(on_leds) && length(pad_ids) == length(off_leds)) do
      %Launchpad.ButtonArray{
        pad_ids: pad_ids,
        on_leds: on_leds,
        off_leds: off_leds,
        action: action,
        onfront: options[:onfront] || fn lp, _v -> lp end,
        onhide: options[:onhide] || fn lp, _v -> lp end,
        value: value
      }
    else
      raise "number of leds and pads is not the same but should be: pad_ids: #{length(pad_ids)} on_leds: #{
              length(on_leds)
            } off_leds: #{length(off_leds)}"
    end
  end

  @spec responseOn(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOn(launchpad, button_id, view, pad_id) do
    value = Enum.find_index(view.pad_ids, &(&1 == pad_id))
    view = %{view | value: value}
    r = view.action.(launchpad, button_id, view, pad_id)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.ButtonArray action result is not a Launchpad.State"
    end
  end

  @spec on_front(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_front(launchpad, view) do
    r = view.onfront.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.ButtonArray onfront action result is not a Launchpad.State"
    end
  end

  @spec on_hide(Launchpad.State.t(), map) :: {map, Launchpad.State.t()}
  def on_hide(launchpad, view) do
    r = view.onhide.(launchpad, view)

    if(is_map(r) && r.__struct__ == Launchpad.State) do
      {view, r}
    else
      raise "Launchpad.ButtonArray onhide action result is not a Launchpad.State"
    end
  end

  @spec responseOff(Launchpad.State.t(), integer, map, integer) :: {map, Launchpad.State.t()}
  def responseOff(launchpad, _button_id, view, _pad_id) do
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
