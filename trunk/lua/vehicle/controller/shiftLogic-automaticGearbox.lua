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
local gearbox = nil
local engine = nil
local torqueConverter = nil
local shiftAggression = 0

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

local automaticHandling = {
  availableModes = {"P","R", "N", "D", "S", "1", "2", "M"},
  hShifterModeLookup = {[-1] = "R", [0] = "N", "P", "D", "S", "2", "1", "M1"},
  availableModeLookup = {},
  existingModeLookup = {},
  modeIndexLookup = {},
  modes = {},
  mode = nil,
  modeIndex = 0,
  maxAllowedGearIndex = 0,
  minAllowedGearIndex = 0,
  autoDownShiftInM = true,
}

local torqueConverterHandling = {
  lockupAV = 0,
  lockupRange = 0,
  lockupMinGear = 0,
  hasLockup = false,
}

local function getGearName()
  local modePrefix = ""
  if automaticHandling.mode == "S" then
    modePrefix = "S"
  elseif type(automaticHandling.mode) == "number" then
    modePrefix = "M"
  end
  return modePrefix ~= "" and modePrefix..tostring(gearbox.gearIndex) or automaticHandling.mode
end

local function getGearPosition()
  return (automaticHandling.modeIndex - 1) / (#automaticHandling.modes - 1)
end

local function calculateShiftAggression()
  shiftAggression = M.smoothedValues.drivingAggression
end

local function applyGearboxModeRestrictions()
  local manualModeIndex
  if string.sub(automaticHandling.mode, 1,1) == "M" then
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

local function applyGearboxMode()
  local autoIndex = automaticHandling.modeIndexLookup[automaticHandling.mode]
  if autoIndex then
    automaticHandling.modeIndex = min(max(autoIndex, 1), #automaticHandling.modes)
    automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  end

  if automaticHandling.mode == "P" then
    gearbox:setGearIndex(0)
    gearbox:setMode("park")
  elseif automaticHandling.mode == "N" then
    gearbox:setGearIndex(0)
    gearbox:setMode("neutral")
  else
    gearbox:setMode("drive")
    if automaticHandling.mode == "R" and gearbox.gearIndex > -1 then
      gearbox:setGearIndex(-1)
    elseif automaticHandling.mode ~= "R" and gearbox.gearIndex < 1 then
      gearbox:setGearIndex(1)
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
    automaticHandling.mode = "M"..tostring(max(gearbox.gearIndex, 1))
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

  if automaticHandling.mode == "D" or automaticHandling.mode == "R" or automaticHandling.mode == "S" then
    local gearIndex = 1
    local tmpEngineAV = gearbox.outputAV1 * gearbox.gearRatios[gearIndex]

    while tmpEngineAV >= engine.maxAV * 0.9 do
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = gearbox.outputAV1 * (gearbox.gearRatios[gearIndex] or 0)
    end
    gearbox:setGearIndex(gearIndex, 0)
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

  if automaticHandling.mode == "D" or automaticHandling.mode == "R" or automaticHandling.mode == "S" then
    local gearIndex = 1
    local tmpEngineAV = gearbox.outputAV1 * gearbox.gearRatios[gearIndex]

    while tmpEngineAV >= engine.maxAV * 0.9 do
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = gearbox.outputAV1 * (gearbox.gearRatios[gearIndex] or 0)
    end
    gearbox:setGearIndex(gearIndex, 0)
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

  if automaticHandling.mode == "D" or automaticHandling.mode == "R" or automaticHandling.mode == "S" then
    local gearIndex = 1
    local tmpEngineAV = gearbox.outputAV1 * gearbox.gearRatios[gearIndex]

    while tmpEngineAV >= engine.maxAV * 0.9 do
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = gearbox.outputAV1 * (gearbox.gearRatios[gearIndex] or 0)
    end
    gearbox:setGearIndex(gearIndex, 0)
  end

  applyGearboxMode()
  applyGearboxModeRestrictions()
end

local function updateInGearArcade(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  local gearboxInputAV = gearbox.inputAV
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

  if M.timer.gearChangeDelayTimer <= 0 and automaticHandling.mode ~= "N" then
    local tmpEngineAV = gearboxInputAV
    local relEngineAV = gearboxInputAV / gearbox.gearRatio

    sharedFunctions.selectShiftPoints(gearIndex)

    while tmpEngineAV < M.shiftBehavior.shiftDownAV and abs(gearIndex) > 1 and M.shiftPreventionData.wheelSlipShiftDown and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold do
      gearIndex = gearIndex - fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV > engine.maxAV * 0.95 then
        tmpEngineAV = relEngineAV / (gearbox.gearRatios[gearIndex] or 0)
        gearIndex = gearIndex + fsign(gearIndex)
        break
      end
      sharedFunctions.selectShiftPoints(gearIndex)
    end

    --shift up?
    if (tmpEngineAV >= M.shiftBehavior.shiftUpAV or engine.revLimiterActive) and M.brake <= 0 and M.shiftPreventionData.wheelSlipShiftUp and abs(M.throttle - M.smoothedValues.throttle) < M.smoothedValues.throttleUpShiftThreshold and gearIndex < gearbox.maxGearIndex and gearIndex > gearbox.minGearIndex then
      gearIndex = gearIndex + fsign(gearIndex)
      tmpEngineAV = relEngineAV * (gearbox.gearRatios[gearIndex] or 0)
      if tmpEngineAV < engine.idleAV * 1.1 then
        tmpEngineAV = relEngineAV / (gearbox.gearRatios[gearIndex] or 0)
        gearIndex = gearIndex - fsign(gearIndex)
      else
        sharedFunctions.selectShiftPoints(gearIndex)
      end
    end
  end

  local lockupTarget = 0
  if torqueConverterHandling.hasLockup and gearIndex >= torqueConverterHandling.lockupMinGear and M.brake <= 0.2 and not gearbox.isShifting then
    lockupTarget = min(max((gearboxInputAV - torqueConverterHandling.lockupAV) / torqueConverterHandling.lockupRange, 0), 1)
  end
  electrics.values.lockupClutchRatio = torqueConverterHandling.lockupSmoother:getUncapped(lockupTarget, dt)

  -- neutral gear handling
  if abs(gearbox.gearIndex) <= 1 and M.timer.neutralSelectionDelayTimer <= 0 then
    if automaticHandling.mode ~= "P" and abs(M.smoothedValues.avgAV) < M.gearboxHandling.arcadeAutoBrakeAVThreshold and M.throttle <= 0 then
      M.brake = max(M.brake, M.gearboxHandling.arcadeAutoBrakeAmount)
    end

    if automaticHandling.mode ~= "N" and abs(M.smoothedValues.avgAV) < M.gearboxHandling.arcadeAutoBrakeAVThreshold and M.smoothedValues.throttle <= 0 then
      gearIndex = 0
      automaticHandling.mode = "N"
      applyGearboxMode()
    else
      if M.smoothedValues.throttleInput > 0 and M.inputValues.throttle > 0 and M.smoothedValues.brakeInput <= 0 and M.smoothedValues.avgAV > -1 and gearIndex < 1 then
        gearIndex = 1
        M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
        automaticHandling.mode = "D"
        applyGearboxMode()
      end

      if M.smoothedValues.brakeInput > 0.1 and M.inputValues.brake > 0 and M.smoothedValues.throttleInput <= 0 and M.smoothedValues.avgAV <= 0.15 and gearIndex > -1  then
        gearIndex = -1
        M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
        automaticHandling.mode = "R"
        applyGearboxMode()
      end
    end
  end

  M.throttle = automaticHandling.mode ~= "N" and M.throttle or 0

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox.gearIndex
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end

  M.currentGearIndex = gearIndex
end

local function updateWhileShiftingArcade()
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false
  -- old -> wait -> new -> in gear update
  local gearIndex = gearbox.gearIndex
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  local gearChangeTime = min(max(automaticHandling.gearChangeTimeRange * (shiftAggression - 0.5) * 2 + automaticHandling.maxGearChangeTime, automaticHandling.minGearChangeTime), automaticHandling.maxGearChangeTime)
  gearbox:setGearIndex(newDesiredGearIndex, gearChangeTime)
  newDesiredGearIndex = 0
  previousGearIndex = 0
  M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  M.updateGearboxGFX = gearboxLogic.inGear
end

local function updateInGear(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = gearbox.gearIndex
  local gearboxInputAV = gearbox.inputAV

  local isSportMode = automaticHandling.mode == "S"

  if M.timer.gearChangeDelayTimer <= 0 and automaticHandling.mode ~= "N" then
    local tmpEngineAV = gearboxInputAV
    local relEngineAV = gearboxInputAV / gearbox.gearRatio

    sharedFunctions.selectShiftPoints(gearIndex, isSportMode)

    --shift down?
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

  local isManualMode = string.sub(automaticHandling.mode, 1,1) == "M"
  --enforce things like L and M modes
  gearIndex = min(max(gearIndex, automaticHandling.minGearIndex), automaticHandling.maxGearIndex)
  if isManualMode and gearIndex > 1 and gearboxInputAV < engine.idleAV * 1.2 and M.shiftPreventionData.wheelSlipShiftDown and automaticHandling.autoDownShiftInM then
    gearIndex = gearIndex - 1
  end

  local lockupTarget = 0
  if torqueConverterHandling.hasLockup and gearIndex >= torqueConverterHandling.lockupMinGear and M.brake <= 0.2 and (not gearbox.isShifting or isSportMode) then
    lockupTarget = min(max((gearboxInputAV - torqueConverterHandling.lockupAV) / torqueConverterHandling.lockupRange, 0), 1)
  end
  electrics.values.lockupClutchRatio = torqueConverterHandling.lockupSmoother:getUncapped(lockupTarget, dt)

  if gearbox.gearIndex ~= gearIndex then
    newDesiredGearIndex = gearIndex
    previousGearIndex = gearbox.gearIndex
    calculateShiftAggression()
    M.updateGearboxGFX = gearboxLogic.whileShifting
  end

  M.currentGearIndex = gearIndex

  if isManualMode then
    automaticHandling.mode = "M"..gearIndex
    automaticHandling.modeIndex = automaticHandling.modeIndexLookup[automaticHandling.mode]
    applyGearboxModeRestrictions()
  end
end

local function updateWhileShifting()
  -- old -> wait -> new -> in gear update
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearChangeTime = min(max(automaticHandling.gearChangeTimeRange * (shiftAggression - 0.5) * 2 + automaticHandling.maxGearChangeTime, automaticHandling.minGearChangeTime), automaticHandling.maxGearChangeTime)
  local autoMode = string.sub(automaticHandling.mode, 1,1)
  if (autoMode == "S" or autoMode == "M") then
    if abs(newDesiredGearIndex) > 1 and abs(newDesiredGearIndex) > abs(gearbox.gearIndex) then
      engine:cutIgnition(automaticHandling.sportGearChangeTime * 0.5)
      gearChangeTime = automaticHandling.sportGearChangeTime
    elseif abs(newDesiredGearIndex) > 0 and abs(newDesiredGearIndex) < abs(gearbox.gearIndex) then
      M.throttle = 1
    end
  end
  gearbox:setGearIndex(newDesiredGearIndex, gearChangeTime)
  newDesiredGearIndex = 0
  previousGearIndex = 0
  M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  M.updateGearboxGFX = gearboxLogic.inGear
end

local function init(jbeamData, expectedDeviceNames, sharedFunctionTable, shiftPoints, engineDevice, gearboxDevice)
  sharedFunctions = sharedFunctionTable
  engine = engineDevice
  gearbox = gearboxDevice
  torqueConverter = powertrain.getDevice(expectedDeviceNames.torqueConverter)
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

  automaticHandling.availableModeLookup = {}
  for _,v in pairs(automaticHandling.availableModes) do
    automaticHandling.availableModeLookup[v] = true
  end

  automaticHandling.modes = {}
  automaticHandling.modeIndexLookup = {}
  local modes = jbeamData.automaticModes or "PRNDS21M"
  local modeCount = #modes
  local modeOffset = 0
  for i = 1, modeCount do
    local mode = modes:sub(i,i)
    if automaticHandling.availableModeLookup[mode] then
      if mode ~= "M" then
        automaticHandling.modes[i + modeOffset] = mode
        automaticHandling.modeIndexLookup[mode] = i + modeOffset
        automaticHandling.existingModeLookup[mode] = true
      else
        for j = 1, gearbox.maxGearIndex, 1 do
          local manualMode = "M"..tostring(j)
          local manualModeIndex = i + j - 1
          automaticHandling.modes[manualModeIndex] = manualMode
          automaticHandling.modeIndexLookup[manualMode] = manualModeIndex
          automaticHandling.existingModeLookup[manualMode] = true
          modeOffset = j - 1
        end
      end
    else
      print("unknown auto mode: "..mode)
    end
  end

  if torqueConverter then
    torqueConverterHandling.lockupAV = (jbeamData.torqueConverterLockupRPM or 0) * constants.rpmToAV
    torqueConverterHandling.lockupRange = (jbeamData.torqueConverterLockupRange or (torqueConverterHandling.lockupAV * 0.2 * constants.avToRPM)) * constants.rpmToAV
    torqueConverterHandling.lockupMinGear = jbeamData.torqueConverterLockupMinGear or 0
    torqueConverterHandling.hasLockup = torqueConverterHandling.lockupAV > 0
    local lockupRate = jbeamData.torqueConverterLockupRate or 5
    local lockupInRate = jbeamData.torqueConverterLockupInRate or lockupRate * 2
    local lockupOutRate = jbeamData.torqueConverterLockupOutRate or lockupRate
    torqueConverterHandling.lockupSmoother = newTemporalSmoothing(lockupInRate, lockupOutRate)
  end

  local defaultMode = jbeamData.defaultAutomaticMode or "N"
  automaticHandling.modeIndex = string.find(modes, defaultMode)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  automaticHandling.maxGearIndex = gearbox.maxGearIndex
  automaticHandling.minGearIndex = gearbox.minGearIndex
  automaticHandling.maxGearChangeTime = jbeamData.maxGearChangeTime or 0
  automaticHandling.minGearChangeTime = jbeamData.minGearChangeTime or 0
  automaticHandling.sportGearChangeTime = jbeamData.sportGearChangeTime or 0
  automaticHandling.gearChangeTimeRange = automaticHandling.minGearChangeTime - automaticHandling.maxGearChangeTime
  automaticHandling.autoDownShiftInM = jbeamData.autoDownShiftInM == nil and true or jbeamData.autoDownShiftInM

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

return M