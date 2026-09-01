--!strict

export type Backend = {
	impulse: ((unknown) -> ())?,
	snap: (() -> ())?,
	cleanup: (() -> ())?,
}

local records: { [unknown]: Backend } = setmetatable({}, { __mode = "k" }) :: any

local Metadata = {}

function Metadata.set(value: unknown, backend: Backend): () records[value] = backend end
function Metadata.get(value: unknown): Backend? return records[value] end

return table.freeze(Metadata)
