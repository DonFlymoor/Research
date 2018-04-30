-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {clutchlike = true, viscouscoupling = true}
M.requiredExternalInertiaOutputs = {1}

local max = math.max
local min = math.min
local abs = math.abs
local guardZero = guardZero

local function updateVelocity(device, dt)
  device.inputAV = device.parent.outputAV1
end

local function updateTorque(device, dt)
  local lockupClutchRatio = electrics.values[device.lockupClutchRatioName] or 0
  local stallTorqueRatio = device.stallTorqueRatio

  local inputAV = guardZero(device.inputAV)
  local outputAV1 = guardZero(device.outputAV1)
  local avRatio = outputAV1 / inputAV
  local avDiff = device.inputAV - device.outputAV1

  device.lockupClutchAngle = min(max(device.lockupClutchAngle + avDiff * dt * 0.25, -device.maxLockupClutchAngle), device.maxLockupClutchAngle)
  local lockupTorque = (min(max(device.lockupClutchAngle * device.lockupClutchSpring + device.lockupClutchDamp * avDiff, -device.lockupClutchTorque), device.lockupClutchTorque)) * lockupClutchRatio

  local kFactor = device.kFactorSmoother:get(-0.004 * device.converterStiffness * (avRatio - 1) / (1 + device.converterStiffness * abs(avRatio - 1)))

  local inputTorque = min(max(kFactor * device.kFactorCoef * inputAV * inputAV * fsign(inputAV), -device.converterTorque), device.converterTorque)

  local torqueRatio = min(max(stallTorqueRatio - (stallTorqueRatio - 1) * avRatio / device.couplingAVRatio, 1), stallTorqueRatio)
  local torqueRatioLimit = max(avRatio, abs(inputAV / outputAV1))

  device.outputTorque1 = inputTorque * min(torqueRatio, torqueRatioLimit) + lockupTorque
  device.torqueDiff = inputTorque + lockupTorque

  --local efficiency = device.outputAV1 * device.outputTorque1 / device.inputAV / device.torqueDiff
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque
end

local function validate(device)
  if not device.parent.deviceCategories.engine then
    log("E", "torqueConverter.validate", "Parent device is not an engine device...")
    log("E", "torqueConverter.validate", "Actual parent:")
    log("E", "torqueConverter.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end

  device.converterTorque = device.jbeamData.converterTorque or (device.parent.torqueData.maxTorque + device.parent.maxRPM * device.parent.inertia * math.pi / 60)
  return true
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function calculateInertia(device)
  local outputInertia = 0
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  if device.children and #device.children > 0 then
    local child = device.children[1]
    outputInertia = child.cumulativeInertia
    cumulativeGearRatio = child.cumulativeGearRatio
    maxCumulativeGearRatio = child.maxCumulativeGearRatio
  end

  device.cumulativeInertia = outputInertia / device.stallTorqueRatio
  device.lockupClutchSpring = device.jbeamData.lockupClutchSpring or (powertrain.stabilityCoef * powertrain.stabilityCoef * device.cumulativeInertia)
  device.lockupClutchDamp = device.lockupClutchSpring / 1000
  device.maxLockupClutchAngle = device.lockupClutchTorque / device.lockupClutchSpring --rad

  device.cumulativeGearRatio = cumulativeGearRatio * device.stallTorqueRatio --todo: not quite accurate, needs calculation of CURRENT "gear ratio"
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.stallTorqueRatio
end

local function reset(device)
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.outputAV1 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.isBroken = false

  device.lockupClutchAngle = 0

  selectUpdates(device)

  return device
end

local function new(jbeamData)
  local device = {
    deviceCategories = shallowcopy(M.deviceCategories),
    requiredExternalInertiaOutputs = shallowcopy(M.requiredExternalInertiaOutputs),
    outputPorts = shallowcopy(M.outputPorts),

    name = jbeamData.name,
    type = jbeamData.type,
    inputName = jbeamData.inputName,
    inputIndex = jbeamData.inputIndex,
    gearRatio = 1,
    additionalEngineInertia = jbeamData.additionalEngineInertia or 0,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,

    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    isBroken = false,

    reset = reset,
    setMode = setMode,
    validate = validate,
    calculateInertia = calculateInertia,
    torqueDiff = 0
  }

  device.lockupClutchRatioName = jbeamData.lockupClutchRatioName or "lockupClutchRatio"
  device.lockupClutchAngle = 0

  device.lockupClutchTorque = jbeamData.lockupClutchTorque or 100 --Nm

  device.couplingAVRatio = jbeamData.couplingAVRatio or 0.85
  device.stallTorqueRatio = jbeamData.stallTorqueRatio or 2
  device.converterStiffness = jbeamData.converterStiffness or 10
  device.converterDiameter = jbeamData.converterDiameter or 0.30
  device.fluidDensity = 844
  device.kFactorSmoother = newExponentialSmoothing(jbeamData.kFactorSmoothing or 75)
  device.kFactorCoef = device.fluidDensity * device.converterDiameter * device.converterDiameter * device.converterDiameter * device.converterDiameter * device.converterDiameter

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  device.jbeamData = jbeamData

  selectUpdates(device)

  return device
end

M.new = new

return M
