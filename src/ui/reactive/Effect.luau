--!strict

local Tracking = require("./Tracking")
local Types = require("./Types")

type Dependency = Tracking.Dependency
type Subscription = Types.Subscription

local function effect(callback: () -> ()): () -> ()
	local dependencies: { [Dependency]: Subscription } = {}
	local stopped = false
	local running = false
	local rerun = false
	local run: () -> ()

	run = function(): ()
		if stopped then return end
		if running then rerun = true; return end
		running = true
		local seen: { [Dependency]: boolean } = {}
		Tracking.capture(function(dependency: Dependency): () seen[dependency] = true end, function(): boolean
			callback()
			return true
		end)
		for dependency, subscription in dependencies do
			if not seen[dependency] then subscription:Destroy(); dependencies[dependency] = nil end
		end
		for dependency in seen do
			if dependencies[dependency] then continue end
			local initial = true
			dependencies[dependency] = dependency.observable:Subscribe(function(_value: unknown): ()
				if initial then initial = false; return end
				run()
			end)
		end
		running = false
		if rerun then rerun = false; run() end
	end

	run()
	return function(): ()
		if stopped then return end
		stopped = true
		for dependency, subscription in dependencies do subscription:Destroy(); dependencies[dependency] = nil end
	end
end

return effect
