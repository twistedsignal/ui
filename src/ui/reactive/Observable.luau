--!strict

-- Rx does not export its Observable constructor, but every Rx observable uses
-- the constructor table as its metatable.
local Rx = require("../../Rx")
return getmetatable(Rx.EMPTY)
