--!strict

export type Owner = {
	cleanups: { () -> () },
	disposed: boolean,
}

local current: Owner? = nil
local Owner = {}

function Owner.create(): Owner
	return { cleanups = {}, disposed = false }
end

function Owner.run<T>(owner: Owner, callback: () -> T): T
	local previous = current
	current = owner
	local results = table.pack(xpcall(callback, debug.traceback))
	current = previous
	if not results[1] then
		error(results[2], 0)
	end
	return results[2] :: T
end

function Owner.add(cleanup: () -> ()): ()
	assert(current and not current.disposed, "ui.cleanup: no active reactive owner")
	table.insert((current :: Owner).cleanups, cleanup)
end

function Owner.dispose(owner: Owner): ()
	if owner.disposed then
		return
	end
	owner.disposed = true
	for index = #owner.cleanups, 1, -1 do
		owner.cleanups[index]()
	end
	table.clear(owner.cleanups)
end

return Owner
