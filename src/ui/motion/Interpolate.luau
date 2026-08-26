--!strict

local Interpolate = {}

function Interpolate.value<T>(from: T, to: T, alpha: number): T
	local kind = typeof(from)
	assert(kind == typeof(to), `ui.interpolate: cannot interpolate {kind} to {typeof(to)}`)
	if kind == "number" then return ((from :: any) + ((to :: any) - (from :: any)) * alpha) :: T end
	if kind == "Vector2" or kind == "Vector3" or kind == "Color3" or kind == "CFrame" then
		return ((from :: any):Lerp(to, alpha)) :: T
	end
	if kind == "UDim" then
		local a = from :: any
		local b = to :: any
		return UDim.new(a.Scale + (b.Scale - a.Scale) * alpha, a.Offset + (b.Offset - a.Offset) * alpha) :: any
	end
	if kind == "UDim2" then
		local a = from :: any
		local b = to :: any
		return UDim2.new(
			a.X.Scale + (b.X.Scale - a.X.Scale) * alpha,
			a.X.Offset + (b.X.Offset - a.X.Offset) * alpha,
			a.Y.Scale + (b.Y.Scale - a.Y.Scale) * alpha,
			a.Y.Offset + (b.Y.Offset - a.Y.Offset) * alpha
		) :: any
	end
	error(`ui.interpolate: unsupported datatype {kind}`, 2)
end

return table.freeze(Interpolate)
