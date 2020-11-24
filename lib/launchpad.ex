defmodule Launchpad do
  @spec setup(String.t(), String.t()) :: {atom, pid}
  def setup(midiin_name \\ "Launchpad MIDI 1", midiout_name \\ "Launchpad MIDI 1") do
    {:ok, midiin_pid} = PortMidi.open(:input, midiin_name)
    {:ok, midiout_pid} = PortMidi.open(:output, midiout_name)
    Launchpad.Listener.start_link(midiin_pid, midiout_pid)
  end

  @spec remove_view(atom | tuple) :: atom
  def remove_view(view_id) do
    GenServer.call(:launchpad, {:remove_view, view_id})
  end

  @spec remove_all_views_startinging_with(tuple | atom) :: atom
  def remove_all_views_startinging_with(view_id) do
    GenServer.call(:launchpad, {:remove_all_views_startinging_with, view_id})
  end

  @spec hide_all_views_startinging_with(tuple | atom) :: atom
  def hide_all_views_startinging_with(view_id) do
    GenServer.call(:launchpad, {:hide_all_views_startinging_with, view_id})
  end

  @spec hide_view(tuple | atom) :: atom
  def hide_view(view_id) do
    GenServer.call(:launchpad, {:hide_view, view_id})
  end

  @spec add_view_and_front(map) :: atom
  def add_view_and_front(view) do
    GenServer.call(:launchpad, {:add_view_and_front, view})
  end

  @spec add_view(map, tuple | atom) :: atom
  def add_view(view, view_id) do
    GenServer.call(:launchpad, {:add_view, view, view_id})
  end

  @spec set_view_to_front(tuple | atom) :: atom
  def set_view_to_front(view_id) do
    GenServer.call(:launchpad, {:set_view_to_front, view_id})
  end

  @spec as_id(integer, integer) :: integer
  defp as_id(x, y) do
    y * 9 + x
  end

  def pad(x, y) do
    [as_id(x, y)]
  end

  @spec pads(integer | Range.t(), integer | Range.t()) :: list
  def pads(x, y) do
    x_range = if(is_number(x), do: x..x, else: x)
    y_range = if(is_number(y), do: y..y, else: y)

    List.flatten(
      Enum.map(y_range, fn y ->
        Enum.map(x_range, fn x ->
          as_id(x, y)
        end)
      end)
    )
  end
end
