# Populator

[![Build Status](https://travis-ci.org/rubencaro/populator.svg?branch=master)](https://travis-ci.org/rubencaro/populator)

A library to help control the population of a given supervisor.

It takes some params, such as the function to get new child specs, or the function to get the list of desired children, and it spawns (or kills) children on the given supervisor as necessary.

The `desired_children` function should return a list of children data, with all the state needed by the `child_spec` function for each of them.

The `child_spec` function should end with a call to `Supervisor.Spec.worker/3`. Populator will use that spec to add new children to the supervisor tree.

Every given `step` secs, or after receiving some specific message, `Populator` will run the `desired_children` function, and compare that list with the actual children of the given supervisor. If any children need to be added, it will call the `child_spec` function for each of them to get the needed specs and use them to add every new child to the supervisor. If there are too many children, `Populator` will get the exceeding ones out of the supervision tree and kill them all. Every children should have a registered unique name, so that `Populator` can identify exactly which ones should die.

## TODOs

* Documentation & examples
* Accept anonymous children
* Add to hex
* Get it stable on production (then get to 1.0)
