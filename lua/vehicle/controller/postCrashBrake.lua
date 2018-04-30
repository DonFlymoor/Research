-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local abs = math.abs

local state = "idle"
local brakeThreshold = 0
local crashCounter = 0
local crashCountThreshold = 0
local lastThrottle = 0

local function updateGFX(dt)
  if state == "idle" then
    if (abs(sensors.gx2) > brakeThreshold or abs(sensors.gy2) > brakeThreshold) then
      state = "braking"
      crashCounter = crashCounter + 1
      electrics.set_warn_signal(true)
      gui.message("Impact detected, stopping car...", 10, "vehicle.postCrashBrake.impact")
    end
  elseif state == "braking" then
    electrics.values.brake = 1
    electrics.values.throttle = 0
    input.event("throttle", 0, 0)

    if abs(electrics.values.wheelspeed) < 0.5 or electrics.values.gearIndex < 0 then
      input.event("parkingbrake", 1, 0)
      state = "holding"
      lastThrottle = input.throttle
    end
  elseif state == "holding" then
    electrics.values.brake = 1
    if input.throttle > lastThrottle * 1.1 then
      input.event("parkingbrake", 0, 0)
      electrics.set_warn_signal(false)
      state = crashCounter <= crashCountThreshold and "idle" or "disabled"
    end
    lastThrottle = input.throttle
  end
end

local function init(data)
  --if the hazards are still active from before reset, deactivate them
  if state == "holding" or state == "braking" then
    electrics.set_warn_signal(false)
  end

  state = "idle"
  crashCounter = 0
  lastThrottle = 0
  brakeThreshold = data.brakeThreshold or 50
  crashCountThreshold = data.crashCountThreshold or 3
end

M.init = init
M.updateGFX = updateGFX

return M