--!strict

local Spring = require("@self/Spring")
local Tween = require("@self/Tween")

export type SpringConfig = Spring.Config

return table.freeze({
	spring = Spring.new,
	tween = Tween.new,
})
