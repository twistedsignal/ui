--!strict

const lest = require("@lest")
const AccelTweenObject = require("./AccelTweenObject")
const describe = lest.describe
const it = lest.it
const expect = lest.expect

describe("AccelTween", function(): ()
	it("reaches targets with bounded acceleration", function(): ()
		local now: number = 0
		const tween = AccelTweenObject.new(4)
		tween:SetClock(function(): number
			return now
		end)
		tween:SetTarget(1)
		const duration: number = tween.rtime
		expect(duration > 0).toBe(true)
		now = duration / 2
		expect(tween.p > 0 and tween.p < 1).toBe(true)
		now = duration
		expect(math.abs(tween.p - 1) <= 1e-6).toBe(true)
		expect(math.abs(tween.v) <= 1e-6).toBe(true)
	end)

	it("snaps without retaining velocity", function(): ()
		const tween = AccelTweenObject.new(10)
		tween:SetTarget(3, true)
		expect(math.abs(tween.p - 3) <= 1e-6).toBe(true)
		expect(tween.t).toBe(3)
		expect(math.abs(tween.v) <= 1e-6).toBe(true)
	end)
end)
