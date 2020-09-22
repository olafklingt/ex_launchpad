# a draft about how one could match ranges
# a = [%{range: %{msgtype: 9..9, chan: 0..15, note: 0..49, vel:  1..127}, val: 1},%{range: %{msgtype: 9..9, chan: 0..15, note: 50..127, vel: 1..127}, val: 2}]
#
# t = %{msgtype: 9, chan: 0, note: 20, vel: 50}
#
# Enum.filter(a,fn x -> for k <- Map.keys(t) do IO.inspect(Map.get(t, k) in Map.get(x.range, k)) end |> Enum.reduce(true,fn x,acc -> x && acc end)end)

# would be good if i could specify ranges with in and integers with ==

defmodule Midi.Listener.State do
  use TypedStruct

  typedstruct do
    field(:midi_in, any, enforce: false)
    field(:midi_out, any, enforce: false)
    field(:tree, list, enforce: false)
  end
end

defmodule Midi.Listener do
  use GenServer
  use Bitwise

  # @spec note_on(non_neg_integer, any, integer, integer) :: any
  def note_on(msg = %Midi.Msg{msgtype: _msgtype, chan: _chan, note: _note, vel: _vel}, state) do
    b = Midi.Matcher.getMatcher(msg, state.tree)

    IO.puts("note_on #{inspect(msg)} #{inspect(b)}")
    state
  end

  # @spec note_off(any, integer) :: any
  def note_off(msg, state) do
    IO.puts("note_off #{inspect(msg)}")
    state
  end

  # @spec start_link(any, any) :: any
  def start_link(input_pids, output, tree) do
    GenServer.start_link(__MODULE__, {input_pids, output, tree})
  end

  @impl true
  def init({input_pids, output, tree}) do
    for x <- input_pids do
      PortMidi.listen(x, self())
    end

    {:ok, %Midi.Listener.State{midi_in: input_pids, midi_out: output, tree: tree}}
  end

  @impl true
  def handle_info({_pid, msg}, state) do
    # state =
    Enum.reduce(msg, state, fn event, state ->
      {{type, note, vel}, _time?} = event
      chan = rem(type, 16)
      msgtype = type >>> 4

      # msg = {msgtype, chan, note, vel}
      msg = %Midi.Msg{msgtype: msgtype, chan: chan, note: note, vel: vel}

      # IO.puts("\n\n\n\nstate: #{inspect(state)}\n\n\n\n\n")

      # b = Midi.Matcher.getMatcher(msg, state.tree)
      Midi.Matcher.match(msg, state.tree)
      # IO.inspect(b)

      # case msg do
      #   %{msgtype: 8, chan: _, note: _, vel: _} ->
      #     note_off(msg, state)
      #
      #   %{msgtype: 9, chan: chan, note: note, vel: 0} ->
      #     note_off(msg, state)
      #
      #   %{msgtype: 9, chan: chan, note: note, vel: _} ->
      #     note_on(msg, state)
      #
      #   {_, _, _, _} ->
      #     IO.puts("unmatched midi event: #{inspect(msg)}")
      #     state
      # end
    end)

    {:noreply, state}
  end
end

# tree = [
#   %Midi.Msg.Handle{
#     matcher: %Midi.Msg.Matcher{msgtype: 9, chan: 0..15, note: 0..127, vel: 1..127},
#     child: fn msg -> IO.puts("note on #{inspect(msg)}") end
#   },
#   %Midi.Msg.Handle{
#     matcher: %Midi.Msg.Matcher{msgtype: 9, chan: 0..15, note: 0..127, vel: 0},
#     child: fn msg -> IO.puts("note on->off #{inspect(msg)}") end
#   },
#   %Midi.Msg.Handle{
#     matcher: %Midi.Msg.Matcher{msgtype: 8, chan: 0..15, note: 50..127, vel: 0..127},
#     child: fn msg -> IO.puts("note off #{inspect(msg)}") end
#   }
# ]

# ml = Midi.Listener.start_link(input_pids, midiout, tree)
