---
sidebar_position: 1
---

# Getting started

`ui` connects reactive state and animation to UI that you built in Roblox Studio.
It does not create Instances or render a component tree.

## Install

Add the package to `wally.toml`:

```toml
[dependencies]
ui = "twistedsignal/ui@0.2.1"
```

Run `wally install`, then map the generated `Packages` directory into your Rojo
project. Require the package from the mapped location:

```lua
local ui = require(ReplicatedStorage.Packages.ui)
```

## Bind existing UI

The keys in a binding tree resolve in this order: property, event, then child.
A property accepts a constant, reactive value, Rx observable, or reactive
expression. An event accepts a callback. A child accepts another binding table.

```lua
local open = ui.value(false)
local scale = ui.spring(function(): number
	return if open() then 1 else 0.9
end, { frequency = 7, damping = 0.75 })

local cleanup = ui.bind(screenGui, {
	Panel = {
		Visible = open,
		UIScale = { Scale = scale },
		Toggle = {
			Activated = function(): ()
				open(not open())
			end,
		},
	},
})
```

Call `cleanup()` when the UI is removed. Calling it more than once is safe. The
bind also stops itself when its root Instance is destroyed.

## Next

Read [Reactive state](reactive-state.md) for values and effects, or
[Motion](motion-and-animation.md) for springs and tweens. The API tab contains
the generated reference.
