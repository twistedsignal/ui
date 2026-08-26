--!strict

local Observable = require("./Observable")
local Tracking = require("./Tracking")
local Types = require("./Types")

export type Value<T> = Types.Value<T>
export type ReadonlyValue<T> = Types.ReadonlyValue<T>
export type Observable<T> = Types.Observable<T>

local Value = {}

function Value.readonly<T>(read: () -> T, observable: Observable<T>): ReadonlyValue<T>
	local callable = { observable = observable }
	return setmetatable(callable, {
		__call = function(_self: typeof(callable), ...: T): T
			if select("#", ...) > 0 then error("ui: Cannot write to a readonly Value", 2) end
			Tracking.read(callable :: any)
			return read()
		end,
	}) :: any
end

function Value.new<T>(initial: T): Value<T>
	local current = initial
	local listeners: { [number]: (T) -> () } = {}
	local nextId = 0
	local observable: Observable<T> = Observable.new(function(sink: any): (() -> ())
		nextId += 1
		local id = nextId
		listeners[id] = function(value: T): () sink:Fire(value) end
		sink:Fire(current)
		return function(): () listeners[id] = nil end
	end)
	local callable = { observable = observable }
	return setmetatable(callable, {
		__call = function(_self: typeof(callable), ...: T): T?
			if select("#", ...) == 0 then
				Tracking.read(callable :: any)
				return current
			end
			local newValue = select(1, ...)
			if current == newValue then return nil end
			current = newValue
			for _, listener in listeners do listener(newValue) end
			return nil
		end,
	}) :: any
end

return Value
