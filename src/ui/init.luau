--!strict

const animation = require("@self/animation")
const bind = require("@self/binding/bind")
const motion = require("@self/motion")
const reactive = require("@self/reactive")
const expect = require("@self/testing/Expect")

--[=[
	@class ui

	Binds reactive state and animation to Roblox UI Instances that already exist.

	Require this module to access the complete public API.
]=]

--[=[
	Creates a writable reactive value. Call it with no argument to read it, or with
	a new value to update it.

	@function value
	@within ui
	@param initial T -- Initial value
	@return Value<T>
]=]

--[=[
	Creates a read-only reactive value from a Nightcycle Rx observable. Reading it
	throws until the observable emits its first value.

	@function fromObservable
	@within ui
	@param observable Observable<T>
	@return ReadonlyValue<T>
]=]

--[=[
	Creates a read-only value computed from other reactive values.

	@function derive
	@within ui
	@param expression () -> T
	@return ReadonlyValue<T>
]=]

--[=[
	Reads a value without making the current derivation or effect depend on it.

	@function peek
	@within ui
	@param value ReadonlyValue<T>
	@return T
]=]

--[=[
	Runs a function immediately and again whenever a reactive value read by the
	function changes. Returns a cleanup function.

	@function effect
	@within ui
	@param callback () -> ()
	@return () -> ()
]=]

--[=[
	Binds properties, events, and named children below an existing Instance.
	Returns an idempotent cleanup function that disconnects the entire tree.

	@function bind
	@within ui
	@param instance Instance -- Root of the binding tree
	@param tree BindingTree -- Property, event, and child bindings
	@return () -> ()
]=]

--[=[
	Creates a spring-backed reactive value that follows a reactive expression.

	@function spring
	@within ui
	@param expression () -> T
	@param config SpringConfig? -- Spring speed and damping
	@return ReadonlyValue<T>
]=]

--[=[
	Creates an acceleration-limited tween that follows a reactive expression.

	@function accelTween
	@within ui
	@param expression () -> T
	@param config AccelTweenConfig? -- Acceleration and speed limits
	@return ReadonlyValue<T>
]=]

--[=[
	Creates a duration-based tween that follows a reactive expression.

	@function tween
	@within ui
	@param expression () -> T
	@param config TweenConfig? -- Duration and easing
	@return ReadonlyValue<T>
]=]

--[=[
	Adds velocity to a spring created by [ui.spring].

	@function impulse
	@within ui
	@param spring ReadonlyValue<T>
	@param velocity T
]=]

--[=[
	Moves a spring to a value immediately and clears its velocity.

	@function snap
	@within ui
	@param spring ReadonlyValue<T>
	@param value T
]=]

--[=[
	Creates a cubic Bezier easing function.

	@function bezier
	@within ui
	@param x1 number
	@param y1 number
	@param x2 number
	@param y2 number
	@return (number) -> number
]=]

--[=[
	The standard easing functions used by [ui.tween].

	@prop ease Easing
	@within ui
	@readonly
]=]

--[=[
	Creates a synchronous fluent assertion. Use the matchers on the returned value,
	or use its `never` field to negate a matcher.

	@function expect
	@within ui
	@param actual unknown
	@return Expectation
]=]

--[=[
	Creates a command that writes a target to a motion value.

	@function to
	@within ui
	@param value (T) -> ()
	@param target T
	@param config MotionConfig?
	@return ToCommand
]=]

--[=[
	Creates a command that pauses a sequence for a duration in seconds.

	@function wait
	@within ui
	@param duration number
	@return WaitCommand
]=]

--[=[
	Creates a command that invokes a callback.

	@function call
	@within ui
	@param callback () -> ()
	@return CallCommand
]=]

--[=[
	Creates a command that runs all child commands at the same time.

	@function parallel
	@within ui
	@param commands { Command }
	@return ParallelCommand
]=]

--[=[
	Creates a command that runs each child command in order.

	@function sequence
	@within ui
	@param commands { Command }
	@return SequenceCommand
]=]

--[=[
	Starts an animation command or a sequence of commands. Returns an idempotent
	cancel function.

	@function play
	@within ui
	@param command Command | { Command }
	@return () -> ()
]=]

export type Value<T> = reactive.Value<T>
export type ReadonlyValue<T> = reactive.ReadonlyValue<T>
export type Observable<T> = reactive.Observable<T>
export type Reactive<T> = reactive.Reactive<T>
export type SpringConfig = motion.SpringConfig
export type AccelTweenConfig = motion.AccelTweenConfig
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
