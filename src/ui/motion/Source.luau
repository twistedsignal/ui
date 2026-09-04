--!strict

local Input = require("./../reactive/Input")
local Types = require("./../reactive/Types")

export type Cleanup = () -> ()

local Source = {}

local function observe<T>(input: Types.Reactive<T>, fire: (T) -> ()): Cleanup
	local subscription: Types.Subscription = Input.toObservable(input):Subscribe(fire)
	return function(): ()
		subscription:Destroy()
	end
end

Source.observe = observe

return table.freeze(Source)
