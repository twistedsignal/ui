--!strict

local Tracking = require("./Tracking")
local Scheduler = require("./Scheduler")
local Types = require("./Types")
local Owner = require("./Owner")

type Dependency = Tracking.Dependency
type Subscription = Types.Subscription

export type Cleanup = () -> ()
export type Callback = () -> Cleanup?
export type Effect = (Callback) -> Cleanup

local function effect(callback: Callback): Cleanup
	local dependencies: { [Dependency]: Subscription } = {}
	local stopped = false
	local running = false
	local rerun = false
	local scheduled = false
	local executionOwner: Owner.Owner? = nil
	local run: () -> ()
	local invalidate: () -> ()

	invalidate = function(): ()
		if stopped or scheduled then
			return
		end
		scheduled = true
		Scheduler.enqueue(dependencies, math.huge, function(): ()
			scheduled = false
			run()
		end)
	end

	run = function(): ()
		if stopped then
			return
		end
		if running then
			rerun = true
			return
		end
		running = true
		if executionOwner then
			Owner.dispose(executionOwner)
		end
		executionOwner = Owner.create()
		local seen: { [Dependency]: boolean } = {}
		Tracking.capture(function(dependency: Dependency): ()
			seen[dependency] = true
		end, function(): boolean
			local cleanup = Owner.run(executionOwner :: Owner.Owner, callback)
			if cleanup then
				table.insert((executionOwner :: Owner.Owner).cleanups, cleanup)
			end
			return true
		end)
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
		running = false
		if rerun then
			rerun = false
			run()
		end
	end

	run()
	return function(): ()
		if stopped then
			return
		end
		stopped = true
		for dependency, subscription in dependencies do
			subscription:Destroy()
			dependencies[dependency] = nil
		end
		if executionOwner then
			Owner.dispose(executionOwner)
			executionOwner = nil
		end
	end
end

return effect
