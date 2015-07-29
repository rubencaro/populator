require Populator.Helpers, as: H

defmodule Populator do

  @doc """
    It will update the given supervisor until it has the population demanded by
    `desired_children`, either by creating new children or by killing existing
    ones.

    Every child created will be done so using the spec returned by
    `child_spec`, so the `child_spec` function should end with a call to
    `Supervisor.Spec.worker/3`. It should also register each worker with
    a unique name.

    The `desired_children` function should return a list of children data,
    with all the state needed by the `child_spec` function for each of them.
    It should include a `:name` with the unique name for each child.
  """
  def run(supervisor: sup,
          child_spec: spec_fun,
          desired_children: desired_fun) do

    desired = desired_fun.()

    # start all desired children
    for d <- desired do
      H.spit spec_fun.(d)
      {:ok, child} = spec_fun.(d) |> H.start_child(sup)
    end

    # kill non desired ones
    desired_names = desired |> Enum.map(&( &1[:name] )) |> Enum.sort

    H.spit desired_names

    H.spit( sup |> H.children_names(all: true) )

    sup
    |> H.children_names
    |> Enum.filter(&( not(&1 in desired_names) ))
    |> Enum.map(&( Process.whereis(&1) ))
    |> Enum.each(&( true = Process.exit(&1, :kill) ))


    :ok
  end

end
