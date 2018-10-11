-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true, [2] = true}
M.deviceCategories = {differential = true}
M.requiredExternalInertiaOutputs = {1, 2}

local overSpeedFriction = 0.000001

local max = math.max
local min = math.min
local abs = math.abs
local fsign = fsign
local sqrt = math.sqrt

local function updateVelocity(device)
  --calculate input AV based on the two differential output AVs (weighted by base torque split as the split is created by different sized gears on each output)
  device.inputAV = (device.outputAV1 * device.diffTorqueSplitA + device.outputAV2 * device.diffTorqueSplitB) * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function openUpdateTorque(device)
  --for most things, use speed difference from 1 to housing, 2 to housing, rather than between 1 to 2, so that behavior is correct with torque/speed split from 0 to 1
  local outputAV1diff = device.outputAV1 - device.inputAV * device.invGearRatio
  local outputAV2diff = device.outputAV2 - device.inputAV * device.invGearRatio

  local inputAVthreshold = min(max(device.inputAV, -1), 1)
  local outputAV1threshold = min(max(outputAV1diff, -1), 1)
  local outputAV2threshold = min(max(outputAV2diff, -1), 1)

  local absMaxOutputAVdiff = max(abs(outputAV1diff), abs(outputAV2diff))
  local inputTorque = device.parent[device.parentOutputTorqueName] * (1 - min(overSpeedFriction * absMaxOutputAVdiff * absMaxOutputAVdiff * absMaxOutputAVdiff, 1)) * device.gearRatio - device.friction * inputAVthreshold

  --some small locking torque due to friction effects
  local openTorque = device.friction + 0.01 * abs(inputTorque)
  device.outputTorque1 = inputTorque * device.diffTorqueSplitA - openTorque * outputAV1threshold
  device.outputTorque2 = inputTorque * device.diffTorqueSplitB - openTorque * outputAV2threshold
end

local function LSDUpdateTorque(device)
  local outputAV1diff = device.outputAV1 - device.inputAV * device.invGearRatio
  local outputAV2diff = device.outputAV2 - device.inputAV * device.invGearRatio

  local inputAVthreshold = min(max(device.inputAV, -1), 1)
  local outputAV1threshold = min(max(outputAV1diff, -1), 1)
  local outputAV2threshold = min(max(outputAV2diff, -1), 1)

  local absMaxOutputAVdiff = max(abs(outputAV1diff), abs(outputAV2diff))
  local inputTorque = device.parent[device.parentOutputTorqueName] * (1 - min(overSpeedFriction * absMaxOutputAVdiff * absMaxOutputAVdiff * absMaxOutputAVdiff, 1)) * device.gearRatio - device.friction * inputAVthreshold

  --lsd works with an initial preload torque + input torque sensing locking ability
  local torqueSign = fsign(inputTorque)
  local lsdLockCoef = max(torqueSign, 0) * device.lsdLockCoef - min(torqueSign, 0) * device.lsdRevLockCoef
  local lsdTorque = device.lsdPreload + lsdLockCoef * abs(inputTorque) + device.friction
  device.outputTorque1 = inputTorque * device.diffTorqueSplitA - device.lsdTorque1Smoother:get(lsdTorque * outputAV1threshold)
  device.outputTorque2 = inputTorque * device.diffTorqueSplitB - device.lsdTorque2Smoother:get(lsdTorque * outputAV2threshold)
end

local function viscousLSDUpdateTorque(device)
  local outputAV1diff = device.outputAV1 - device.inputAV * device.invGearRatio
  local outputAV2diff = device.outputAV2 - device.inputAV * device.invGearRatio

  local inputAVthreshold = min(max(device.inputAV, -1), 1)
  local outputAV1threshold = min(max(outputAV1diff, -1), 1)
  local outputAV2threshold = min(max(outputAV2diff, -1), 1)

  local absMaxOutputAVdiff = max(abs(outputAV1diff), abs(outputAV2diff))
  local inputTorque = device.parent[device.parentOutputTorqueName] * (1 - min(overSpeedFriction * absMaxOutputAVdiff * absMaxOutputAVdiff * absMaxOutputAVdiff, 1)) * device.gearRatio - device.friction * inputAVthreshold

  --vlsd works with speed sensitive locking torque
  local viscousTorque1 = min(max((device.viscousCoef * outputAV1diff), -device.viscousTorque), device.viscousTorque)
  local viscousTorque2 = min(max((device.viscousCoef * outputAV2diff), -device.viscousTorque), device.viscousTorque)
  device.outputTorque1 = inputTorque * device.diffTorqueSplitA - device.viscousTorque1Smoother:get(viscousTorque1 - device.friction * outputAV1threshold)
  device.outputTorque2 = inputTorque * device.diffTorqueSplitB - device.viscousTorque2Smoother:get(viscousTorque2 - device.friction * outputAV2threshold)
end

local function lockedUpdateTorque(device, dt)
  local outputAVdiff = device.outputAV1 - device.outputAV2
  local inputAVthreshold = min(max(device.inputAV, -1), 1)
  local outputAVthreshold = min(max(outputAVdiff * 0.5, -1), 1)

  local absOutputAVdiff = abs(outputAVdiff)
  local inputTorque = device.parent[device.parentOutputTorqueName] * (1 - min(overSpeedFriction * absOutputAVdiff * absOutputAVdiff * absOutputAVdiff, 1)) * device.gearRatio - device.friction * inputAVthreshold

  --integrate a position difference for the locking spring to act on, but constrain it to deform if too much torque
  device.diffAngle = min(max(device.diffAngle + outputAVdiff * dt, -device.maxDiffAngle), device.maxDiffAngle)
  local lockTorque = min(max(device.diffAngle * device.diffAngle * device.lockSpring * fsign(device.diffAngle) + device.lockDamp * outputAVdiff, -device.lockTorque), device.lockTorque)
  device.outputTorque1 = inputTorque * 0.5 - lockTorque - device.friction * outputAVthreshold
  device.outputTorque2 = inputTorque * 0.5 + lockTorque + device.friction * outputAVthreshold
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  if device.mode == "open" then
    device.torqueUpdate = openUpdateTorque
  elseif device.mode == "lsd" then
    device.torqueUpdate = LSDUpdateTorque
  elseif device.mode == "viscous" then
    device.torqueUpdate = viscousLSDUpdateTorque
  elseif device.mode == "locked" then
    device.torqueUpdate = lockedUpdateTorque
  else
    log("E", "differential.selectDeviceUpdates", "Found unknown differential type: '" .. device.mode .. "'")
  end
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function calculateInertia(device)
  local outputInertia = 0
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  if device.children then
    local grA = 0
    local grB = 0
    local maxGRA = 0
    local maxGRB = 0
    if device.children[1] then
      outputInertia = outputInertia + device.children[1].cumulativeInertia * device.diffTorqueSplitB
      grB = device.children[1].cumulativeGearRatio
      maxGRB = device.children[1].maxCumulativeGearRatio
    end
    if device.children[2] then
      outputInertia = outputInertia + device.children[2].cumulativeInertia * device.diffTorqueSplitA
      grA = device.children[2].cumulativeGearRatio
      maxGRA = device.children[2].maxCumulativeGearRatio
    end

    if grA ~= grB or maxGRA ~= maxGRB then
      log("W", "differential.calculateInertia", string.format("Found non-matching gear ratios for differential outputs: A: '%.4f', B: '%.4f', A(max): '%.4f', B(max): '%.4f'", grA, grB, maxGRA, maxGRB))
    else
      cumulativeGearRatio = grA
      maxCumulativeGearRatio = maxGRA
    end
    outputInertia = outputInertia * 2
  end

  if device.lockSpringAutoCalc then
    device.lockSpring = powertrain.stabilityCoef * powertrain.stabilityCoef * min(device.children[1].cumulativeInertia, device.children[2].cumulativeInertia)
    device.lockTorque = device.lockSpring
  end
  device.lockDamp = device.lockSpring * 0.001
  device.maxDiffAngle = sqrt(device.lockTorque / device.lockSpring)

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

  device.invGearRatio = 1 / device.gearRatio

  --lsd specific
  device.lsdTorque1Smoother:reset()
  device.lsdTorque2Smoother:reset()

  --viscous specific
  device.viscousTorque1Smoother:reset()
  device.viscousTorque2Smoother:reset()

  --locked specific
  device.diffAngle = 0

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
    reset = reset,
    setMode = setMode,
    calculateInertia = calculateInertia
  }

  local diffTorqueSplit = jbeamData.diffTorqueSplit or 0.5
  device.diffTorqueSplitA = diffTorqueSplit
  device.diffTorqueSplitB = 1 - device.diffTorqueSplitA

  if type(jbeamData.diffType) == "table" then
    device.availableModes = shallowcopy(jbeamData.diffType)
    device.mode = jbeamData.diffType[1] or "open"
    device.defaultToggle = jbeamData.defaultToggle or true
  else
    device.mode = jbeamData.diffType or "open"
    device.availableModes = {device.mode}
  end

  device.visualType = "differential_" .. device.mode

  device.invGearRatio = 1 / device.gearRatio

  --lsd specific
  device.lsdPreload = jbeamData.lsdPreload or 50
  device.lsdLockCoef = jbeamData.lsdLockCoef or 0.2
  device.lsdRevLockCoef = jbeamData.lsdRevLockCoef or device.lsdLockCoef
  device.lsdTorque1Smoother = newExponentialSmoothing(jbeamData.lsdSmoothing or 25)
  device.lsdTorque2Smoother = newExponentialSmoothing(jbeamData.lsdSmoothing or 25)

  --viscous specific
  device.viscousCoef = jbeamData.viscousCoef or 5
  device.viscousTorque = jbeamData.viscousTorque or device.viscousCoef * 10
  device.viscousTorque1Smoother = newExponentialSmoothing(jbeamData.viscousSmoothing or 25)
  device.viscousTorque2Smoother = newExponentialSmoothing(jbeamData.viscousSmoothing or 25)

  --locked specific
  device.diffAngle = 0
  device.lockTorque = jbeamData.lockTorque or 500
  device.lockSpring = jbeamData.lockSpring or device.lockTorque

  device.lockSpringAutoCalc = jbeamData.lockSpring == nil and jbeamData.lockTorque == nil

  device.jbeamData = jbeamData

  selectUpdates(device)

  return device
end

M.new = new

return M
