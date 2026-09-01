--!strict

const AccelTweenObject = require("./AccelTweenObject")
const Metadata = require("./Metadata")
const Scheduler = require("./Scheduler")
const Source = require("./Source")
const Types = require("./../reactive/Types")
const Value = require("./../reactive/Value")

export type Config = { acceleration: number? }

const AccelTween = {}

function AccelTween.new(input: Types.Reactive<number>, config: Config?): Types.ReadonlyValue<number>
	const options: Config = config or {}
	const acceleration: number = options.acceleration or 30
	assert(acceleration >= 0, "ui.accelTween: acceleration must be non-negative")
	const backend = AccelTweenObject.new(acceleration)
	local output: Types.Value<number>? = nil
	local stopStep: (() -> ())? = nil

	const function schedule(): ()
		if stopStep then
			return
		end
		stopStep = Scheduler.add(function(_deltaTime: number): boolean
			const currentOutput = output :: Types.Value<number>
			currentOutput(backend.p)
			if backend.rtime > 0 then
				return true
			end
			currentOutput(backend.t)
			stopStep = nil
			return false
		end)
	end

	const cleanup: () -> () = Source.observe(input, function(target: number): ()
		if output == nil then
			backend:SetTarget(target, true)
			output = Value.new(target)
			return
		end
		backend:SetTarget(target)
		schedule()
	end)
	assert(output, "ui.accelTween: source did not synchronously produce an initial value")
	const currentOutput = output :: Types.Value<number>
	const readonly = Value.readonly(function(): number
		return currentOutput()
	end, currentOutput.observable)
	Metadata.set(readonly, {
		snap = function(): ()
			backend:SetTarget(backend.t, true)
			currentOutput(backend.t)
			if stopStep then
				stopStep()
				stopStep = nil
			end
		end,
		cleanup = function(): ()
			cleanup()
			if stopStep then
				stopStep()
				stopStep = nil
			end
		end,
	})
	return readonly
end

return table.freeze(AccelTween)
