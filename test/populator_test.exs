require Populator.Helpers, as: H
require Populator.TestHelpers, as: TH

defmodule PopulatorTest do
  use ExUnit.Case

  setup do
    # kill test supervisor if it's alive
    pid = TH.Supervisor |> Process.whereis
    if pid, do: true = Process.exit(pid,:kill)

    # clean any mock on exit
    on_exit fn -> :meck.unload end

    :ok
  end

  test "population growth" do
    # get funs
    {child_spec, desired_children} = get_growth_funs
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

    # create supervisor, with one random child already
    {:ok, _} = TH.Supervisor.start_link children: [child_spec.(name: :w2)]

    # call Populator.run, it should populate with new children
    :ok = Populator.run TH.Supervisor, child_spec, desired_children

    # check supervisor has the 5 children
    H.wait_for fn ->
      H.children_names(TH.Supervisor) == desired_names
    end

    # save linked_ids to ensure they are steady
    linked_ids = H.get_linked_ids TH.Supervisor

    # call Populator.run, nothing should change
    :ok = Populator.run TH.Supervisor, child_spec, desired_children

    # check linked_ids are still the same
    assert linked_ids == H.get_linked_ids(TH.Supervisor)
  end

  test "population shrink" do
    # create child_spec function
    child_spec = get_child_spec_fun

    # create supervisor, with some children
    children = [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
        |> Enum.map(&( child_spec.(&1)))
    {:ok, _} = TH.Supervisor.start_link children: children

    # create desired_children function for 2 children
    desired_children = fn()->
      [[name: :w3],[name: :w5]]
    end
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

    # call Populator.run, it should kill some children
    :ok = Populator.run TH.Supervisor, child_spec, desired_children

    # check supervisor has the 2 children
    H.wait_for fn ->
      H.children_names(TH.Supervisor) == desired_names
    end

    # save linked_ids to ensure they are steady
    linked_ids = H.get_linked_ids TH.Supervisor

    # call Populator.run, nothing should change
    :ok = Populator.run TH.Supervisor, child_spec, desired_children

    # check linked_ids are still the same
    assert linked_ids == H.get_linked_ids(TH.Supervisor)
  end

  test "stationary population" do
    # get funs for growing population
    {child_spec, desired_children} = get_growth_funs

    # create supervisor, with one random child already
    {:ok, _} = TH.Supervisor.start_link children: [child_spec.(name: :w2)]

    # save linked_ids to ensure they are steady
    linked_ids = H.get_linked_ids TH.Supervisor

    # call Populator.run, it should do nothing, even if funs say it should grow
    # that's because we passed the `stationary` param
    :stationary = Populator.run TH.Supervisor,
                                child_spec,
                                desired_children,
                                stationary: true

    # check linked_ids are still the same
    assert linked_ids == H.get_linked_ids(TH.Supervisor)
  end

  test "loop runner" do
    # place mocks, we are only testing the runner
    :meck.new(Populator)
    :meck.expect(Populator, :run, fn(_, _, _)-> :ok end)

    # args expected by Populator.run
    run_args = [:sup, :spec, :desired]

    # spawn the loop runner, let it loop 5 times
    args = [step: 1, max_loops: 5, name: :test_looper, run_args: run_args]
    assert :ok = Populator.Looper.run(args)

    # check everything went as expected
    H.wait_for fn ->
      :meck.num_calls(Populator, :run, [run_args]) == 5
    end
  end

  test "message runner" do
    # place mocks, we are only testing the runner
    :meck.new(Populator)
    :meck.expect(Populator, :run, fn(_, _, _)-> :ok end)

    # args expected by Populator.run
    run_args = [:sup, :spec, :desired]

    # spawn the loop runner, let it loop 5 times
    args = [name: :test_receiver, run_args: run_args]
    Task.async fn-> Populator.Receiver.run(args) end

    assert :meck.num_calls(Populator, :run, [run_args]) == 0

    # wait for the name to be registered
    H.wait_for fn -> Process.whereis(:test_receiver) end

    # send the `:populate` message
    send :test_receiver, :populate

    # check everything went as expected
    H.wait_for fn ->
      :meck.num_calls(Populator, :run, [run_args]) == 1
    end
  end

  # get child_spec_fun and desired_children_fun for growth test
  defp get_growth_funs do
    # create desired_children function for 5 children
    desired_children = fn()->
      [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
    end

    {get_child_spec_fun, desired_children}
  end

  # create child_spec function
  defp get_child_spec_fun do
    fn(data)->
      Supervisor.Spec.worker(Task,
                             [TH, :lazy_worker, [[ name: data[:name] ]] ],
                             [id: data[:name]])
    end
  end
end
