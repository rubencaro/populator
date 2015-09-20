
defmodule Populator.Helpers do

  @moduledoc """
    require Populator.Helpers, as: H  # the cool way
  """

  @doc """
    Convenience to get environment bits. Avoid all that repetitive
    `Application.get_env( :myapp, :blah, :blah)` noise.
  """
  def env(key, default \\ nil), do: env(Mix.Project.get!.project[:app], key, default)
  def env(app, key, default), do: Application.get_env(app, key, default)

  @doc """
    Spit to stdout any passed variable, with location information.
  """
  defmacro spit(obj \\ "", inspect_opts \\ []) do
    quote do
      %{file: file, line: line} = __ENV__
      name = Process.info(self)[:registered_name]
      chain = [ :bright, :red, "\n\n#{file}:#{line}",
                :normal, "\n     #{inspect self}", :green," #{name}"]

      msg = inspect(unquote(obj),unquote(inspect_opts))
      if String.length(msg) > 2, do: chain = chain ++ [:red, "\n\n#{msg}"]

      # chain = chain ++ [:yellow, "\n\n#{inspect Process.info(self)}"]

      (chain ++ ["\n\n", :reset]) |> IO.ANSI.format(true) |> IO.puts

      unquote(obj)
    end
  end

  @doc """
    Print to stdout a _TODO_ message, with location information.
  """
  defmacro todo(msg \\ "") do
    quote do
      %{file: file, line: line} = __ENV__
      [ :yellow, "\nTODO: #{file}:#{line} #{unquote(msg)}\n", :reset]
      |> IO.ANSI.format(true)
      |> IO.puts
      :todo
    end
  end

  @doc """
    Wait for given function to return true.
    Optional `msecs` and `step`.
    Be aware that exceptions raised and thrown messages by given `func` will be
    discarded.
    Optional `:timeout` giving the return value for a timeout event. Special
    `:raise` value (default) will raise en exception.
  """
  def wait_for(opts \\ [], func) do
    opts = [msecs: 5_000, step: 100, timeout: :raise] |> Keyword.merge opts
    res = try do
      func.()
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
    end

    if res do
      :ok
    else
      if opts[:msecs] <= 0 do
        case opts[:timeout] do
          :raise -> raise "Timeout!"
          x -> x
        end
      else
        # sleep and loop
        :timer.sleep opts[:step]
        wait_for Keyword.merge(opts, [msecs: opts[:msecs] - opts[:step]]), func
      end
    end
  end

  @doc """
    Gets names for children in given supervisor. Children with no registered
    name are not returned. List is sorted. Options al passed to `children_data/2`.
  """
  def children_names(supervisor) do
    supervisor
      |> get_linked_ids
      |> Enum.map( &( get_name(&1) ) )
      |> Enum.filter( &(&1) ) # remove nils
      |> Enum.sort
  end

  @doc """
    Get linked pids list, useful to guess supervisor children without blocking it.
  """
  def get_linked_ids(name) do
    res = name |> Process.whereis |> Process.info |> Keyword.get(:links)
    res
  end

  defp get_name(pid) do
    (Process.info(pid) || [])|> Keyword.get :registered_name, nil
  end

  @doc """
    Kill all of given supervisor's children
  """
  def kill_children(supervisor) do
    children = supervisor |> Supervisor.which_children
    for {_,pid,_,_} <- children, do: true = Process.exit(pid, :kill)
    :ok
  end

  @doc """
    Start a children with given spec in the given supervisor if not already started.

    Returns `{:ok, child}` if the child is successfully started or
    it was already started. `{:error, reason}` otherwise.
  """
  def start_child(spec, supervisor) do
    res = Supervisor.start_child supervisor, spec

    case child_is_started_ok(res) do
      # Something went wrong so return the gotten result
      false -> res

      # The spec is there but the process isn't so restart it
      :already_present ->
        child_id = elem(spec, 0)
        # IO.puts "+++++++++++ reestart +++++++++++++: #{child_id}"
        Supervisor.restart_child(supervisor, child_id)

      # There's a running process so it's returned
      child ->
        # IO.puts "-----------   start -------------: #{:erlang.pid_to_list(child)}"
        {:ok, child}
    end
  end

  defp child_is_started_ok({:ok,child}), do: child
  defp child_is_started_ok({:ok,child,_}), do: child
  defp child_is_started_ok({:error, {:already_started, child}}), do: child
  defp child_is_started_ok({:error, :already_present}), do: :already_present
  defp child_is_started_ok(_), do: false

  @doc """
    Raise an error if any given key is not in the given Keyword.
    Returns given Keyword, so it can be chained using pipes.
  """
  def requires(args, required) do
    keys = args |> Keyword.keys
    for r <- required do
      if not r in keys do
        raise ArgumentError, message: "Required argument '#{r}' was not present in #{inspect(args)}"
      end
    end
    args # chainable
  end

  @doc """
    Apply given defaults to given Keyword. Returns merged Keyword.
  """
  def defaults(args, defs) do
    defs |> Keyword.merge(args)
  end

end
