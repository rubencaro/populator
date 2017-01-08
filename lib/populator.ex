require Populator.Helpers, as: H

defmodule Populator do
  @moduledoc """
  Main Populator module
  """

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

    `:ok` will be returned.

    * `supervisor` is the supervisor name
    * `child_spec` is a function returning a children spec given its child data
    * `desired_children` is a function returning a list with data for each child
    * `stationary` can be given to avoid the actual execution, useful on testing
      environments, for example. `:stationary` will be returned.

    See README.md for further details.
  """
  def run(supervisor, child_spec, desired_children, opts \\ [])
      when is_atom(supervisor)
      and is_function(child_spec,2)
      and is_function(desired_children,1) do

    if opts[:stationary], do: :stationary,
      else: populate(supervisor, child_spec, desired_children, opts)
  end

  # Actually perform population operations
  #
  defp populate(supervisor, child_spec, desired_children, opts) do
    # start all desired children
    desired = desired_children.(opts)

    for d <- desired do
      {:ok, _} = H.start_child(child_spec.(d, opts), supervisor)
    end

    # kill non desired ones
    desired_names = desired |> Enum.map(&(&1[:name])) |> Enum.sort

    supervisor
    |> H.children_names
    |> Enum.reject(&(&1 in desired_names))
    |> Enum.each(fn(x) ->
      Supervisor.terminate_child(supervisor, x)
      Supervisor.delete_child(supervisor, x)
    end)

    :ok
  end
end
