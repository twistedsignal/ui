--!strict

-- Filesystem-only bridge for Lest and Luau tools. Rojo maps the generated Wally
-- dependency beside `ui`, and Wally creates the same sibling alias for consumers.
return require("../Packages/Rx")
