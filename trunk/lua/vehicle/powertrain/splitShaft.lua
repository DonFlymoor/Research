-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true, [2] = true}
M.deviceCategories = {shaft = true, differential = true}
M.requiredExternalInertiaOutputs = {1, 2}

local primaryOutputID = 1
local secondaryOutputID = 2

local max = math.max
local min = math.min
local fsign = fsign

local function updateVelocity(device, dt)
  device.inputAV = device[device.primaryOutputAVName] * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function lockedUpdateTorque(device, dt)
  local avDiff = (device[device.primaryOutputAVName] - device[device.secondaryOutputAVName])
  device.shaftAngle = min(max(device.shaftAngle + avDiff * dt, -device.maxShaftAngle), device.maxShaftAngle)
  local secondaryTorque = min(max(device.shaftAngle * device.shaftAngle * device.lockSpring * fsign(device.shaftAngle) + device.lockDamp * avDiff, -device.lockTorque), device.lockTorque)
  local primaryTorque = device.parent[device.parentOutputTorqueName] * device.gearRatio - secondaryTorque - device.friction * min(max(device[device.primaryOutputAVName], -1), 1)
  device[device.primaryOutputTorqueName] = primaryTorque
  device[device.secondaryOutputTorqueName] = secondaryTorque
end

local function viscousUpdateTorque(device)
  local avDiff = (device[device.primaryOutputAVName] - device[device.secondaryOutputAVName])
  local secondaryTorque = device.torqueSmoother:get(min(max((device.viscousCoef * avDiff), -device.viscousTorque), device.viscousTorque))
  local primaryTorque = device.parent[device.parentOutputTorqueName] * device.gearRatio - secondaryTorque - device.friction * min(max(device[device.primaryOutputAVName], -1), 1)
  device[device.primaryOutputTorqueName] = primaryTorque
  device[device.secondaryOutputTorqueName] = secondaryTorque
end

local function disconnectedUpdateTorque(device)
  device[device.primaryOutputTorqueName] = device.parent[device.parentOutputTorqueName] * device.gearRatio - device.friction * min(max(device[device.primaryOutputAVName], -1), 1)
  device[device.secondaryOutputTorqueName] = 0
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  if device.splitType == "viscous" then
    device.torqueUpdate = viscousUpdateTorque
  elseif device.splitType == "locked" then
    device.torqueUpdate = lockedUpdateTorque
  end

  if device.isBroken or device.mode == "disconnected" then
    device.torqueUpdate = disconnectedUpdateTorque
  end
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function validate(device)
  if device.isPhysicallyDisconnected then
    device.mode = "disconnected"
    selectUpdates(device)
  end

  return true
end

local function onBreak(device)
  device.isBroken = true
  device.virtualMassAV = device.outputAV1

  selectUpdates(device)
end

local function calculateInertia(device)
  local outputInertia = 0
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  if device.children then
    if device.children[primaryOutputID] then
      outputInertia = device.children[primaryOutputID].cumulativeInertia
      cumulativeGearRatio = device.children[primaryOutputID].cumulativeGearRatio
      maxCumulativeGearRatio = device.children[primaryOutputID].maxCumulativeGearRatio
    end
  end

  device.cumulativeInertia = outputInertia / device.gearRatio / device.gearRatio
  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.gearRatio
end

local function reset(device)
  local jbeamData = device.jbeamData

  device.gearRatio = jbeamData.gearRatio or 1
  device.friction = jbeamData.friction or 0
  device.cumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.outputAV1 = 0
  device.outputAV2 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.outputTorque2 = 0
  device.visualShaftAngle = 0
  device.isBroken = false

  device.viscousCoef = jbeamData.viscousCoef or 10

  if jbeamData.canDisconnect then
    device.mode = jbeamData.isDisconnected and "disconnected" or "connected"
  else
    device.mode = "connected"
  end

  --locked specific
  device.shaftAngle = 0

  --viscous specific
  device.torqueSmoother:reset()

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
    gearRatio = jbeamData.gearRatio or 1,
    friction = jbeamData.friction or 0,
    cumulativeInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,

    defaultVirtualInertia = jbeamData.defaultVirtualInertia or nil, --meant to be nil if not specified manually

    outputAV1 = 0,
    outputAV2 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    outputTorque2 = 0,
    visualShaftAngle = 0,
    isBroken = false,
    splitType = jbeamData.splitType or "viscous",

    reset = reset,
    onBreak = onBreak,
    setMode = setMode,
    validate = validate,
    calculateInertia = calculateInertia,
  }

  primaryOutputID = min(max(jbeamData.primaryOutputID or 1, 1), 2)  --must be either 1 or 2
  secondaryOutputID = math.abs(primaryOutputID * 3 - 5) --converts 1 -> 2 and 2 -> 1

  device.primaryOutputTorqueName = "outputTorque"..tostring(primaryOutputID)
  device.primaryOutputAVName = "outputAV"..tostring(primaryOutputID)
  device.secondaryOutputTorqueName = "outputTorque"..tostring(secondaryOutputID)
  device.secondaryOutputAVName = "outputAV"..tostring(secondaryOutputID)

  if jbeamData.canDisconnect then
    device.availableModes = {"connected", "disconnected"}
    device.mode = jbeamData.isDisconnected and "disconnected" or "connected"
  else
    device.availableModes = {"connected"}
    device.mode = "connected"
  end

  --locked specific
  device.shaftAngle = 0
  device.lockTorque = jbeamData.lockTorque or 500
  device.lockSpring = jbeamData.lockSpring or device.lockTorque
  device.maxShaftAngle = math.sqrt(device.lockTorque / device.lockSpring)
  device.lockDamp = device.lockSpring / 1000

  --viscous specific
  device.viscousCoef = jbeamData.viscousCoef or 10
  device.viscousTorque = jbeamData.viscousTorque or device.viscousCoef * 10
  device.torqueSmoother = newExponentialSmoothing(jbeamData.viscousSmoothing or 25)

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
