-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {gearbox = true}
M.requiredExternalInertiaOutputs = {1}

local max = math.max
local min = math.min
local abs = math.abs

local function updateVelocity(device, dt)
  device.inputAV = device.outputAV1 * device.gearRatio  * device.lockCoef * device.reverseGearRatioCoef
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  local reverseGearRatioCoef = device.reverseGearRatioCoef
  local oneWayTorque = min(max(device.oneWayViscousCoef * device.outputAV1 * reverseGearRatioCoef, -device.oneWayViscousTorque), 0)
  device.outputTorque1 = ((device.parent[device.parentOutputTorqueName] - device.friction * min(max(device.inputAV, -1), 1)) * device.gearRatio - oneWayTorque) * reverseGearRatioCoef * device.lockCoef
end

local function neutralUpdateVelocity(device, dt)
  device.inputAV = device.virtualMassAV
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function neutralUpdateTorque(device, dt)
  local outputTorque = device.parent[device.parentOutputTorqueName] - device.friction * min(max(device.inputAV, -1), 1)
  device.virtualMassAV = device.virtualMassAV + outputTorque * device.invCumulativeInertia * dt
  device.outputTorque1 = 0
end

local function parkUpdateVelocity(device, dt)
  device.inputAV = device.virtualMassAV
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function parkUpdateTorque(device, dt)
  local outputTorque = device.parent[device.parentOutputTorqueName] - device.friction * min(max(device.inputAV, -1), 1)
  device.virtualMassAV = device.virtualMassAV + outputTorque * device.invCumulativeInertia * dt

  if abs(device.outputAV1) < 100 then
    device.parkEngaged = 1
  end

  device.parkClutchAngle = min(max(device.parkClutchAngle + device.outputAV1 * dt, -device.maxParkClutchAngle), device.maxParkClutchAngle)
  device.outputTorque1 = -device.parkClutchAngle * device.parkLockSpring * device.parkEngaged * device.lockCoef
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.mode == "neutral" then
    device.velocityUpdate = neutralUpdateVelocity
    device.torqueUpdate = neutralUpdateTorque
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end

  if device.mode == "park" then
    device.velocityUpdate = parkUpdateVelocity
    device.torqueUpdate = parkUpdateTorque
    device.parkEngaged = 0
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end
end

local function validate(device)

  return true
end

local function setMode(device, mode)
  device.mode = mode
  device.reverseGearRatioCoef = mode == "reverse" and -1 or 1
  selectUpdates(device)
end

local function setGearRatio(device, ratio)
  device.gearRatio = min(max(ratio, device.minGearRatio), device.maxGearRatio)

  selectUpdates(device)
end

local function setLock(device, enabled)
  device.lockCoef = enabled and 0 or 1
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

  device.cumulativeInertia = outputInertia / device.maxGearRatio / device.maxGearRatio
  device.invCumulativeInertia = 1 / device.cumulativeInertia

  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.maxGearRatio
end

local function reset(device)
  local jbeamData = device.jbeamData
  device.gearRatio = jbeamData.gearRatio
  device.friction = jbeamData.friction or 0
  device.cumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.outputAV1 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.virtualMassAV = 0
  device.isBroken = false

  device.lockCoef = 1
  device.reverseGearRatioCoef = 1
  device.parkClutchAngle = 0

  device:setGearRatio(device.maxGearRatio)

  selectUpdates(device)
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
    gearRatio = jbeamData.gearRatio ,
    friction = jbeamData.friction or 0,
    cumulativeInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,

    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    virtualMassAV = 0,
    isBroken = false,

    lockCoef = 1,

    minGearRatio = jbeamData.minGearRatio or 0.5,
    maxGearRatio = jbeamData.maxGearRatio or 2.5,
    reverseGearRatioCoef = 1,
    gearCount = 1,
    minGearIndex = 1,
    maxGearIndex = 1,
    gearIndex = 1,
    reset = reset,
    setMode = setMode,
    validate = validate,
    calculateInertia = calculateInertia,
    setLock = setLock,

    setGearRatio = setGearRatio,
  }

  --gearbox park locking clutch
  device.parkClutchAngle = 0
  device.parkLockTorque = jbeamData.parkLockTorque or 1000 --Nm
  device.parkLockSpring = jbeamData.parkLockSpring or device.parkLockTorque --Nm/rad
  device.maxParkClutchAngle = device.parkLockTorque / device.parkLockSpring --rad

  --one way viscous coupling (prevents rolling backwards)
  device.oneWayViscousCoef = jbeamData.oneWayViscousCoef or 5
  device.oneWayViscousTorque = jbeamData.oneWayViscousTorque or  device.oneWayViscousCoef * 20

  if jbeamData.gearboxNode_nodes and type(jbeamData.gearboxNode_nodes) == "table" then
    device.transmissionNodeID = jbeamData.gearboxNode_nodes[1]
  end

  device:setGearRatio(device.maxGearRatio)

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
