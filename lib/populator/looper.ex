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

    State can be accessed using an `Agent` registered as `:my_looper_agent`
    (`"\#{args[:name]}_agent"`).

    This can be useful if you need to change any of the given arguments after
    the loop is started. Any changes over that state are used in the next
    iteration of the loooper. Agent updates are atomic, so any update you will
    be fully applied, or no applied at all (i.e. will be applied from the next
    iteration on).
  """
  def run(args) do
    args = args
      |> H.defaults(step: 30000, max_loops: -1, runner: Populator)

    # register the name if asked
    agent_name =
      if args[:name] do
        Process.register(self,args[:name])
        "#{args[:name]}_agent" |> String.to_atom
      else
        "#{self() |> :erlang.pid_to_list()}_populator_agent" |> String.to_atom
      end

    Agent.start_link(fn -> args end, name: agent_name)

    do_loop(args, args[:max_loops], agent_name, args[:runner])
  end

  defp do_loop(args, left, agent_name, runner) do

    # actual run
    :ok = apply(runner, :run, args[:run_args])

    # only stop here, negative values mean infinite loop
    if left == 1 do
      :ok
    else
      # only sleep & loop if any loops left
      :timer.sleep(args[:step])

      # get args from the agent
      args = Agent.get(agent_name, &(&1))

      do_loop(args, left - 1, agent_name, runner)
    end
  end

end
