--!strict

export type Dependency = {
	observable: { Subscribe: (self: any, fire: (unknown) -> ()) -> { Destroy: (self: any) -> () } },
}

export type Collector = (Dependency) -> ()

local current: Collector? = nil

local Tracking = {}

function Tracking.read(dependency: Dependency): ()
	if current then
		current(dependency)
	end
end

function Tracking.capture<T>(collector: Collector, callback: () -> T): T
	local previous = current
	current = collector
	local results = table.pack(xpcall(callback, debug.traceback))
	current = previous
	if not results[1] then
		error(results[2], 0)
	end
	return results[2] :: T
end

function Tracking.untracked<T>(callback: () -> T): T
	local previous = current
	current = nil
	local results = table.pack(xpcall(callback, debug.traceback))
	current = previous
	if not results[1] then
		error(results[2], 0)
	end
	return results[2] :: T
end

return Tracking
