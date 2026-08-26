--!strict

-- adapted from Nevermore AccelTween (MIT)
-- copyright TreyReynolds/AxisAngles and Nevermore Engine contributors
-- https://github.com/Quenty/NevermoreEngine/blob/main/src/acceltween/src/Shared/AccelTween.lua

export type AccelTween = {
	p: number,
	v: number,
	a: number,
	t: number,
	rtime: number,
	pt: number,
	SetTarget: (self: AccelTween, target: number, doNotAnimate: boolean?) -> (),
	SetClock: (self: AccelTween, clock: () -> number) -> (),
	GetClock: (self: AccelTween) -> () -> number,
	_getState: (self: AccelTween, time: number) -> (number, number),
	_setState: (self: AccelTween, position: number?, velocity: number?, acceleration: number?, target: number?) -> (),
	_clock: () -> number,
	_accel: number,
	_t0: number,
	_y0: number,
	_a0: number,
	_t1: number,
	_y1: number,
	_a1: number,
}

const AccelTween = {}

function AccelTween.new(maxAcceleration: number?): AccelTween
	return setmetatable({
		_clock = os.clock,
		_accel = maxAcceleration or 1,
		_t0 = 0,
		_y0 = 0,
		_a0 = 0,
		_t1 = 0,
		_y1 = 0,
		_a1 = 0,
	}, AccelTween :: unknown) :: AccelTween
end

function AccelTween.SetTarget(self: AccelTween, target: number, doNotAnimate: boolean?): ()
	self.t = target
	if doNotAnimate then
		self.p = target
		self.v = 0
	end
end

function AccelTween.SetClock(self: AccelTween, clock: () -> number): ()
	const delta: number = clock() - self._clock()
	self._clock = clock
	self._t0 += delta
	self._t1 += delta
end

function AccelTween.GetClock(self: AccelTween): () -> number
	return self._clock
end

function AccelTween._getState(self: AccelTween, time: number): (number, number)
	if time < (self._t0 + self._t1) / 2 then
		const elapsed: number = time - self._t0
		return self._y0 + elapsed * elapsed / 2 * self._a0, elapsed * self._a0
	elseif time < self._t1 then
		const elapsed: number = time - self._t1
		return self._y1 + elapsed * elapsed / 2 * self._a1, elapsed * self._a1
	end
	return self._y1, 0
end

function AccelTween._setState(
	self: AccelTween,
	newPosition: number?,
	newVelocity: number?,
	newAcceleration: number?,
	newTarget: number?
): ()
	const time: number = self._clock()
	local position: number, velocity: number = self:_getState(time)
	position = newPosition or position
	velocity = newVelocity or velocity
	self._accel = newAcceleration or self._accel
	const target: number = newTarget or self._y1

	if self._accel * self._accel < 1e-8 then
		self._t0, self._y0, self._a0 = 0, position, 0
		self._t1, self._y1, self._a1 = math.huge, target, 0
		return
	end

	const targetBehind: boolean = target < position
	const movingBackward: boolean = velocity < 0
	const stopsPastTargetBackward: boolean = position - velocity * velocity / (2 * self._accel) < target
	const stopsBeforeTargetForward: boolean = position + velocity * velocity / (2 * self._accel) < target
	if targetBehind and movingBackward and stopsPastTargetBackward
		or not targetBehind and (movingBackward or not movingBackward and stopsBeforeTargetForward)
	then
		self._a0 = self._accel
		self._t1 = time + (math.sqrt(2 * velocity * velocity + 4 * self._accel * (target - position)) - velocity) / self._accel
	else
		self._a0 = -self._accel
		self._t1 = time + (math.sqrt(2 * velocity * velocity - 4 * self._accel * (target - position)) + velocity) / self._accel
	end
	self._t0 = time - velocity / self._a0
	self._y0 = position - velocity * velocity / (2 * self._a0)
	self._y1 = target
	self._a1 = -self._a0
end

function AccelTween.__index(self: AccelTween, index: string): unknown
	const method = (AccelTween :: { [string]: unknown })[index]
	if method ~= nil then
		return method
	elseif index == "p" then
		const position: number, _velocity: number = self:_getState(self._clock())
		return position
	elseif index == "v" then
		const _position: number, velocity: number = self:_getState(self._clock())
		return velocity
	elseif index == "a" then
		return self._accel
	elseif index == "t" then
		return self._y1
	elseif index == "rtime" then
		const time: number = self._clock()
		return if time < self._t1 then self._t1 - time else 0
	end
	error(`Bad AccelTween index "{index}"`, 2)
end

function AccelTween.__newindex(
	self: AccelTween,
	index: string,
	value: number
): ()
	if index == "p" then
		self:_setState(value, nil, nil, nil)
	elseif index == "v" then
		self:_setState(nil, value, nil, nil)
	elseif index == "a" then
		self:_setState(nil, nil, value, nil)
	elseif index == "t" then
		self:_setState(nil, nil, nil, value)
	elseif index == "pt" then
		self:_setState(value, 0, nil, value)
	else
		error(`Bad AccelTween index "{index}"`, 2)
	end
end

return table.freeze(AccelTween)
