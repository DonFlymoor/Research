-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- This file contains several smoothing filters. Please refer to the documentation
-- created by BeamNG

local max = math.max
local min = math.min
local abs = math.abs

--== Filter codenames ==--
FILTER_KBD    = 0
FILTER_PAD    = 1
FILTER_DIRECT = 2
FILTER_KBD2   = 3

--== TemporalSpring ==--
local temporalSpring = {}
temporalSpring.__index = temporalSpring

function newTemporalSpring(spring, damp, startingValue)
  local data = {spring = spring or 10, damp = damp or 2, state = startingValue or 0, vel = 0}
  setmetatable(data, temporalSpring)
  return data
end

function temporalSpring:get(sample, dt)
  self.vel = self.vel * max(1 - self.damp * dt, 0) + (sample - self.state) * min(self.spring * dt, 1/dt)
  self.state = self.state + self.vel * dt
  return self.state
end

function temporalSpring:set(sample)
  self.state = sample
  self.vel = 0
end

function temporalSpring:value()
  return self.state
end

--== TemporalSigmoidSmoothing ==--
local temporalSigmoidSmoothing = {}
temporalSigmoidSmoothing.__index = temporalSigmoidSmoothing

function newTemporalSigmoidSmoothing(inRate, startAccel, stopAccel, outRate, startingValue)
  local rate = inRate or 1
  local startaccel = startAccel or math.huge
  local data = {[false] = rate, [true] = outRate or rate, startAccel = startaccel, stopAccel = stopAccel or startaccel, state = startingValue or 0, prevvel = 0}
  setmetatable(data, temporalSigmoidSmoothing)
  return data
end

function temporalSigmoidSmoothing:get(sample, dt)
  local dif = sample - self.state

  local prevvel = self.prevvel * max(fsign(self.prevvel * dif), 0)
  local vsq = prevvel * prevvel
  local absdif = abs(dif)
  local difsign = dif / (absdif + 1e-307)
  local acceldt

  local absdif2 = absdif * 2
  if vsq > absdif2 * self.stopAccel then
    acceldt = -difsign * min((vsq / absdif2) * dt, abs(prevvel))
  else
    acceldt = difsign * self.startAccel * dt
  end

  local ratelimit = self[dif * self.state >= 0]
  self.state = self.state + difsign * min(min(abs(prevvel + 0.5 * acceldt), ratelimit) * dt, absdif)
  self.prevvel = difsign * min(abs(prevvel + acceldt), ratelimit)
  return self.state
end

function temporalSigmoidSmoothing:getWithRateAccel(sample, dt, ratelimit, startAccel, stopAccel)
  local dif = sample - self.state
  local prevvel = self.prevvel * max(fsign(self.prevvel * dif), 0)
  local vsq = prevvel * prevvel
  local absdif = abs(dif)
  local difsign = dif / (absdif + 1e-307)
  local acceldt

  local absdif2 = absdif * 2
  if vsq > absdif2 * (stopAccel or startAccel) then
    acceldt = -difsign * min((vsq / absdif2) * dt, abs(prevvel))
  else
    acceldt = difsign * startAccel * dt
  end

  self.state = self.state + difsign * min(min(abs(prevvel + 0.5 * acceldt), ratelimit) * dt, absdif)
  self.prevvel = difsign * min(abs(prevvel + acceldt), ratelimit)
  return self.state
end

function temporalSigmoidSmoothing:set(sample)
  self.state = sample
  self.prevvel = 0
end

function temporalSigmoidSmoothing:value()
  return self.state
end

--== TemporalSmoothingNonLinear ==--
local temporalSmoothingNonLinear = {}
temporalSmoothingNonLinear.__index = temporalSmoothingNonLinear

function newTemporalSmoothingNonLinear(inRate, outRate, startingValue)
  local rate = inRate or 1
  local data = {[false] = rate, [true] = outRate or rate, state = startingValue or 0}
  setmetatable(data, temporalSmoothingNonLinear)
  return data
end

function temporalSmoothingNonLinear:get(sample, dt)
  local dif = sample - self.state
  self.state = self.state + dif * min(self[dif * self.state >= 0] * dt, 1)
  return self.state
end

function temporalSmoothingNonLinear:getWithRate(sample, dt, rate)
  self.state = self.state + (sample - self.state) * min(rate * dt, 1)
  return self.state
end

function temporalSmoothingNonLinear:set(sample)
  self.state = sample
end

function temporalSmoothingNonLinear:value()
  return self.state
end

function temporalSmoothingNonLinear:reset()
  self.state = 0
end

--== TemporalSmoothing ==--
local temporalSmoothing = {}
temporalSmoothing.__index = temporalSmoothing

function newTemporalSmoothing(inRate, outRate, autoCenterRate, startingValue)
  inRate = max(inRate or 1, 1e-307)
  startingValue = startingValue or 0

  local data = {[false] = inRate, [true] = max(outRate or inRate, 1e-307),
                autoCenterRate = max(autoCenterRate or inRate, 1e-307),
                _startingValue = startingValue,
                state = startingValue}

  setmetatable(data, temporalSmoothing)

  if data.autoCenterRate ~= inRate then
    data.getUncapped = data.getUncappedAutoCenter
  end
  return data
end

function temporalSmoothing:getUncappedAutoCenter(sample, dt)
  local st = self.state
  local dif = (sample - st)
  local rate

  if sample == 0 then
    rate = self.autoCenterRate  -- autocentering
  else
    rate = self[dif * st >= 0]
  end
  st = st + dif * min(rate * dt / abs(dif), 1)
  self.state = st
  return st
end

function temporalSmoothing:getUncapped(sample, dt) -- no autocenter
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(self[dif * st >= 0] * dt / abs(dif), 1)
  self.state = st
  return st
end

function temporalSmoothing:get(sample, dt)
  return max(min(self:getUncapped(sample, dt), 1), -1)
end

function temporalSmoothing:getWithRateUncapped(sample, dt, rate)
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(rate * dt / (abs(dif) + 1e-307), 1)
  self.state = st
  return st
end

function temporalSmoothing:getWithRate(sample, dt, rate)
  return max(min(self:getWithRateUncapped(sample, dt, rate), 1), -1)
end

function temporalSmoothing:reset()
  self.state = self._startingValue
end

function temporalSmoothing:value()
  return self.state
end

function temporalSmoothing:set(v)
  self.state = v
end

--== LinearSmoothing ==--
local linearSmoothing = {}
linearSmoothing.__index = linearSmoothing

function newLinearSmoothing(dt, inRate, outRate)
  inRate = max(inRate or 1, 1e-307)
  local data = {[false] = inRate * dt, [true] = max(outRate or inRate, 1e-307) * dt, state = 0}
  setmetatable(data, linearSmoothing)
  return data
end

function linearSmoothing:get(sample) -- no autocenter
  local st = self.state
  local dif = (sample - st)
  st = st + dif * min(self[dif * st >= 0] / abs(dif), 1)
  self.state = st
  return st
end

function linearSmoothing:set(v)
  self.state = v
end

function linearSmoothing:reset()
  self.state = 0
end

--== ExponentialSmoothing ==--
local ExponentialSmoothing = {}
ExponentialSmoothing.__index = ExponentialSmoothing

-- creation method of the object, inits the member variables
function newExponentialSmoothing(window, startingValue)
  local data = {a = 2 / window, _startingValue = startingValue or 0, st = startingValue or 0}
  setmetatable(data, ExponentialSmoothing)
  return data
end

function ExponentialSmoothing:get(sample)
  local st = self.st
  st = st + self.a * (sample - st)
  self.st = st
  return st
end

function ExponentialSmoothing:getWindow(sample, window)
  local st = self.st
  st = st + 2 * (sample - st) / max(window, 2)
  self.st = st
  return st
end

function ExponentialSmoothing:value()
  return self.st
end

function ExponentialSmoothing:set(value)
  self.st = value
end

function ExponentialSmoothing:reset(value)
  self.st = self._startingValue
end
