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
  local absInputAV = abs(device.inputAV)

  local volumeOutputAVOffset = clamp(absOutputAV * 0.0007, 0, 0.3)
  local volumeOutput = clamp(device.gearWhineOutputVolumeCoef * device.whineVolumePerNmOut + volumeOutputAVOffset, 0, 10) * straightCutGearCoef
  volumeOutput = device.gearWhineOutputVolumeSmoother:getUncapped(volumeOutput, dt)

  local volumeInputAVOffset = clamp(absInputAV * 0.0007, 0, 0.3)
  local volumeInput = clamp(device.gearWhineInputVolumeCoef * device.whineVolumePerNmIn + volumeInputAVOffset, 0, 10) * straightCutGearCoef
  volumeInput = device.gearWhineInputVolumeSmoother:getUncapped(volumeInput, dt)

  local pitchInput = min(max(abs(device.gearWhineInputPitchCoef) * device.whinePitchPerAVIn, 0), 10)
  pitchInput = device.gearWhineInputPitchSmoother:getUncapped(pitchInput, dt)

  local pitchOutput = min(max(abs(device.gearWhineOutputPitchCoef) * device.whinePitchPerAVOut, 0), 10)
  pitchOutput = device.gearWhineOutputPitchSmoother:getUncapped(pitchOutput, dt)

  obj:setVolumePitch(device.gearWhineOutputLoop, volumeOutput, pitchOutput)
  obj:setVolumePitch(device.gearWhineInputLoop, volumeInput, pitchInput)
end

local function updateVelocity(device, dt)
  device.inputAV = device.outputAV1 * device.gearRatio * device.lockCoef
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  local inputTorque = device.parent[device.parentOutputTorqueName]
  local inputAV = device.inputAV
  device.outputTorque1 = (inputTorque - device.friction * min(max(inputAV, -1), 1)) * device.gearRatio * device.lockCoef

  device.gearWhineOutputVolumeCoef = device.gearWhineOutputVolumeCoefSmoother:get(abs(device.outputTorque1))
  device.gearWhineOutputPitchCoef = device.gearWhineOutputPitchCoefSmoother:get(device.outputAV1)
  device.gearWhineInputVolumeCoef = device.gearWhineInputVolumeCoefSmoother:get(abs(inputTorque))
  device.gearWhineInputPitchCoef = device.gearWhineInputPitchCoefSmoother:get(inputAV)
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
  if device.targetGearIndex then
    device.gearIndex = device.targetGearIndex
    device.gearRatio = device.gearRatios[device.gearIndex]

    device.targetGearIndex = nil

    if device.gearRatio ~= 0 then
      powertrain.calculateTreeInertia()
    end

    selectUpdates(device)
  end
end

local function setGearIndex(device, index)
  local oldIndex = device.gearIndex
  local maxIndex = min(oldIndex + 1, device.maxGearIndex)
  local minIndex = max(oldIndex - 1, device.minGearIndex)

  local target = min(max(index, minIndex), maxIndex)
  if oldIndex ~= 0 then
    device.targetGearIndex = target
  else
    device.gearIndex = target
    device.gearRatio = device.gearRatios[device.gearIndex]

    if device.gearRatio ~= 0 then
      powertrain.calculateTreeInertia()
    end

    selectUpdates(device)
  end
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
  device.gearWhineInputPitchSmoother:reset()
  device.gearWhineInputVolumeSmoother:reset()
  device.gearWhineOutputPitchSmoother:reset()
  device.gearWhineOutputVolumeSmoother:reset()

  device.gearWhineOutputPitchCoefSmoother:reset()
  device.gearWhineOutputVolumeCoefSmoother:reset()
  device.gearWhineInputPitchCoefSmoother:reset()
  device.gearWhineInputVolumeCoefSmoother:reset()

  device.gearWhineOutputVolumeCoef = 0
  device.gearWhineOutputPitchCoef = 0
  device.gearWhineInputVolumeCoef = 0
  device.gearWhineInputPitchCoef = 0
end

local function initSounds(device)
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>fabian_test_out"
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>gt_twine_out"
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>rally_twine_out"
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>standard_twine_out"
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>stockcar_twine_out"
  --local gearWhineOutputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>vintage_twine_out"
  local gearWhineOutputSample = device.jbeamData.gearWhineSampleOutput or "event:>Vehicle>Transmission>Straight_02>twine_out"
  device.gearWhineOutputLoop = obj:createSFXSource(gearWhineOutputSample, "AudioDefaultLoop3D", "GearWhineOut", device.transmissionNodeID or sounds.engineNode)

  --local gearWhineInputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>gt_twine_in"
  --local gearWhineInputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>rally_twine_in"
  --local gearWhineInputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>standard_twine_in"
  --local gearWhineInputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>stockcar_twine_in"
  --local gearWhineInputSample = "event:>Vehicle>Transmission>Greg_Hill_Tests>vintage_twine_in"
  local gearWhineInputSample = device.jbeamData.gearWhineSampleInput or "event:>Vehicle>Transmission>Straight_02>twine_in"
  device.gearWhineInputLoop = obj:createSFXSource(gearWhineInputSample, "AudioDefaultLoop3D", "GearWhineIn", device.transmissionNodeID or sounds.engineNode)

  local inputPitchCoefSmoothing = device.jbeamData.gearWhineInputPitchCoefSmoothing or 50
  local outputPitchCoefSmoothing = device.jbeamData.gearWhineOutputPitchCoefSmoothing or 50
  local inputVolumeCoefSmoothing = device.jbeamData.gearWhineInputVolumeCoefSmoothing or 10
  local outputVolumeCoefSmoothing = device.jbeamData.gearWhineOutputVolumeCoefSmoothing or 10

  device.gearWhineOutputPitchCoefSmoother = newExponentialSmoothing(outputPitchCoefSmoothing)
  device.gearWhineOutputVolumeCoefSmoother = newExponentialSmoothing(outputVolumeCoefSmoothing)
  device.gearWhineInputPitchCoefSmoother = newExponentialSmoothing(inputPitchCoefSmoothing)
  device.gearWhineInputVolumeCoefSmoother = newExponentialSmoothing(inputVolumeCoefSmoothing)

  local inputPitchSmoothingIn = device.jbeamData.gearWhineInputPitchSmoothingIn or 10000
  local inputPitchSmoothingOut = device.jbeamData.gearWhineInputPitchSmoothingOut or 10000
  local outputPitchSmoothingIn = device.jbeamData.gearWhineOutputPitchSmoothingIn or 10000
  local outputPitchSmoothingOut = device.jbeamData.gearWhineOutputPitchSmoothingOut or 10000
  local inputVolumeSmoothingIn = device.jbeamData.gearWhineInputVolumeSmoothingIn or 10000
  local inputVolumeSmoothingOut = device.jbeamData.gearWhineInputVolumeSmoothingOut or 10000
  local outputVolumeSmoothingIn = device.jbeamData.gearWhineOutputVolumeSmoothingIn or 10000
  local outputVolumeSmoothingOut = device.jbeamData.gearWhineOutputVolumeSmoothingOut or 10000

  device.gearWhineOutputPitchSmoother = newTemporalSmoothing(outputPitchSmoothingIn, inputPitchSmoothingOut)
  device.gearWhineOutputVolumeSmoother = newTemporalSmoothing(outputVolumeSmoothingIn, outputVolumeSmoothingOut)
  device.gearWhineInputPitchSmoother = newTemporalSmoothing(inputPitchSmoothingIn, outputPitchSmoothingOut)
  device.gearWhineInputVolumeSmoother = newTemporalSmoothing(inputVolumeSmoothingIn, inputVolumeSmoothingOut)

  device.whinePitchPerAVIn = device.jbeamData.gearWhineInputPitchCoef or 0.0008
  device.whinePitchPerAVOut = device.jbeamData.gearWhineOuputPitchCoef or 0.00112

  device.whineVolumePerNmIn = device.jbeamData.gearWhineInputVolumeCoef or 0.01
  device.whineVolumePerNmOut = device.jbeamData.gearWhineOutputVolumeCoef or 0.01

  device.gearWhineOutputVolumeCoef = 0
  device.gearWhineOutputPitchCoef = 0
  device.gearWhineInputVolumeCoef = 0
  device.gearWhineInputPitchCoef = 0

  if device.gearWhineOutputLoop and device.gearWhineInputLoop then
  --device.updateSounds = updateSounds
  end
end

local function reset(device)
  local jbeamData = device.jbeamData

  device.gearRatio = jbeamData.gearRatio or 1
  device.targetGearIndex = nil
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
  device.gearIndex = 0

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
    gearIndex = 0,
    targetGearIndex = nil,
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
    updateGFX = updateGFX
  }

  local forwardGears = {}
  local reverseGears = {}
  for _, v in pairs(jbeamData.gearRatios) do
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
    for _, v in pairs(jbeamData.straightCutGearIndexes) do
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
