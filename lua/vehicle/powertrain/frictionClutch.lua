-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {clutchlike = true, clutch = true}
M.requiredExternalInertiaOutputs = {1}

local max = math.max
local min = math.min

local kelvinToCelsius = -273.15

local function updateGFX(device, dt)
  local kClutchToBellHousing = 30
  local tEnv = obj:getEnvTemperature() + kelvinToCelsius

  local energyToClutch = device.frictionLossPerUpdate * device.clutchThermalsCoef * device.clutchThermalsEnabledCoef
  local energyClutchToBellHousing = (device.clutchTemperature - tEnv) * kClutchToBellHousing * dt

  device.clutchTemperature = min(max(device.clutchTemperature + (energyToClutch - energyClutchToBellHousing) * device.clutchEnergyCoef, tEnv), device.clutchPermanentDamageTempThreshold)
  local thermalEfficiency = min(max(-0.5 * (device.clutchTemperature - 300) / 100 + 1, 0.5), 1)
  device.thermalEfficiency = device.clutchPermanentlyDamaged and 0.25 or thermalEfficiency

  device.clutchSmokeTimer = device.clutchSmokeTimer > 1 and 0 or device.clutchSmokeTimer + dt * (1 - thermalEfficiency) * 50
  if device.clutchSmokeTimer >= 1 and device.children[1].transmissionNodeID then
    obj:addParticleByNodesRelative(device.children[1].transmissionNodeID, device.children[1].transmissionNodeID, 1 , 35, 0, 1)
  end

  local clutchMessage = nil
  local messageTime = 1

  if device.clutchTemperature >= 200 and not device.clutchPermanentlyDamaged then
    clutchMessage = "High clutch temperature..."
  end
  if device.thermalEfficiency < 1 and not device.clutchPermanentlyDamaged then
    clutchMessage = "Clutch overheating..."
  end

  if device.clutchTemperature >= device.clutchPermanentDamageTempThreshold and not device.clutchPermanentlyDamaged then
    clutchMessage = "Clutch permanently damaged!"
    messageTime = 3
    damageTracker.setDamage("powertrain", device.name, true)
  end

  if clutchMessage then
    device.clutchThermalsMessageTimer = device.clutchThermalsMessageTimer - dt
    if device.clutchThermalsMessageTimer <= 0 then
      gui.message({txt = clutchMessage}, messageTime, "vehicle.clutchThermals")
      device.clutchThermalsMessageTimer = 0.9
    end
  end
  --print(device.clutchTemperature)
  --print(device.thermalEfficiency)

  device.clutchPermanentlyDamaged = device.clutchPermanentlyDamaged or device.clutchTemperature >= device.clutchPermanentDamageTempThreshold

  device.frictionLossPerUpdate = 0
end

local function updateVelocity(device, dt)
  device.inputAV = device.parent.outputAV1
end

local function updateTorque(device, dt)
  device.clutchRatio = electrics.values[device.electricsClutchRatioName] or 1
  local avDiff = device.inputAV - device.outputAV1
  device.clutchAngle = min(max(device.clutchAngle + avDiff * dt * device.clutchStiffness, -device.maxClutchAngle), device.maxClutchAngle)
  local lockTorque = device.lockTorque * device.thermalEfficiency
  device.torqueDiff = (min(max(device.clutchAngle * device.lockSpring + device.lockDamp * avDiff, -lockTorque), lockTorque)) * device.clutchRatio
  device.outputTorque1 = device.torqueDiff

  device.frictionLossPerUpdate = device.frictionLossPerUpdate + device.torqueDiff * avDiff * dt
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque
end

local function setLock(device, enabled)
  device.clutchThermalsCoef = enabled and 0 or 1
end

local function validate(device)
  if not device.parent.deviceCategories.engine then
    log("E", "frictionClutch.validate", "Parent device is not an engine device...")
    log("E", "frictionClutch.validate", "Actual parent:")
    log("E", "frictionClutch.validate", powertrain.dumpsDeviceData(device.parent))
    return false
  end

  device.lockTorque = device.jbeamData.lockTorque or (device.parent.torqueData.maxTorque + device.parent.maxRPM * device.parent.inertia * math.pi / 30)
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

  device.cumulativeInertia = min(outputInertia, device.parent.inertia * 0.5)
  device.lockSpring = device.jbeamData.lockSpring or (powertrain.stabilityCoef * powertrain.stabilityCoef * device.cumulativeInertia) --Nm/rad
  device.lockDamp = device.lockSpring / 1000
  device.maxClutchAngle = device.lockTorque / device.lockSpring --rad

  device.cumulativeGearRatio = cumulativeGearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio
end

local function reset(device)
  device.cumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.outputAV1 = 0
  device.inputAV = 0
  device.outputTorque1 = 0
  device.clutchAngle = 0
  device.clutchRatio = 1
  device.torqueDiff = 0

  device.thermalEfficiency = 1
  device.frictionLossPerUpdate = 0
  device.clutchTemperature = obj:getEnvTemperature() + kelvinToCelsius
  device.clutchPermanentlyDamaged = false
  device.clutchSmokeTimer = 0
  device.clutchThermalsCoef = 1
  device.clutchThermalsMessageTimer = 0

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
    gearRatio = 1,
    additionalEngineInertia = jbeamData.additionalEngineInertia or 0,
    cumulativeInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,

    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    clutchAngle = 0,
    clutchRatio = 1,
    torqueDiff = 0,

    thermalEfficiency = 1,
    frictionLossPerUpdate = 0,
    clutchTemperature = obj:getEnvTemperature() + kelvinToCelsius,
    clutchPermanentDamageTempThreshold = jbeamData.maxClutchTemp or 500,
    clutchPermanentlyDamaged = false,
    clutchSmokeTimer = 0,
    clutchThermalsCoef = 1,
    clutchThermalsEnabledCoef = 1,
    clutchThermalsMessageTimer = 0,

    electricsClutchRatioName = jbeamData.electricsClutchRatioName or "clutchRatio",
    clutchStiffness = jbeamData.clutchStiffness or 1,

    reset = reset,
    validate = validate,
    calculateInertia = calculateInertia,
    setLock = setLock,
    updateGFX = updateGFX,
  }

  local thermalsEnabled = jbeamData.thermalsEnabled or true
  device.clutchThermalsEnabledCoef = thermalsEnabled and 1 or 0
  local mass = jbeamData.clutchMass or 10
  local specificHeat = jbeamData.clutchSpecificHeat or 490
  device.clutchEnergyCoef = 1 /  (mass * specificHeat)

  device.jbeamData = jbeamData

  selectUpdates(device)

  return device
end

M.new = new

return M
