defmodule Populator.Receiver do

  @doc """
    Start a `receive` block to listen to `:populate` message.
    Any `:populate` message will trigger a run of `Populator.run/3`.
    Example:

    ```elixir
    Task.async fn->
      Populator.Receiver.run(name: :my_receiver, run_args: run_args)
    end

    send :my_receiver, :populate
    ```

    To be added to a supervisor hierarchy wrapped in a `Task`, like this:

    ```elixir
    worker(Task, [Populator.Receiver,:run,[args]])
    ```

    * `run_args` are the arguments expected by `Populator.run/3`
    * `name` is the name to be registered with (not given means not registered)
  """
  def run(args) do
    # register the name if asked
    if args[:name], do: Process.register(self,args[:name])

    do_receive args
  end

  defp do_receive(args) do
    receive do
      :populate ->
        :ok = apply(Populator, :run, args[:run_args])
        do_receive args
    end
  end

end
