--!strict

const Effect = require("./../reactive/Effect")
const Observable = require("./../reactive/Observable")
const Types = require("./../reactive/Types")

type Subscription = Types.Subscription
type Observable<T> = Types.Observable<T>
export type BindingTree = { [string]: unknown }
export type Cleanup = () -> ()
type MemberKind = "property" | "event" | "child" | "missing"

const function valueType(value: unknown): string
	const kind = typeof(value)
	if kind == "table" and Observable.isObservable(value) then
		return "Observable"
	end
	return kind
end

const function isValue(value: unknown): boolean
	if typeof(value) ~= "table" then
		return false
	end

	const candidate = value :: { [string]: unknown }
	return typeof(candidate.observable) == "table" and Observable.isObservable(candidate.observable)
end

const function assign(instance: Instance, property: string, value: unknown, path: string): ()
	const success, reason = pcall(function(): ()
		(instance :: any)[property] = value
	end)
	if not success then
		error(`ui.bind: Could not assign property "{path}": {tostring(reason)}`, 0)
	end
end

const function bindObservable(instance: Instance, property: string, path: string, observable: Observable<unknown>): Cleanup
	const subscription: Subscription = observable:Subscribe(function(value: unknown): ()
		assign(instance, property, value, path)
	end)
	return function(): ()
		subscription:Destroy()
	end
end

const function bindExpression(instance: Instance, property: string, path: string, expression: () -> unknown): Cleanup
	return Effect(function(): ()
		assign(instance, property, expression(), path)
	end)
end

const function resolveMember(instance: Instance, name: string): (MemberKind, unknown)
	const isProperty = pcall(function(): ()
		instance:GetPropertyChangedSignal(name)
	end)
	if isProperty then
		return "property", nil
	end

	const hasMember, member = pcall(function(): unknown
		return (instance :: any)[name]
	end)
	if hasMember and typeof(member) == "RBXScriptSignal" then
		return "event", member
	end

	const child = instance:FindFirstChild(name)
	if child then
		return "child", child
	end
	return "missing", nil
end

const function bindTree(instance: Instance, tree: BindingTree, path: string, cleanups: { Cleanup }): ()
	for name, binding in tree do
		if typeof(name) ~= "string" then
			error(`ui.bind: Expected string binding key below "{path}", got {typeof(name)}`, 0)
		end

		const memberPath = `{path}.{name}`
		const memberKind, member = resolveMember(instance, name)
		if memberKind == "event" then
			if typeof(binding) ~= "function" then
				error(`ui.bind: Expected function for event "{memberPath}", got {valueType(binding)}`, 0)
			end
			const connection: RBXScriptConnection = (member :: RBXScriptSignal):Connect(binding :: (...any) -> ())
			table.insert(cleanups, function(): ()
				connection:Disconnect()
			end)
		elseif memberKind == "property" then
			if typeof(binding) == "table" and not isValue(binding) and not Observable.isObservable(binding) then
				error(`ui.bind: "{memberPath}" is a property, not a child binding`, 0)
			elseif isValue(binding) then
				const valueObject = binding :: { observable: Observable<unknown> }
				table.insert(cleanups, bindObservable(instance, name, memberPath, valueObject.observable))
			elseif Observable.isObservable(binding) then
				table.insert(cleanups, bindObservable(instance, name, memberPath, binding :: Observable<unknown>))
			elseif typeof(binding) == "function" then
				table.insert(cleanups, bindExpression(instance, name, memberPath, binding :: () -> unknown))
			else
				assign(instance, name, binding, memberPath)
			end
		elseif memberKind == "child" then
			const child = member :: Instance
			if typeof(binding) ~= "table" or isValue(binding) or Observable.isObservable(binding) then
				error(`ui.bind: Expected binding table for child "{memberPath}", got {valueType(binding)}`, 0)
			end
			bindTree(child, binding :: BindingTree, memberPath, cleanups)
		else
			error(`ui.bind: Could not resolve "{memberPath}"`, 0)
		end
	end
end

const function bind(instance: Instance, tree: BindingTree): Cleanup
	const cleanups: { Cleanup } = {}
	const rootPath = instance.Name
	const success, reason = pcall(function(): ()
		bindTree(instance, tree, rootPath, cleanups)
	end)
	if not success then
		for index = #cleanups, 1, -1 do
			cleanups[index]()
		end
		error(reason, 2)
	end

	local destroyed = false
	return function(): ()
		if destroyed then
			return
		end
		destroyed = true
		for index = #cleanups, 1, -1 do
			cleanups[index]()
		end
		table.clear(cleanups)
	end
end

return bind

