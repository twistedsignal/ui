--!strict

local Value = require("./Value")
local Types = require("./Types")

local Adapters = {}

function Adapters.attribute<T>(instance: Instance, name: string, default: T?): Types.Value<T?>
	local current = instance:GetAttribute(name)
	local value = Value.new(if current == nil then default else current :: T)
	local writing = false
	local connection = instance:GetAttributeChangedSignal(name):Connect(function(): ()
		if writing then return end
		local nextValue = instance:GetAttribute(name)
		value(if nextValue == nil then default else nextValue :: T)
	end)
	local adapter = setmetatable({ observable = value.observable }, {
		__call = function(_self: unknown, ...: T): T?
			if select("#", ...) == 0 then return value() end
			local nextValue = select(1, ...)
			writing = true
			instance:SetAttribute(name, nextValue)
			writing = false
			value(nextValue)
			return nil
		end,
	}) :: any
	local destroying: RBXScriptConnection
	destroying = instance.Destroying:Connect(function(): ()
		connection:Disconnect()
		destroying:Disconnect()
	end)
	return adapter
end

function Adapters.property<T>(instance: Instance, propertyName: string): Types.Value<T>
	local ok, current = pcall(function(): unknown return (instance :: any)[propertyName] end)
	assert(ok, `ui.property: invalid property "{propertyName}" on {instance.ClassName}`)
	local writable = pcall(function(): () (instance :: any)[propertyName] = current end)
	assert(writable, `ui.property: property "{propertyName}" on {instance.ClassName} is read-only`)
	local value = Value.new(current :: T)
	local writing = false
	local connection = instance:GetPropertyChangedSignal(propertyName):Connect(function(): ()
		if not writing then value((instance :: any)[propertyName] :: T) end
	end)
	local adapter = setmetatable({ observable = value.observable }, {
		__call = function(_self: unknown, ...: T): T?
			if select("#", ...) == 0 then return value() end
			local nextValue = select(1, ...)
			writing = true
			(instance :: any)[propertyName] = nextValue
			writing = false
			value(nextValue)
			return nil
		end,
	}) :: any
	local destroying: RBXScriptConnection
	destroying = instance.Destroying:Connect(function(): ()
		connection:Disconnect()
		destroying:Disconnect()
	end)
	return adapter
end

return table.freeze(Adapters)
