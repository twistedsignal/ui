--!strict

const lest = require("@lest")
const bind = require("./bind")
const Value = require("./../reactive/Value")
const reactive = require("./../reactive")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("ui.bind", function(): ()
	it("updates a property once after batched dependencies change", function(): ()
		local label = Instance.new("TextLabel")
		local first = reactive.value("Ada")
		local last = reactive.value("Byron")
		local assignments = 0
		local cleanup = bind(label, {
			Text = function(): string
				assignments += 1
				return `{first()} {last()}`
			end,
		})
		reactive.batch(function(): () first("Augusta"); last("Lovelace") end)
		expect(label.Text).toBe("Augusta Lovelace")
		expect(assignments).toBe(2)
		cleanup()
		label:Destroy()
	end)

	it("binds constants, Values, expressions, and nested children", function(): ()
		const root = Instance.new("Folder")
		root.Name = "Root"
		const label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Parent = root
		const typedRoot = (root :: any) :: Folder & { Label: TextLabel }
		const text = Value.new("one")
		const visible = Value.new(true)
		const cleanup = bind(typedRoot, {
			Label = {
				Text = text,
				Visible = function(): boolean
					return visible()
				end,
				BackgroundTransparency = 0.25,
			},
		})

		expect(label.Text).toBe("one")
		expect(label.Visible).toBe(true)
		expect(label.BackgroundTransparency).toBe(0.25)
		text("two")
		visible(false)
		expect(label.Text).toBe("two")
		expect(label.Visible).toBe(false)

		cleanup()
		text("three")
		visible(true)
		expect(label.Text).toBe("two")
		expect(label.Visible).toBe(false)
		root:Destroy()
	end)

	it("connects events and disconnects them during cleanup", function(): ()
		const event = Instance.new("BindableEvent")
		event.Name = "Action"
		local received = 0
		const cleanup = bind(event, {
			Event = function(amount: number): ()
				received += amount
			end,
		})

		event:Fire(3)
		expect(received).toBe(3)
		cleanup()
		event:Fire(2)
		expect(received).toBe(3)
		event:Destroy()
	end)

	it("reports complete paths and invalid target modes", function(): ()
		const root = Instance.new("Folder")
		root.Name = "Root"
		const missingOk, missingError = pcall(function(): ()
			(bind :: any)(root, { Missing = {} })
		end)
		expect(missingOk).toBe(false)
		expect(tostring(missingError)).toContain('Could not resolve "Root.Missing"')

		const event = Instance.new("BindableEvent")
		event.Name = "Action"
		const eventOk, eventError = pcall(function(): ()
			(bind :: any)(event, { Event = true })
		end)
		expect(eventOk).toBe(false)
		expect(tostring(eventError)).toContain('Expected function for event "Action.Event", got boolean')
		root:Destroy()
		event:Destroy()
	end)

	it("composes fragments and restores property layers", function(): ()
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Text = "initial"
		local enabled = Value.new(true)
		local bindings: bind.Binding<TextLabel> = {
			{ Text = "base" },
			function()
				return if enabled() then { Text = "active" } else nil
			end,
		}
		local cleanup = bind(label, bindings)
		expect(label.Text).toBe("active")
		enabled(false)
		expect(label.Text).toBe("base")
		cleanup()
		expect(label.Text).toBe("initial")
		label:Destroy()
	end)

	it("composes event fragments", function(): ()
		local event = Instance.new("BindableEvent")
		local calls: { number } = {}
		local bindings: bind.Binding<BindableEvent> = {
			{ Event = function(): () table.insert(calls, 1) end },
			{ Event = function(): () table.insert(calls, 2) end },
		}
		local cleanup = bind(event, bindings)
		event:Fire()
		expect(calls).toEqual({ 1, 2 })
		cleanup()
		event:Destroy()
	end)

	it("rejects ambiguous child names", function(): ()
		local root = Instance.new("Folder")
		root.Name = "Root"
		for _ = 1, 2 do
			local child = Instance.new("Folder")
			child.Name = "Duplicate"
			child.Parent = root
		end
		expect(function(): () (bind :: any)(root, { Duplicate = {} }) end).toThrow("Ambiguous child")
		root:Destroy()
	end)
end)
