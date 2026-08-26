--!strict

export type Subscription = {
	Destroy: (self: Subscription) -> (),
}

export type Observable<T> = {
	ClassName: string,
	Subscribe: (self: Observable<T>, fire: ((T) -> ())?, fail: ((...unknown) -> ())?, complete: (() -> ())?) -> Subscription,
}

export type ReadonlyValue<T> = ((() -> T) & {
	observable: Observable<T>,
})

export type Value<T> = (((newValue: T) -> ()) & (() -> T) & {
	observable: Observable<T>,
})

export type Reactive<T> = T | ReadonlyValue<T> | Observable<T> | (() -> T)

return nil
