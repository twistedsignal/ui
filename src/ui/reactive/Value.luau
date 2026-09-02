--!strict

local Observable = require("./Observable")
local Scheduler = require("./Scheduler")
local Tracking = require("./Tracking")
local Types = require("./Types")

export type Value<T> = Types.Value<T>
export type ReadonlyValue<T> = Types.ReadonlyValue<T>
export type Observable<T> = Types.Observable<T>

local Value = {}

function Value.readonly<T>(read: () -> T, observable: Observable<T>, fields: any?): ReadonlyValue<T>
	local callable = fields or { observable = observable }
	callable.observable = observable
	callable._rank = callable._rank or 0
	if not callable._subscribeReactive then
		function callable._subscribeReactive(_self: any, invalidate: () -> ()): Types.Subscription
			local subscribing = true
			local subscription = observable:Subscribe(function(_value: T): ()
				if not subscribing then
					invalidate()
				end
			end)
			subscribing = false
			return subscription
		end
	end
	return setmetatable(callable, {
		__call = function(_self: typeof(callable), ...: T): T
			if select("#", ...) > 0 then
				error("ui: Cannot write to a readonly Value", 2)
			end
			Tracking.read(callable :: any)
			return read()
		end,
	}) :: any
end

function Value.new<T>(initial: T): Value<T>
	local current = initial
	local listeners: { [number]: (T) -> () } = {}
	local reactiveListeners: { [number]: () -> () } = {}
	local nextId = 0
	local observable: Observable<T> = Observable.new(function(sink: any): () -> ()
		nextId += 1
		local id = nextId
		listeners[id] = function(value: T): ()
			sink:Fire(value)
		end
		sink:Fire(current)
		return function(): ()
			listeners[id] = nil
		end
	end)
	local callable = { observable = observable, _rank = 0 }
	function callable._subscribeReactive(_self: typeof(callable), invalidate: () -> ()): Types.Subscription
		nextId += 1
		local id = nextId
		reactiveListeners[id] = invalidate
		return {
			Destroy = function(): ()
				reactiveListeners[id] = nil
			end,
		}
	end
	return setmetatable(callable, {
		__call = function(_self: typeof(callable), ...: T): T?
			if select("#", ...) == 0 then
				Tracking.read(callable :: any)
				return current
			end
			local newValue = select(1, ...)
			if current == newValue then
				return nil
			end
			current = newValue
			Scheduler.transaction(function(): ()
				for _, invalidate in reactiveListeners do
					invalidate()
				end
				Scheduler.enqueue(callable, 0, function(): ()
					for _, listener in listeners do
						listener(current)
					end
				end)
			end)
			return nil
		end,
	}) :: any
end

return Value
