--!strict

local lest = require("@lest")
local Scheduler = require("../reactive/Scheduler")

local describe = lest.describe
local expect = lest.expect
local it = lest.it

describe("batch scheduler validation", function(): ()
	it("orders, coalesces, returns, and recovers from errors", function(): ()
		local events: { string } = {}
		local key = {}
		local first, second = Scheduler.batch(function(): (number, string)
			Scheduler.enqueue(key, 2, function(): ()
				table.insert(events, "old")
			end)
			Scheduler.enqueue(key, 1, function(): ()
				table.insert(events, "new")
			end)
			Scheduler.enqueue({}, 0, function(): ()
				table.insert(events, "first")
			end)
			return 4, "ok"
		end)
		expect(first).toBe(4)
		expect(second).toBe("ok")
		expect(events).toEqual({ "first", "new" })
		expect(function(): ()
			Scheduler.batch(function(): ()
				error("expected")
			end)
		end).toThrow("expected")
		Scheduler.transaction(function(): ()
			table.insert(events, "recovered")
		end)
		expect(events).toEqual({ "first", "new", "recovered" })
	end)
end)
