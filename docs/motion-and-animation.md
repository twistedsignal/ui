---
sidebar_position: 3
---

# Motion and animation

## Motion values

Pass a reactive expression to `ui.spring`, `ui.tween`, or `ui.accelTween`. The
returned read-only value follows the expression and can be bound to an Instance
property.

```luau
local target = ui.value(0)
local position = ui.tween(function(): number
	return target()
end, {
	duration = 0.25,
	easing = ui.ease.quadOut,
})
```

Use `ui.impulse` to add spring velocity. Use `ui.snap` to move a spring to a value
immediately.

## Animation commands

Commands describe work without starting it. `ui.play` starts one command or an
array of commands. An array runs as a sequence.

```luau
local cancel = ui.play(ui.sequence({
	ui.to(opacity, 1, { tween = { duration = 0.2 } }),
	ui.wait(1),
	ui.parallel({
		ui.to(opacity, 0, { tween = { duration = 0.2 } }),
		ui.call(function(): ()
			print("closing")
		end),
	}),
}))
```

Call the returned function to cancel the active animation. Cancellation is safe
to call more than once.
