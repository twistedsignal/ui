---
sidebar_position: 2
---

# Reactive state

The reactive APIs run synchronously. An ordinary write finishes all resulting
derived work, effects, and bindings before the write returns. `ui.batch` groups
several writes into one synchronous propagation cycle; it does not wait for a
frame, spawn a task, or change Roblox scheduling.

## Which API should I use?

| Need                         | API              |
| ---------------------------- | ---------------- |
| Writable state               | `value`          |
| Computed read-only state     | `derive`         |
| Reactive Instance properties | binding function |
| Non-property side effects    | `effect`         |
| Group related state changes  | `batch`          |
| Read without tracking        | `untrack`        |
| Register owned cleanup       | `cleanup`        |

## Values and derived values

`ui.value(initial)` returns writable state. Call it without arguments to read
the current value and with one argument to write it. A write takes effect at
once. If `newValue == currentValue`, the write does nothing and sends no
notification.

`ui.derive(compute)` returns a read-only value. It records the values read by
`compute`, caches the result, and recomputes when a recorded dependency changes.
Dependencies are dynamic: every computation replaces the previous dependency
set. A branch that is no longer read stops triggering the derived value.

```lua
local count = ui.value(0)
local doubled = ui.derive(function(): number
	return count() * 2
end)
```

Derived results do not use equality deduplication. A dependency change can
notify consumers even when `compute` returns a result equal to its cached
result. Use equality checks inside an effect if the external operation needs
stricter deduplication.

`ui.untrack(run)` executes `run` without adding any reads to the current effect
or derived computation. It returns the callback's result. It does not freeze a
value or prevent later writes.

## Batches

`ui.batch(run)` calls `run` immediately and returns all callback results. Writes
inside it change their source values at once, so later reads in the same callback
see the latest values. Reading a derived value also computes the current result,
including every earlier write in the batch.

The following work waits until the outermost batch callback finishes:

- public observable notifications from `ui.value`;
- scheduled derived recomputation and derived observable notifications;
- effect reruns and their cleanup;
- reactive binding functions and their Instance property assignments.

Invalidation still crosses the entire dependency graph as each write happens.
At the end, ui recomputes derived values in dependency order and runs effects
after derived values settle. Each affected derived value, effect, or binding
function runs at most once for the final state. This prevents diamond-shaped
graphs from exposing a mix of old and new inputs.

```lua
local firstName = ui.value("")
local lastName = ui.value("")

local fullName = ui.derive(function()
	return `{firstName()} {lastName()}`
end)

ui.batch(function()
	firstName("Ada")
	lastName("Lovelace")
end)
```

Nested batches share their parent's propagation cycle. An empty batch has no
observable effect. If the callback throws, ui finishes propagation for writes
that already happened, restores batching state, then rethrows the original
error with its traceback. Later writes continue normally.

Batch related writes that represent one logical change. A single ordinary write
already propagates synchronously and does not need a batch. Do not use a batch to
store computed state:

```lua
-- Prefer derive for this relationship.
local area = ui.derive(function(): number
	return width() * height()
end)
```

`ui.batch` only coordinates ui values and work reached through their reactive
dependencies. An unrelated external Rx Observable can still emit while a batch
callback is running according to that Observable's own scheduling rules.

## Effects and cleanup

`ui.effect(run)` calls `run` immediately. It reruns synchronously when a value
read by the previous execution changes. Like `derive`, it replaces its tracked
dependency set after every run.

Before a rerun, ui disposes the previous execution's owned resources. The
callback returned by the effect runs first. Callbacks registered with
`ui.cleanup` then run in reverse registration order. Calling the function
returned by `effect` performs the same cleanup and unsubscribes the effect;
calling it again does nothing.

```lua
local stop = ui.effect(function(): () -> ()
	print(`Count is {count()}`)
	return function(): ()
		print("cleaning the previous run")
	end
end)

stop()
```

`ui.cleanup(dispose)` registers a resource with the current effect execution or
tracked binding function. Calling it without an active reactive owner is an
error. Reactive ownership is not general Roblox ownership. ui does not destroy
an Instance that your code created or disconnect a connection that your code
made unless you register that work with `cleanup` or return an effect cleanup.

## Bindings

Use a binding function for a reactive Instance property:

```lua
local stop = ui.bind(label, {
	Text = function(): string
		return fullName()
	end,
})
```

The function is an effect with dynamic dependencies and follows the same batch
and cleanup rules. `bind` owns the subscriptions, event connections, and
reactive branches that it creates. Stopping the bind restores captured property
values. It does not destroy the target Instance or any child Instance, and it
does not own resources created outside its tracked functions. See
[Bindings](./bindings.md) for composition and property-layer rules.

## Roblox adapters and Rx Observables

`ui.attribute(instance, name, default)` creates a two-way value for an attribute.
`ui.property(instance, name)` does the same for a writable property. External
Instance changes update reactive consumers, and writing the value updates the
Instance.

`ui.fromObservable(source)` wraps an Rx Observable in a callable
`ui.ReadonlyValue<T>`. Reading it returns the latest emitted value. The first
read requires a synchronous emission; subscribe to `.observable` before reading
an asynchronous source. `ui.toObservable(input)` converts a value, read-only
value, tracked function, or constant into an Rx Observable.
