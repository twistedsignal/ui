# ui

`ui` binds reactive state and animation to Roblox UI that already exists in Studio. It does not create Instances, manage components, or render a virtual tree.

```lua
local ui = require("path/to/ui")

local open = ui.value(false)
local scale = ui.spring(function(): number
	return if open() then 1 else 0.9
end, { frequency = 7, damping = 0.75 })

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
rojo build dev.project.json -o ui.rbxlx
```

## API

The full guides and generated API reference are published at
[twistedsignal.github.io/ui](https://twistedsignal.github.io/ui/).

- `value`, `derive`, `effect`, and `batch` provide synchronous reactive state backed by Rx Observables. The project uses `nightcycle/rx`, which packages Quenty's Rx implementation for Wally.
- `bind` composes property, event, child, fragment, and reactive-structure bindings. Stopping a bind disposes its work and restores captured properties.
- `tween` accepts `TweenInfo`. `spring` accepts `frequency`, `damping`, and an optional initial value.
- `cleanup` and `untrack` control reactive lifetime and dependency tracking.
- `attribute` and `property` create two-way adapters for Roblox-owned state.
- `fromObservable` and `toObservable` convert between Rx Observables and reactive values.

## Development

Run `lest` for tests and `rojo build dev.project.json -o ui.rbxlx` for the development place. Run `npm install` followed by `npm run docs:dev` to preview the documentation. See [CONTRIBUTING.md](CONTRIBUTING.md).

MIT licensed. Copyright 2026 Twisted Signal.
