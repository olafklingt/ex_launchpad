defmodule Launchpad.RepeatingRoutine do
  use GenServer

  @spec start_link(fun, tuple, integer) :: {atom, pid}
  def start_link(func, func_state, interval) do
    GenServer.start_link(__MODULE__, {func, func_state, interval})
  end

  @impl true
  def init({func, func_state, interval}) do
    func_state = func.(func_state)
    Process.send_after(self(), :work, interval)
    {:ok, {func, func_state, interval}}
  end

  @impl true
  def handle_info(:work, {func, func_state, interval}) do
    func_state = func.(func_state)
    Process.send_after(self(), :work, interval)
    {:noreply, {func, func_state, interval}}
  end

  @impl true
  def handle_call(:return, _from, {_func, func_state, _interval}) do
    {:stop, :normal, func_state, nil}
  end
end
