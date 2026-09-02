---
sidebar_position: 3
---

# Bindings

`ui.bind(instance, bindings)` attaches behavior to UI that already exists. Named
keys resolve to a property, event, or direct child. Array entries compose binding
fragments.

```lua
local stop = ui.bind(button, {
	baseStyle,
	hoverSounds(),

	Text = function(): string
		return if busy() then "Please wait" else label()
	end,

	Activated = submit,

	UIScale = {
		Scale = animatedScale,
	},
})
```

Property functions are tracked expressions. Event functions are callbacks. Child
tables recurse into an existing child with the exact key name.

`ui.Binding<T>` is exported for annotations. Its generic parameter records the
root Instance type, while its entries stay open because Roblox properties,
events, named children, and numeric fragments share the same table. `bind`
checks those entries when it mounts them. This avoids recursive compile-time
type evaluation on large Instance types.

```lua
local bindings: ui.Binding<TextButton> = {
	Text = "Save",
	Activated = function(inputObject: InputObject, clickCount: number)
		print(inputObject, clickCount)
	end,
	UIScale = {
		Scale = 1,
	},
}

ui.bind(existingButton, bindings)
```

## Reactive structure

An array function can return a binding fragment or `nil`. Its dependencies decide
when the branch is replaced.

```lua
ui.bind(button, {
	{ BackgroundTransparency = 0 },

	function()
		return if selected() then {
			BackgroundTransparency = 0.2,
			UIStroke = { Enabled = true },
		} else nil
	end,
})
```

Later active fragments take priority. Removing a fragment reveals the previous
writer. Stopping the root bind restores the property value captured before the
first writer and disconnects every event and reactive branch.

Fragments are ordinary tables, so components are ordinary functions that return
tables. No component constructor or merge helper is needed.
