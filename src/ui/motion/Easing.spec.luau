--!strict

const lest = require("@lest")
const Easing = require("./Easing")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("motion easing", function(): ()
	it("keeps endpoints", function(): ()
		expect(Easing.linear(0)).toBe(0)
		expect(Easing.linear(1)).toBe(1)
		expect(Easing.quadOut(0)).toBe(0)
		expect(Easing.quadOut(1)).toBe(1)
	end)

	it("creates cubic bezier easing", function(): ()
		const curve = Easing.cubicBezier(0.42, 0, 0.58, 1)
		expect(math.abs(curve(0)) <= 1e-6).toBe(true)
		expect(math.abs(curve(0.5) - 0.5) <= 1e-3).toBe(true)
		expect(math.abs(curve(1) - 1) <= 1e-6).toBe(true)
	end)

	it("rejects invalid x control points", function(): ()
		expect(function(): ()
			Easing.cubicBezier(-0.1, 0, 1, 1)
		end).toThrow("x1")
	end)
end)
