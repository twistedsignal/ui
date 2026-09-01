--!strict

local Effect = require("./../reactive/Effect")
local Input = require("./../reactive/Input")
local Observable = require("./../reactive/Observable")
local Metadata = require("./../motion/Metadata")

export type Binding = { [string | number]: unknown }
export type Cleanup = () -> ()
type MemberKind = "property" | "event" | "child" | "missing" | "ambiguous"
type Writer = { value: unknown }
type PropertyState = { initial: unknown, writers: { Writer } }
type Context = {
	properties: { [Instance]: { [string]: PropertyState } },
	motionRefs: { [unknown]: number },
	stopped: boolean,
}

local function valueType(value: unknown): string
	if Input.isValue(value) then return "Value" end
	if Observable.isObservable(value) then return "Observable" end
	return typeof(value)
end

local function resolveMember(instance: Instance, name: string): (MemberKind, unknown)
	if pcall(function(): () instance:GetPropertyChangedSignal(name) end) then return "property", nil end
	local hasMember, member = pcall(function(): unknown return (instance :: any)[name] end)
	if hasMember and typeof(member) == "RBXScriptSignal" then return "event", member end
	local found: Instance? = nil
	for _, child in instance:GetChildren() do
		if child.Name == name then
			if found then return "ambiguous", nil end
			found = child
		end
	end
	if found then return "child", found end
	return "missing", nil
end

local function assign(instance: Instance, property: string, value: unknown, path: string): ()
	local success, reason = pcall(function(): () (instance :: any)[property] = value end)
	if not success then error(`ui.bind: Could not assign property "{path}": {tostring(reason)}`, 0) end
end

local function propertyState(context: Context, instance: Instance, property: string): PropertyState
	local states = context.properties[instance]
	if not states then states = {}; context.properties[instance] = states end
	local state = states[property]
	if not state then state = { initial = (instance :: any)[property], writers = {} }; states[property] = state end
	return state
end

local function mountProperty(context: Context, instance: Instance, property: string, input: unknown, path: string): Cleanup
	local state = propertyState(context, instance, property)
	local writer: Writer = { value = nil }
	table.insert(state.writers, writer)
	local function update(value: unknown): ()
		writer.value = value
		if state.writers[#state.writers] == writer and not context.stopped then assign(instance, property, value, path) end
	end
	local stop: Cleanup? = nil
	if Input.isValue(input) then
		local subscription = (input :: any).observable:Subscribe(update)
		stop = function(): () subscription:Destroy() end
	elseif Observable.isObservable(input) then
		local subscription = (input :: any):Subscribe(update)
		stop = function(): () subscription:Destroy() end
	elseif typeof(input) == "function" then
		stop = Effect(function(): (() -> ())? update((input :: () -> unknown)()); return nil end)
	else update(input) end
	local metadata = Metadata.get(input)
	if metadata and metadata.cleanup then context.motionRefs[input] = (context.motionRefs[input] or 0) + 1 end
	local removed = false
	return function(): ()
		if removed then return end
		removed = true
		if stop then stop() end
		if metadata and metadata.cleanup then
			local remaining = (context.motionRefs[input] or 1) - 1
			context.motionRefs[input] = if remaining > 0 then remaining else nil
			if remaining == 0 then metadata.cleanup() end
		end
		local index = table.find(state.writers, writer)
		if index then table.remove(state.writers, index) end
		if context.stopped then return end
		local top = state.writers[#state.writers]
		assign(instance, property, if top then top.value else state.initial, path)
	end
end

local mountBinding: (Context, Instance, Binding, string) -> Cleanup

local function mountEntry(context: Context, instance: Instance, name: string, binding: unknown, path: string): Cleanup
	local memberPath = `{path}.{name}`
	local kind, member = resolveMember(instance, name)
	if kind == "ambiguous" then error(`ui.bind: Ambiguous child "{memberPath}"`, 0) end
	if kind == "missing" then error(`ui.bind: Could not resolve "{memberPath}"`, 0) end
	if kind == "event" then
		if typeof(binding) ~= "function" then error(`ui.bind: Expected function for event "{memberPath}", got {valueType(binding)}`, 0) end
		local connection = (member :: RBXScriptSignal):Connect(binding :: (...any) -> ())
		return function(): () connection:Disconnect() end
	end
	if kind == "property" then return mountProperty(context, instance, name, binding, memberPath) end
	if typeof(binding) ~= "table" or Input.isValue(binding) or Observable.isObservable(binding) then
		error(`ui.bind: Expected binding table for child "{memberPath}", got {valueType(binding)}`, 0)
	end
	return mountBinding(context, member :: Instance, binding :: Binding, memberPath)
end

local function mountFragment(context: Context, instance: Instance, fragment: unknown, path: string): Cleanup
	if fragment == nil then return function(): () end end
	if typeof(fragment) ~= "table" or Input.isValue(fragment) or Observable.isObservable(fragment) then
		error(`ui.bind: Expected binding fragment below "{path}", got {valueType(fragment)}`, 0)
	end
	return mountBinding(context, instance, fragment :: Binding, path)
end

local function mountReactiveFragment(context: Context, instance: Instance, input: unknown, path: string): Cleanup
	local branchCleanup: Cleanup? = nil
	local function replace(fragment: unknown): ()
		if branchCleanup then branchCleanup(); branchCleanup = nil end
		branchCleanup = mountFragment(context, instance, fragment, path)
	end
	local stop: Cleanup
	if Input.isValue(input) then
		local subscription = (input :: any).observable:Subscribe(replace)
		stop = function(): () subscription:Destroy() end
	elseif Observable.isObservable(input) then
		local subscription = (input :: any):Subscribe(replace)
		stop = function(): () subscription:Destroy() end
	else
		stop = Effect(function(): (() -> ())? replace((input :: () -> unknown)()); return nil end)
	end
	return function(): () stop(); if branchCleanup then branchCleanup(); branchCleanup = nil end end
end

mountBinding = function(context: Context, instance: Instance, bindings: Binding, path: string): Cleanup
	local cleanups: { Cleanup } = {}
	local success, reason = pcall(function(): ()
		for index = 1, #bindings do
			local fragment = bindings[index]
			if typeof(fragment) == "function" or Input.isValue(fragment) or Observable.isObservable(fragment) then
				table.insert(cleanups, mountReactiveFragment(context, instance, fragment, path))
			else table.insert(cleanups, mountFragment(context, instance, fragment, path)) end
		end
		for name, binding in bindings do
			if typeof(name) == "string" then table.insert(cleanups, mountEntry(context, instance, name, binding, path)) end
		end
	end)
	if not success then
		for index = #cleanups, 1, -1 do cleanups[index]() end
		error(reason, 0)
	end
	local cleaned = false
	return function(): ()
		if cleaned then return end
		cleaned = true
		for index = #cleanups, 1, -1 do cleanups[index]() end
		table.clear(cleanups)
	end
end

local function bind(instance: Instance, bindings: unknown): Cleanup
	assert(typeof(instance) == "Instance", "ui.bind: expected an Instance")
	local context: Context = { properties = {}, motionRefs = {}, stopped = false }
	local rootCleanup: Cleanup? = nil
	local success, reason = pcall(function(): ()
		if typeof(bindings) == "function" or Input.isValue(bindings) or Observable.isObservable(bindings) then
			rootCleanup = mountReactiveFragment(context, instance, bindings, instance.Name)
		else rootCleanup = mountFragment(context, instance, bindings, instance.Name) end
	end)
	if not success then context.stopped = true; if rootCleanup then rootCleanup() end; error(reason, 2) end
	local destroying: RBXScriptConnection? = nil
	local stopped = false
	local function cleanup(): ()
		if stopped then return end
		stopped = true
		if destroying then destroying:Disconnect(); destroying = nil end
		if rootCleanup then rootCleanup(); rootCleanup = nil end
		context.stopped = true
		table.clear(context.properties)
	end
	destroying = instance.Destroying:Connect(function(): () context.stopped = true; cleanup() end)
	return cleanup
end

return bind
