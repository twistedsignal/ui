--!strict

local Observable = require("./Observable")
local Tracking = require("./Tracking")
local Types = require("./Types")
local Value = require("./Value")

type Dependency = Tracking.Dependency
type Subscription = Types.Subscription

local function derive<T>(compute: () -> T): Types.ReadonlyValue<T>
	local cached: T
	local hasCached = false
	local evaluating = false
	local active = false
	local dependencies: { [Dependency]: Subscription } = {}
	local sinks: { [number]: any } = {}
	local nextId = 0

	local evaluate: () -> T
	local refreshSubscriptions: ({ [Dependency]: boolean }) -> ()

	refreshSubscriptions = function(seen: { [Dependency]: boolean }): ()
		for dependency, subscription in dependencies do
			if not seen[dependency] then subscription:Destroy(); dependencies[dependency] = nil end
		end
		for dependency in seen do
			if dependencies[dependency] then continue end
			local initial = true
			dependencies[dependency] = dependency.observable:Subscribe(function(_value: unknown): ()
				if initial then initial = false; return end
				local nextValue = evaluate()
				for _, sink in sinks do sink:Fire(nextValue) end
			end)
		end
	end

	evaluate = function(): T
		if evaluating then error("ui.derive: Circular dependency detected", 2) end
		evaluating = true
		local seen: { [Dependency]: boolean } = {}
		local ok, result = xpcall(function(): T
			return Tracking.capture(function(dependency: Dependency): () seen[dependency] = true end, compute)
		end, debug.traceback)
		evaluating = false
		if not ok then error(result, 0) end
		cached = result :: T
		hasCached = true
		if active then refreshSubscriptions(seen) end
		return cached
	end

	local observable: Types.Observable<T> = Observable.new(function(sink: any): (() -> ())
		nextId += 1
		local id = nextId
		sinks[id] = sink
		if not active then active = true; evaluate() end
		sink:Fire(cached)
		return function(): ()
			sinks[id] = nil
			if next(sinks) then return end
			active = false
			for dependency, subscription in dependencies do subscription:Destroy(); dependencies[dependency] = nil end
		end
	end)

	return Value.readonly(function(): T
		if active and hasCached then return cached end
		return evaluate()
	end, observable)
end

return derive
