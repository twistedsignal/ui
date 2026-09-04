--!strict

export type Easing = (number) -> number

local Easing = {}

function Easing.linear(t: number): number return t end
function Easing.quadIn(t: number): number return t * t end
function Easing.quadOut(t: number): number return 1 - (1 - t) * (1 - t) end
function Easing.quadInOut(t: number): number return if t < 0.5 then 2 * t * t else 1 - ((-2 * t + 2) ^ 2) / 2 end
function Easing.cubicIn(t: number): number return t ^ 3 end
function Easing.cubicOut(t: number): number return 1 - (1 - t) ^ 3 end
function Easing.cubicInOut(t: number): number return if t < 0.5 then 4 * t ^ 3 else 1 - ((-2 * t + 2) ^ 3) / 2 end
function Easing.sineIn(t: number): number return 1 - math.cos(t * math.pi / 2) end
function Easing.sineOut(t: number): number return math.sin(t * math.pi / 2) end
function Easing.sineInOut(t: number): number return -(math.cos(math.pi * t) - 1) / 2 end
function Easing.backOut(t: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function Easing.cubicBezier(x1: number, y1: number, x2: number, y2: number): Easing
	assert(x1 >= 0 and x1 <= 1, "ui.bezier: x1 must be between 0 and 1")
	assert(x2 >= 0 and x2 <= 1, "ui.bezier: x2 must be between 0 and 1")
	local function component(t: number, a: number, b: number): number
		local inverse = 1 - t
		return 3 * inverse * inverse * t * a + 3 * inverse * t * t * b + t ^ 3
	end
	return function(x: number): number
		local t = math.clamp(x, 0, 1)
		for _index: number = 1, 8 do
			local estimate = component(t, x1, x2) - x
			local derivative = 3 * (1 - t) ^ 2 * x1 + 6 * (1 - t) * t * (x2 - x1) + 3 * t ^ 2 * (1 - x2)
			if math.abs(derivative) < 1e-7 then break end
			t = math.clamp(t - estimate / derivative, 0, 1)
		end
		local low: number = 0
		local high: number = 1
		for _index: number = 1, 10 do
			local estimate: number = component(t, x1, x2)
			if math.abs(estimate - x) <= 1e-7 then
				break
			end
			if estimate < x then
				low = t
			else
				high = t
			end
			t = (low + high) / 2
		end
		return component(t, y1, y2)
	end
end

return table.freeze(Easing)
