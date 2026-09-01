---
sidebar_position: 2
---

# Reactive state

## Values

`ui.value(initial)` returns a callable value. Call it with no arguments to read
the current value. Pass one argument to update it.

```luau
local count = ui.value(0)
print(count())
count(count() + 1)
```

## Derived values

`ui.derive` tracks every reactive value read by its function. It recomputes when
one of those dependencies changes.

```luau
local doubled = ui.derive(function(): number
	return count() * 2
end)
```

Use `ui.peek(value)` when you need the current value without creating a reactive
dependency.

## Effects

`ui.effect` runs immediately. It runs again when a value read during the last run
changes. Keep the returned cleanup function and call it when the effect is no
longer needed.

```luau
local stop = ui.effect(function(): ()
	print(`Count is {count()}`)
end)

stop()
```

## Rx observables

`ui.fromObservable(observable)` adapts an Rx observable into a read-only reactive
value. Reading the value before its first emission throws. The adapter subscribes
only while something observes the returned value.
