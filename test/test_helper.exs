ExUnit.start()

defmodule Populator.TestHelpers.Supervisor do
  use Supervisor

  def start_link(args \\ []), do: Supervisor.start_link(__MODULE__, [args], name: __MODULE__)

  def init([args]) do
    args = [children: [], max_restarts: 3, max_seconds: 5] |> Keyword.merge args

    supervise(args[:children], strategy: :one_for_one,
                        max_restarts: args[:max_restarts],
                        max_seconds: args[:max_seconds])
  end

end

defmodule Populator.TestHelpers do

  def lazy_worker(opts \\ []) do
    if opts[:name], do: Process.register(self,opts[:name])
    :timer.sleep(50)
    lazy_worker
  end

  def one_time_worker(opts \\ []) do
    if opts[:name], do: Process.register(self,opts[:name])
    :timer.sleep(1_000)
  end

end
