-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs

local constants = {rpmToAV = 0.104719755, avToRPM = 9.549296596425384}

local engines = nil

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
M.clutchRatio = 1
M.throttleInput = 0
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
  availableModes = {"P", "R", "N", "D", "S"},
  hShifterModeLookup = {[-1] = "R", [0] = "N", "P", "D", "S"},
  cvtGearIndexLookup = {P = -2, R = -1, N = 0, D = 1, S = 2, ["2"] = 3, ["1"] = 4, M1 = 5},
  availableModeLookup = {},
  existingModeLookup = {},
  modeIndexLookup = {},
  modes = {},
  mode = nil,
  modeIndex = 0,
  maxAllowedGearIndex = 0,
  minAllowedGearIndex = 0
}

local function getGearName()
  return automaticHandling.mode
end

local function getGearPosition()
  return (automaticHandling.modeIndex - 1) / (#automaticHandling.modes - 1)
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

  local motorDirection = 1 --D
  if automaticHandling.mode == "P" then
    motorDirection = 1
  elseif automaticHandling.mode == "N" then
    motorDirection = 1
  elseif automaticHandling.mode == "R" then
    motorDirection = -1
  end

  for _, v in ipairs(engines) do
    v.motorDirection = motorDirection
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
end

local function shiftDown()
  if automaticHandling.mode == "N" then
    M.timer.gearChangeDelayTimer = M.timerConstants.gearChangeDelay
  end

  automaticHandling.modeIndex = max(automaticHandling.modeIndex - 1, 1)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]

  applyGearboxMode()
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
end

local function updateExposedData()
  M.rpm = 0
  for _, v in ipairs(engines) do
    M.rpm = max(M.rpm, abs(v.outputAV1) * constants.avToRPM)
  end
  M.smoothedAvgAVInput = sharedFunctions.updateAvgAVDeviceCategory("clutchlike")
  M.waterTemp = 0
  M.oilTemp = 0
  M.checkEngine = 0
  M.ignition = true
  M.engineThrottle = M.throttle
  M.engineLoad = engine and (engine.isDisabled and 0 or engine.instantEngineLoad) or 0
  M.running = true
  M.engineTorque = engine and engine.combustionTorque or 0
  M.gearboxTorque = gearbox and gearbox.outputTorque or 0
  M.isEngineRunning = 1
end

local function updateInGearArcade(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false
  M.clutchRatio = 1

  local gearIndex = automaticHandling.cvtGearIndexLookup[automaticHandling.mode]
  -- driving backwards? - only with automatic shift - for obvious reasons ;)
  if (gearIndex < 0 and M.smoothedValues.avgAV <= 0.15) or (gearIndex <= 0 and M.smoothedValues.avgAV < -1) then
    M.throttle, M.brake = M.brake, M.throttle
    M.isArcadeSwitched = true
  end

  -- neutral gear handling
  if M.timer.neutralSelectionDelayTimer <= 0 then
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

      if M.smoothedValues.brakeInput > 0.1 and M.inputValues.brake > 0 and M.smoothedValues.throttleInput <= 0 and M.smoothedValues.avgAV <= 0.5 and gearIndex > -1 then
        gearIndex = -1
        M.timer.neutralSelectionDelayTimer = M.timerConstants.neutralSelectionDelay
        automaticHandling.mode = "R"
        applyGearboxMode()
      end
    end
  end

  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
  updateExposedData()
end

local function updateInGear(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false
  M.clutchRatio = 1

  local gearIndex = automaticHandling.cvtGearIndexLookup[automaticHandling.mode]

  M.currentGearIndex = (automaticHandling.mode == "N" or automaticHandling.mode == "P") and 0 or gearIndex
  updateExposedData()
end

local function sendTorqueData()
  for _, v in ipairs(engines) do
    v:sendTorqueData()
  end
end

local function init(jbeamData, sharedFunctionTable)
  sharedFunctions = sharedFunctionTable

  M.currentGearIndex = 0
  M.throttle = 0
  M.brake = 0
  M.clutchRatio = 1

  gearboxAvailableLogic = {
    arcade = {
      inGear = updateInGearArcade,
      shiftUp = sharedFunctions.warnCannotShiftSequential,
      shiftDown = sharedFunctions.warnCannotShiftSequential,
      shiftToGearIndex = sharedFunctions.switchToRealisticBehavior
    },
    realistic = {
      inGear = updateInGear,
      shiftUp = shiftUp,
      shiftDown = shiftDown,
      shiftToGearIndex = shiftToGearIndex
    }
  }

  engines = {}
  local engineNames = {"mainEngine", "mainEngine1", "mainEngine2"}
  for _, v in ipairs(engineNames) do
    local engine = powertrain.getDevice(v)
    if engine then
      M.maxRPM = max(M.maxRPM, engine.maxAV * constants.avToRPM)
      table.insert(engines, engine)
    end
  end

  automaticHandling.availableModeLookup = {}
  for _, v in pairs(automaticHandling.availableModes) do
    automaticHandling.availableModeLookup[v] = true
  end

  automaticHandling.modes = {}
  automaticHandling.modeIndexLookup = {}
  local modes = jbeamData.automaticModes or "PRNDS"
  local modeCount = #modes
  local modeOffset = 0
  for i = 1, modeCount do
    local mode = modes:sub(i, i)
    if automaticHandling.availableModeLookup[mode] then
      automaticHandling.modes[i + modeOffset] = mode
      automaticHandling.modeIndexLookup[mode] = i + modeOffset
      automaticHandling.existingModeLookup[mode] = true
    else
      print("unknown auto mode: " .. mode)
    end
  end

  local defaultMode = jbeamData.defaultAutomaticMode or "N"
  automaticHandling.modeIndex = string.find(modes, defaultMode)
  automaticHandling.mode = automaticHandling.modes[automaticHandling.modeIndex]
  automaticHandling.maxGearIndex = 1
  automaticHandling.minGearIndex = -1

  M.idleRPM = 0
  M.maxGearIndex = automaticHandling.maxGearIndex
  M.minGearIndex = abs(automaticHandling.minGearIndex)
  M.energyStorages = sharedFunctions.getEnergyStorages(engines)

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
