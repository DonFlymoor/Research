-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local constants = {rpmToAV = 0.104719755, avToRPM = 9.549296596425384}

local gearbox = nil
local engine = nil

local sharedFunctions = nil

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

local function getGearName()
  return ""
end

local function getGearPosition()
  return 0
end

local function updateGearboxGFX(dt)
  M.throttle = M.inputValues.throttle
  M.brake = M.inputValues.brake
  M.isArcadeSwitched = false

  M.rpm = engine and (engine.outputAV1 * constants.avToRPM) or 0
  M.smoothedAvgAVInput = sharedFunctions.updateAvgAVSingleDevice("gearbox")
  M.waterTemp = (engine and engine.thermals) and engine.thermals.coolantTemperature or 0
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

local function sendTorqueData()
  if engine then
    engine:sendTorqueData()
  end
end

local function init(jbeamData, sharedFunctionTable)
  sharedFunctions = sharedFunctionTable
  engine = powertrain.getDevice("mainEngine")
  gearbox = powertrain.getDevice("gearbox")

  M.currentGearIndex = 0
  M.throttle = 0
  M.brake = 0
  M.clutchRatio = 0

  M.maxRPM = engine and engine.maxRPM or 0
  M.idleRPM = engine and engine.idleRPM or 0
  M.maxGearIndex = 0
  M.minGearIndex = 0
  M.energyStorages = sharedFunctions.getEnergyStorages({engine})
end

M.init = init

M.gearboxBehaviorChanged = nop
M.shiftUp = nop
M.shiftDown = nop
M.shiftToGearIndex = nop
M.updateGearboxGFX = updateGearboxGFX
M.getGearName = getGearName
M.getGearPosition = getGearPosition
M.sendTorqueData = sendTorqueData

return M
