--!strict

-- Rx does not export its Observable constructor, but every Rx observable uses
-- the constructor table as its metatable.
local bundled: boolean, dependency: unknown = pcall(require, "../Packages/Rx")
local Rx: any = dependency
if not bundled then
	Rx = require("../../Rx")
end
return getmetatable(Rx.EMPTY)
