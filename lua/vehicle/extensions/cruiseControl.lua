-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.hasReachedTargetSpeed = false
M.minimumSpeed = 30 / 3.6

local min = math.min
local max = math.max

local isEnabled = false
local targetSpeed = 0
local state = {}
local disableOnReset = false
local integral = 0
local lastError = 0
local lastThrottle = -1
local throttleSmooth = newTemporalSmoothing(2,0.5)

local function onReset()
  log("D", "CruiseControl", "Cruise Control online")
  if disableOnReset then
    isEnabled = false
    electrics.values.throttleOverride = nil
  end
  M.hasReachedTargetSpeed = false
  state = {}
  lastThrottle = -1
  throttleSmooth:reset()
end

local function updateGFX(dt)
  if not isEnabled then
    return
  end

  if input.brake > 0 then
    --disable cruise control when braking
    isEnabled = false
    electrics.values.throttleOverride = nil
    M.requestState()
    return
  end

  if input.clutch > 0 or input.throttle > 0 then
    --dont't do anything if we use the clutch or if we manually input a throttle value
    lastThrottle = input.throttle
    electrics.values.throttleOverride = input.throttle
    return
  end

  local acc = sensors.gy2 / obj:getGravity()
  local accError = max(acc - 0.4, 0)

  local currentSpeed = electrics.values.wheelspeed or 0
  local error = targetSpeed - currentSpeed
  integral = max(min(integral + error * dt, 7), 0)
  local derivative = (error - lastError) / dt;

  electrics.values.throttleOverride = throttleSmooth:getUncapped(max(max(min(error * 1.0 + integral * 0.15 + derivative * 0, 1), 0) - accError * 10, 0), dt)
  lastError = error
  lastThrottle = input.throttle

  M.hasReachedTargetSpeed = math.abs(lastError) / targetSpeed <= 0.02
end

local function setSpeed(speed)
  isEnabled = true
  targetSpeed = max(speed, M.minimumSpeed)
  M.hasReachedTargetSpeed = false
end

local function changeSpeed(offset)
  isEnabled = true
  targetSpeed = max(targetSpeed + offset, M.minimumSpeed)
  M.hasReachedTargetSpeed = false
end

local function holdCurrentSpeed()
  local currentSpeed = electrics.values.wheelspeed or 0
  if currentSpeed > M.minimumSpeed then
    setSpeed(currentSpeed)
  end
  M.requestState()
end

local function setEnabled(enabled)
  isEnabled = enabled
  M.hasReachedTargetSpeed = false
  electrics.values.throttleOverride = nil
  lastThrottle = -1
  throttleSmooth:reset()
  M.requestState()
end

local function requestState()
  state.targetSpeed = targetSpeed
  state.isEnabled = isEnabled

  if not playerInfo.firstPlayerSeated then return end
  guihooks.trigger('CruiseControlState', state)
end

local function getConfiguration()
  return { isEnabled = isEnabled, targetSpeed = targetSpeed, minimumSpeed = M.minimumSpeed, hasReachedTargetSpeed = M.hasReachedTargetSpeed }
end

-- public interface
M.onReset   = onReset
M.updateGFX = updateGFX
M.setSpeed = setSpeed
M.changeSpeed = changeSpeed
M.holdCurrentSpeed = holdCurrentSpeed
M.setEnabled = setEnabled
M.requestState = requestState
M.getConfiguration = getConfiguration

return M
