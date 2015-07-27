require Populator.Helpers, as: H
require Populator.TestHelpers, as: TH

defmodule PopulatorTest do
  use ExUnit.Case

  test "population growth" do
    # create child_spec function
    child_spec = fn(data)->
      Supervisor.Spec.worker(Task, [TH, :lazy_worker, [[ name: data[:name] ]] ])
    end

    # create supervisor, with one random child already
    {:ok, sup} = TH.Supervisor.start_link children: [child_spec(name: :w2)]

    # create desired_children function for 5 children
    desired_children = fn()->
      [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
    end
    desired_names = desired_children.() |> Enum.map &( &1[:name] )

    # call Populator.run
    Populator.run supervisor: sup,
                  child_spec: child_spec,
                  desired_children: desired_children

    # check supervisor has the 5 children
    H.wait_for fn ->
      H.children_names(sup)  == desired_names
    end
  end

  test "population shrink" do
    H.todo
  end

  test "stationary population" do
    H.todo
  end
end
