require Populator.Helpers, as: H

defmodule Populator.Looper do

  @doc """
    To be added to a supervisor hierarchy wrapped in a `Task`, like this:
    ```elixir
    worker(Task, [Populator.Looper,:run,[args]])
    ```

    `max_loops` below zero implies forever loop
  """
  def run(args) do
    args = args
      |> H.defaults(step: 30000, max_loops: -1)

    # register the name if asked
    if args[:name], do: Process.register(self,args[:name])

    do_loop args, args[:max_loops]
  end

  defp do_loop(args, left) do
    # actual run
    :ok = apply(Populator, :run, args[:run_args])

    # only stop here, negative values mean infinite loop
    if left == 1 do
      :ok
    else
      # only sleep & loop if any loops left
      :timer.sleep(args[:step])
      do_loop(args, left - 1)
    end
  end

end
