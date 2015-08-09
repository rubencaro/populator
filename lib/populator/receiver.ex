require Populator.Helpers, as: H

defmodule Populator.Receiver do

  @doc """
    To be added to a supervisor hierarchy wrapped in a `Task`, like this:
    ```elixir
    worker(Task, [Populator.Receiver,:run,[args]])
    ```

    Any `:populate` message will trigger a run of the Populator.
  """
  def run(args) do
    # register the name if asked
    if args[:name], do: Process.register(self,args[:name])

    do_receive args
  end

  defp do_receive(args) do
    receive do
      :populate ->
        :ok = Populator.run args[:run_args]
        do_receive args
    end
  end

end
