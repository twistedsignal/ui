--!strict

local lest = require("@lest")
local reactive = require("./init")

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

	it("rejects readonly writes", function(): ()
		local result = reactive.derive(function(): number return 1 end)
		expect(function(): () (result :: any)(2) end).toThrow("readonly Value")
	end)
end)
