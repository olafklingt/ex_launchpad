defmodule Midi.Msg do
  use TypedStruct

  typedstruct do
    field(:chan, integer, enforce: true)
    field(:msgtype, integer, enforce: true)
    field(:note, integer, enforce: true)
    field(:vel, integer, enforce: true)
  end
end

defmodule Midi.Msg.Matcher do
  use TypedStruct

  typedstruct do
    field(:chan, integer | Range.t(), enforce: true)
    field(:msgtype, integer | Range.t(), enforce: true)
    field(:note, integer | Range.t(), enforce: true)
    field(:vel, integer | Range.t(), enforce: true)
  end
end

defmodule Midi.Msg.Handle do
  use TypedStruct

  typedstruct do
    field(:matcher, Midi.Msg.Matcher.t(), enforce: true)
    field(:child, any)
  end
end

defmodule Midi.Matcher do
  def match(msg, tree) do
    getMatcher(msg, tree).child.(msg)
  end

  def getMatcher(msg, tree) do
    _b =
      List.first(
        Enum.filter(tree, fn x ->
          for k <- Map.keys(msg) do
            # k != :__struct__ is so stupid
            if(k != :__struct__) do
              val = Map.get(msg, k)
              r = Map.get(x.matcher, k)

              cond do
                is_number(r) -> val == r
                r.__struct__ === Range -> Map.get(msg, k) in r
                true -> raise "only range and integers are suported#{inspect(r)}"
              end
            else
              true
            end
          end
          |> Enum.reduce(true, fn x, acc -> x && acc end)
        end)
      )
  end

  def test() do
    Enum.reduce(["a", "b", "c"], {0, nil}, fn x, {n, p} ->
      if(p == nil,
        do:
          if(x == "b",
            do: {n + 1, n},
            else: {n + 1, nil}
          ),
        else: {n, p}
      )
    end)
  end

  def test2() do
    Enum.reduce_while(["a", "b", "c"], 0, fn x, n ->
      if(x == "b",
        do: {:halt, n},
        else: {:cont, n + 1}
      )
    end)
  end
end
