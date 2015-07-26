require Logger, as: L

defmodule Populator.Helpers do

  @doc """
    Convenience to get environment bits. Avoid all that repetitive
    `Application.get_env( :myapp, :blah, :blah)` noise.
  """
  def env(key, default \\ nil), do: env(Mix.Project.get!.project[:app], key, default)
  def env(app, key, default), do: Application.get_env(app, key, default)

  @doc """
    Spit to logger any passed variable, with location information.
  """
  defmacro spit(obj, inspect_opts \\ []) do
    quote do
      %{file: file, line: line} = __ENV__
      [ :bright, :red, "\n\n#{file}:#{line}",
        :normal, "\n\n#{inspect(unquote(obj),unquote(inspect_opts))}\n\n", :reset]
      |> IO.ANSI.format(true) |> IO.puts
    end
  end

  @doc """
    Print to stdout a _TODO_ message, with location information.
  """
  defmacro todo(msg \\ "") do
    quote do
      %{file: file, line: line} = __ENV__
      [ :yellow, "\nTODO: #{file}:#{line} #{unquote(msg)}\n", :reset]
      |> IO.ANSI.format(true) |> IO.puts
    end
  end

  @doc """
    Wait for given function to return true.
    Optional `msecs` and `step`.
    Be aware that exceptions raised and thrown messages by given `func` will be discarded.
  """
  def wait_for(func, msecs \\ 5_000, step \\ 100) do
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
      if msecs <= 0, do: raise "Timeout!"
      :timer.sleep step
      wait_for func, msecs - step, step
    end
  end

  @doc """
    Gets names for children in given supervisor. Children with no registered
    name are not returned. List is sorted.
  """
  def named_children(supervisor) do
    supervisor
      |> Supervisor.which_children
      |> Enum.map(fn({_,pid,_,_})-> Process.info(pid)[:registered_name] end)
      |> Enum.filter(&(&1))
      |> Enum.sort
  end

  @doc """
    Kill all of given supervisor's children
  """
  def kill_children(supervisor) do
    children = supervisor |> Supervisor.which_children
    for {_,pid,_,_} <- children, do: true = Process.exit(pid, :kill)
    :ok
  end

end
