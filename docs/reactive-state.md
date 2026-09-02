---
sidebar_position: 2
---

# Reactive state

## Values

`ui.value(initial)` returns a callable value. Call it with no arguments to read
the current value. Pass one argument to update it.

```lua
local count = ui.value(0)
print(count())
count(count() + 1)
```

## Derived values

`ui.derive` tracks every reactive value read by its function. It recomputes when
one of those dependencies changes.

```lua
local doubled = ui.derive(function(): number
	return count() * 2
end)
```

Use `ui.untrack(function() return value() end)` when you need a current value
without creating a dependency.

## Effects

`ui.effect` runs immediately and again when a value read during the last run
changes. A cleanup returned by the effect runs before the next execution and when
the effect stops.

```lua
local stop = ui.effect(function(): () -> ()
	print(`Count is {count()}`)
	return function(): ()
		print("cleaning the previous run")
	end
end)

stop()
```

Call `ui.cleanup(callback)` inside an effect, bind, or reactive branch when one run
owns several resources. Calling it outside an active owner is an error.

## Roblox adapters

`ui.attribute(instance, name, default)` creates a two-way value for an attribute.
`ui.property(instance, name)` does the same for a writable Roblox property.
External Instance changes update reactive consumers, and writing the value updates
the Instance.

```lua
local mode = ui.attribute(button, "Mode", "Default")
local position = ui.property(scrollingFrame, "CanvasPosition")

mode("Manual")
print(position())
```

## Rx Observables

`ui.fromObservable(source)` wraps an Rx Observable in a callable
`ui.ReadonlyValue<T>`. Reading it returns the latest emitted value. The first
read requires a synchronous emission. For an asynchronous source, subscribe to
the value's `.observable` before reading it.

`ui.toObservable(input)` converts a value, read-only value, tracked function, or
constant into an Rx Observable.

```lua
local count: ui.ReadonlyValue<number> = ui.fromObservable(countObservable)
local doubled: ui.Observable<number> = ui.toObservable(function(): number
	return count() * 2
end)
```
