require Populator.Helpers, as: H
require Populator.TestHelpers, as: TH

defmodule PopulatorTest do
  use ExUnit.Case

  test "population growth" do
    # create child_spec function
    child_spec = fn(data)->
      Supervisor.Spec.worker(Task,
                             [TH, :lazy_worker, [[ name: data[:name] ]] ],
                             id: data[:name])
    end

    # create supervisor, with one random child already
    {:ok, sup} = TH.Supervisor.start_link children: [child_spec.(name: :w2)]

    # create desired_children function for 5 children
    desired_children = fn()->
      [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
    end
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

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
    Populator.run supervisor: TH.Supervisor,
                  child_spec: child_spec,
                  desired_children: desired_children

    # check linked_ids are still the same
    assert linked_ids == H.get_linked_ids(TH.Supervisor)
  end

  test "population shrink" do
    # create child_spec function
    child_spec = fn(data)->
      Supervisor.Spec.worker(Task,
                             [TH, :lazy_worker, [[ name: data[:name] ]] ],
                             [id: data[:name]])
    end

    # create supervisor, with some children
    children = [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
        |> Enum.map(&( child_spec.(&1)))
    {:ok, sup} = TH.Supervisor.start_link children: children

    # create desired_children function for 2 children
    desired_children = fn()->
      [[name: :w3],[name: :w5]]
    end
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

    # call Populator.run, it should kill some children
    Populator.run supervisor: TH.Supervisor,
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
    H.todo
  end
end
