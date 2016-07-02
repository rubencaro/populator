ExUnit.start()

# save some state
Agent.start_link(fn -> %{} end, name: :populator_test_agent)

defmodule Populator.TestHelpers.Supervisor do
  use Supervisor

  def start_link(args \\ []), do: Supervisor.start_link(__MODULE__, [args], name: __MODULE__)

  def init([args]) do
    args = [children: [], max_restarts: 3, max_seconds: 5] |> Keyword.merge(args)

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

  def get_count(key) do
    Agent.get(:populator_test_agent,&(&1)) |> Map.get(key, 0)
  end

  def unique, do: :erlang.unique_integer([:positive])

end

defmodule Populator.TestHelpers.MockRunner do

  @doc """
    Accumulates the number of calls to each combination of params
  """
  def run(a, b, c, d \\ nil) do
    # calc the key first
    key = if d, do: [a, b, c, d], else: [a, b, c]

    Agent.update(:populator_test_agent, fn(s)->
      Map.update(s, key, 1, &(&1 + 1))
    end)

    :ok
  end

end
