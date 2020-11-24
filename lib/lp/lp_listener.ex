defmodule Launchpad.Listener do
  use GenServer
  use Bitwise

  @spec start_link(pid, pid) :: any
  def start_link(midiin_pid, midiout_pid) do
    GenServer.start_link(__MODULE__, {midiin_pid, midiout_pid}, name: :launchpad)
  end

  @impl true
  def init({midiin_pid, midiout_pid}) do
    launchpad = Launchpad.State.init(midiin_pid, midiout_pid)
    PortMidi.listen(midiin_pid, self())

    {:ok, launchpad}
  end

  @impl true
  def handle_info({_pid, msg}, launchpad) do
    launchpad =
      Enum.reduce(msg, launchpad, fn event, launchpad ->
        {{type, note, vel}, _time?} = event
        chan = rem(type, 16)
        msgtype = type >>> 4
        # msg = {msgtype, chan, note, vel}
        msg = %Midi.Msg{msgtype: msgtype, chan: chan, note: note, vel: vel}
        launchpad = Launchpad.State.process_msg(launchpad, msg)
        launchpad
      end)

    {:noreply, launchpad}
  end

  @impl true
  def handle_call({:remove_view, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.remove_view(launchpad, view_id)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:remove_all_views_startinging_with, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.remove_all_views_startinging_with(launchpad, view_id)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:hide_all_views_startinging_with, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.hide_all_views_startinging_with(launchpad, view_id)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:hide_view, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.hide_view(launchpad, view_id)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:add_view_and_front, view}, _from, launchpad) do
    {view_id, launchpad} = Launchpad.State.add_view_and_front(launchpad, view)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:add_view, view, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.add_view(launchpad, view, view_id)
    {:reply, view_id, launchpad}
  end

  @impl true
  def handle_call({:set_view_to_front, view_id}, _from, launchpad) do
    launchpad = Launchpad.State.set_view_to_front(launchpad, view_id)
    {:reply, view_id, launchpad}
  end
end
