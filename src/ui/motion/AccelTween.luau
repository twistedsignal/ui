--!strict

local AccelTween = {}

function AccelTween.new(_input: unknown, _config: unknown?): never
	error("ui.accelTween: AccelTween is unavailable; no project implementation was accessible", 2)
end

return table.freeze(AccelTween)
