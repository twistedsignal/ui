--!strict

local RunService = game:GetService("RunService")

export type Step = (number) -> boolean

local active: { Step } = {}
local connection: RBXScriptConnection? = nil

local Scheduler = {}

local function disconnectIfIdle(): ()
	if #active == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function onStep(deltaTime: number): ()
	local index = #active
	while index >= 1 do
		if not active[index](deltaTime) then
			active[index] = active[#active]
			table.remove(active)
		end
		index -= 1
	end
	disconnectIfIdle()
end

function Scheduler.add(step: Step): () -> ()
	table.insert(active, step)
	if not connection then
		connection = RunService.Heartbeat:Connect(onStep)
	end
	local subscribed = true
	return function(): ()
		if not subscribed then return end
		subscribed = false
		local index = table.find(active, step)
		if index then
			active[index] = active[#active]
			table.remove(active)
		end
		disconnectIfIdle()
	end
end

function Scheduler.count(): number
	return #active
end

return table.freeze(Scheduler)
