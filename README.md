# ui

`ui` binds reactive state and animation to Roblox UI that already exists in Studio. It does not create Instances, manage components, or render a virtual tree.

```luau
local ui = require("path/to/ui")

local open = ui.value(false)
local scale = ui.spring(function(): number
	return if open() then 1 else 0.9
end, { speed = 24, damping = 0.75 })

local cleanup = ui.bind(ScreenGui, {
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

## Install

Pin the package with Wally, then require the resulting module with a string require. This repository itself uses Rokit:

```sh
rokit install
wally install
rojo build default.project.json -o ui.rbxlx
```

## API

- `value`, `derive`, `peek`, `effect`, and `fromObservable` provide callable reactive values backed by Nightcycle Rx Observables.
- `bind` resolves existing properties, events, and children. Its cleanup function owns the whole nested binding.
- `spring`, `tween`, `impulse`, and `snap` use one motion scheduler. `accelTween` fails clearly because no authoritative AccelTween dependency was available.
- `ease` contains the standard easing functions. `bezier(x1, y1, x2, y2)` creates a cubic Bézier easing function.
- `to`, `wait`, `call`, `parallel`, `sequence`, and `play` are small tagged-data animation commands.
- `expect` provides synchronous fluent assertions, including deep equality and negation through `.never`.

`fromObservable(observable)()` throws until the source emits once. Calling it does not create a permanent subscription. Subscription begins when the returned value is observed.

## Development

Run `lest` for tests and `rojo build default.project.json -o ui.rbxlx` for the project build. See [CONTRIBUTING.md](CONTRIBUTING.md).

MIT licensed. Copyright 2026 Twisted Signal.
