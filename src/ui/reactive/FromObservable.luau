--!strict

local Types = require("./Types")
local Value = require("./Value")
local Observable = require("./Observable")

local function fromObservable<T>(source: Types.Observable<T>): Types.ReadonlyValue<T>
	local current: T
	local hasCurrent = false
	local observable: Types.Observable<T> = Observable.new(function(sink: any): (() -> ())
		local subscription = source:Subscribe(function(value: T): ()
			current = value
			hasCurrent = true
			sink:Fire(value)
		end, function(...: unknown): () sink:Fail(...) end, function(): () sink:Complete() end)
		return function(): () subscription:Destroy() end
	end)
	return Value.readonly(function(): T
		if hasCurrent then return current end
		local subscription = observable:Subscribe()
		subscription:Destroy()
		if not hasCurrent then
			error("ui.fromObservable: Observable has not emitted a value; subscribe before reading it", 2)
		end
		return current
	end, observable)
end

return fromObservable
