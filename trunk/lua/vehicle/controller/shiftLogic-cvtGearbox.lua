-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs

local constants = {rpmToAV = 0.104719755, avToRPM = 9.549296596425384}

local newDesiredGearIndex = 0
local previousGearIndex = 0
local gearbox = nil
local engine = nil
local torqueConverter = nil

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
M.throttleInput = 0
M.isArcadeSwitched = false
M.isSportModeActive = false

local automaticHandling = {
  availableModes = {"P","R", "N", "D", "S", "1", "2", "M"},
  hShifterModeLookup = {[-1] = "R", [0] = "N", "P", "D", "S", "2", "1", "M1"},
  cvtGearIndexLookup = {P = -2, R = -1, N = 0, D = 1, S = 2, ["2"] = 3, ["1"]= 4, M1 = 5},
  availableModeLookup = {},
  existingModeLookup = {},
  modeIndexLookup = {},
  modes = {},
  mode = nil,
  modeIndex = 0,
  maxAllowedGearIndex = 0,
  minAllowedGearIndex = 0,
}

local cvtHandling = {
  aggression = 0.5,
  highAV = 0,
  lowAV = 0,
}

local smoother = {
  --gearRatio smoother reduces oscillations during sharp changes in throttle
  cvtGearRatioSmoother = nil,
  --target smoother represents "driver intent"
  cvtTargetAVSmoother = nil,
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
  return automaticHandling.mode
end

local function getGearPosition()
  return (automaticHandling.modeIndex - 1) / (#automaticHandling.modes - 1)
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
    gearbox:setMode("park")
  elseif automaticHandling.mode == "N" then
    gearbox:setMode("neutral")
  elseif automaticHandling.mode == "R" then
    gearbox:setMode("reverse")
  else
    gearbox:setMode("drive")
  end

  M.isSportModeActive = automaticHandling.mode == "S"
end

local function shiftUp()
  if automaticHandling.mode == "N" then
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  automaticHandling.modeIndex = min(automaticHandling.modeIndex + 1, #automaticHandling.modes)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]

  applyGearboxMode()
  applyGearboxModeRestrictions()
end

local function shiftDown()
  if automaticHandling.mode == "N" then
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  automaticHandling.modeIndex = max(automaticHandling.modeIndex - 1, 1)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]

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

local function updateInGearArcade(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = automaticHandling.cvtGearIndexLookup[automaticHandling.mode]
  -- driving backwards? - only with automatic shift - for obvious reasons ;)
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  --interpolate based on throttle between high/low ranges
  local throttleCubed = M.throttle * M.throttle * M.throttle
  local targetAV = cvtHandling.lowAV + (cvtHandling.highAV - cvtHandling.lowAV) * throttleCubed
  local targetAVSmooth = smoother.cvtTargetAVSmoother:get(targetAV,dt)
  local engineAV = engine.outputAV1
  local avError = ((targetAVSmooth - engineAV)) * cvtHandling.aggression

  gearbox:setGearRatio(smoother.cvtGearRatioSmoother:get(gearbox.gearRatio + avError * dt,dt))

  if torqueConverterHandling.hasLockup and gearIndex >= torqueConverterHandling.lockupMinGear then
    electrics.values.lockupClutchRatio = min(max((engineAV - torqueConverterHandling.lockupAV) / torqueConverterHandling.lockupRange, 0), 1)
  else
    electrics.values.lockupClutchRatio = 0
  end

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

  --Arcade mode gets a "rev limiter" in case the engine does not have one
  if engine.outputAV1 > engine.maxAV and not engine.hasRevLimiter then
    M.throttle = 0
  end

  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
end

local function updateInGear(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  local gearIndex = automaticHandling.cvtGearIndexLookup[automaticHandling.mode]
  --interpolate based on throttle between high/low ranges
  local throttleCubed = automaticHandling.mode ~= "S" and (M.throttle * M.throttle * M.throttle) or 1
  local targetAV = cvtHandling.lowAV + (cvtHandling.highAV - cvtHandling.lowAV) * throttleCubed
  local targetAVSmooth = smoother.cvtTargetAVSmoother:get(targetAV,dt)
  local engineAV = engine.outputAV1
  local avError = ((targetAVSmooth - engineAV)) * cvtHandling.aggression

  gearbox:setGearRatio(smoother.cvtGearRatioSmoother:get(gearbox.gearRatio + avError * dt, dt))

  if torqueConverterHandling.hasLockup and gearIndex >= torqueConverterHandling.lockupMinGear then
    electrics.values.lockupClutchRatio = min(max((engineAV - torqueConverterHandling.lockupAV) / torqueConverterHandling.lockupRange, 0), 1)
  else
    electrics.values.lockupClutchRatio = 0
  end

  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
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
      shiftUp = sharedFunctions.warnCannotShiftSequential,
      shiftDown = sharedFunctions.warnCannotShiftSequential,
      shiftToGearIndex = sharedFunctions.switchToRealisticBehavior,
    },
    realistic =
    {
      inGear = updateInGear,
      shiftUp = shiftUp,
      shiftDown = shiftDown,
      shiftToGearIndex = shiftToGearIndex,
    }
  }

  local cvtGearRatioSmoothingIn = jbeamData.cvtGearRatioSmoothingIn or 20
  local cvtGearRatioSmoothingOut = jbeamData.cvtGearRatioSmoothingOut or 5
  local cvtTargetAVSmoothingIn = jbeamData.cvtTargetAVSmoothingIn or 0.5
  local cvtTargetAVSmoothingOut = jbeamData.cvtTargetAVSmoothingOut or 2

  smoother.cvtGearRatioSmoother = newTemporalSmoothingNonLinear(cvtGearRatioSmoothingIn, cvtGearRatioSmoothingOut)
  smoother.cvtTargetAVSmoother = newTemporalSmoothingNonLinear(cvtTargetAVSmoothingIn, cvtTargetAVSmoothingOut)

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
  end

  local defaultMode = jbeamData.defaultAutomaticMode or "N"
  automaticHandling.modeIndex = string.find(modes, defaultMode)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  automaticHandling.maxGearIndex = gearbox.maxGearIndex
  automaticHandling.minGearIndex = gearbox.minGearIndex

  cvtHandling.aggression = jbeamData.cvtAggression or 0.5
  cvtHandling.highAV = (jbeamData.cvtHighRPM or (shiftPoints[1] and shiftPoints[1].highShiftUpAV / constants.rpmToAV) or 0) * constants.rpmToAV
  cvtHandling.lowAV = (jbeamData.cvtLowRPM or (shiftPoints[1] and shiftPoints[1].lowShiftUpAV / constants.rpmToAV) or 0) * constants.rpmToAV

  smoother.cvtGearRatioSmoother:set(gearbox.maxGearRatio)
  smoother.cvtTargetAVSmoother:set(cvtHandling.lowAV)
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