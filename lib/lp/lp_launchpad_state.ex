defmodule Launchpad.State do
  use TypedStruct
  use Bitwise

  @type view_id :: atom | tuple
  @type pad_id :: integer
  @type on_pad :: list[view_id]
  @type velocity :: integer

  typedstruct do
    field(:views, keyword[{view_id, map}], enforce: true)
    field(:midiin_pid, pid, enforce: true)
    field(:midiout_pid, pid, enforce: true)
    field(:last_generated_view_id, integer, default: 0)

    field(:on_pads, list[on_pad], enforce: true)
    field(:off_pads, list[{view_id, map}], enforce: true)
    field(:out_pads, list[velocity], enforce: true)
  end

  @spec reset(Launchpad.State.t()) :: Launchpad.State.t()
  def reset(launchpad) do
    PortMidi.write(launchpad.midiout_pid, {0, 0, 0})
    # launchpad.midiout_pid(0, 0, 0)
    Enum.map(0..(9 * 9), fn id ->
      setLED(launchpad.midiout_pid, id, Launchpad.LED.black())
    end)

    launchpad
  end

  @spec init(pid, pid) :: Launchpad.State.t()
  def init(midiin_pid, midiout_pid) do
    launchpad = %Launchpad.State{
      views: [],
      midiin_pid: midiin_pid,
      midiout_pid: midiout_pid,
      on_pads: Enum.map(0..(9 * 9), fn _pad_id -> [] end),
      off_pads: Enum.map(0..(9 * 9), fn _id -> nil end),
      out_pads: Enum.map(0..(9 * 9), fn _id -> 0 end)
    }

    reset(launchpad)
    launchpad
  end

  @spec hide_view(Launchpad.State.t(), view_id) :: Launchpad.State.t()
  def hide_view(launchpad, view_id) do
    view_tuple = List.keyfind(launchpad.views, view_id, 0)

    if(is_nil(view_tuple)) do
      {nil, launchpad}
    else
      {view_id, view} = view_tuple
      on_pads = remove_view_id_from_pads(launchpad.on_pads, view_id, view.pad_ids)
      launchpad = %{launchpad | on_pads: on_pads}
      {view, launchpad} = apply(view.__struct__, :on_hide, [launchpad, view])
      _launchpad = update_pad_leds_after_remove(launchpad, view.pad_ids)
    end
  end

  @spec remove_all_views_startinging_with(Launchpad.State.t(), list) :: Launchpad.State.t()
  def remove_all_views_startinging_with(launchpad, view_id_list) do
    list =
      Enum.filter(launchpad.views, fn {id, _v} ->
        if is_atom(id) do
          false
        else
          List.starts_with?(Tuple.to_list(id), view_id_list)
        end
      end)

    launchpad =
      Enum.reduce(list, launchpad, fn {id, _v}, launchpad ->
        # IO.inspect({:remove_view_from_views, id})
        remove_view(launchpad, id)
      end)

    list =
      launchpad.off_pads
      |> Enum.filter(& &1)
      |> Enum.filter(fn {id, _v} ->
        if is_atom(id) do
          false
        else
          List.starts_with?(Tuple.to_list(id), view_id_list)
        end
      end)

    # Enum.filter(launchpad.off_pads, fn pad ->
    #   if(is_nil(pad)) do
    #     false
    #   else
    #     {id, _v} = pad
    #
    #     if is_atom(id) do
    #       false
    #     else
    #       List.starts_with?(Tuple.to_list(id), view_id_list)
    #     end
    #   end
    # end)

    launchpad =
      Enum.reduce(list, launchpad, fn {id, _v}, launchpad ->
        # IO.inspect({:remove_view_from_off_pads, id})
        remove_view(launchpad, id)
      end)

    launchpad
  end

  @spec hide_all_views_startinging_with(Launchpad.State.t(), list) :: Launchpad.State.t()
  def hide_all_views_startinging_with(launchpad, view_id_list) do
    list =
      Enum.filter(launchpad.views, fn {id, _v} ->
        if is_atom(id) do
          false
        else
          List.starts_with?(Tuple.to_list(id), view_id_list)
        end
      end)

    # IO.inspect(Keyword.keys(list))

    Enum.reduce(list, launchpad, fn {id, _v}, launchpad ->
      hide_view(launchpad, id)
    end)
  end

  @spec remove_view(Launchpad.State.t(), view_id) :: Launchpad.State.t()
  def remove_view(launchpad, view_id) do
    {view, launchpad} = pop_view_from_views(launchpad, view_id)
    view_from_off_pads_tuple = List.keyfind(launchpad.off_pads, view_id, 0)

    if(is_nil(view)) do
      if(is_nil(view_from_off_pads_tuple)) do
        IO.puts(
          "this case shouldn't happen i think no view found for key: #{inspect(view_id)} in off_pads and views ... but it happens if a view is removed more than once"
        )

        launchpad
      else
        {view_id, view_from_off_pads} = view_from_off_pads_tuple
        view = view_from_off_pads
        on_pads = remove_view_id_from_pads(launchpad.on_pads, view_id, view.pad_ids)
        launchpad = %{launchpad | on_pads: on_pads}
        {_view, launchpad} = apply(view.__struct__, :on_hide, [launchpad, view])
        launchpad
      end
    else
      on_pads = remove_view_id_from_pads(launchpad.on_pads, view_id, view.pad_ids)
      launchpad = %{launchpad | on_pads: on_pads}

      {view, launchpad} = apply(view.__struct__, :on_hide, [launchpad, view])

      if(is_nil(view_from_off_pads_tuple)) do
        # IO.inspect({:view, view})
        launchpad = update_pad_leds_after_remove(launchpad, view.pad_ids)
        # IO.inspect({:at40, Enum.at(launchpad.on_pads, 40)})
        launchpad
      else
        IO.puts(
          "this should not happen view found for key: #{inspect(view_id)} in off_pads and on_pads"
        )

        launchpad
      end
    end
  end

  @spec add_view_and_front(Launchpad.State.t(), map) :: {view_id, Launchpad.State.t()}
  def add_view_and_front(launchpad, view) do
    {view_id, launchpad} = gen_view_id(launchpad)
    launchpad = add_view(launchpad, view, view_id)
    launchpad = set_view_to_front(launchpad, view_id)
    {view_id, launchpad}
  end

  # @spec add_view_to_front(Launchpad.State.t(), map, view_id) :: Launchpad.State.t()
  # def add_view_to_front(launchpad, view, view_id) do
  #   view_tuple = List.keyfind(launchpad.views, view_id, 0)
  #
  #   # if Keyword.has_key?(launchpad.views, view_id) do
  #   if is_nil(view_tuple) do
  #     IO.puts("view_id key is not found in Launchpad state: #{inspect(view_id)} ")
  #     launchpad
  #   else
  #     launchpad
  #   end
  # end

  @spec set_view_to_front(Launchpad.State.t(), view_id) :: Launchpad.State.t()
  def set_view_to_front(launchpad, view_id) do
    view_tuple = List.keyfind(launchpad.views, view_id, 0)

    # if Keyword.has_key?(launchpad.views, view_id) do
    if is_nil(view_tuple) do
      IO.puts("view_id key is not found in Launchpad state: #{inspect(view_id)} ")
      launchpad
    else
      {view_id, view} = view_tuple

      launchpad = %{
        launchpad
        | on_pads: add_view_id_to_pads(launchpad.on_pads, view.pad_ids, view_id)
      }

      {view, launchpad} = apply(view.__struct__, :on_front, [launchpad, view])

      _launchpad = update_leds(launchpad, view_id, view)
    end
  end

  @spec add_view(Launchpad.State.t(), map, view_id) :: Launchpad.State.t()
  def add_view(launchpad, view, view_id) do
    # if Keyword.has_key?(launchpad.views, view_id) do
    if List.keymember?(launchpad.views, view_id, 0) do
      IO.puts("view_id key is duplicate choose another one: #{inspect(view_id)} ")
      launchpad
    else
      # IO.inspect({:add_view, view_id})
      views = [{view_id, view} | launchpad.views]
      # IO.inspect({:add_view_views, views})
      %{launchpad | views: views}
    end
  end

  @spec process_msg(Launchpad.State.t(), map) :: Launchpad.State.t()
  def process_msg(launchpad, msg) do
    pad_id = as_id(msg)

    if(is_on?(msg)) do
      process_on_msg(launchpad, pad_id)
    else
      process_off_msg(launchpad, pad_id)
    end
  end

  @spec gen_view_id(Launchpad.State.t()) :: {atom, Launchpad.State.t()}
  defp gen_view_id(launchpad) do
    int_id = launchpad.last_generated_view_id + 1
    id = String.to_atom("auto_" <> Integer.to_string(int_id))
    {id, %{launchpad | last_generated_view_id: int_id}}
  end

  @spec update_pad_leds_after_remove(Launchpad.State.t(), list[pad_id]) ::
          Launchpad.State.t()
  defp update_pad_leds_after_remove(launchpad, pad_ids) do
    pad_n_view_ids =
      Enum.map(pad_ids, fn pad_id ->
        {pad_id, List.first(Enum.at(launchpad.on_pads, pad_id))}
      end)

    # pads that are empty that need to be cleared
    nil_view_ids = Enum.filter(pad_n_view_ids, fn {_, v} -> v == nil end)

    launchpad =
      Enum.reduce(nil_view_ids, launchpad, fn {pad_id, _v}, launchpad ->
        update_led(launchpad, pad_id, Launchpad.LED.black())
      end)

    # pads that have a view that need to be updated (but only once)
    view_ids =
      Enum.filter(pad_n_view_ids, fn {_, v} -> v != nil end)
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.sort()
      |> Enum.dedup()

    launchpad =
      Enum.reduce(view_ids, launchpad, fn view_id, launchpad ->
        # view = launchpad.views[view_id]
        view_tuple = List.keyfind(launchpad.views, view_id, 0)

        if(!is_nil(view_tuple)) do
          {view_id, view} = view_tuple
          _launchpad = update_leds(launchpad, view_id, view)
        else
          # if the view is on right now and waiting for off msg
          # view = Keyword.get(launchpad.off_pads, view_id)
          {view_id, view} = List.keyfind(launchpad.off_pads, view_id, 0)

          if(!is_nil(view)) do
            _launchpad = update_leds(launchpad, view_id, view)
          end
        end
      end)

    launchpad
  end

  @spec pop_view_from_views(Launchpad.State.t(), view_id) ::
          {view_id, Launchpad.State.t()}
  defp pop_view_from_views(launchpad, view_id) do
    # view = launchpad.views[view_id]
    view_tuple = List.keyfind(launchpad.views, view_id, 0)
    # launchpad = %{launchpad | views: Keyword.delete(launchpad.views, view_id)}
    if(is_nil(view_tuple)) do
      {nil, launchpad}
    else
      {view_id, view} = view_tuple
      launchpad = %{launchpad | views: List.keydelete(launchpad.views, view_id, 0)}
      {view, launchpad}
    end
  end

  @spec add_view_id_to_pads(list[on_pad], list[pad_id], view_id) :: list[on_pad]
  defp add_view_id_to_pads(on_pads, pad_ids, view_id) do
    Enum.reduce(pad_ids, on_pads, fn pad_id, on_pads ->
      pad_stack = Enum.at(on_pads, pad_id)
      pad_stack = List.delete(pad_stack, view_id)
      pad_stack = [view_id | pad_stack]
      List.replace_at(on_pads, pad_id, pad_stack)
    end)
  end

  @spec remove_view_id_from_pads(list[on_pad], view_id, list[pad_id]) :: list[on_pad]
  defp remove_view_id_from_pads(on_pads, view_id, pad_ids) do
    # IO.inspect({:remove_view_id_from_pads, view_id})

    Enum.reduce(pad_ids, on_pads, fn pad_id, on_pads ->
      pad_stack = Enum.at(on_pads, pad_id)
      pad_stack = List.delete(pad_stack, view_id)
      List.replace_at(on_pads, pad_id, pad_stack)
    end)
  end

  @spec as_xy(pad_id) :: {integer, integer}
  defp as_xy(pad_id) do
    {
      Integer.mod(pad_id, 9),
      trunc(pad_id / 9)
    }
  end

  @spec as_id(integer, integer) :: pad_id
  defp as_id(x, y) do
    y * 9 + x
  end

  @spec as_id(Midi.Msg.t()) :: pad_id
  defp as_id(msg) do
    if(msg.msgtype == 11) do
      x = msg.note - 104
      y = 0
      as_id(x, y)
    else
      x = Integer.mod(msg.note, 16)
      y = trunc((msg.note - x) / 16 + 1)
      as_id(x, y)
    end
  end

  @spec is_on?(Midi.Msg.t()) :: boolean
  defp is_on?(msg) do
    case msg do
      %Midi.Msg{msgtype: 9, chan: _, note: _, vel: 0} ->
        false

      %Midi.Msg{msgtype: 9, chan: _, note: _, vel: _} ->
        true

      %Midi.Msg{msgtype: 8, chan: _, note: _, vel: _} ->
        false

      _ ->
        if(Integer.mod(msg.vel, 2) == 1) do
          true
        else
          false
        end
    end
  end

  @spec setLED(pid, pad_id, velocity) :: any
  defp setLED(midiout_pid, pad_id, vel) do
    {x, y} = as_xy(pad_id)

    if(y == 0) do
      setTopLED(midiout_pid, x, vel)
    else
      setMatrixLED(midiout_pid, x, y, vel)
    end
  end

  # @spec setLED(pid, integer, integer, velocity) :: any
  # defp setLED(midiout_pid, x, y, vel) do
  #   if(y == 0) do
  #     setTopLED(midiout_pid, x, vel)
  #   else
  #     setMatrixLED(midiout_pid, x, y, vel)
  #   end
  # end

  @spec xyMIDINode(integer, integer) :: integer
  defp xyMIDINode(x, y) do
    x + y * 16
  end

  @spec pos2CC(integer) :: integer
  defp pos2CC(pos) do
    104 + pos
  end

  @spec setMatrixLED(pid, integer, integer, velocity) :: any
  defp setMatrixLED(midiout_pid, x, y, vel) do
    PortMidi.write(midiout_pid, {9 <<< 4, xyMIDINode(x, y - 1), vel})
  end

  @spec setTopLED(pid, integer, velocity) :: any
  defp setTopLED(midiout_pid, x, vel) do
    PortMidi.write(midiout_pid, {11 <<< 4, pos2CC(x), vel})
  end

  @spec update_led(Launchpad.State.t(), pad_id, velocity) :: Launchpad.State.t()
  defp update_led(launchpad, pad_id, vel) do
    if(Enum.at(launchpad.out_pads, pad_id) != vel) do
      out_pads = List.replace_at(launchpad.out_pads, pad_id, vel)
      # {x, y} = as_xy(pad_id)
      setLED(launchpad.midiout_pid, pad_id, vel)
      %{launchpad | out_pads: out_pads}
    else
      launchpad
    end
  end

  @spec is_view_top?(Launchpad.State.t(), view_id, pad_id) :: boolean
  defp is_view_top?(launchpad, view_id, pad_id) do
    List.first(Enum.at(launchpad.on_pads, pad_id)) == view_id
  end

  @spec update_leds(Launchpad.State.t(), view_id, map) :: Launchpad.State.t()
  defp update_leds(launchpad, view_id, view) when is_map(view) do
    # IO.inspect({:ul, launchpad, view_id, view})
    pad_ids_n_vel = apply(view.__struct__, :getLEDs, [launchpad, view])

    _launchpad =
      Enum.reduce(pad_ids_n_vel, launchpad, fn {pad_id, vel}, launchpad ->
        if is_view_top?(launchpad, view_id, pad_id) do
          # :timer.sleep(1)
          update_led(launchpad, pad_id, vel)
        else
          launchpad
        end
      end)
  end

  @spec process_on_msg(Launchpad.State.t(), pad_id) :: Launchpad.State.t()
  defp process_on_msg(launchpad, pad_id) do
    pad_stack = Enum.at(launchpad.on_pads, pad_id)

    if(length(pad_stack) == 0) do
      # IO.puts("no view on pad_id: #{pad_id} in on_pads")
      launchpad
    else
      [view_id | _] = pad_stack
      # {view, views} = Keyword.pop(launchpad.views, view_id)
      view_tuple = List.keyfind(launchpad.views, view_id, 0)
      views = List.keydelete(launchpad.views, view_id, 0)

      # IO.inspect({:lplps325, view, views})

      if(!is_nil(view_tuple)) do
        {view_id, view} = view_tuple
        launchpad = %{launchpad | views: views}
        # l_id = Enum.find_index(view.pad_ids, pad_id)
        button_id = Enum.find_index(view.pad_ids, fn x -> x == pad_id end)

        {view, launchpad} =
          apply(view.__struct__, :responseOn, [launchpad, button_id, view, pad_id])

        launchpad = update_leds(launchpad, view_id, view)

        off_pads = List.replace_at(launchpad.off_pads, pad_id, {view_id, view})
        %{launchpad | off_pads: off_pads}
      else
        # IO.puts("don't handle two triggers on the same view")
        launchpad
      end
    end
  end

  @spec process_off_msg(Launchpad.State.t(), pad_id) :: Launchpad.State.t()
  defp process_off_msg(launchpad, pad_id) do
    view_tuple = Enum.at(launchpad.off_pads, pad_id)
    List.replace_at(launchpad.off_pads, pad_id, nil)

    if(!is_nil(view_tuple)) do
      {view_id, view} = view_tuple
      # l_id = Enum.find_index(view.pad_ids, pad_id)
      button_id = Enum.find_index(view.pad_ids, fn x -> x == pad_id end)

      {view, launchpad} =
        apply(view.__struct__, :responseOff, [launchpad, button_id, view, pad_id])

      # update leds
      is_view_alive = Enum.member?(Enum.at(launchpad.on_pads, pad_id), view_id)

      launchpad =
        if(is_view_alive) do
          # IO.puts("view is alive: #{inspect(view_id)} #{pad_id}")

          views = [{view_id, view} | launchpad.views]
          launchpad = %{launchpad | views: views}

          _launchpad = update_leds(launchpad, view_id, view)
        else
          # IO.puts("view is not alive: #{inspect(view_id)} #{pad_id}")
          pad_ids = view.pad_ids
          update_pad_leds_after_remove(launchpad, pad_ids)
        end

      %{launchpad | off_pads: List.replace_at(launchpad.off_pads, pad_id, nil)}
    else
      # IO.puts("no view on pad_id: #{pad_id} in off_pads")
      launchpad
    end
  end
end
