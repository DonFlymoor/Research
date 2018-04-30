-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {clutchlike = true, gearbox = true}
M.requiredExternalInertiaOutputs = {1}

local max = math.max
local min = math.min
local abs = math.abs

local function updateVelocity(device, dt)
  device.inputAV = device.parent.outputAV1
  device.clutchAV1 = device.outputAV1 * device.gearRatio1 * device.lockCoef
  device.clutchAV2 = device.outputAV1 * device.gearRatio2 * device.lockCoef
end

local function updateTorque(device, dt)
  device.clutchRatio1 = electrics.values[device.electricsClutchRatio1Name] or 0
  device.clutchRatio2 = electrics.values[device.electricsClutchRatio2Name] or 0

  if device.inputAV < (device.parent.idleAV or device.inputAV) * 0.5 then
    device.clutchRatio1 = 0
    device.clutchRatio2 = 0
  end

  local avDiff1 = device.inputAV - device.clutchAV1
  local avDiff2 = device.inputAV - device.clutchAV2

  device.clutchAngle1 = min(max(device.clutchAngle1 + avDiff1 * dt * device.clutchStiffness, -device.maxClutchAngle), device.maxClutchAngle)
  device.clutchAngle2 = min(max(device.clutchAngle2 + avDiff2 * dt * device.clutchStiffness, -device.maxClutchAngle), device.maxClutchAngle)

  device.torqueDiff1 = (min(max(device.clutchAngle1 * device.lockSpring + device.lockDamp * avDiff1, -device.lockTorque), device.lockTorque)) * device.clutchRatio1
  device.torqueDiff2 = (min(max(device.clutchAngle2 * device.lockSpring + device.lockDamp * avDiff2, -device.lockTorque), device.lockTorque)) * device.clutchRatio2

  device.torqueDiff = device.torqueDiff1 + device.torqueDiff2 - device.friction * min(max(device.inputAV, -1), 1)

  device.outputTorque1 = (device.torqueDiff1 * device.gearRatio1 + device.torqueDiff2 * device.gearRatio2) * device.lockCoef
  device.clutchRatio = max(device.clutchRatio1, device.clutchRatio2)
end

local function neutralUpdateVelocity(device, dt)
  device.inputAV = device.parent.outputAV1
end

local function neutralUpdateTorque(device, dt)
  device.torqueDiff = 0
  device.outputTorque1 = 0
end

local function parkUpdateVelocity(device, dt)
  device.inputAV = device.parent.outputAV1
end

local function parkUpdateTorque(device, dt)
  device.torqueDiff = 0

  if math.abs(device.outputAV1) < 50 then
    device.parkEngaged = 1
  end

  device.parkClutchAngle = min(max(device.parkClutchAngle + device.outputAV1 * dt, -device.maxParkClutchAngle), device.maxParkClutchAngle)
  device.outputTorque1 = -device.parkClutchAngle * device.parkLockSpring * device.parkEngaged
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.mode == "neutral" then
    device.velocityUpdate = neutralUpdateVelocity
    device.torqueUpdate = neutralUpdateTorque
  end

  if device.mode == "park" then
    device.velocityUpdate = parkUpdateVelocity
    device.torqueUpdate = parkUpdateTorque
    device.parkEngaged = 0
  end
end

local function validate(device)
  if not device.parent.deviceCategories.engine then
    log("E", "dctGearbox.validate", "Parent device is not an engine device...")
    log("E", "dctGearbox.validate", "Actual parent:")
    log("E", "dctGearbox.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end

  device.lockTorque = device.jbeamData.lockTorque or (device.parent.torqueData.maxTorque + device.parent.maxRPM * device.parent.inertia * math.pi / 60)
  return true
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function setGearIndex1(device, index)
  device.gearIndex1 = min(max(index, device.minGearIndex), device.maxGearIndex)
  device.gearRatio1 = device.gearRatios[device.gearIndex1]

  selectUpdates(device)
end

local function setGearIndex2(device, index)
  device.gearIndex2 = min(max(index, device.minGearIndex), device.maxGearIndex)
  device.gearRatio2 = device.gearRatios[device.gearIndex2]

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

  local gearRatio = device.clutchRatio1 > device.clutchRatio2 and device.gearRatio1 or device.gearRatio2
  local divisionSafeGearRatio = device.gearRatio ~= 0 and abs(gearRatio) or device.maxGearRatio

  device.cumulativeInertia = min(outputInertia / divisionSafeGearRatio / divisionSafeGearRatio, device.parent.inertia * 0.5)

  device.lockSpring = device.jbeamData.lockSpring or (powertrain.stabilityCoef * powertrain.stabilityCoef * device.cumulativeInertia) --Nm/rad
  device.lockDamp = device.lockSpring / 1000
  device.maxClutchAngle = device.lockTorque / device.lockSpring --rad

  device.cumulativeGearRatio = cumulativeGearRatio * gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.maxGearRatio
end

local function reset(device)
  local jbeamData = device.jbeamData
  device.gearRatio = 0
  device.friction = jbeamData.friction or 0
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.outputAV1 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.isBroken = false

  device.lockCoef = 1

  device.gearRatio1 = 0
  device.gearRatio2 = 0

  device.clutchAngle1 = 0
  device.clutchAngle2 = 0
  device.clutchRatio1 = 1
  device.clutchRatio2 = 1
  device.clutchRatio = 1 --just used as a "max" of the two actual clutches for display purposes
  device.torqueDiff1 = 0
  device.torqueDiff2 = 0
  device.torqueDiff = 0

  device.parkClutchAngle = 0

  device.parkLockTorque = jbeamData.parkLockTorque or 1000 --Nm
  device.parkLockSpring = jbeamData.parkLockSpring or device.parkLockTorque --Nm/rad
  device.maxParkClutchAngle = device.parkLockTorque / device.parkLockSpring --rad

  device:setGearIndex1(1)
  device:setGearIndex2(2)

  device.jbeamData = jbeamData

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
    gearRatio = 0,
    friction = jbeamData.friction or 0,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,

    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    isBroken = false,

    lockCoef = 1,

    electricsClutchRatio1Name = jbeamData.electricsClutchRatio1Name or "clutchRatio1",
    electricsClutchRatio2Name = jbeamData.electricsClutchRatio2Name or "clutchRatio2",

    gearRatios = {},
    gearRatio1 = 0,
    gearRatio2 = 0,

    clutchAngle1 = 0,
    clutchAngle2 = 0,
    clutchRatio1 = 1,
    clutchRatio2 = 1,
    clutchRatio = 1, --just used as a "max" of the two actual clutches for display purposes
    torqueDiff1 = 0,
    torqueDiff2 = 0,
    torqueDiff = 0,

    additionalEngineInertia = jbeamData.additionalEngineInertia or 0,

    reset = reset,
    setMode = setMode,
    validate = validate,
    setLock = setLock,
    calculateInertia = calculateInertia,

    setGearIndex1 = setGearIndex1,
    setGearIndex2 = setGearIndex2,
  }

  device.jbeamData = jbeamData

  device.clutchStiffness = jbeamData.clutchStiffness or 1

  device.parkClutchAngle = 0

  device.parkLockTorque = jbeamData.parkLockTorque or 1000 --Nm
  device.parkLockSpring = jbeamData.parkLockSpring or device.parkLockTorque --Nm/rad
  device.maxParkClutchAngle = device.parkLockTorque / device.parkLockSpring --rad

  local forwardGears = {}
  local reverseGears = {}
  for _,v in pairs(jbeamData.gearRatios) do
    table.insert(v >= 0 and forwardGears or reverseGears, v)
  end

  device.maxGearIndex = 0
  device.minGearIndex = 0
  device.maxGearRatio = 0
  device.minGearRatio = 999999
  for i = 0, tableSize(forwardGears) - 1, 1 do
    device.gearRatios[i] = forwardGears[i + 1]
    device.maxGearIndex = max(device.maxGearIndex, i)
    device.maxGearRatio = max(device.maxGearRatio, abs(device.gearRatios[i]))
    if device.gearRatios[i] ~= 0 then
      device.minGearRatio = min(device.minGearRatio, abs(device.gearRatios[i]))
    end
  end
  local reverseGearCount = tableSize(reverseGears)
  for i = -reverseGearCount, -1, 1 do
    local index = -reverseGearCount - i - 1
    device.gearRatios[i] = reverseGears[abs(index)]
    device.minGearIndex = min(device.minGearIndex, index)
    device.maxGearRatio = max(device.maxGearRatio, abs(device.gearRatios[i]))
    if device.gearRatios[i] ~= 0 then
      device.minGearRatio = min(device.minGearRatio, abs(device.gearRatios[i]))
    end
  end
  device.gearCount = abs(device.maxGearIndex) + abs(device.minGearIndex)

  if jbeamData.gearboxNode_nodes and type(jbeamData.gearboxNode_nodes) == "table" then
    device.transmissionNodeID = jbeamData.gearboxNode_nodes[1]
  end

  device:setGearIndex1(1)
  device:setGearIndex2(2)

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
