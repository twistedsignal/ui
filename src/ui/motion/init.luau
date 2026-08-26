--!strict

const AccelTween = require("@self/AccelTween")
const Easing = require("@self/Easing")
const Interpolate = require("@self/Interpolate")
const Spring = require("@self/Spring")
const Tween = require("@self/Tween")

export type SpringConfig = Spring.Config
export type AccelTweenConfig = AccelTween.Config
export type TweenConfig = Tween.Config

return table.freeze({
	spring = Spring.new,
	impulse = Spring.impulse,
	snap = Spring.snap,
	tween = Tween.new,
	accelTween = AccelTween.new,
	ease = Easing,
	interpolate = Interpolate.value,
	cubicBezier = Easing.cubicBezier,
})
