--!strict

local Interpolate = require("./Interpolate")
local Metadata = require("./Metadata")
local Scheduler = require("./Scheduler")
local Source = require("./Source")
local Types = require("./../reactive/Types")
local Value = require("./../reactive/Value")

local Tween = {}

function Tween.new<T>(input: Types.Reactive<T>, info: TweenInfo?): Types.ReadonlyValue<T>
	local tweenInfo = info or TweenInfo.new(0.2)
	local duration = tweenInfo.Time
	local function easing(alpha: number): number
		return game:GetService("TweenService"):GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
	end
	assert(duration >= 0, "ui.tween: duration must be non-negative")
	local output: Types.Value<T>? = nil
	local target: T
	local stopStep: (() -> ())? = nil
	local generation = 0

	local cleanup = Source.observe(input, function(nextTarget: T): ()
		if not output then output = Value.new(nextTarget); target = nextTarget; return end
		const currentOutput = output :: Types.Value<T>
		local from = currentOutput()
		target = nextTarget
		generation += 1
		local ownGeneration = generation
		if stopStep then stopStep(); stopStep = nil end
		if duration == 0 then currentOutput(nextTarget); return end
		local elapsed = 0
		stopStep = Scheduler.add(function(deltaTime: number): boolean
			if generation ~= ownGeneration then return false end
			elapsed += deltaTime
			local motionDuration = duration * (if tweenInfo.Reverses then 2 else 1)
			local cycleDuration = tweenInfo.DelayTime + motionDuration
			local cycle = math.floor(elapsed / cycleDuration)
			if tweenInfo.RepeatCount >= 0 and cycle > tweenInfo.RepeatCount then
				currentOutput(if tweenInfo.Reverses then from else nextTarget)
				stopStep = nil
				return false
			end
			local cycleElapsed = elapsed - cycle * cycleDuration
			if cycleElapsed < tweenInfo.DelayTime then return true end
			local motionElapsed = cycleElapsed - tweenInfo.DelayTime
			local alpha = math.min(motionElapsed / duration, 1)
			if tweenInfo.Reverses and motionElapsed > duration then alpha = 1 - math.min((motionElapsed - duration) / duration, 1) end
			currentOutput(Interpolate.value(from, nextTarget, easing(alpha)))
			if tweenInfo.RepeatCount < 0 or cycle < tweenInfo.RepeatCount or motionElapsed < motionDuration then return true end
			stopStep = nil
			return false
		end)
	end)
	assert(output, "ui.tween: source did not synchronously produce an initial value")
	const currentOutput = output :: Types.Value<T>
	local readonly = Value.readonly(function(): T return currentOutput() end, currentOutput.observable)
	Metadata.set(readonly, {
		snap = function(): ()
			generation += 1
			if stopStep then stopStep(); stopStep = nil end
			currentOutput(target)
		end,
		cleanup = cleanup,
	})
	return readonly
end

return table.freeze(Tween)
