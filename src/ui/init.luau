--!strict

local bind = require("@self/binding/bind")
local motion = require("@self/motion")
local reactive = require("@self/reactive")

--[=[
	@class ui

	Makes existing Roblox UI reactive. Values hold state, functions express
	reactive work, binding tables compose behavior, and `bind` owns the lifetime.
]=]

--[=[
	Creates synchronous writable reactive state. Calling the Value with no argument
	reads it; calling it with a value writes it. Equal writes are ignored.
	@function value
	@within ui
	@param initial T
	@return Value<T>
]=]
--[=[
	Creates a lazy, memoized read-only value with dynamic dependency tracking.
	Derived results are not equality-deduplicated.
	@function derive
	@within ui
	@param compute () -> T
	@return ReadonlyValue<T>
]=]
--[=[
	Runs tracked side-effecting work immediately and synchronously after its dynamic
	dependencies change. Before a rerun, the returned cleanup runs, followed by
	`cleanup` callbacks in reverse registration order.
	@function effect
	@within ui
	@param run () -> (() -> ())?
	@return () -> ()
]=]
--[=[
	Groups synchronous reactive writes into one propagation cycle. Writes and reads
	inside `run` use current values. Derived emissions, effects, and bindings update
	once after the outermost batch returns. Nested batches share the same cycle. If
	`run` throws, completed writes propagate before its original error is rethrown.
	@function batch
	@within ui
	@param run () -> T...
	@return T...
]=]
--[=[
	Mounts bindings onto an existing Instance. The returned cleanup is idempotent,
	disposes subscriptions, declared event connections, and reactive branches, then
	restores captured properties. It does not destroy Instances or external work.
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
	Registers a callback with the current effect execution or tracked binding
	function. Owned callbacks run in reverse order; calling this without an owner
	is an error. Instances and external connections are not owned automatically.
	@function cleanup
	@within ui
	@param dispose () -> ()
]=]
--[=[
	Runs a function without recording its reactive reads as dependencies. This does
	not prevent writes or stop existing dependencies from updating.
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
--[=[
	Wraps an Rx Observable in a callable read-only value.
	@function fromObservable
	@within ui
	@param source Observable<T>
	@return ReadonlyValue<T>
]=]
--[=[
	Converts a reactive input into an Rx Observable.
	@function toObservable
	@within ui
	@param input Reactive<T>
	@return Observable<T>
]=]

export type Value<T> = reactive.Value<T>
export type ReadonlyValue<T> = reactive.ReadonlyValue<T>
export type Observable<T> = reactive.Observable<T>
export type Reactive<T> = reactive.Reactive<T>
export type Cleanup = reactive.Cleanup
export type EffectCallback = reactive.EffectCallback
export type Effect = reactive.Effect
export type FromObservable = reactive.FromObservable
export type ToObservable = reactive.ToObservable
export type SpringOptions = motion.SpringConfig
export type Binding<T> = bind.Binding<T>
export type Bind = bind.Bind

return table.freeze({
	value = reactive.value,
	derive = reactive.derive,
	effect = reactive.effect,
	batch = reactive.batch,
	bind = bind,
	tween = motion.tween,
	spring = motion.spring,
	cleanup = reactive.cleanup,
	untrack = reactive.untrack,
	attribute = reactive.attribute,
	property = reactive.property,
	fromObservable = reactive.fromObservable,
	toObservable = reactive.toObservable,
})
