--!strict

const Spring = require("@self/Spring")
const Tween = require("@self/Tween")

export type SpringConfig = Spring.Config

return table.freeze({
	spring = Spring.new,
	tween = Tween.new,
})
