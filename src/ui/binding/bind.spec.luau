--!strict

const lest = require("@lest")
const bind = require("./bind")
const Value = require("./../reactive/Value")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("ui.bind", function(): ()
	it("binds constants, Values, expressions, and nested children", function(): ()
		const root = Instance.new("Folder")
		root.Name = "Root"
		const label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Parent = root
		const text = Value.new("one")
		const visible = Value.new(true)
		const cleanup = bind(root, {
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
			bind(root, { Missing = {} })
		end)
		expect(missingOk).toBe(false)
		expect(tostring(missingError)).toContain('Could not resolve "Root.Missing"')

		const event = Instance.new("BindableEvent")
		event.Name = "Action"
		const eventOk, eventError = pcall(function(): ()
			bind(event, { Event = true })
		end)
		expect(eventOk).toBe(false)
		expect(tostring(eventError)).toContain('Expected function for event "Action.Event", got boolean')
		root:Destroy()
		event:Destroy()
	end)
end)
