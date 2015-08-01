require Populator.Helpers, as: H
require Populator.TestHelpers, as: TH

defmodule PopulatorTest do
  use ExUnit.Case

  setup do
    # kill test supervisor if it's alive
    pid = TH.Supervisor |> Process.whereis
    if pid, do: true = Process.exit(pid,:kill)
    :ok
  end

  test "population growth" do
    # get funs
    {child_spec, desired_children} = get_growth_funs
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

    # create supervisor, with one random child already
    {:ok, _} = TH.Supervisor.start_link children: [child_spec.(name: :w2)]

    # call Populator.run, it should populate with new children
    Populator.run supervisor: TH.Supervisor,
                  child_spec: child_spec,
                  desired_children: desired_children

    # check supervisor has the 5 children
    H.wait_for fn ->
      H.children_names(TH.Supervisor) == desired_names
    end

    # save linked_ids to ensure they are steady
    linked_ids = H.get_linked_ids TH.Supervisor

    # call Populator.run, nothing should change
    :ok = Populator.run supervisor: TH.Supervisor,
                        child_spec: child_spec,
                        desired_children: desired_children

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
    :ok = Populator.run supervisor: TH.Supervisor,
                        child_spec: child_spec,
                        desired_children: desired_children

    # check supervisor has the 2 children
    H.wait_for fn ->
      H.children_names(TH.Supervisor) == desired_names
    end

    # save linked_ids to ensure they are steady
    linked_ids = H.get_linked_ids TH.Supervisor

    # call Populator.run, nothing should change
    Populator.run supervisor: TH.Supervisor,
                  child_spec: child_spec,
                  desired_children: desired_children

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
    :stationary = Populator.run supervisor: TH.Supervisor,
                                child_spec: child_spec,
                                desired_children: desired_children,
                                stationary: true

    # check linked_ids are still the same
    assert linked_ids == H.get_linked_ids(TH.Supervisor)
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
