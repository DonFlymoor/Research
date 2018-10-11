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

local function updateSounds(device, dt)
  local straightCutGearCoef = device.straightCutGearIndexes[device.gearIndex] and 1 or 0
  local absOutputAV = abs(device.outputAV1)
  local fadeInStartAV = 20
  local fadeInEndAV = 60
  local volumeFadeIn = min(max((absOutputAV - fadeInStartAV) / (fadeInEndAV - fadeInStartAV), 0), 1)
  local volumePerAV = 0.0009
  local maxVolume = 3
  local volume = min(max(abs(device.outputTorque1) * volumePerAV, 0), maxVolume) * volumeFadeIn * straightCutGearCoef
  volume = device.gearWhineVolumeSmoother:getUncapped(volume, dt)
  local pitchPerAV = 0.01
  local minPitch = 0.5
  local maxPitch = 15
  local pitch = min(max(absOutputAV * pitchPerAV, minPitch), maxPitch)
  pitch = device.gearWhinePitchSmoother:getUncapped(pitch, dt)
  obj:setVolumePitch(device.gearWhineLoop, volume, pitch)
end

local function updateVelocity(device, dt)
  device.inputAV = device.outputAV1 * device.gearRatio * device.lockCoef
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  device.outputTorque1 = (device.parent[device.parentOutputTorqueName] - device.friction * min(max(device.inputAV, -1), 1)) * device.gearRatio * device.lockCoef
end

local function neutralUpdateVelocity(device, dt)
  device.inputAV = device.virtualMassAV
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function neutralUpdateTorque(device, dt)
  local inputTorque = device.parent[device.parentOutputTorqueName] - device.friction * min(max(device.inputAV, -1), 1)
  device.virtualMassAV = device.virtualMassAV + inputTorque * device.invCumulativeInertia * dt
  device.outputTorque1 = 0
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.isBroken or device.gearRatio == 0 then
    device.velocityUpdate = neutralUpdateVelocity
    device.torqueUpdate = neutralUpdateTorque
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end
end

local function setGearIndex(device, index)
  local oldIndex = device.gearIndex
  local maxIndex = min(oldIndex + 1, device.maxGearIndex)
  local minIndex = max(oldIndex - 1, device.minGearIndex)

  device.gearIndex = min(max(index, minIndex), maxIndex)
  device.gearRatio = device.gearRatios[device.gearIndex]

  --obj:playSFXOnce(device.gearShiftSample, device.transmissionNodeID or sounds.engineNode, 1, 1)

  if device.gearRatio ~= 0 then
    powertrain.calculateTreeInertia()
  end

  selectUpdates(device)
end

local function onBreak(device)
  device.isBroken = true
  selectUpdates(device)
end

local function setLock(device, enabled)
  device.lockCoef = enabled and 0 or 1
  if device.parent and device.parent.setLock then
    device.parent:setLock(enabled)
  end
end

local function validate(device)
  if device.parent and not device.parent.deviceCategories.clutch then
    log("E", "sequentialGearbox.validate", "Parent device is not a clutch device...")
    log("E", "sequentialGearbox.validate", "Actual parent:")
    log("E", "sequentialGearbox.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end

  if not device.transmissionNodeID then
    local engine = device.parent and device.parent.parent or nil
    local engineNodeID = engine and engine.engineNodeID or nil
    device.transmissionNodeID = engineNodeID or sounds.engineNode
  end

  return true
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

  local gearRatio = device.gearRatio ~= 0 and abs(device.gearRatio) or (device.maxGearRatio * 2)
  device.cumulativeInertia = outputInertia / gearRatio / gearRatio
  device.invCumulativeInertia = 1 / device.cumulativeInertia

  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.maxGearRatio
end

local function resetSounds(device)
  device.gearWhinePitchSmoother:reset()
  device.gearWhineVolumeSmoother:reset()
end

local function initSounds(device)
 -- local gearWhineSample = "event:>Vehicle>Transmission>Straight_Cut_Gear_02"
  --device.gearWhineLoop = obj:createSFXSource(gearWhineSample, "AudioDefaultLoop3D", "GearWhine", device.transmissionNodeID or sounds.engineNode)
  device.gearWhinePitchSmoother = newTemporalSmoothing(1.5, 1.5)
  device.gearWhineVolumeSmoother = newTemporalSmoothing(20, 10)

  --device.gearShiftSample = "event:>Vehicle>gearShift"
  if device.gearWhineLoop then
    device.updateSounds = updateSounds
  end
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
  device.gearIndex = 1

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

    gearIndex = 1,
    gearRatios = {},

    reset = reset,
    initSounds = initSounds,
    resetSounds = resetSounds,
    updateSounds = nil,
    onBreak = onBreak,
    validate = validate,
    setLock = setLock,
    calculateInertia = calculateInertia,
    setGearIndex = setGearIndex,
  }

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

  device.straightCutGearIndexes = {}
  if jbeamData.straightCutGearIndexes and type(jbeamData.straightCutGearIndexes) == "table" then
    for _,v in pairs(jbeamData.straightCutGearIndexes) do
      device.straightCutGearIndexes[v] = true
    end
  else
    for i = device.minGearIndex, device.maxGearIndex, 1 do
      if i ~= 0 then
        device.straightCutGearIndexes[i] = true
      end
    end
  end

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
