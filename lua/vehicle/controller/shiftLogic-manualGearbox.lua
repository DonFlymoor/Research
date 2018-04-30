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
local previousGearIndex = 0
local shiftAggression = 1
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

local clutchHandling = {
  clutchInRate = 5,
  clutchOutRate = 5,
  clutchLaunchTargetAV = 0,
  clutchLaunchStartAV = 0,
  clutchLaunchIFactor = 0,
  preShiftClutchRatio = 0,
  shiftState = "clutchIn",
  revMatchThrottle = 0.5,
  didRevMatch = false,
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

local function calculateShiftAggression()
  local gearRatioDifference = min(max(abs(gearbox.gearRatios[previousGearIndex] - gearbox.gearRatios[newDesiredGearIndex]), 0), 0.8)
  local gearingCoef = min(1 - gearRatioDifference, 0.4)

  local aggressionCoef = 0.5 * M.smoothedValues.drivingAggression

  shiftAggression = 0.1 + aggressionCoef + gearingCoef
end

local function shiftUp()
  local previousGearIndex = gearbox.gearIndex
  local gearIndex = newDesiredGearIndex == 0 and gearbox.gearIndex + 1 or newDesiredGearIndex + 1
  gearIndex = min(max(gearIndex, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[newDesiredGearIndex]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = previousGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox.gearIndex
    clutchHandling.shiftState = "clutchIn"
    clutchHandling.preShiftClutchRatio = M.clutchRatio
    calculateShiftAggression()
    M.updateGearboxGFX  = gearboxLogic.whileShifting
  end
end

local function shiftDown()
  local previousGearIndex = gearbox.gearIndex
  local gearIndex = newDesiredGearIndex == 0 and gearbox.gearIndex - 1 or newDesiredGearIndex - 1
  gearIndex = min(max(gearIndex, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[gearIndex]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = previousGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox.gearIndex
    clutchHandling.shiftState = "clutchIn"
    clutchHandling.preShiftClutchRatio = M.clutchRatio
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end
end

local function shiftToGearIndex(index)
  local previousGearIndex = gearbox.gearIndex
  local gearIndex = min(max(index, gearbox.minGearIndex), gearbox.maxGearIndex)

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = gearbox.gearRatios[index]
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      gearIndex = previousGearIndex
    end
  end

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox.gearIndex
    M.timer.shiftDelayTimer = 0
    clutchHandling.shiftState = "clutchIn"
    clutchHandling.preShiftClutchRatio = M.clutchRatio
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end
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
    while tmpEngineAV < M.shiftBehavior.shiftDownAV and abs(gearIndex) > 1 and M.shiftPreventionData.wheelSlipShiftDown and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold do
      gearIndex = gearIndex - fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV >= engine.maxAV * 0.85 then
        tmpEngineAV = relEngineAV / (gearbox.gearRatios[gearIndex] or 0)
        gearIndex = gearIndex + fsign(gearIndex)
        sharedFunctions.selectShiftPoints(gearIndex)
        break
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
    if abs(M.smoothedValues.avgAV) < M.gearboxHandling.arcadeAutoBrakeAVThreshold and M.throttle <= 0 then
      M.brake = max(M.inputValues.brake, M.gearboxHandling.arcadeAutoBrakeAmount)
    end

    if M.smoothedValues.throttleInput > 0 and M.smoothedValues.brakeInput <= 0 and M.smoothedValues.avgAV > -1 and gearIndex < 1 then
      gearIndex = 1
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
    end

    if M.smoothedValues.brakeInput > 0 and M.smoothedValues.throttleInput <= 0 and M.smoothedValues.avgAV <= 0.15 and electrics.values.airspeed < 2 and gearIndex > -1 then
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
    previousGearIndex = gearbox.gearIndex
    clutchHandling.shiftState = "clutchIn"
    calculateShiftAggression()
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
    local stallPrevent = min(max((engine.outputAV1 * 0.95 - engine.idleAV ) / (engine.idleAV * 0.1), 0), 1)
    M.clutchRatio = min(M.clutchRatio, stallPrevent * stallPrevent)
  end

  clutchHandling.preShiftClutchRatio = M.clutchRatio
  M.currentGearIndex = gearIndex
end

local function updateWhileShiftingArcade(dt)
  -- old -> N -> wait -> new -> in gear update
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  --set throttle to zero when we are actually shifting, this does not apply when going from N to 1 or -1
  M.throttle = (abs(gearIndex) <= 1 and abs(newDesiredGearIndex) <= 1) and M.inputValues.throttle or 0

  if clutchHandling.shiftState == "clutchIn" then
    M.clutchRatio = max(M.clutchRatio - dt * clutchHandling.clutchInRate * shiftAggression, 0)
    if M.clutchRatio <= 0 then
      if previousGearIndex ~= 0 then
        clutchHandling.shiftState = "neutral"
      else
        clutchHandling.shiftState = "shift"
      end
    end

  elseif clutchHandling.shiftState == "neutral" then
    gearbox:setGearIndex(0)
    M.timer.shiftDelayTimer = M.timerConstants.shiftDelay / shiftAggression
    clutchHandling.shiftState = "shift"

  elseif clutchHandling.shiftState == "shift" then
    local canShift = true
    local isEngineRunning = engine.ignitionCoef >= 1 and not engine.isStalled
    local targetAV = (gearbox.gearRatios[newDesiredGearIndex] / gearbox.gearRatios[previousGearIndex]) * (gearbox.outputAV1 * gearbox.gearRatios[previousGearIndex])
    if targetAV > engine.outputAV1 and previousGearIndex ~= 0 and not clutchHandling.didRevMatch and clutchHandling.preShiftClutchRatio >= 1 and isEngineRunning then
      M.throttle = clutchHandling.revMatchThrottle
      canShift = engine.outputAV1 >= targetAV or targetAV > engine.maxAV
      clutchHandling.didRevMatch = canShift
    end
    if M.timer.shiftDelayTimer <= 0 and canShift then
      gearbox:setGearIndex(newDesiredGearIndex)
      newDesiredGearIndex = 0
      previousGearIndex = 0
      M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
      clutchHandling.didRevMatch = false
      clutchHandling.shiftState = "clutchOut"
    end

  elseif clutchHandling.shiftState == "clutchOut" then
    if clutchHandling.preShiftClutchRatio > 0 then
      local stallPrevent = min(max((engine.outputAV1 * 0.9 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
      M.clutchRatio = min(M.clutchRatio + dt * clutchHandling.clutchOutRate * shiftAggression, stallPrevent * stallPrevent)
      if M.clutchRatio >= 1 or stallPrevent < 1 then
        M.updateGearboxGFX = gearboxLogic.inGear
      end
    else
      M.updateGearboxGFX = gearboxLogic.inGear
    end
  end
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

    if engine.ignitionCoef < 1 or ((engine.idleAVStartOffset or 0) > 1 and M.throttle <= 0) then
      M.clutchRatio = 0
    end
  else
    M.clutchRatio = 1 - M.inputValues.clutch
  end
  M.currentGearIndex = gearbox.gearIndex
end

local function updateWhileShifting(dt)
  -- old -> N -> wait -> new -> in gear update
  if M.gearboxHandling.autoThrottle then
    --set throttle to zero when we are actually shifting, this does not apply when going from N to 1 or -1
    M.throttle = (abs(gearbox.gearIndex) <= 1 and abs(newDesiredGearIndex) <= 1) and M.inputValues.throttle or 0
  else
    M.throttle = M.inputValues.throttle
  end
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  if clutchHandling.shiftState == "clutchIn" then
    if M.gearboxHandling.autoClutch then
      M.clutchRatio = max(M.clutchRatio - dt * clutchHandling.clutchInRate * shiftAggression, 0)
      if M.clutchRatio <= 0 then
        if gearbox.gearIndex ~= 0 then
          clutchHandling.shiftState = "neutral"
        else
          clutchHandling.shiftState = "shift"
        end
      end
    else
      M.clutchRatio = min(1 - M.inputValues.clutch, M.clutchRatio)
      if gearbox.gearIndex ~= 0 then
        clutchHandling.shiftState = "neutral"
      else
        clutchHandling.shiftState = "shift"
      end
    end

  elseif clutchHandling.shiftState == "neutral" then
    gearbox:setGearIndex(0)
    M.timer.shiftDelayTimer = M.timerConstants.shiftDelay / (M.gearboxHandling.autoClutch and shiftAggression or 1)
    clutchHandling.shiftState = "shift"

  elseif clutchHandling.shiftState == "shift" then
    local canShift = true
    local targetAV = gearbox.gearRatios[newDesiredGearIndex] * gearbox.outputAV1
    local isEngineRunning = engine.ignitionCoef >= 1 and not engine.isStalled
    if M.gearboxHandling.autoThrottle and targetAV > engine.outputAV1 and not clutchHandling.didRevMatch and clutchHandling.preShiftClutchRatio >= 1 and isEngineRunning then
      M.throttle = clutchHandling.revMatchThrottle
      canShift = engine.outputAV1 >= targetAV or targetAV > engine.maxAV
      clutchHandling.didRevMatch = canShift
    end
    if not M.gearboxHandling.autoClutch then
      M.clutchRatio = min(1 - M.inputValues.clutch, M.clutchRatio)
    end
    if M.timer.shiftDelayTimer <= 0 and canShift then
      gearbox:setGearIndex(newDesiredGearIndex)
      newDesiredGearIndex = gearbox.gearIndex == newDesiredGearIndex and 0 or newDesiredGearIndex
      previousGearIndex = 0
      M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
      clutchHandling.didRevMatch = false
      clutchHandling.shiftState = "clutchOut"
    end
  elseif clutchHandling.shiftState == "clutchOut" then
    if M.gearboxHandling.autoClutch and clutchHandling.preShiftClutchRatio > 0 then
      local stallPrevent = min(max((engine.outputAV1 * 0.9 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
      M.clutchRatio = min(M.clutchRatio + dt * clutchHandling.clutchOutRate * shiftAggression, stallPrevent)
      if M.clutchRatio >= 1 or stallPrevent < 1 then
        M.updateGearboxGFX = gearboxLogic.inGear
      end
    else
      if not M.gearboxHandling.autoClutch then
        M.clutchRatio = 1 - M.inputValues.clutch
      end
      M.updateGearboxGFX = gearboxLogic.inGear
    end
  end
end

local function init(jbeamData, expectedDeviceNames, sharedFunctionTable, shiftPoints, engineDevice, gearboxDevice)
  sharedFunctions = sharedFunctionTable
  engine = engineDevice
  gearbox = gearboxDevice
  newDesiredGearIndex = 0
  previousGearIndex = 0

  M.currentGearIndex = 0
  M.throttle = 0
  M.brake = 0
  M.clutchRatio = 0

  gearboxAvailableLogic = {
    arcade =
    {
      inGear = updateInGearArcade,
      whileShifting = updateWhileShiftingArcade,
      shiftUp = sharedFunctions.warnCannotShiftSequential,
      shiftDown = sharedFunctions.warnCannotShiftSequential,
      shiftToGearIndex = sharedFunctions.switchToRealisticBehavior,
    },
    realistic =
    {
      inGear = updateInGear,
      whileShifting = updateWhileShifting,
      shiftUp = shiftUp,
      shiftDown = shiftDown,
      shiftToGearIndex = shiftToGearIndex,
    }
  }

  clutchHandling.clutchLaunchTargetAV = (jbeamData.clutchLaunchTargetRPM or 3000) * constants.rpmToAV * 0.5
  clutchHandling.clutchLaunchStartAV = ((jbeamData.clutchLaunchStartRPM or 2000) * constants.rpmToAV - engine.idleAV) * 0.5
  clutchHandling.clutchLaunchIFactor = 0

  clutchHandling.clutchInRate = jbeamData.clutchInRate or 15
  clutchHandling.clutchOutRate = jbeamData.clutchOutRate or 10

  clutchHandling.revMatchThrottle = jbeamData.revMatchThrottle or 0.5
end

M.init = init

M.gearboxBehaviorChanged = gearboxBehaviorChanged
M.shiftUp = shiftUp
M.shiftDown = shiftDown
M.shiftToGearIndex = shiftToGearIndex
M.updateGearboxGFX = nop
M.getGearName = getGearName
M.getGearPosition = getGearPosition

return M