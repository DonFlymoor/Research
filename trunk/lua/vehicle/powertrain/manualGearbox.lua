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
local rpmToAV = 0.104719755

local function updateSounds(device, dt)
  local straightCutGearCoef = device.straightCutGearIndexes[device.gearIndex] and 1 or 0
  local absOutputAV = abs(device.outputAV1)
  local fadeInStartAV = 20
  local fadeInEndAV = 60
  local volumeFadeIn = min(max((absOutputAV - fadeInStartAV) / (fadeInEndAV - fadeInStartAV), 0), 1)
  local volumePerAV = 0.0005
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

local function updateGFX(device, dt)
  local lastMisShiftTimer = device.misShiftPenaltyTimer
  device.misShiftPenaltyTimer = max(device.misShiftPenaltyTimer - dt, 0)
  if lastMisShiftTimer > 0 and device.misShiftPenaltyTimer <= 0 then
    device.gearRatio = device.gearRatios[device.gearIndex]
    powertrain.calculateTreeInertia()
    selectUpdates(device)
  end
end

local function setGearIndex(device, index)
  local oldIndex = device.gearIndex
  device.gearIndex = min(max(index, device.minGearIndex), device.maxGearIndex)
  local avDifference = abs((device.outputAV1 * device.gearRatios[device.gearIndex]) - device.inputAV)
  if oldIndex ~= device.gearIndex and device.gearIndex ~= 0 and avDifference >= 0.5 then
    local damage = avDifference * max(device.parent.clutchRatio - 0.2, 0)
    device.gearDamages[device.gearIndex] = min(device.gearDamages[device.gearIndex] + damage, device.gearDamageThreshold)
    --log('W', 'manualGearbox', string.format("Damage gear %d: %.2f%% (%f)", device.gearIndex, device.gearDamages[device.gearIndex] / device.gearDamageThreshold * 100, device.gearDamages[device.gearIndex]))
    if damage > 0 then
      obj:playSFXOnce(device.gearGrindSoundFile, device.transmissionNodeID or sounds.engineNode, min(max(avDifference / 80, 0), 5), min(max(avDifference / 20, 0.95), 1.1))
    end
    if damage > device.gearDamageThreshold * 0.01 and device.gearDamages[device.gearIndex] < device.gearDamageThreshold then
      gui.message({txt = string.format("Gear %g damaged (%d%%), please use the clutch!", device.gearIndex, device.gearDamages[device.gearIndex] / device.gearDamageThreshold * 100), context = {}}, 5, "vehicle.damage.gears")
    end
  end

  if device.gearDamages[device.gearIndex] >= device.gearDamageThreshold and device.gearRatios[device.gearIndex] ~= 0 then
    --gear broken...
    device.gearRatios[device.gearIndex] = 0
    gui.message({txt = string.format("Gear %g permanently broken", device.gearIndex), context = {}}, 5, "vehicle.damage.gears")
    damageTracker.setDamage("powertrain", device.name, true)
  end

  device.gearRatio = device.gearRatios[device.gearIndex]
  if device.parent and device.parent.clutchRatio > 0.6 and device.gearIndex ~= 0 and avDifference > device.shiftDenialMinimumAVDifference then
    device.gearRatio = 0
    device.misShiftPenaltyTimer = 0.5
  end

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
    log("E", "manualGearbox.validate", "Parent device is not a clutch device...")
    log("E", "manualGearbox.validate", "Actual parent:")
    log("E", "manualGearbox.validate", powertrain.dumpsDeviceData(device.parent))
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
  device.gearGrindSoundFile = device.jbeamData.gearGrindSoundFile or "file:>art>sound>transmission>gear_grind1.wav"
  --local gearWhineSample = "event:>Vehicle>Transmission>Straight_Cut_Gear_02"
  --device.gearWhineLoop = obj:createSFXSource(gearWhineSample, "AudioDefaultLoop3D", "GearWhine", device.transmissionNodeID or sounds.engineNode)
  device.gearWhinePitchSmoother = newTemporalSmoothing(1.5, 1.5)
  device.gearWhineVolumeSmoother = newTemporalSmoothing(20, 10)
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
  device.misShiftPenaltyTimer = 0

  device.gearIndex = 1
  device.gearDamages = {}

  for k, v in pairs(device.initialGearRatios) do
    device.gearRatios[k] = v
  end

  for k, v in pairs(device.initialGearDamages) do
    device.gearDamages[k] = v
  end

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
    misShiftPenaltyTimer = 0,
    gearIndex = 1,
    gearRatios = {},
    gearDamages = {},
    gearDamageThreshold = jbeamData.gearDamageThreshold or 3000,
    reset = reset,
    updateGFX = updateGFX,
    initSounds = initSounds,
    resetSounds = resetSounds,
    updateSounds = nil,
    onBreak = onBreak,
    validate = validate,
    setLock = setLock,
    calculateInertia = calculateInertia,
    setGearIndex = setGearIndex
  }

  local forwardGears = {}
  local reverseGears = {}
  local forwardGearDamages = {}
  local reverseGearDamages = {}
  for _, v in pairs(jbeamData.gearRatios) do
    table.insert(v >= 0 and forwardGears or reverseGears, v)
  end

  for _, v in pairs(jbeamData.gearDamages or {}) do
    table.insert(v >= 0 and forwardGearDamages or reverseGearDamages, abs(v))
  end

  device.maxGearIndex = 0
  device.minGearIndex = 0
  device.maxGearRatio = 0
  device.minGearRatio = 999999
  device.initialGearDamages = {}
  for i = 0, tableSize(forwardGears) - 1, 1 do
    device.gearRatios[i] = forwardGears[i + 1]
    device.gearDamages[i] = forwardGearDamages[i + 1] or 0
    device.initialGearDamages[i] = forwardGearDamages[i + 1] or 0
    device.gearDamages[i] = device.initialGearDamages[i]
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
    device.initialGearDamages[i] = reverseGearDamages[abs(index)] or 0
    device.gearDamages[i] = device.initialGearDamages[i]
    device.minGearIndex = min(device.minGearIndex, index)
    device.maxGearRatio = max(device.maxGearRatio, abs(device.gearRatios[i]))
    if device.gearRatios[i] ~= 0 then
      device.minGearRatio = min(device.minGearRatio, abs(device.gearRatios[i]))
    end
  end
  device.gearCount = abs(device.maxGearIndex) + abs(device.minGearIndex)

  device.initialGearRatios = shallowcopy(device.gearRatios)

  device.straightCutGearIndexes = {}
  if jbeamData.straightCutGearIndexes and type(jbeamData.straightCutGearIndexes) == "table" then
    for _, v in pairs(jbeamData.straightCutGearIndexes) do
      device.straightCutGearIndexes[v] = true
    end
  else
    device.straightCutGearIndexes[-1] = true
  end

  if jbeamData.gearboxNode_nodes and type(jbeamData.gearboxNode_nodes) == "table" then
    device.transmissionNodeID = jbeamData.gearboxNode_nodes[1]
  end

  device.shiftDenialMinimumAVDifference = (jbeamData.shiftDenialMinimumRPMDifference or 200) * rpmToAV

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
