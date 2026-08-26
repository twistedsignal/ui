--!strict

const animation = require("@self/animation")
const bind = require("@self/binding/bind")
const motion = require("@self/motion")
const reactive = require("@self/reactive")
const expect = require("@self/testing/Expect")

export type Value<T> = reactive.Value<T>
export type ReadonlyValue<T> = reactive.ReadonlyValue<T>
export type Observable<T> = reactive.Observable<T>
export type Reactive<T> = reactive.Reactive<T>
export type SpringConfig = motion.SpringConfig
export type TweenConfig = motion.TweenConfig
export type BindingTree = { [string]: unknown }

return table.freeze({
	value = reactive.value,
	fromObservable = reactive.fromObservable,
	derive = reactive.derive,
	peek = reactive.peek,
	effect = reactive.effect,
	bind = bind,
	spring = motion.spring,
	accelTween = motion.accelTween,
	tween = motion.tween,
	impulse = motion.impulse,
	snap = motion.snap,
	ease = motion.ease,
	bezier = motion.cubicBezier,
	expect = expect,
	to = animation.to,
	wait = animation.wait,
	call = animation.call,
	parallel = animation.parallel,
	sequence = animation.sequence,
	play = animation.play,
})
