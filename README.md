# Populator

[![Build Status](https://travis-ci.org/rubencaro/populator.svg?branch=master)](https://travis-ci.org/rubencaro/populator)
[![Hex Version](http://img.shields.io/hexpm/v/populator.svg?style=flat)](https://hex.pm/packages/populator)

A library to help control the population of a given supervisor.

Just add it among your project dependencies on `mix.exs`:

```elixir
{:populator, "0.2.0"}
```

## What

It takes the name of the supervisor and some params, such as the function to get new child specs, or the function to get the list of desired children, and it spawns (or kills) children on the given supervisor as necessary.

The `child_spec` function should end with a call to `Supervisor.Spec.worker/3` or to `Supervisor.Spec.supervisor/3`. Populator will use that spec to add every new children to the supervisor tree.

The `desired_children` function should return a list of children data, with all the state needed by the `child_spec` function for each of them.

We could use `Populator.run/3` directly, just like:

```elixir
:ok = Populator.run(MySupervisor, my_spec_fun, my_desired_fun)
```

But is much better to use one of `Populator.Receiver.run/1` or `Populator.Looper.run/1`. This way, every given `step` secs, or after receiving some specific message, `Populator` will run the `desired_children` function, and compare that list with the actual children of the given supervisor.

If any new child needs to be added, it will call the `child_spec` function for each of them to get the needed specs and use them to add every new child to the supervisor. If there are too many children, `Populator` will get the exceeding ones out of the supervision tree and kill them all.

Every children should have a registered unique name, so that `Populator` can identify exactly which ones should die.

## `desired_children` function

The `desired_children` function must return a list of children data, with all the state needed by the `child_spec` function for each of them. For example:

```elixir
# create desired_children function for 5 children
desired_children = fn(_opts)->
  [[name: :w1],[name: :w2],[name: :w3],[name: :w4],[name: :w5]]
end
```

A more useful case could be to get that list from a database, or from other dynamic resource, like this:

```elixir
desired_children = fn(_opts)->
  Mongo.db("mydb")
  |> Mongo.Db.collection("workers")
  |> Mongo.Collection.find
  |> Enum.to_list
end
```

Thus when the list of workers returned by the database changes, then `Populator` will adapt the actual workers under the supervisor to match that list.

## `child_spec` function

The `child_spec` function is given a member of the list returned by the `desired_children` function, and returns the children specification for the corresponding child. This usually means just a call to `Supervisor.Spec.worker/3` or `Supervisor.Spec.supervisor/3`.

For example, this `child_spec` function returns the children specification that wraps some `MyModule.worker_fun/1` in a `Task` and adds it to the supervisor using its unique `:name` as id:

```elixir
# your code
defmodule MyModule do
  def worker_fun(args) do
    # register our unique name
    true = Process.register(self,args[:name])
    # do some actual work here ...
  end
end

# the child_spec function
spec_fun = fn(data, _opts)->
             Supervisor.Spec.worker(Task,
                                    [MyModule, :worker_fun, [data]],
                                    [id: data[:name]]) # child id
           end
```

By now, every child must have a registered name, and it should be also used as the child `:id` on the spec. `Populator` will use it to know whether that particular child is alive inside the target supervisor.

## `Populator.Looper`

One way to use `Populator` is by starting a looper process that checks our supervisor every once in a while. We do this using `Populator.Looper.run/1` like this:

```elixir
# args expected by `Populator.run/3`
run_args = [MySupervisor, my_spec_fun, my_desired_fun]

# spawn the loop runner, let it loop every 30sec
args = [step: 30000, name: :my_looper, run_args: run_args]
Task.async fn-> Populator.Looper.run(args) end

# `MySupervisor` children pool will be adapted every 30sec.
```

Usually you may want the looper `Task` to be in your supervision tree, like this:

```elixir
worker(Task, [Populator.Looper,:run,[args]])
```

## `Populator.Receiver`

Another way to use `Populator` is by starting a receiver process and then sending it a `:populate` message whenever we want it to adapt our supervisor. We can use `Populator.Receiver.run/1` like this:

```elixir
# args expected by `Populator.run/3`
run_args = [MySupervisor, my_spec_fun, my_desired_fun]

# spawn the receiver process inside a `Task`
args = [name: :my_receiver, run_args: run_args]
Task.async fn-> Populator.Receiver.run(args) end

# Send it a message whenever we want `MySupervisor` to be adapted.
send :my_receiver, :populate
```

Usually you may want the receiver `Task` to be in your supervision tree, like this:

```elixir
worker(Task, [Populator.Receiver,:run,[args]])
```

## TODOs

* Get it stable on production (then get to 1.0)
* Accept anonymous supervisor
* Accept anonymous children
