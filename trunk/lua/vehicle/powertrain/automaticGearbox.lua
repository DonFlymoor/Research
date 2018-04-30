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
local fsign = fsign

local function updateVelocity(device, dt)
  device.inputAV = device.outputAV1 * device.gearRatio * device.lockCoef
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  local signGearRatio = fsign(device.gearRatio)

  local oneWayTorque = device.oneWayTorqueSmoother:get(min(max(device.oneWayViscousCoef * device.outputAV1, -device.oneWayViscousTorque), device.oneWayViscousTorque))
  device.oneWayTorqueSmoother:set(device.outputAV1 * signGearRatio < 0 and oneWayTorque or 0)
  oneWayTorque = device.oneWayTorqueSmoother:value() * signGearRatio

  device.outputTorque1 = ((device.parent[device.parentOutputTorqueName] * device.shiftLossCoef - device.friction * min(max(device.inputAV, -1), 1)) * device.gearRatio - oneWayTorque * signGearRatio) * device.lockCoef
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

  device.parkClutchAngle = min(max(device.parkClutchAngle + device.outputAV1 * dt, -device.maxParkClutchAngle), device.maxParkClutchAngle)
  device.outputTorque1 = -device.parkClutchAngle * device.parkLockSpring * device.parkEngaged * device.lockCoef
end

local function updateGFX(device, dt)
  --interpolate gear ratio to simulate the opening/closing clutches of the auto gearbox
  if device.gearRatio ~= device.desiredGearRatio then
    local difference = device.desiredGearRatio - device.gearRatio
    local change = min(device.gearRatioChangeRate * dt, abs(difference))
    device.gearRatio = device.gearRatio + change * fsign(difference)
    if device.gearRatio == device.desiredGearRatio then
      powertrain.calculateTreeInertia()
      device.shiftLossCoef = 1
    end
    --print(string.format("Gearratio: %.3f / %.3f", device.gearRatio, device.desiredGearRatio))
  end

  device.isShifting = device.gearRatio ~= device.desiredGearRatio

  if device.mode == "park" and abs(device.outputAV1) < 100 then
    device.parkEngaged = 1
  end
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.mode == "park" then
    device.velocityUpdate = parkUpdateVelocity
    device.torqueUpdate = parkUpdateTorque
    device.parkEngaged = 0
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end

  if device.mode == "neutral" then
    device.velocityUpdate = neutralUpdateVelocity
    device.torqueUpdate = neutralUpdateTorque
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end
end

local function validate(device)
  if not device.parent.deviceCategories.viscouscoupling then
    log("E", "automaticGearbox.validate", "Parent device is not a viscous coupling device...")
    log("E", "automaticGearbox.validate", "Actual parent:")
    log("E", "automaticGearbox.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end
  return true
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function setGearIndex(device, index, gearChangeTime)
  device.gearIndex = min(max(index, device.minGearIndex), device.maxGearIndex)
  device.desiredGearRatio = device.gearRatios[device.gearIndex]
  device.gearRatioChangeRate = abs((device.desiredGearRatio - device.gearRatio) / (max(device.minimumGearChangeTime, gearChangeTime or 0)))
  device.shiftLossCoef = device.shiftEfficiency

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

  local gearRatio = device.gearRatio ~= 0 and abs(device.gearRatio) or device.maxGearRatio
  device.cumulativeInertia = outputInertia / gearRatio /gearRatio
  device.invCumulativeInertia = 1 / device.cumulativeInertia

  device.parkLockSpring = device.jbeamData.parkLockSpring or (powertrain.stabilityCoef * powertrain.stabilityCoef * device.cumulativeInertia) --Nm/rad
  device.maxParkClutchAngle = device.parkLockTorque / device.parkLockSpring --rad

  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.maxGearRatio
end

local function reset(device)
  local jbeamData = device.jbeamData
  device.gearRatio = jbeamData.gearRatio or 1
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

  device.shiftLossCoef = 1

  device.desiredGearRatio = 0
  device.isShifting = false
  device.mode = "drive"

  --gearbox park locking clutch
  device.parkClutchAngle = 0

  --one way viscous coupling (prevents rolling backwards)
  device.oneWayTorqueSmoother:reset()
  device:setGearIndex(0)

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

    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    virtualMassAV = 0,
    isBroken = false,

    lockCoef = 1,

    shiftEfficiency = jbeamData.shiftEfficiency or 0.5,
    shiftLossCoef = 1,

    gearRatios = {},
    desiredGearRatio = 0,
    isShifting = false,
    minimumGearChangeTime = jbeamData.gearChangeTime or 0.5, --time in s it takes to interpolate from one to another gear ratio when shifting (simulates clutches inside the auto transmission)
    mode = "drive",

    reset = reset,
    setMode = setMode,
    validate = validate,
    calculateInertia = calculateInertia,

    setGearIndex = setGearIndex,
    updateGFX = updateGFX,
    setLock = setLock,
  }

  local forwardGears = {}
  local reverseGears = {}
  for k,v in pairs(jbeamData.gearRatios) do
    if type(k) == "number" then
      table.insert(v >= 0 and forwardGears or reverseGears, v)
    end
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

  --gearbox park locking clutch
  device.parkClutchAngle = 0
  device.parkLockTorque = jbeamData.parkLockTorque or 1000 --Nm

  --one way viscous coupling (prevents rolling backwards)
  device.oneWayViscousCoef = jbeamData.oneWayViscousCoef or 5
  device.oneWayViscousTorque = jbeamData.oneWayViscousTorque or  device.oneWayViscousCoef * 25
  device.oneWayTorqueSmoother = newExponentialSmoothing(jbeamData.oneWayViscousSmoothing or 50)

  if jbeamData.gearboxNode_nodes and type(jbeamData.gearboxNode_nodes) == "table" then
    device.transmissionNodeID = jbeamData.gearboxNode_nodes[1]
  end

  device:setGearIndex(0)

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
