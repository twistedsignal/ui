--!strict

local Metadata = require("@self/Metadata")
local Source = require("@self/Source")
local SpringObject = require("@self/SpringObject")
local Types = require("./../reactive/Types")
local Value = require("./../reactive/Value")

export type Config = { speed: number?, damping: number?, epsilon: number? }

local Spring = {}

function Spring.new<T>(input: Types.Reactive<T>, config: Config?): Types.ReadonlyValue<T>
	const options: Config = config or {}
	local backend: SpringObject.SpringObject<T>? = nil
	local output: Types.Value<T>? = nil
	local springSubscription: Types.Subscription? = nil
	local epsilon = options.epsilon or 1e-4
	assert((options.speed or 20) >= 0, "ui.spring: speed must be non-negative")
	assert((options.damping or 1) >= 0, "ui.spring: damping must be non-negative")
	assert(epsilon > 0, "ui.spring: epsilon must be positive")

	local cleanup = Source.observe(input, function(target: T): ()
		if not backend then
			backend = SpringObject.new(target, options.speed, options.damping)
			const initializedBackend = backend :: SpringObject.SpringObject<T>
			initializedBackend:SetEpsilon(epsilon)
			output = Value.new(target)
			springSubscription = initializedBackend:Observe():Subscribe(function(value: T): ()
				(output :: Types.Value<T>)(value)
			end)
			return
		end
		(backend :: SpringObject.SpringObject<T>):SetTarget(target)
	end)
	assert(output, "ui.spring: source did not synchronously produce an initial value")
	const currentOutput = output :: Types.Value<T>
	const currentBackend = backend :: SpringObject.SpringObject<T>
	local readonly = Value.readonly(function(): T return currentOutput() end, currentOutput.observable)
	Metadata.set(readonly, {
		impulse = function(amount: unknown): () currentBackend:Impulse(amount :: T) end,
		snap = function(): ()
			currentBackend:SetTarget(currentBackend.Target, true)
			currentOutput(currentBackend.Target)
		end,
		cleanup = function(): ()
			cleanup()
			if springSubscription then
				springSubscription:Destroy()
				springSubscription = nil
			end
			currentBackend:Destroy()
		end,
	})
	return readonly
end

function Spring.impulse(value: unknown, amount: unknown): ()
	local backend = Metadata.get(value)
	assert(backend and backend.impulse, "ui.impulse: expected a spring motion Value")
	backend.impulse(amount)
end

function Spring.snap(value: unknown): ()
	local backend = Metadata.get(value)
	assert(backend and backend.snap, "ui.snap: this Value does not support snapping")
	backend.snap()
end

return table.freeze(Spring)
