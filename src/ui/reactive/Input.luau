--!strict

local Derive = require("./Derive")
local FromObservable = require("./FromObservable")
local Observable = require("./Observable")
local Types = require("./Types")

local Input = {}

function Input.isValue(value: unknown): boolean
	return type(value) == "table" and type((value :: any).observable) == "table" and getmetatable(value) ~= nil
end

function Input.toObservable<T>(input: Types.Reactive<T>): Types.Observable<T>
	if Input.isValue(input) then return (input :: Types.ReadonlyValue<T>).observable end
	if Observable.isObservable(input) then return input :: Types.Observable<T> end
	if type(input) == "function" then return Derive(input :: () -> T).observable end
	return Observable.new(function(sink: any): (() -> ())? sink:Fire(input :: T); return nil end)
end

function Input.read<T>(input: Types.Reactive<T>): T
	if Input.isValue(input) or type(input) == "function" then return (input :: any)() end
	if Observable.isObservable(input) then return FromObservable(input :: Types.Observable<T>)() end
	return input :: T
end

return Input
