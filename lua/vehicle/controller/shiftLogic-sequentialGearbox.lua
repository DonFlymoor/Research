-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs
local fsign = fsign

local constants = {rpmToAV = 0.104719755, avToRPM = 9.549296596425384}

local newDesiredGearIndex = 0
local gearbox = nil
local engine = nil

local sharedFunctions = nil
local gearboxAvailableLogic = nil
local gearboxLogic = nil

M.gearboxHandling = nil
M.timer = nil
M.timerConstants = nil
M.inputValues = nil
M.shiftPreventionData = nil
M.shiftBehavior = nil
M.smoothedValues = nil

M.currentGearIndex = 0
M.throttle = 0
M.brake = 0
M.clutchRatio = 0
M.isArcadeSwitched = false
M.isSportModeActive = false

M.smoothedAvgAVInput = 0
M.rpm = 0
M.idleRPM = 0
M.maxRPM = 0

M.engineThrottle = 0
M.engineLoad = 0
M.engineTorque = 0
M.gearboxTorque = 0

M.ignition = true
M.isEngineRunning = 0

M.oilTemp = 0
M.waterTemp = 0
M.checkEngine = false

M.energyStorages = {}

local clutchHandling = {
  clutchLaunchTargetAV = 0,
  clutchLaunchStartAV = 0,
  clutchLaunchIFactor = 0
}

local function getGearName()
  return gearbox.gearIndex
end

local function getGearPosition()
  return 0 --TODO, implement once H-shifter patterns are possible with props
end

local function gearboxBehaviorChanged(behavior)
  gearboxLogic = gearboxAvailableLogic[behavior]
  M.updateGearboxGFX = gearboxLogic.inGear
  M.shiftUp = gearboxLogic.shiftUp
  M.shiftDown = gearboxLogic.shiftDown
  M.shiftToGearIndex = gearboxLogic.shiftToGearIndex

  if behavior == "realistic" and not M.gearboxHandling.autoClutch and abs(gearbox.gearIndex) == 1 then
    gearbox:setGearIndex(0)
  end
end

local function shiftUp()
  local prevGearIndex = gearbox.gearIndex
  local gearIndex = newDesiredGearIndex == 0 and gearbox.gearIndex + 1 or newDesiredGearIndex + 1
  gearIndex = min(max(gearIndex, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[newDesiredGearIndex]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = prevGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end
end

local function shiftDown()
  local prevGearIndex = gearbox.gearIndex
  local gearIndex = newDesiredGearIndex == 0 and gearbox.gearIndex - 1 or newDesiredGearIndex - 1
  gearIndex = min(max(gearIndex, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[gearIndex]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = prevGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end
end

local function shiftToGearIndex(index)
  local prevGearIndex = gearbox.gearIndex
  local gearIndex = min(max(index, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[index]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = prevGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end
end

local function updateExposedData()
  M.rpm = engine and (engine.outputAV1 * constants.avToRPM) or 0
  M.smoothedAvgAVInput = sharedFunctions.updateAvgAVSingleDevice("gearbox")
  M.waterTemp = (engine and engine.thermals) and (engine.thermals.coolantTemperature and engine.thermals.coolantTemperature or engine.thermals.oilTemperature) or 0
  M.oilTemp = (engine and engine.thermals) and engine.thermals.oilTemperature or 0
  M.checkEngine = engine and engine.isDisabled or false
  M.ignition = engine and not engine.isDisabled or false
  M.engineThrottle = (engine and engine.isDisabled) and 0 or M.throttle
  M.engineLoad = engine and (engine.isDisabled and 0 or engine.instantEngineLoad) or 0
  M.running = engine and not engine.isDisabled or false
  M.engineTorque = engine and engine.combustionTorque or 0
  M.gearboxTorque = gearbox and gearbox.outputTorque or 0
  M.isEngineRunning = engine and ((engine.isStalled or engine.ignitionCoef <= 0) and 0 or 1) or 1
end

local function updateInGearArcade(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  local engineAV = engine.outputAV1

  -- driving backwards? - only with automatic shift - for obvious reasons ;)
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  --Arcade mode gets a "rev limiter" in case the engine does not have one
  if engineAV > engine.maxAV and not engine.hasRevLimiter then
    local throttleAdjust = min(max((engineAV - engine.maxAV * 1.02) / (engine.maxAV * 0.03), 0), 1)
    M.throttle = min(max(M.throttle - throttleAdjust, 0), 1)
  end

  if M.timer.gearChangeDelayTimer <= 0 and gearIndex ~= 0 then
    local tmpEngineAV = engineAV
    local relEngineAV = engineAV / gearbox.gearRatio

    sharedFunctions.selectShiftPoints(gearIndex)

    --shift down?
    if tmpEngineAV < M.shiftBehavior.shiftDownAV and abs(gearIndex) > 1 and M.shiftPreventionData.wheelSlipShiftDown and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold then
      gearIndex = gearIndex - fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV >= engine.maxAV * 0.85 then
        tmpEngineAV = relEngineAV / (gearbox.gearRatios[gearIndex] or 0)
        gearIndex = gearIndex + fsign(gearIndex)
      end
      sharedFunctions.selectShiftPoints(gearIndex)
    end

    local inGearRange = gearIndex < gearbox.maxGearIndex and gearIndex > gearbox.minGearIndex
    local clutchReady = M.clutchRatio >= 1
    local engineRevTooHigh = (tmpEngineAV >= M.shiftBehavior.shiftUpAV or engine.revLimiterActive)
    local throttleSpike = abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold
    local notBraking = M.brake <= 0
    --shift up?
    if clutchReady and engineRevTooHigh and M.shiftPreventionData.wheelSlipShiftUp and notBraking and throttleSpike and inGearRange then
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV < engine.idleAV then
        gearIndex = gearIndex - fsign(gearIndex)
      end
      sharedFunctions.selectShiftPoints(gearIndex)
    end
  end

  -- neutral gear handling
  if abs(gearIndex) <= 1 and M.timer.neutralSelectionDelayTimer <= 0 then
    if gearIndex ~= 0 and abs(M.smoothedValues.avgAV) < M.gearboxHandling.arcadeAutoBrakeAVThreshold and M.throttle <= 0 then
      M.brake = max(M.inputValues.brake, M.gearboxHandling.arcadeAutoBrakeAmount)
    end

    if M.smoothedValues.throttleInput > 0 and M.smoothedValues.brakeInput <= 0 and M.smoothedValues.avgAV > -1 and gearIndex < 1 then
      gearIndex = 1
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
    end

    if M.smoothedValues.brakeInput > 0 and M.smoothedValues.throttleInput <= 0 and M.smoothedValues.avgAV <= 0.15 and gearIndex > -1 then
      gearIndex = -1
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
    end

    if engine.ignitionCoef < 1 and gearIndex ~= 0 then
      gearIndex = 0
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end

  -- Control clutch to buildup engine RPM
  if abs(gearIndex) == 1 and M.throttle > 0 then
    local ratio = max((engine.outputAV1 - clutchHandling.clutchLaunchStartAV * (1 + M.throttle)) / (clutchHandling.clutchLaunchTargetAV * (1 + clutchHandling.clutchLaunchIFactor)), 0)
    clutchHandling.clutchLaunchIFactor = min(clutchHandling.clutchLaunchIFactor + dt * 0.5, 1)
    M.clutchRatio = min(max(ratio * ratio, 0), 1)
  else
    if M.smoothedValues.avgAV * gearbox.gearRatio * engine.outputAV1 > 0 then
      M.clutchRatio = 1
    elseif abs(gearbox.gearIndex) > 1 then
      M.brake = M.throttle
      M.throttle = 0
    end
    clutchHandling.clutchLaunchIFactor = 0
  end

  if M.inputValues.clutch > 0 then
    M.clutchRatio = min(1 - M.inputValues.clutch, M.clutchRatio)
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  --always prevent stalling
  if abs(gearbox.outputAV1 * gearbox.gearRatio) < engine.idleAV then
    local stallPrevent = min(max((engine.outputAV1 * 0.95 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
    M.clutchRatio = min(M.clutchRatio, stallPrevent * stallPrevent)
  end

  M.currentGearIndex = gearIndex
  updateExposedData()
end

local function updateWhileShiftingArcade(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end
  if newDesiredGearIndex > gearIndex and gearIndex ~= 0 then
    engine:cutIgnition(0.15)
  end

  gearbox:setGearIndex(newDesiredGearIndex)
  newDesiredGearIndex = 0
  M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  M.updateGearboxGFX = gearboxLogic.inGear
  updateExposedData()
end

local function updateInGear(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  -- Control clutch to buildup engine RPM
  if M.gearboxHandling.autoClutch then
    if abs(gearbox.gearIndex) == 1 and M.throttle > 0 then
      local ratio = max((engine.outputAV1 - clutchHandling.clutchLaunchStartAV * (1 + M.throttle)) / (clutchHandling.clutchLaunchTargetAV * (1 + clutchHandling.clutchLaunchIFactor)), 0)
      clutchHandling.clutchLaunchIFactor = min(clutchHandling.clutchLaunchIFactor + dt * 0.5, 1)
      M.clutchRatio = min(max(ratio * ratio, 0), 1)
    else
      if gearbox.outputAV1 * gearbox.gearRatio * engine.outputAV1 > 0 then
        M.clutchRatio = 1
      elseif abs(gearbox.gearIndex) > 1 then
        local ratio = max((engine.outputAV1 - clutchHandling.clutchLaunchStartAV * (1 + M.throttle)) / (clutchHandling.clutchLaunchTargetAV * (1 + clutchHandling.clutchLaunchIFactor)), 0)
        clutchHandling.clutchLaunchIFactor = min(clutchHandling.clutchLaunchIFactor + dt * 0.5, 1)
        M.clutchRatio = min(max(ratio * ratio, 0), 1)
      end
      clutchHandling.clutchLaunchIFactor = 0
    end

    if M.inputValues.clutch > 0 then
      M.clutchRatio = min(1 - M.inputValues.clutch, M.clutchRatio)
    end

    if abs(gearbox.outputAV1 * gearbox.gearRatio) < engine.idleAV then
      --always prevent stalling
      local stallPrevent = min(max((engine.outputAV1 * 0.95 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
      M.clutchRatio = min(M.clutchRatio, stallPrevent * stallPrevent)
    end

    if engine.isDisabled then
      M.clutchRatio = min(1 - M.inputValues.clutch, 1)
    end

    if engine.ignitionCoef < 1 or (engine.idleAVStartOffset > 1 and M.throttle <= 0) then
      M.clutchRatio = 0
    end
  else
    M.clutchRatio = 1 - M.inputValues.clutch
  end
  M.currentGearIndex = gearbox.gearIndex
  updateExposedData()
end

local function updateWhileShifting(dt)
  -- old -> N -> wait -> new -> in gear update
  M.brake = M.inputValues.brake
  M.throttle = M.inputValues.throttle
  M.isArcadeSwitched = false
  if newDesiredGearIndex > gearbox.gearIndex and gearbox.gearIndex ~= 0 then
    engine:cutIgnition(0.15)
  end

  gearbox:setGearIndex(newDesiredGearIndex)
  newDesiredGearIndex = 0
  M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  M.updateGearboxGFX = gearboxLogic.inGear
  updateExposedData()
end

local function sendTorqueData()
  if engine then
    engine:sendTorqueData()
  end
end

local function init(jbeamData, sharedFunctionTable)
  sharedFunctions = sharedFunctionTable
  engine = powertrain.getDevice("mainEngine")
  gearbox = powertrain.getDevice("gearbox")
  newDesiredGearIndex = 0

  M.currentGearIndex = 0
  M.throttle = 0
  M.brake = 0
  M.clutchRatio = 0

  gearboxAvailableLogic = {
    arcade = {
      inGear = updateInGearArcade,
      whileShifting = updateWhileShiftingArcade,
      shiftUp = sharedFunctions.warnCannotShiftSequential,
      shiftDown = sharedFunctions.warnCannotShiftSequential,
      shiftToGearIndex = sharedFunctions.switchToRealisticBehavior
    },
    realistic = {
      inGear = updateInGear,
      whileShifting = updateWhileShifting,
      shiftUp = shiftUp,
      shiftDown = shiftDown,
      shiftToGearIndex = shiftToGearIndex
    }
  }

  clutchHandling.clutchLaunchTargetAV = (jbeamData.clutchLaunchTargetRPM or 3000) * constants.rpmToAV * 0.5
  clutchHandling.clutchLaunchStartAV = ((jbeamData.clutchLaunchStartRPM or 2000) * constants.rpmToAV - engine.idleAV) * 0.5
  clutchHandling.clutchLaunchIFactor = 0

  M.maxRPM = engine.maxRPM
  M.idleRPM = engine.idleRPM
  M.maxGearIndex = gearbox.maxGearIndex
  M.minGearIndex = abs(gearbox.minGearIndex)
  M.energyStorages = sharedFunctions.getEnergyStorages({engine})
end

M.init = init

M.gearboxBehaviorChanged = gearboxBehaviorChanged
M.shiftUp = shiftUp
M.shiftDown = shiftDown
M.shiftToGearIndex = shiftToGearIndex
M.updateGearboxGFX = nop
M.getGearName = getGearName
M.getGearPosition = getGearPosition
M.sendTorqueData = sendTorqueData

return M
