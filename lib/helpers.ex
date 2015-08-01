
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
  def children_names(supervisor, opts \\ []) do
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
    Process.info(pid) |> Keyword.get :registered_name, nil
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
      child -> {:ok, child}
      false -> res
    end
  end

  defp child_is_started_ok({:ok,child}), do: child
  defp child_is_started_ok({:ok,child,_}), do: child
  defp child_is_started_ok({:error, {:already_started, child}}), do: child
  defp child_is_started_ok(_), do: false

  @doc """
    Gets an usable string from a binary crypto hash
  """
  def hexdigest(binary) do
    for b <- :erlang.binary_to_list(binary), do: :io_lib.format("~2.16.0B", [b])
      |> List.flatten |> :string.to_lower |> List.to_string
  end

  @doc """
    Gets an md5 string
  """
  def md5(binary), do: :crypto.hash(:md5, binary) |> hexdigest

  @doc """
    Get timestamp in seconds, microseconds, or nanoseconds
  """
  def ts(scale \\ :seconds) do
    {mega, sec, micro} = :os.timestamp
    t = mega * 1_000_000 + sec
    case scale do
      :seconds -> t
      :micro -> t * 1_000_000 + micro
      :nano -> (t * 1_000_000 + micro) * 1_000
    end
  end
end
