--!strict

const Input = require("./../reactive/Input")
const Types = require("./../reactive/Types")

export type Cleanup = () -> ()

const Source = {}

const function observe<T>(input: Types.Reactive<T>, fire: (T) -> ()): Cleanup
	const subscription: Types.Subscription = Input.toObservable(input):Subscribe(fire)
	return function(): ()
		subscription:Destroy()
	end
end

Source.observe = observe

return table.freeze(Source)
