---
sidebar_position: 4
---

# Motion

`ui.tween` and `ui.spring` turn any reactive input into a read-only animated
value. Bind that value to one or more Instance properties.

## Tweens

Pass a `TweenInfo` to use Roblox easing styles and directions. Retargeting starts
at the current interpolated value.

```lua
local open = ui.value(false)
local transparency = ui.tween(function(): number
	return if open() then 0 else 1
end, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))

ui.bind(panel, {
	BackgroundTransparency = transparency,
})
```

Tweenable values include numbers, `Vector2`, `Vector3`, `Color3`, `CFrame`,
`UDim`, and `UDim2`. An unsupported type produces an error when interpolation
starts.

## Springs

Springs use frequency in hertz and a damping ratio. They preserve velocity when
the target changes and stop frame updates after settling.

```lua
local scale = ui.spring(function(): number
	return if pressing() then 0.92 else 1
end, {
	frequency = 8,
	damping = 0.72,
	initial = 1,
})

ui.bind(button, {
	UIScale = { Scale = scale },
})
```

Motion values are owned by the bind that consumes them. Stopping the bind removes
their subscriptions and scheduled frame work.
