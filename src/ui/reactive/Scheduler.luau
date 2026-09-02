--!strict

type Job = { key: unknown, rank: number, order: number, run: () -> () }

local depth = 0
local flushing = false
local nextOrder = 0
local pending: { [unknown]: Job } = {}
local Scheduler = {}

local function flush(): (boolean, unknown)
	if flushing then
		return true, nil
	end
	flushing = true
	local firstError: unknown = nil
	while next(pending) do
		local selected: Job? = nil
		for _, job in pending do
			if
				not selected
				or job.rank < selected.rank
				or (job.rank == selected.rank and job.order < selected.order)
			then
				selected = job
			end
		end
		local job = selected :: Job
		pending[job.key] = nil
		local ok, reason = xpcall(job.run, debug.traceback)
		if not ok and firstError == nil then
			firstError = reason
		end
	end
	flushing = false
	return firstError == nil, firstError
end

function Scheduler.enqueue(key: unknown, rank: number, run: () -> ()): ()
	local existing = pending[key]
	if existing then
		existing.rank = math.min(existing.rank, rank)
		existing.run = run
		return
	end
	nextOrder += 1
	pending[key] = { key = key, rank = rank, order = nextOrder, run = run }
	if depth == 0 and not flushing then
		local ok, reason = flush()
		if not ok then
			error(reason, 0)
		end
	end
end

function Scheduler.transaction(run: () -> ()): ()
	depth += 1
	local ok, reason = xpcall(run, debug.traceback)
	depth -= 1
	local flushOk, flushReason = true, nil
	if depth == 0 then
		flushOk, flushReason = flush()
	end
	if not ok then
		error(reason, 0)
	end
	if not flushOk then
		error(flushReason, 0)
	end
end

function Scheduler.batch<T...>(run: () -> T...): T...
	depth += 1
	local results = table.pack(xpcall(run, debug.traceback))
	depth -= 1
	local flushOk, flushReason = true, nil
	if depth == 0 then
		flushOk, flushReason = flush()
	end
	if not results[1] then
		error(results[2], 0)
	end
	if not flushOk then
		error(flushReason, 0)
	end
	return table.unpack(results, 2, results.n)
end

return Scheduler
