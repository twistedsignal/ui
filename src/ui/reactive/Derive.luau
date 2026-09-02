--!strict

local Observable = require("./Observable")
local Scheduler = require("./Scheduler")
local Tracking = require("./Tracking")
local Types = require("./Types")
local Value = require("./Value")

type Dependency = Tracking.Dependency
type Subscription = Types.Subscription

local function derive<T>(compute: () -> T): Types.ReadonlyValue<T>
	local cached: T
	local hasCached = false
	local dirty = true
	local evaluating = false
	local active = false
	local invalidated = false
	local rank = 1
	local dependencies: { [Dependency]: Subscription } = {}
	local sinks: { [number]: any } = {}
	local reactiveListeners: { [number]: () -> () } = {}
	local nextId = 0
	local callable: any

	local evaluate: () -> T
	local refreshSubscriptions: ({ [Dependency]: boolean }) -> ()
	local invalidate: () -> ()
	local publish: () -> ()

	refreshSubscriptions = function(seen: { [Dependency]: boolean }): ()
		for dependency, subscription in dependencies do
			if not seen[dependency] then
				subscription:Destroy()
				dependencies[dependency] = nil
			end
		end
		for dependency in seen do
			if dependencies[dependency] then
				continue
			end
			dependencies[dependency] = dependency:_subscribeReactive(invalidate)
		end
	end

	evaluate = function(): T
		if evaluating then
			error("ui.derive: Circular dependency detected", 2)
		end
		evaluating = true
		local seen: { [Dependency]: boolean } = {}
		local ok, result = xpcall(function(): T
			return Tracking.capture(function(dependency: Dependency): ()
				seen[dependency] = true
			end, compute)
		end, debug.traceback)
		evaluating = false
		if not ok then
			error(result, 0)
		end
		local nextRank = 1
		for dependency in seen do
			nextRank = math.max(nextRank, dependency._rank + 1)
		end
		rank = nextRank
		callable._rank = rank
		cached = result :: T
		hasCached = true
		dirty = false
		if active then
			refreshSubscriptions(seen)
		end
		return cached
	end

	publish = function(): ()
		if not invalidated then
			return
		end
		invalidated = false
		if dirty then
			evaluate()
		end
		for _, sink in sinks do
			sink:Fire(cached)
		end
	end

	invalidate = function(): ()
		dirty = true
		if invalidated then
			return
		end
		invalidated = true
		for _, listener in reactiveListeners do
			listener()
		end
		Scheduler.enqueue(callable, rank, publish)
	end

	local observable: Types.Observable<T> = Observable.new(function(sink: any): () -> ()
		nextId += 1
		local id = nextId
		sinks[id] = sink
		if not active then
			active = true
			evaluate()
		elseif dirty then
			evaluate()
		end
		sink:Fire(cached)
		return function(): ()
			sinks[id] = nil
			if next(sinks) or next(reactiveListeners) then
				return
			end
			active = false
			for dependency, subscription in dependencies do
				subscription:Destroy()
				dependencies[dependency] = nil
			end
		end
	end)

	callable = { observable = observable, _rank = rank }
	function callable._subscribeReactive(_self: any, listener: () -> ()): Subscription
		nextId += 1
		local id = nextId
		reactiveListeners[id] = listener
		if not active then
			active = true
			evaluate()
		elseif dirty then
			evaluate()
		end
		return {
			Destroy = function(): ()
				reactiveListeners[id] = nil
				if next(sinks) or next(reactiveListeners) then
					return
				end
				active = false
				for dependency, subscription in dependencies do
					subscription:Destroy()
					dependencies[dependency] = nil
				end
			end,
		}
	end

	return Value.readonly(function(): T
		if not active or dirty or not hasCached then
			return evaluate()
		end
		return cached
	end, observable, callable) :: any
end

return derive
