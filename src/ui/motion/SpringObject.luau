--!strict

-- Adapted from Quenty's Nevermore Spring and SpringObject (MIT).
-- Copyright (c) Quenty and Nevermore Engine contributors.
-- https://github.com/Quenty/NevermoreEngine/tree/main/src/spring

const Observable = require("./../reactive/Observable")
const Scheduler = require("@self/Scheduler")

export type Observable<T> = {
	ClassName: string,
	Subscribe: (self: Observable<T>, fire: ((T) -> ())?, fail: ((...unknown) -> ())?, complete: (() -> ())?) -> { Destroy: (self: any) -> () },
}

export type SpringObject<T> = {
	Observe: (self: SpringObject<T>) -> Observable<T>,
	SetTarget: (self: SpringObject<T>, target: T, doNotAnimate: boolean?) -> (() -> ()),
	Impulse: (self: SpringObject<T>, velocity: T) -> (),
	IsAnimating: (self: SpringObject<T>) -> boolean,
	SetClock: (self: SpringObject<T>, clock: () -> number) -> (),
	SetEpsilon: (self: SpringObject<T>, epsilon: number) -> (),
	Destroy: (self: SpringObject<T>) -> (),
	Value: T,
	Position: T,
	Velocity: T,
	Target: T,
	Speed: number,
	Damper: number,
	_clock: () -> number,
	_time0: number,
	_position0: T,
	_velocity0: T,
	_target: T,
	_speed: number,
	_damper: number,
	_epsilon: number,
	_destroyed: boolean,
	_observers: { [number]: (T) -> () },
	_nextObserver: number,
	_stopStep: (() -> ())?,
}

const SpringObject = {}

const function positionVelocity<T>(self: SpringObject<T>, now: number): (T, T)
	const p0: any = self._position0
	const v0: any = self._velocity0
	const p1: any = self._target
	const damping = self._damper
	const speed = self._speed
	const elapsed = speed * (now - self._time0)
	if speed == 0 then
		return p0 :: T, v0 :: T
	end

	const dampingSquared = damping * damping
	local h: number
	local sine: number
	local cosine: number
	if dampingSquared < 1 then
		h = math.sqrt(1 - dampingSquared)
		const exponential = math.exp(-damping * elapsed) / h
		cosine, sine = exponential * math.cos(h * elapsed), exponential * math.sin(h * elapsed)
	elseif dampingSquared == 1 then
		h = 1
		const exponential = math.exp(-damping * elapsed)
		cosine, sine = exponential, exponential * elapsed
	else
		h = math.sqrt(dampingSquared - 1)
		const positive = math.exp((-damping + h) * elapsed) / (2 * h)
		const negative = math.exp((-damping - h) * elapsed) / (2 * h)
		cosine, sine = positive + negative, positive - negative
	end

	const position: any = (h * cosine + damping * sine) * p0
		+ (1 - (h * cosine + damping * sine)) * p1
		+ (sine / speed) * v0
	const velocity: any = (-speed * sine) * p0
		+ (speed * sine) * p1
		+ (h * cosine - damping * sine) * v0
	return position :: T, velocity :: T
end

const function magnitude(value: any): number
	return if type(value) == "number" then math.abs(value) else value.Magnitude
end

const function emit<T>(self: SpringObject<T>, value: T): ()
	for _, observer: (T) -> () in self._observers do
		observer(value)
	end
end

const function isAnimating<T>(self: SpringObject<T>): (boolean, T)
	const position, velocity = positionVelocity(self, self._clock())
	const animating = magnitude((position :: any) - (self._target :: any)) > self._epsilon
		or magnitude(velocity) > self._epsilon
	return animating, if animating then position else self._target
end

const function start<T>(self: SpringObject<T>): ()
	if self._stopStep or self._destroyed or next(self._observers) == nil then
		return
	end
	self._stopStep = Scheduler.add(function(_deltaTime: number): boolean
		const animating, value = isAnimating(self)
		emit(self, value)
		if animating and not self._destroyed then
			return true
		end
		self._stopStep = nil
		return false
	end)
end

function SpringObject.new<T>(target: T, speed: number?, damper: number?): SpringObject<T>
	const clock = os.clock
	return setmetatable({
		_clock = clock,
		_time0 = clock(),
		_position0 = target,
		_velocity0 = (0 :: any) * target,
		_target = target,
		_speed = speed or 1,
		_damper = damper or 1,
		_epsilon = 1e-6,
		_destroyed = false,
		_observers = {},
		_nextObserver = 0,
		_stopStep = nil,
	}, SpringObject :: any) :: any
end

function SpringObject.Observe<T>(self: SpringObject<T>): Observable<T>
	return Observable.new(function(sink: any): () -> ()
		assert(not self._destroyed, "SpringObject is destroyed")
		self._nextObserver += 1
		const id = self._nextObserver
		self._observers[id] = function(value: T): ()
			sink:Fire(value)
		end
		const _, value = isAnimating(self)
		sink:Fire(value)
		start(self)
		return function(): ()
			self._observers[id] = nil
			if next(self._observers) == nil and self._stopStep then
				self._stopStep()
				self._stopStep = nil
			end
		end
	end) :: any
end

function SpringObject.SetTarget<T>(self: SpringObject<T>, target: T, doNotAnimate: boolean?): () -> ()
	assert(not self._destroyed, "SpringObject is destroyed")
	const now = self._clock()
	if doNotAnimate then
		self._position0 = target
		self._velocity0 = (0 :: any) * target
	else
		self._position0, self._velocity0 = positionVelocity(self, now)
	end
	self._target = target
	self._time0 = now
	if doNotAnimate then
		emit(self, target)
	else
		start(self)
	end
	return function(): () end
end

function SpringObject.Impulse<T>(self: SpringObject<T>, velocity: T): ()
	assert(not self._destroyed, "SpringObject is destroyed")
	const now = self._clock()
	self._position0, self._velocity0 = positionVelocity(self, now)
	self._velocity0 = ((self._velocity0 :: any) + velocity) :: T
	self._time0 = now
	start(self)
end

function SpringObject.IsAnimating<T>(self: SpringObject<T>): boolean
	const animating: boolean, _value: T = isAnimating(self)
	return animating
end

function SpringObject.SetClock<T>(self: SpringObject<T>, clock: () -> number): ()
	const position, velocity = positionVelocity(self, self._clock())
	self._position0, self._velocity0 = position, velocity
	self._clock = clock
	self._time0 = clock()
end

function SpringObject.SetEpsilon<T>(self: SpringObject<T>, epsilon: number): ()
	assert(epsilon > 0, "epsilon must be positive")
	self._epsilon = epsilon
end

function SpringObject.Destroy<T>(self: SpringObject<T>): ()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._stopStep then
		self._stopStep()
		self._stopStep = nil
	end
	table.clear(self._observers)
end

(SpringObject :: any).__index = function<T>(self: SpringObject<T>, key: string): any
	const method = (SpringObject :: any)[key]
	if method then
		return method
	elseif key == "Value" or key == "Position" then
		const position: T, _velocity: T = positionVelocity(self, self._clock())
		return position
	elseif key == "Velocity" then
		const _, velocity = positionVelocity(self, self._clock())
		return velocity
	elseif key == "Target" then
		return self._target
	elseif key == "Speed" then
		return self._speed
	elseif key == "Damper" then
		return self._damper
	end
	error(`{key} is not a member of SpringObject`, 2)
end

return table.freeze(SpringObject)
