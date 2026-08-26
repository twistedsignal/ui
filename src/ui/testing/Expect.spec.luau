--!strict

const lest = require("@lest")
const expectUi = require("./Expect")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("ui.expect", function(): ()
	it("supports equality, numeric, truthiness, throwing, and negation", function(): ()
		expectUi(1).toBe(1)
		expectUi({ a = { 1, 2 } }).toEqual({ a = { 1, 2 } })
		expectUi(1.001).toBeNear(1, 0.01)
		expectUi(true).toBeTruthy()
		expectUi(false).toBeFalsy()
		expectUi(nil).toBeNil()
		expectUi(function(): () error("boom") end).toThrow("boom")
		expectUi(1).never.toBe(2)
	end)

	it("formats failures", function(): ()
		const ok: boolean, message: unknown = pcall(function(): ()
			expectUi(12).toBe(10)
		end)
		expect(ok).toBe(false)
		expect(tostring(message)).toContain("Expected:")
		expect(tostring(message)).toContain("Received:")
	end)
end)
