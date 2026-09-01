# ui

`ui` binds reactive state and animation to Roblox UI that already exists in Studio. It does not create Instances, manage components, or render a virtual tree.

```lua
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

The full guides and generated API reference are published at
[twistedsignal.github.io/ui](https://twistedsignal.github.io/ui/).

- `value`, `derive`, `peek`, `effect`, and `fromObservable` provide callable reactive values backed by Rx Observables. The project uses `nightcycle/rx`, which packages Quenty's Rx implementation for Wally.
- `bind` resolves existing properties, events, and children. Its cleanup function owns the whole nested binding.
- `spring`, `accelTween`, `tween`, `impulse`, and `snap` use one motion scheduler. The acceleration tween vendors Nevermore's dependency-free analytic implementation.
- `ease` contains the standard easing functions. `bezier(x1, y1, x2, y2)` creates a cubic Bézier easing function.
- `to`, `wait`, `call`, `parallel`, `sequence`, and `play` are small tagged-data animation commands.
- `expect` provides synchronous fluent assertions, including deep equality and negation through `.never`.

`fromObservable(observable)()` throws until the source emits once. Calling it does not create a permanent subscription. Subscription begins when the returned value is observed.

## Development

Run `lest` for tests and `rojo build default.project.json -o ui.rbxlx` for the project build. Run `npm install` followed by `npm run docs:dev` to preview the documentation. See [CONTRIBUTING.md](CONTRIBUTING.md).

MIT licensed. Copyright 2026 Twisted Signal.
