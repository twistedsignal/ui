--!strict

export type Writable<T> = ((T) -> ()) & (() -> T)
export type MotionConfig = {
	tween: { duration: number?, easing: ((number) -> number)? }?,
	spring: { speed: number?, damping: number? }?,
}
export type ToCommand = { kind: "to", value: (unknown) -> (), target: unknown, config: MotionConfig? }
export type WaitCommand = { kind: "wait", duration: number }
export type CallCommand = { kind: "call", callback: () -> () }
export type ParallelCommand = { kind: "parallel", commands: { Command } }
export type SequenceCommand = { kind: "sequence", commands: { Command } }
export type Command = ToCommand | WaitCommand | CallCommand | ParallelCommand | SequenceCommand
export type Cancel = () -> ()

const animation = {}

const function to<T>(value: Writable<T>, target: T, config: MotionConfig?): ToCommand
	return { kind = "to", value = value :: (unknown) -> (), target = target, config = config }
end

const function wait(duration: number): WaitCommand
	assert(duration >= 0, "ui.wait: duration must be non-negative")
	return { kind = "wait", duration = duration }
end

const function call(callback: () -> ()): CallCommand
	return { kind = "call", callback = callback }
end

const function parallel(commands: { Command }): ParallelCommand
	return { kind = "parallel", commands = commands }
end

const function sequence(commands: { Command }): SequenceCommand
	return { kind = "sequence", commands = commands }
end

const function play(commandOrCommands: Command | { Command }): Cancel
	const root: Command = if (commandOrCommands :: Command).kind ~= nil
		then commandOrCommands :: Command
		else sequence(commandOrCommands :: { Command })
	local cancelled: boolean = false
	const threads: { thread } = {}

	local run: (Command) -> ()
	run = function(command: Command): ()
		if cancelled then
			return
		end
		if command.kind == "to" then
			command.value(command.target)
			const tween = command.config and command.config.tween
			if tween and tween.duration then
				task.wait(tween.duration)
			end
		elseif command.kind == "wait" then
			task.wait(command.duration)
		elseif command.kind == "call" then
			command.callback()
		elseif command.kind == "sequence" then
			for index: number = 1, #command.commands do
				const child: Command = command.commands[index]
				run(child)
				if cancelled then
					return
				end
			end
		elseif command.kind == "parallel" then
			const remaining = Instance.new("BindableEvent")
			local count: number = #command.commands
			if count == 0 then
				remaining:Destroy()
				return
			end
			for index: number = 1, #command.commands do
				const child: Command = command.commands[index]
				const childThread: thread = task.spawn(function(): ()
					run(child)
					count -= 1
					if count == 0 then
						remaining:Fire()
					end
				end)
				table.insert(threads, childThread)
			end
			remaining.Event:Wait()
			remaining:Destroy()
		end
	end

	const rootThread: thread = task.spawn(function(): ()
		run(root)
	end)
	table.insert(threads, rootThread)

	return function(): ()
		if cancelled then
			return
		end
		cancelled = true
		for activeThread: thread in threads do
			task.cancel(activeThread)
		end
		table.clear(threads)
	end
end

animation.to = to
animation.wait = wait
animation.call = call
animation.parallel = parallel
animation.sequence = sequence
animation.play = play

return animation
