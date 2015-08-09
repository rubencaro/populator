require Populator.Helpers, as: H

defmodule Populator.Looper do

  @doc """
    Start a looper that runs `Populator.run/3` on every loop. Example:

    ```elixir
    Populator.Looper.run step: 30000, name: :my_looper, run_args: run_args
    ```

    To be added to a supervisor hierarchy wrapped in a `Task`, like this:

    ```elixir
    worker(Task, [Populator.Looper,:run,[args]])
    ```

    * `run_args` are the arguments expected by `Populator.run/3`
    * `max_loops` below zero implies forever loop (default -1).
      `:ok` is returned if `:max_loops` reached.
    * `step` is in milliseconds, time to sleep between loops (default 30000)
    * `name` is the name to be registered with (not given means not registered)
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
