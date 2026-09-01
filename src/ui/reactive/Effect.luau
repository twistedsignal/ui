--!strict

local Tracking = require("./Tracking")
local Types = require("./Types")
local Owner = require("./Owner")

type Dependency = Tracking.Dependency
type Subscription = Types.Subscription

local function effect(callback: () -> (() -> ())?): () -> ()
	local dependencies: { [Dependency]: Subscription } = {}
	local stopped = false
	local running = false
	local rerun = false
	local executionOwner: Owner.Owner? = nil
	local run: () -> ()

	run = function(): ()
		if stopped then return end
		if running then rerun = true; return end
		running = true
		if executionOwner then Owner.dispose(executionOwner) end
		executionOwner = Owner.create()
		local seen: { [Dependency]: boolean } = {}
		Tracking.capture(function(dependency: Dependency): () seen[dependency] = true end, function(): boolean
			local cleanup = Owner.run(executionOwner :: Owner.Owner, callback)
			if cleanup then
				table.insert((executionOwner :: Owner.Owner).cleanups, cleanup)
			end
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
		if executionOwner then Owner.dispose(executionOwner); executionOwner = nil end
	end
end

return effect
