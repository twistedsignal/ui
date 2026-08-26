--!strict

export type Matcher = {
	toBe: (expected: unknown) -> (),
	toEqual: (expected: unknown) -> (),
	toBeTruthy: () -> (),
	toBeFalsy: () -> (),
	toBeNil: () -> (),
	toBeNear: (expected: number, epsilon: number?) -> (),
	toThrow: (message: string?) -> (),
}

export type Expectation = Matcher & { never: Matcher }

type Seen = { [unknown]: { [unknown]: boolean } }

const function formatValue(value: unknown, depth: number, seen: { [unknown]: boolean }): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	if type(value) ~= "table" then
		return tostring(value)
	end
	if seen[value] then
		return "<cycle>"
	end
	if depth >= 4 then
		return "{...}"
	end
	seen[value] = true
	const parts: { string } = {}
	for key: unknown, child: unknown in value :: { [unknown]: unknown } do
		table.insert(parts, `{formatValue(key, depth + 1, seen)} = {formatValue(child, depth + 1, seen)}`)
	end
	seen[value] = nil
	return `{ {table.concat(parts, ", ")} }`
end

const function equal(actual: unknown, expected: unknown, seen: Seen): boolean
	if actual == expected then
		return true
	end
	if type(actual) == "number" and type(expected) == "number" then
		return actual ~= actual and expected ~= expected
	end
	if type(actual) ~= "table" or type(expected) ~= "table" then
		return false
	end
	seen[actual] = seen[actual] or {}
	if seen[actual][expected] then
		return true
	end
	seen[actual][expected] = true
	for key: unknown, value: unknown in actual :: { [unknown]: unknown } do
		if not equal(value, (expected :: { [unknown]: unknown })[key], seen) then
			return false
		end
	end
	for key: unknown in expected :: { [unknown]: unknown } do
		if (actual :: { [unknown]: unknown })[key] == nil then
			return false
		end
	end
	return true
end

const function fail(actual: unknown, expected: unknown): never
	error(`Expected:\n    {formatValue(expected, 0, {})}\nReceived:\n    {formatValue(actual, 0, {})}`, 3)
end

const function build(actual: unknown, negated: boolean): Matcher
	const function check(result: boolean, expected: unknown): ()
		if result == negated then
			fail(actual, if negated then `not {formatValue(expected, 0, {})}` else expected)
		end
	end

	return {
		toBe = function(expected: unknown): ()
			check(actual == expected, expected)
		end,
		toEqual = function(expected: unknown): ()
			check(equal(actual, expected, {}), expected)
		end,
		toBeTruthy = function(): ()
			check(not not actual, "truthy")
		end,
		toBeFalsy = function(): ()
			check(not actual, "falsy")
		end,
		toBeNil = function(): ()
			check(actual == nil, nil)
		end,
		toBeNear = function(expected: number, epsilon: number?): ()
			if type(actual) ~= "number" then
				fail(actual, expected)
			end
			const numericActual: number = actual :: number
			check(math.abs(numericActual - expected) <= (epsilon or 1e-6), expected)
		end,
		toThrow = function(message: string?): ()
			if type(actual) ~= "function" then
				error("ui.expect: toThrow expects a function", 2)
			end
			const ok: boolean, result: unknown = pcall(actual :: () -> ())
			const matches: boolean = not ok and (message == nil or string.find(tostring(result), message, 1, true) ~= nil)
			check(matches, message or "an error")
		end,
	}
end

const function expect(actual: unknown): Expectation
	const positive: Matcher = build(actual, false)
	return {
		toBe = positive.toBe,
		toEqual = positive.toEqual,
		toBeTruthy = positive.toBeTruthy,
		toBeFalsy = positive.toBeFalsy,
		toBeNil = positive.toBeNil,
		toBeNear = positive.toBeNear,
		toThrow = positive.toThrow,
		never = build(actual, true),
	}
end

return expect
