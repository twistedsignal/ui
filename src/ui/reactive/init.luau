--!strict

local Derive = require("@self/Derive")
local Effect = require("@self/Effect")
local FromObservable = require("@self/FromObservable")
local Input = require("@self/Input")
local Tracking = require("@self/Tracking")
local Types = require("@self/Types")
local Value = require("@self/Value")
local Owner = require("@self/Owner")
local Adapters = require("@self/Adapters")

export type Value<T> = Types.Value<T>
export type ReadonlyValue<T> = Types.ReadonlyValue<T>
export type Observable<T> = Types.Observable<T>
export type Reactive<T> = Types.Reactive<T>

local reactive = {
	value = Value.new,
	derive = Derive,
	effect = Effect,
	cleanup = Owner.add,
	untrack = Tracking.untracked,
	attribute = Adapters.attribute,
	property = Adapters.property,
	fromObservable = FromObservable,
	toObservable = Input.toObservable,
	read = Input.read,
}

function reactive.peek<T>(value: ReadonlyValue<T>): T
	return Tracking.untracked(function(): T return value() end)
end

return reactive
