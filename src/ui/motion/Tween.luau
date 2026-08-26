--!strict

local Easing = require("@self/Easing")
local Interpolate = require("@self/Interpolate")
local Metadata = require("@self/Metadata")
local Scheduler = require("@self/Scheduler")
local Source = require("@self/Source")
local Types = require("./../reactive/Types")
local Value = require("./../reactive/Value")

export type Config = { duration: number?, easing: Easing.Easing? }

local Tween = {}

function Tween.new<T>(input: Types.Reactive<T>, config: Config?): Types.ReadonlyValue<T>
	const options: Config = config or {}
	local duration = options.duration or 0.2
	local easing = options.easing or Easing.linear
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
			local alpha = math.min(elapsed / duration, 1)
			currentOutput(Interpolate.value(from, nextTarget, easing(alpha)))
			if alpha < 1 then return true end
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
