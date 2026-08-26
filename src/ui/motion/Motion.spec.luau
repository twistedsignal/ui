--!strict

const lest = require("@lest")
const Easing = require("./Easing")
const Interpolate = require("./Interpolate")
const SpringObject = require("./SpringObject")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("motion", function(): ()
	it("interpolates supported Roblox values", function(): ()
		expect(Interpolate.value(0, 10, 0.25)).toBe(2.5)
		expect(Interpolate.value(Vector2.zero, Vector2.new(10, 20), 0.5)).toBe(Vector2.new(5, 10))
		expect(Interpolate.value(Color3.new(0, 0, 0), Color3.new(1, 1, 1), 0.5)).toBe(Color3.new(0.5, 0.5, 0.5))
	end)

	it("uses the synced SpringObject behavior", function(): ()
		local now: number = 0
		const spring = SpringObject.new(0, 10, 1)
		spring:SetClock(function(): number
			return now
		end)
		spring:SetTarget(1)
		now = 0.1
		expect(spring.Position > 0).toBe(true)
		expect(spring.Position < 1).toBe(true)
		spring:Impulse(1)
		expect(spring:IsAnimating()).toBe(true)
		spring:SetTarget(1, true)
		expect(spring.Position).toBe(1)
		spring:Destroy()
	end)

	it("keeps cubic bezier endpoints", function(): ()
		const curve = Easing.cubicBezier(0.42, 0, 0.58, 1)
		expect(math.abs(curve(0)) <= 1e-6).toBe(true)
		expect(math.abs(curve(1) - 1) <= 1e-6).toBe(true)
	end)
end)
