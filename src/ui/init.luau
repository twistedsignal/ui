--!strict

const bind = require("@self/binding/bind")
const motion = require("@self/motion")
const reactive = require("@self/reactive")

--[=[
	@class ui

	Makes existing Roblox UI reactive. Values hold state, functions express
	reactive work, binding tables compose behavior, and `bind` owns the lifetime.
]=]

--[=[
	Creates writable reactive state.
	@function value
	@within ui
	@param initial T
	@return Value<T>
]=]
--[=[
	Creates a lazy, memoized read-only value.
	@function derive
	@within ui
	@param compute () -> T
	@return ReadonlyValue<T>
]=]
--[=[
	Runs tracked side-effecting work immediately and after its dependencies change.
	A cleanup returned by `run` executes before the next run and when stopped.
	@function effect
	@within ui
	@param run () -> (() -> ())?
	@return () -> ()
]=]
--[=[
	Mounts bindings onto an existing Instance. The returned cleanup is idempotent,
	disposes every owned branch and resource, and restores captured properties.
	@function bind
	@within ui
	@param instance Instance
	@param bindings Binding | Reactive<Binding?>
	@return () -> ()
]=]
--[=[
	Animates a reactive target using Roblox tween interpolation.
	@function tween
	@within ui
	@param target Reactive<T>
	@param info TweenInfo?
	@return ReadonlyValue<T>
]=]
--[=[
	Physically approaches a reactive target while preserving retargeted velocity.
	@function spring
	@within ui
	@param target Reactive<T>
	@param options SpringOptions?
	@return ReadonlyValue<T>
]=]
--[=[
	Registers a callback with the current bind, effect, or reactive branch.
	@function cleanup
	@within ui
	@param dispose () -> ()
]=]
--[=[
	Runs a function without recording reactive dependencies.
	@function untrack
	@within ui
	@param read () -> T
	@return T
]=]
--[=[
	Creates a two-way reactive adapter for an Instance attribute.
	@function attribute
	@within ui
	@param instance Instance
	@param name string
	@param default T?
	@return Value<T?>
]=]
--[=[
	Creates a two-way reactive adapter for a writable Instance property.
	@function property
	@within ui
	@param instance Instance
	@param propertyName string
	@return Value<T>
]=]

export type Value<T> = reactive.Value<T>
export type ReadonlyValue<T> = reactive.ReadonlyValue<T>
export type Observable<T> = reactive.Observable<T>
export type Reactive<T> = reactive.Reactive<T>
export type SpringOptions = motion.SpringConfig
export type Binding = { [string | number]: unknown }

return table.freeze({
	value = reactive.value,
	derive = reactive.derive,
	effect = reactive.effect,
	bind = bind,
	tween = motion.tween,
	spring = motion.spring,
	cleanup = reactive.cleanup,
	untrack = reactive.untrack,
	attribute = reactive.attribute,
	property = reactive.property,
})
