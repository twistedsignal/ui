--!strict

const lest = require("@lest")
const animation = require("./init")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("animation commands", function(): ()
	it("creates tagged command data", function(): ()
		local current: number = 0
		const value = function(nextValue: number?): number?
			if nextValue ~= nil then
				current = nextValue
			end
			return current
		end
		const command = animation.to(value, 2)
		expect(command.kind).toBe("to")
		expect(command.target).toBe(2)
	end)

	it("plays calls and target writes in sequence", function(): ()
		local current: number = 0
		const value = function(nextValue: number?): number?
			if nextValue ~= nil then
				current = nextValue
			end
			return current
		end
		local called: boolean = false
		const cancel = animation.play({
			animation.to(value, 3),
			animation.call(function(): ()
				called = true
			end),
		})
		task.wait()
		expect(current).toBe(3)
		expect(called).toBe(true)
		cancel()
	end)
end)
