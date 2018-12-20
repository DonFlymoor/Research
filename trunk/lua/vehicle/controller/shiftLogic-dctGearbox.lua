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

local automaticHandling = {
  availableModes = {"P", "R", "N", "D", "S", "1", "2", "M"},
  hShifterModeLookup = {[-1] = "R", [0] = "N", "P", "D", "S", "2", "1", "M1"},
  availableModeLookup = {},
  existingModeLookup = {},
  modeIndexLookup = {},
  modes = {},
  mode = nil,
  modeIndex = 0,
  maxAllowedGearIndex = 0,
  minAllowedGearIndex = 0,
  autoDownShiftInM = true
}

local clutchHandling = {
  clutchLaunchTargetAV = 0,
  clutchLaunchStartAV = 0,
  clutchLaunchIFactor = 0,
  revMatchThrottle = 0.5,
  didRevMatch = false,
  didCutIgnition = false
}

local dct = {
  access1 = {clutchRatioName = "clutchRatio1", gearIndexName = "gearIndex1", setGearIndexName = "setGearIndex1"},
  access2 = {clutchRatioName = "clutchRatio2", gearIndexName = "gearIndex2", setGearIndexName = "setGearIndex2"},
  primaryAccess = nil,
  secondaryAccess = nil,
  clutchTime = 0
}

local function getGearName()
  local modePrefix = ""
  if automaticHandling.mode == "S" then
    modePrefix = "S"
  elseif type(automaticHandling.mode) == "number" then
    modePrefix = "M"
  end
  return modePrefix ~= "" and modePrefix .. tostring(gearbox[dct.primaryAccess.gearIndexName]) or automaticHandling.mode
end

local function getGearPosition()
  return (automaticHandling.modeIndex - 1) / (#automaticHandling.modes - 1)
end

local function applyGearboxModeRestrictions()
  local manualModeIndex
  if string.sub(automaticHandling.mode, 1, 1) == "M" then
    manualModeIndex = string.sub(automaticHandling.mode, 2)
  end
  local maxGearIndex = gearbox.maxGearIndex
  local minGearIndex = gearbox.minGearIndex
  if automaticHandling.mode == "1" then
    maxGearIndex = 1
    minGearIndex = 1
  elseif automaticHandling.mode == "2" then
    maxGearIndex = 2
    minGearIndex = 1
  elseif manualModeIndex then
    maxGearIndex = manualModeIndex
    minGearIndex = manualModeIndex
  end

  automaticHandling.maxGearIndex = maxGearIndex
  automaticHandling.minGearIndex = minGearIndex
end

local function gearboxBehaviorChanged(behavior)
  gearboxLogic = gearboxAvailableLogic[behavior]
  M.updateGearboxGFX = gearboxLogic.inGear
  M.shiftUp = gearboxLogic.shiftUp
  M.shiftDown = gearboxLogic.shiftDown
  M.shiftToGearIndex = gearboxLogic.shiftToGearIndex
end

local function calculateShiftAggression()
  local gearRatioDifference = min(max(abs(gearbox.gearRatios[previousGearIndex] - gearbox.gearRatios[newDesiredGearIndex]), 0), 0.8)
  local gearingCoef = min(1 - gearRatioDifference, 0.4)
  local aggressionCoef = 0.5 * M.smoothedValues.drivingAggression

  shiftAggression = 0.1 + gearingCoef + aggressionCoef
end

local function applyGearboxMode()
  local autoIndex = automaticHandling.modeIndexLookup[automaticHandling.mode]
  if autoIndex then
    automaticHandling.modeIndex = min(max(autoIndex, 1), #automaticHandling.modes)
    automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  end

  if automaticHandling.mode == "P" then
    gearbox:setMode("park")
  elseif automaticHandling.mode == "N" then
    gearbox:setMode("neutral")
  else
    gearbox:setMode("drive")
    local gearIndex = gearbox[dct.primaryAccess.gearIndexName]
    if automaticHandling.mode == "R" and gearbox[dct.access1.gearIndexName] > -1 then
      gearIndex = -1
      dct.primaryAccess = dct.access1
      dct.secondaryAccess = dct.access2
    elseif automaticHandling.mode ~= "R" and gearbox[dct.access1.gearIndexName] < 1 then
      gearIndex = 1
      dct.primaryAccess = dct.access1
      dct.secondaryAccess = dct.access2
    end

    if gearbox[dct.primaryAccess.gearIndexName] ~= gearIndex then
      newDesiredGearIndex = gearIndex
      previousGearIndex = gearbox[dct.primaryAccess.gearIndexName]
      M.timer.shiftDelayTimer = 0
      M.updateGearboxGFX = gearboxLogic.whileShifting
    end
  end

  M.isSportModeActive = automaticHandling.mode == "S"
end

local function shiftUp()
  if automaticHandling.mode == "N" then
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  local previousMode = automaticHandling.mode
  automaticHandling.modeIndex = min(automaticHandling.modeIndex + 1, #automaticHandling.modes)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]

  if automaticHandling.mode == "M1" then --we just shifted into M1
    --instead of actually using M1, we want to KEEP the current gear, so M<current gear>
    automaticHandling.mode = "M" .. tostring(max(gearbox.gearIndex, 1))
  end

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = 0
    if string.find(automaticHandling.mode, "M") then
      local gearIndex = tonumber(string.sub(automaticHandling.mode, 2))
      gearRatio = gearbox.gearRatios[gearIndex]
    end
    if tonumber(automaticHandling.mode) then
      local gearIndex = tonumber(automaticHandling.mode)
      gearRatio = gearbox.gearRatios[gearIndex]
    end
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      automaticHandling.mode = previousMode
    end
  end

  applyGearboxMode()
  applyGearboxModeRestrictions()
end

local function shiftDown()
  if automaticHandling.mode == "N" then
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  local previousMode = automaticHandling.mode
  automaticHandling.modeIndex = max(automaticHandling.modeIndex - 1, 1)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]

  if previousMode == "M1" and electrics.values.wheelspeed > 2 and M.gearboxHandling.gearboxSafety then
    --we just tried to downshift past M1, something that is irritating while racing, so we disallow this shift unless we are really slow
    automaticHandling.mode = previousMode
  end

  if M.gearboxHandling.gearboxSafety then
    local gearRatio = 0
    if string.find(automaticHandling.mode, "M") then
      local gearIndex = tonumber(string.sub(automaticHandling.mode, 2))
      gearRatio = gearbox.gearRatios[gearIndex]
    end

    if tonumber(automaticHandling.mode) then
      local gearIndex = tonumber(automaticHandling.mode)
      gearRatio = gearbox.gearRatios[gearIndex]
    end
    if gearbox.outputAV1 * gearRatio > engine.maxAV then
      automaticHandling.mode = previousMode
    end
  end

  applyGearboxMode()
  applyGearboxModeRestrictions()
end

local function shiftToGearIndex(index)
  local desiredMode = automaticHandling.hShifterModeLookup[index]
  if not desiredMode or not automaticHandling.existingModeLookup[desiredMode] then
    if desiredMode and not automaticHandling.existingModeLookup[desiredMode] then
      gui.message({txt = "vehicle.drivetrain.cannotShiftAuto", context = {mode = desiredMode}}, 2, "vehicle.shiftLogic.cannotShift")
    end
    desiredMode = "N"
  end
  automaticHandling.mode = desiredMode

  applyGearboxMode()
  applyGearboxModeRestrictions()
end

local function dctPredictNextGear()
  local nextGear = gearbox[dct.secondaryAccess.gearIndexName]
  if M.throttle > 0 and gearbox[dct.primaryAccess.gearIndexName] > 0 and M.smoothedValues.brake <= 0 and (engine.outputAV1 / M.shiftBehavior.shiftUpAV) > 0.9 then
    nextGear = gearbox[dct.primaryAccess.gearIndexName] + fsign(gearbox[dct.primaryAccess.gearIndexName])
  elseif gearbox[dct.primaryAccess.gearIndexName] > 0 then
    nextGear = gearbox[dct.primaryAccess.gearIndexName] - fsign(gearbox[dct.primaryAccess.gearIndexName])
  end
  if gearbox[dct.secondaryAccess.gearIndexName] ~= nextGear and gearbox[dct.secondaryAccess.gearIndexName] < gearbox.maxGearIndex and M.timer.shiftDelayTimer <= 0 then
    gearbox[dct.secondaryAccess.setGearIndexName](gearbox, nextGear)
    M.timer.shiftDelayTimer = M.timerConstants.shiftDelay
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

  local gearIndex = gearbox[dct.primaryAccess.gearIndexName]
  local engineAV = engine.outputAV1

  -- driving backwards? - only with automatic shift - for obvious reasons ;)
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (automaticHandling.mode == "N" and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  --Arcade mode gets a "rev limiter" in case the engine does not have one
  if engineAV > engine.maxAV and not engine.hasRevLimiter then
    local throttleAdjust = min(max((engineAV - engine.maxAV * 1.02) / (engine.maxAV * 0.03), 0), 1)
    M.throttle = min(max(M.throttle - throttleAdjust, 0), 1)
  end

  if M.timer.gearChangeDelayTimer <= 0 and automaticHandling.mode ~= "N" then
    local tmpEngineAV = engineAV
    local relEngineAV = engineAV / gearbox.gearRatios[gearIndex]

    sharedFunctions.selectShiftPoints(gearIndex)

    --shift down?
    while tmpEngineAV < M.shiftBehavior.shiftDownAV and abs(gearIndex) > 1 and M.shiftPreventionData.wheelSlipShiftDown and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold do
      gearIndex = gearIndex - fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV > engine.maxAV then
        gearIndex = gearIndex + fsign(gearIndex)
        break
      end
      sharedFunctions.selectShiftPoints(gearIndex)
    end

    --shift up?
    if (tmpEngineAV >= M.shiftBehavior.shiftUpAV or engine.revLimiterActive) and M.brake <= 0 and electrics.values[dct.primaryAccess.clutchRatioName] >= 1 and M.shiftPreventionData.wheelSlipShiftUp and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold and gearIndex < gearbox.maxGearIndex and gearIndex > gearbox.minGearIndex then
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV < engine.idleAV then
        gearIndex = gearIndex - fsign(gearIndex)
      end
      sharedFunctions.selectShiftPoints(gearIndex)
    end
  end

  -- neutral gear handling
  local neutralGearChanged = false
  if M.timer.neutralSelectionDelayTimer <= 0 then
    if automaticHandling.mode ~= "P" and abs(M.smoothedValues.avgAV) < M.gearboxHandling.arcadeAutoBrakeAVThreshold and M.throttle <= 0 then
      M.brake = max(M.brake, M.gearboxHandling.arcadeAutoBrakeAmount)
    end

    if M.smoothedValues.throttleInput > 0 and M.smoothedValues.brakeInput <= 0 and M.smoothedValues.avgAV > -1 and automaticHandling.mode ~= "D" then
      gearIndex = 1
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
      automaticHandling.mode = "D"
      neutralGearChanged = true
      applyGearboxMode()
    end

    if M.smoothedValues.brakeInput > 0 and M.smoothedValues.throttleInput <= 0 and M.smoothedValues.avgAV <= 0.15 and automaticHandling.mode ~= "R" then
      gearIndex = -1
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
      automaticHandling.mode = "R"
      neutralGearChanged = true
      applyGearboxMode()
    end

    if engine.ignitionCoef < 1 and automaticHandling.mode ~= "N" then
      gearIndex = 0
      M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
      automaticHandling.mode = "N"
      neutralGearChanged = true
      applyGearboxMode()
    end
  end

  if not neutralGearChanged and gearbox[dct.primaryAccess.gearIndexName] ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox[dct.primaryAccess.gearIndexName]
    M.timer.shiftDelayTimer = 0
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end

  -- Control clutch to buildup engine RPM
  local dctClutchRatio = 0
  if abs(gearIndex) == 1 and M.throttle > 0 and not neutralGearChanged then
    local ratio = max((engine.outputAV1 - clutchHandling.clutchLaunchStartAV * (1 + M.throttle)) / (clutchHandling.clutchLaunchTargetAV * (1 + clutchHandling.clutchLaunchIFactor)), 0)
    clutchHandling.clutchLaunchIFactor = min(clutchHandling.clutchLaunchIFactor + dt * 0.5, 1)
    dctClutchRatio = math.min(math.max(ratio * ratio, 0), 1)
  else
    if M.smoothedValues.avgAV * gearbox.gearRatios[gearIndex] * engine.outputAV1 > 0 then
      dctClutchRatio = 1
    elseif abs(gearIndex) > 1 then
      M.brake = M.throttle
      M.throttle = 0
    end
    clutchHandling.clutchLaunchIFactor = 0
  end

  if abs(gearbox.outputAV1 * gearbox.gearRatios[gearIndex]) < engine.idleAV then
    --always prevent stalling
    local stallPrevent = min(max((engine.outputAV1 * 0.95 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
    dctClutchRatio = min(dctClutchRatio, stallPrevent * stallPrevent)
  end

  electrics.values[dct.primaryAccess.clutchRatioName] = dctClutchRatio
  electrics.values[dct.secondaryAccess.clutchRatioName] = 0
  M.clutchRatio = 1
  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
  gearbox.gearIndex = gearIndex --just so that the DCT can always present the "active" gear/ratio to the outside world
  gearbox.gearRatio = gearbox.gearRatios[gearIndex]
  updateExposedData()

  dctPredictNextGear()
end

local function updateWhileShiftingArcade(dt)
  --keep throttle input for upshifts and kill it for downshifts so that rev matching can work properly
  --also make sure to only keep throttle while shifting in the same direction, ie not -1 to 1 or so
  M.throttle = (newDesiredGearIndex > gearbox[dct.primaryAccess.gearIndexName] and newDesiredGearIndex * gearbox[dct.primaryAccess.gearIndexName] > 0) and M.inputValues.throttle or 0
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  -- secondary clutch closes while primary opens -> in gear update once fully closed
  local primaryGearIndex = gearbox[dct.primaryAccess.gearIndexName]
  local secondaryGearIndex = gearbox[dct.secondaryAccess.gearIndexName]
  if newDesiredGearIndex ~= secondaryGearIndex and M.timer.shiftDelayTimer <= 0 then
    --find out if our desired gear is actually on the secondary shaft
    local sameShaft = newDesiredGearIndex % 2 == secondaryGearIndex % 2
    --if so, we can directly shift to that desired gear on the secondary shaft
    --if not, we need to use a helper gear first which makes the actually desired gear part of the secondary shaft
    local newGearIndex = sameShaft and newDesiredGearIndex or primaryGearIndex + fsign(newDesiredGearIndex - primaryGearIndex)
    if secondaryGearIndex ~= newGearIndex then
      gearbox[dct.secondaryAccess.setGearIndexName](gearbox, newGearIndex)
      M.timer.shiftDelayTimer = M.timerConstants.shiftDelay / shiftAggression
    end
  end

  local canShift = true
  local isEngineRunning = engine.ignitionCoef >= 1 and not engine.isStalled
  local targetGearRatio = gearbox.gearRatios[newDesiredGearIndex]
  local targetAV = targetGearRatio * gearbox.outputAV1
  local isDownShift = abs(newDesiredGearIndex) < abs(primaryGearIndex)
  if isDownShift and targetAV > engine.outputAV1 and not clutchHandling.didRevMatch and isEngineRunning then
    M.throttle = clutchHandling.revMatchThrottle
    electrics.values[dct.primaryAccess.clutchRatioName] = 0
    electrics.values[dct.secondaryAccess.clutchRatioName] = 0
    canShift = engine.outputAV1 >= targetAV or targetAV > engine.maxAV
    clutchHandling.didRevMatch = canShift
  elseif not clutchHandling.didRevMatch then
    clutchHandling.didRevMatch = true
  end

  if M.timer.shiftDelayTimer <= 0 and canShift then
    if gearbox[dct.primaryAccess.gearIndexName] < gearbox[dct.secondaryAccess.gearIndexName] and not clutchHandling.didCutIgnition then
      engine:cutIgnition(dct.clutchTime * shiftAggression)
      clutchHandling.didCutIgnition = true
    end

    local clutchRatio = min(electrics.values[dct.secondaryAccess.clutchRatioName] + (1 / dct.clutchTime * shiftAggression) * dt, 1)
    local stallPrevent = min(max((engine.outputAV1 * 0.9 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
    electrics.values[dct.primaryAccess.clutchRatioName] = min(1 - clutchRatio, stallPrevent * stallPrevent)
    electrics.values[dct.secondaryAccess.clutchRatioName] = min(clutchRatio, stallPrevent * stallPrevent)
    if clutchRatio == 1 or stallPrevent < 1 then
      dct.primaryAccess, dct.secondaryAccess = dct.secondaryAccess, dct.primaryAccess
      primaryGearIndex = gearbox[dct.primaryAccess.gearIndexName]

      if newDesiredGearIndex == primaryGearIndex then
        M.updateGearboxGFX = gearboxLogic.inGear
        M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
        clutchHandling.didRevMatch = false
        clutchHandling.didCutIgnition = false
      end
    end
  end

  gearbox.gearIndex = primaryGearIndex --just so that the DCT can always present the "active" gear to the outside world
  updateExposedData()
end

local function updateInGear(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox[dct.primaryAccess.gearIndexName]

  local engineAV = engine.outputAV1

  if M.timer.gearChangeDelayTimer <= 0 and automaticHandling.mode ~= "N" then
    local tmpEngineAV = engineAV
    local relEngineAV = engineAV / gearbox.gearRatios[gearIndex]

    local isSportMode = automaticHandling.mode == "S"
    sharedFunctions.selectShiftPoints(gearIndex, isSportMode)

    while tmpEngineAV < M.shiftBehavior.shiftDownAV and abs(gearIndex) > 1 and M.shiftPreventionData.wheelSlipShiftDown and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold do
      gearIndex = gearIndex - fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV > engine.maxAV then
        gearIndex = gearIndex + fsign(gearIndex)
        break
      end
      sharedFunctions.selectShiftPoints(gearIndex, isSportMode)
    end

    --shift up?
    if (tmpEngineAV >= M.shiftBehavior.shiftUpAV or engine.revLimiterActive) and M.brake <= 0 and M.shiftPreventionData.wheelSlipShiftUp and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold and gearIndex < gearbox.maxGearIndex and gearIndex > gearbox.minGearIndex then
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV < engine.idleAV then
        gearIndex = gearIndex - fsign(gearIndex)
      end
      sharedFunctions.selectShiftPoints(gearIndex, isSportMode)
    end
  end

  local isManualMode = string.sub(automaticHandling.mode, 1, 1) == "M"
  --enforce things like L and M modes
  gearIndex = min(max(gearIndex, automaticHandling.minGearIndex), automaticHandling.maxGearIndex)
  if isManualMode and gearIndex > 1 and engineAV < engine.idleAV * 1.2 and M.shiftPreventionData.wheelSlipShiftDown and automaticHandling.autoDownShiftInM then
    gearIndex = gearIndex - 1
  end

  if gearbox[dct.primaryAccess.gearIndexName] ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox[dct.primaryAccess.gearIndexName]
    M.timer.shiftDelayTimer = 0
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end

  -- Control clutch to buildup engine RPM
  local dctClutchRatio = 0
  if abs(gearIndex) == 1 and M.throttle > 0 then
    local ratio = max((engine.outputAV1 - clutchHandling.clutchLaunchStartAV * (1 + M.throttle)) / (clutchHandling.clutchLaunchTargetAV * (1 + clutchHandling.clutchLaunchIFactor)), 0)
    clutchHandling.clutchLaunchIFactor = min(clutchHandling.clutchLaunchIFactor + dt * 0.5, 1)
    dctClutchRatio = math.min(math.max(ratio * ratio, 0), 1)
  else
    if gearbox.outputAV1 * gearbox.gearRatios[gearIndex] * engine.outputAV1 > 0 then
      dctClutchRatio = 1
    end
    clutchHandling.clutchLaunchIFactor = 0
  end

  if abs(gearbox.outputAV1 * gearbox.gearRatios[gearIndex]) < engine.idleAV then
    --always prevent stalling
    local stallPrevent = min(max((engine.outputAV1 * 0.95 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
    dctClutchRatio = min(dctClutchRatio, stallPrevent * stallPrevent)
  end

  if engine.ignitionCoef < 1 or (engine.idleAVStartOffset > 1 and M.throttle <= 0) then
    dctClutchRatio = 0
  end

  electrics.values[dct.primaryAccess.clutchRatioName] = dctClutchRatio
  electrics.values[dct.secondaryAccess.clutchRatioName] = 0
  M.clutchRatio = 1
  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
  gearbox.gearIndex = gearIndex --just so that the DCT can always present the "active" gear to the outside world
  gearbox.gearRatio = gearbox.gearRatios[gearIndex]

  if isManualMode then
    automaticHandling.mode = "M" .. gearIndex
    automaticHandling.modeIndex = automaticHandling.modeIndexLookup[automaticHandling.mode]
    applyGearboxModeRestrictions()
  end

  updateExposedData()
  dctPredictNextGear()
end

local function updateWhileShifting(dt)
  --keep throttle input for upshifts and kill it for downshifts so that rev matching can work properly
  --also make sure to only keep throttle while shifting in the same direction, ie not -1 to 1 or so
  M.throttle = (newDesiredGearIndex > gearbox[dct.primaryAccess.gearIndexName] and newDesiredGearIndex * gearbox[dct.primaryAccess.gearIndexName] > 0) and M.inputValues.throttle or 0
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  -- secondary clutch closes while primary opens -> in gear update once fully closed
  local primaryGearIndex = gearbox[dct.primaryAccess.gearIndexName]
  local secondaryGearIndex = gearbox[dct.secondaryAccess.gearIndexName]

  if newDesiredGearIndex ~= secondaryGearIndex and M.timer.shiftDelayTimer <= 0 then
    --find out if our desired gear is actually on the secondary shaft
    local sameShaft = newDesiredGearIndex % 2 == secondaryGearIndex % 2
    --if so, we can directly shift to that desired gear on the secondary shaft
    --if not, we need to use a helper gear first which makes the actually desired gear part of the secondary shaft
    local newGearIndex = sameShaft and newDesiredGearIndex or primaryGearIndex + fsign(newDesiredGearIndex - primaryGearIndex)
    if secondaryGearIndex ~= newGearIndex then
      gearbox[dct.secondaryAccess.setGearIndexName](gearbox, newGearIndex)
      M.timer.shiftDelayTimer = M.timerConstants.shiftDelay / shiftAggression
    end
  end

  local canShift = true
  local isEngineRunning = engine.ignitionCoef >= 1 and not engine.isStalled
  local targetGearRatio = gearbox.gearRatios[newDesiredGearIndex]
  local targetAV = targetGearRatio * gearbox.outputAV1
  local isDownShift = abs(newDesiredGearIndex) < abs(primaryGearIndex)
  if isDownShift and targetAV > engine.outputAV1 and not clutchHandling.didRevMatch and isEngineRunning then
    M.throttle = clutchHandling.revMatchThrottle
    electrics.values[dct.primaryAccess.clutchRatioName] = 0
    electrics.values[dct.secondaryAccess.clutchRatioName] = 0
    canShift = engine.outputAV1 >= targetAV or targetAV > engine.maxAV
    clutchHandling.didRevMatch = canShift
  elseif not clutchHandling.didRevMatch then
    clutchHandling.didRevMatch = true
  end

  if M.timer.shiftDelayTimer <= 0 and canShift then
    if gearbox[dct.primaryAccess.gearIndexName] < gearbox[dct.secondaryAccess.gearIndexName] and not clutchHandling.didCutIgnition then
      engine:cutIgnition(dct.clutchTime * shiftAggression)
      clutchHandling.didCutIgnition = true
    end
    local clutchRatio = min(electrics.values[dct.secondaryAccess.clutchRatioName] + (1 / dct.clutchTime * shiftAggression) * dt, 1)
    local stallPrevent = min(max((engine.outputAV1 * 0.9 - engine.idleAV) / (engine.idleAV * 0.1), 0), 1)
    electrics.values[dct.primaryAccess.clutchRatioName] = min(1 - clutchRatio, stallPrevent * stallPrevent)
    electrics.values[dct.secondaryAccess.clutchRatioName] = min(clutchRatio, stallPrevent * stallPrevent)
    if clutchRatio == 1 or stallPrevent < 1 then
      dct.primaryAccess, dct.secondaryAccess = dct.secondaryAccess, dct.primaryAccess
      primaryGearIndex = gearbox[dct.primaryAccess.gearIndexName]
      clutchHandling.didRevMatch = false
      clutchHandling.didCutIgnition = false

      if newDesiredGearIndex == primaryGearIndex then
        M.updateGearboxGFX = gearboxLogic.inGear
        M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
      end
    end
  end

  --If we are currently in the wrong sign of gear (ie trying to drive backwards while technically a forward gear is still selected),
  --do not ever close the primary clutch to prevent the car from driving in the wrong direction
  if newDesiredGearIndex * gearbox[dct.primaryAccess.gearIndexName] <= 0 then
    electrics.values[dct.primaryAccess.clutchRatioName] = 0
  end

  gearbox.gearIndex = primaryGearIndex --just so that the DCT can always present the "active" gear to the outside world
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
  previousGearIndex = 0

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

  clutchHandling.didRevMatch = false
  clutchHandling.didCutIgnition = false
  clutchHandling.clutchLaunchTargetAV = (jbeamData.clutchLaunchTargetRPM or 3000) * constants.rpmToAV * 0.5
  clutchHandling.clutchLaunchStartAV = ((jbeamData.clutchLaunchStartRPM or 2000) * constants.rpmToAV - engine.idleAV) * 0.5
  clutchHandling.clutchLaunchIFactor = 0
  clutchHandling.revMatchThrottle = jbeamData.revMatchThrottle or 0.5

  automaticHandling.availableModeLookup = {}
  for _, v in pairs(automaticHandling.availableModes) do
    automaticHandling.availableModeLookup[v] = true
  end

  automaticHandling.modes = {}
  automaticHandling.modeIndexLookup = {}
  local modes = jbeamData.automaticModes or "PRNDS21M"
  local modeCount = #modes
  local modeOffset = 0
  for i = 1, modeCount do
    local mode = modes:sub(i, i)
    if automaticHandling.availableModeLookup[mode] then
      if mode ~= "M" then
        automaticHandling.modes[i + modeOffset] = mode
        automaticHandling.modeIndexLookup[mode] = i + modeOffset
        automaticHandling.existingModeLookup[mode] = true
      else
        for j = 1, gearbox.maxGearIndex, 1 do
          local manualMode = "M" .. tostring(j)
          local manualModeIndex = i + j - 1
          automaticHandling.modes[manualModeIndex] = manualMode
          automaticHandling.modeIndexLookup[manualMode] = manualModeIndex
          automaticHandling.existingModeLookup[manualMode] = true
          modeOffset = j - 1
        end
      end
    else
      print("unknown auto mode: " .. mode)
    end
  end

  local defaultMode = jbeamData.defaultAutomaticMode or "N"
  automaticHandling.modeIndex = string.find(modes, defaultMode)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  automaticHandling.maxGearIndex = gearbox.maxGearIndex
  automaticHandling.minGearIndex = gearbox.minGearIndex
  automaticHandling.autoDownShiftInM = jbeamData.autoDownShiftInM == nil and true or jbeamData.autoDownShiftInM

  dct.clutchTime = jbeamData.dctClutchTime or 0.05

  M.maxRPM = engine.maxRPM
  M.idleRPM = engine.idleRPM
  M.maxGearIndex = automaticHandling.maxGearIndex
  M.minGearIndex = abs(automaticHandling.minGearIndex)
  M.energyStorages = sharedFunctions.getEnergyStorages({engine})

  dct.primaryAccess = dct.access1
  dct.secondaryAccess = dct.access2
  applyGearboxMode()
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
