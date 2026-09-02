--!strict

local lest = require("@lest")
local reactive = require("./init")
local ui = require("../init")

local describe = lest.describe
local expect = lest.expect
local it = lest.it

describe("reactive core", function(): ()
	it("reads, writes, and observes values", function(): ()
		local count = reactive.value(1)
		local seen: { number } = {}
		local subscription = count.observable:Subscribe(function(value: number): () table.insert(seen, value) end)
		count(2)
		expect(count()).toBe(2)
		expect(seen).toEqual({ 1, 2 })
		subscription:Destroy()
		count(3)
		expect(seen).toEqual({ 1, 2 })
	end)

	it("updates derives and switches dependencies", function(): ()
		local chooseFirst = reactive.value(true)
		local first = reactive.value(2)
		local second = reactive.value(10)
		local selected = reactive.derive(function(): number return if chooseFirst() then first() else second() end)
		local seen: { number } = {}
		local subscription = selected.observable:Subscribe(function(value: number): () table.insert(seen, value) end)
		first(3)
		chooseFirst(false)
		first(4)
		second(11)
		expect(seen).toEqual({ 2, 3, 10, 11 })
		subscription:Destroy()
	end)

	it("supports peek and effect cleanup", function(): ()
		local tracked = reactive.value(1)
		local ignored = reactive.value(4)
		local result = reactive.derive(function(): number return tracked() + reactive.peek(ignored) end)
		local seen: { number } = {}
		local stop = reactive.effect(function(): () table.insert(seen, result()) end)
		ignored(5)
		tracked(2)
		stop()
		tracked(3)
		expect(seen).toEqual({ 5, 7 })
	end)

	it("runs effect cleanup before reruns and when stopped", function(): ()
		local source = reactive.value(1)
		local events: { string } = {}
		local stop = reactive.effect(function(): () -> ()
			local snapshot = source()
			table.insert(events, `run {snapshot}`)
			return function(): () table.insert(events, `clean {snapshot}`) end
		end)
		source(2)
		stop()
		expect(events).toEqual({ "run 1", "clean 1", "run 2", "clean 2" })
	end)

	it("supports owned cleanup and untracked reads", function(): ()
		local tracked = reactive.value(1)
		local ignored = reactive.value(10)
		local runs = 0
		local cleanups = 0
		local stop = reactive.effect(function(): (() -> ())?
			runs += tracked()
			reactive.untrack(function(): number return ignored() end)
			reactive.cleanup(function(): () cleanups += 1 end)
			return nil
		end)
		ignored(11)
		tracked(2)
		stop()
		expect(runs).toBe(3)
		expect(cleanups).toBe(2)
		expect(function(): () reactive.cleanup(function(): () end) end).toThrow("no active reactive owner")
	end)

	it("adapts attributes and properties in both directions", function(): ()
		local frame = Instance.new("Frame")
		local mode = reactive.attribute(frame, "Mode", "Default")
		expect(mode()).toBe("Default")
		mode("Manual")
		expect(frame:GetAttribute("Mode")).toBe("Manual")
		frame:SetAttribute("Mode", "Auto")
		expect(mode()).toBe("Auto")

		local visible = reactive.property(frame, "Visible")
		visible(false)
		expect(frame.Visible).toBe(false)
		frame.Visible = true
		expect(visible()).toBe(true)
		frame:Destroy()
	end)

	it("rejects readonly writes", function(): ()
		local result = reactive.derive(function(): number return 1 end)
		expect(function(): () (result :: any)(2) end).toThrow("readonly Value")
	end)

	it("converts values and Observables in both directions", function(): ()
		local source = ui.value(3)
		local converted: ui.ReadonlyValue<number> = ui.fromObservable(source.observable)
		expect(converted()).toBe(3)

		local seen: { number } = {}
		local observable: ui.Observable<number> = ui.toObservable(converted)
		local subscription = observable:Subscribe(function(value: number): () table.insert(seen, value) end)
		source(4)
		expect(converted()).toBe(4)
		expect(seen).toEqual({ 3, 4 })
		subscription:Destroy()
	end)
end)
