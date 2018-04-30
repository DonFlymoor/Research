-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil
M.defaultOrder = 600

local min = math.min
local floor = math.floor

local name = nil
local electricsName = nil
local absBlinkTimer = 0
local absBlinkOffTimer = 0
local absBlinkTime = 0
local absBlinkOffTime = 0
local blinkPulse = 1
local absActiveSmoother = nil
local escActiveSmoother = nil
local indicateESCUsageWithBrakelights = true
local activateHazardsAfterEmergencyBraking = true
local hazardArmSpeed = 10
local hazardActivateSpeed = 3
local hazardDeactivateThrottle = 0.3
local hazardDeactivateSpeed = 3
local emergencyBrakingHazardsArmed = false
local emergencyBrakingHazardsActive = false

local function updateGFX(dt)
  local absActive = absActiveSmoother:getUncapped(electrics.values.absActive or 0, dt)
  local escActive = escActiveSmoother:getUncapped(electrics.values.escActive and 1 or 0, dt)

  if blinkPulse > 0 then
    absBlinkTimer = absBlinkTimer + dt * absActive
    if absBlinkTimer > absBlinkTime then
      absBlinkTimer = 0
      blinkPulse = 0
    end
  end

  if blinkPulse <= 0 then
    absBlinkOffTimer = absBlinkOffTimer + dt
    if absBlinkOffTimer > absBlinkOffTime then
      absBlinkOffTimer = 0
      blinkPulse = 1
    end
  end

  if electrics.values.wheelspeed >= hazardArmSpeed then
    emergencyBrakingHazardsArmed = true
  elseif absActive <= 0 then
    emergencyBrakingHazardsArmed = false
  end

  if emergencyBrakingHazardsArmed and absActive > 0 and electrics.values.wheelspeed < hazardActivateSpeed and activateHazardsAfterEmergencyBraking then
    electrics.set_warn_signal(true)
    emergencyBrakingHazardsActive = true
  end

  if emergencyBrakingHazardsActive and electrics.values.throttle > hazardDeactivateThrottle and electrics.values.wheelspeed > hazardDeactivateSpeed then
    electrics.set_warn_signal(false)
    emergencyBrakingHazardsActive = false
  end

  local escBrakeValue = floor(escActive)

  local brakeValue = min(electrics.values.brake + escBrakeValue, 1)
  electrics.values[electricsName] = brakeValue * blinkPulse
end

local function reset()
  if emergencyBrakingHazardsActive then
    electrics.set_warn_signal(false)
  end

  absBlinkTimer = 0
  absBlinkOffTimer = 0
  blinkPulse = 1
  absActiveSmoother:reset()
  escActiveSmoother:reset()
  emergencyBrakingHazardsArmed = false
  emergencyBrakingHazardsActive = false
end

local function init(jbeamData)
  name = jbeamData.name
  electricsName = jbeamData.electricsName or "brakelights"
  indicateESCUsageWithBrakelights = jbeamData.indicateESCUsageWithBrakelights == nil and true or jbeamData.indicateESCUsageWithBrakelights
  activateHazardsAfterEmergencyBraking = jbeamData.activateHazardsAfterEmergencyBraking == nil and true or jbeamData.activateHazardsAfterEmergencyBraking
  hazardArmSpeed = jbeamData.hazardArmSpeed or 10
  hazardActivateSpeed = jbeamData.hazardActivateSpeed or 3
  hazardDeactivateThrottle = jbeamData.hazardDeactivateThrottle or 0.3
  hazardDeactivateSpeed = jbeamData.hazardDeactivateSpeed or 3
  absBlinkTime = jbeamData.blinkOnTime or 0.1
  absBlinkOffTime = jbeamData.blinkOffTime or 0.1

  absBlinkTimer = 0
  absBlinkOffTimer = 0
  blinkPulse = 1
  absActiveSmoother = newTemporalSmoothing(2,2)
  escActiveSmoother = newTemporalSmoothing(2,2)
  emergencyBrakingHazardsArmed = false
  emergencyBrakingHazardsActive = false
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M