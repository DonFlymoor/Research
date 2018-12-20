-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {engine = true}

local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor

local rpmToAV = 0.104719755
local avToRPM = 9.549296596425384
local torqueToPower = 0.0001404345295653085
local psToWatt = 735.499

local function getTorqueData(device)
  local curves = {}
  local curveCounter = 1
  local maxTorque = 0
  local maxTorqueRPM = 0
  local maxPower = 0
  local maxPowerRPM = 0
  local maxRPM = 0

  local torqueCurve = {}
  local powerCurve = {}

  for k, v in pairs(device.torqueCurve) do
    if type(k) == "number" then
      torqueCurve[k + 1] = v - device.friction - (device.dynamicFriction * k * rpmToAV)
      powerCurve[k + 1] = torqueCurve[k + 1] * k * torqueToPower
      if torqueCurve[k + 1] > maxTorque then
        maxTorque = torqueCurve[k + 1]
        maxTorqueRPM = k + 1
      end
      if powerCurve[k + 1] > maxPower then
        maxPower = powerCurve[k + 1]
        maxPowerRPM = k + 1
      end
      maxRPM = max(maxRPM, k)
    end
  end

  table.insert(curves, curveCounter, {torque = torqueCurve, power = powerCurve, name = "Electric", priority = 10})

  table.sort(
    curves,
    function(a, b)
      local ra, rb = a.priority, b.priority
      if ra == rb then
        return a.name < b.name
      else
        return ra > rb
      end
    end
  )

  local dashes = {nil, {10, 4}, {8, 3, 4, 3}, {6, 3, 2, 3}, {5, 3}}
  for k, v in ipairs(curves) do
    v.dash = dashes[k]
    v.width = 2
  end

  return {maxRPM = maxRPM, curves = curves, maxTorque = maxTorque, maxPower = maxPower, maxTorqueRPM = maxTorqueRPM, maxPowerRPM = maxPowerRPM, finalCurveName = curveCounter, deviceName = device.name, vehicleID = obj:getID()}
end

local function sendTorqueData(device, data)
  if not data then
    data = device:getTorqueData()
  end
  guihooks.trigger("TorqueCurveChanged", data)
end

local function scaleFriction(device, friction)
  device.friction = device.friction * friction
end

local function scaleOutputTorque(device, state)
  device.outputTorqueState = device.outputTorqueState * state
end

local function disable(device)
  device.outputTorqueState = 0
  device.isDisabled = true
end

local function enable(device)
  device.outputTorqueState = 1
  device.isDisabled = false
end

local function lockUp(device)
  device.outputTorqueState = 0
  device.outputAVState = 0
  device.isDisabled = true
end

local function updateEnergyStorageRatios(device)
  device.energyStorageRatios = {}
  for _, s in pairs(device.registeredEnergyStorages) do
    local storage = energyStorage.getStorage(s)
    if storage then
      if storage.storedEnergy > 0 then
        device.energyStorageRatios[storage.name] = 1 / device.storageWithEnergyCounter
      else
        device.energyStorageRatios[storage.name] = 0
      end
    end
  end
end

local function updateEnergyUsage(device)
  if not device.energyStorage then
    return
  end

  local hasEnergy = false
  local previousStorageCount = device.storageWithEnergyCounter
  for _, s in pairs(device.registeredEnergyStorages) do
    local storage = energyStorage.getStorage(s)
    if storage then
      local previous = device.previousEnergyLevels[storage.name]
      storage.storedEnergy = max(storage.storedEnergy - (device.spentEnergy * device.energyStorageRatios[storage.name]), 0)
      if previous > 0 and storage.storedEnergy <= 0 then
        device.storageWithEnergyCounter = device.storageWithEnergyCounter - 1
      elseif previous <= 0 and storage.storedEnergy > 0 then
        device.storageWithEnergyCounter = device.storageWithEnergyCounter + 1
      end
      device.previousEnergyLevels[storage.name] = storage.storedEnergy
    end

    hasEnergy = hasEnergy or (storage and storage.storedEnergy > 0 or false)
  end
  if previousStorageCount ~= device.storageWithEnergyCounter then
    device:updateEnergyStorageRatios()
  end
  device.spentEnergy = 0

  if not hasEnergy and not device.isDisabled then
    device:disable()
  elseif hasEnergy and device.isDisabled then
    device:enable()
  end
end

local function updateGFX(device, dt)
  device:updateEnergyUsage()

  device.outputRPM = device.outputAV1 * avToRPM

  device.grossWorkPerUpdate = 0
  device.frictionLossPerUpdate = 0
end

local function updateSounds(device, dt)
  local rpm = device.soundRPMSmoother:get(device.outputAV1 * avToRPM, dt)
  local engineLoad = min(max(device.soundLoadSmoother:get(device.instantEngineLoad * device.instantEngineLoad, dt), device.soundMinLoadMix), device.soundMaxLoadMix)
  --rpm = abs(rpm - (device.lastSoundRPM or 0)) > 100 and rpm or (device.lastSoundRPM or 0)
  --engineLoad = abs(engineLoad - (device.lastSoundLoad or 0)) > 1.99 and engineLoad or (device.lastSoundLoad or 0)
  --print(abs(rpm - (device.lastSoundRPM or 0)))
  --  if abs(rpm - (device.lastSoundRPM or 0)) > rpm * 0.0015 or abs(engineLoad - (device.lastSoundLoad or 0)) > 0.05 then
  --    obj:setEngineSound(0, rpm, engineLoad, sounds.hzToFMODHz(rpm / 20), 1)
  --    device.lastSoundRPM = rpm
  --    device.lastSoundLoad = engineLoad
  --  end

  obj:setEngineSound(device.engineSoundID, rpm, engineLoad, sounds.hzToFMODHz(rpm / 20), 1)
end

--velocity update is always nopped for engines

local function updateTorque(device, dt)
  --device.motorDirection = -1
  local engineAV = device.outputAV1
  local throttle = (electrics.values[device.electricsThrottleName] or 0) * (electrics.values[device.electricsThrottleFactorName] or 1)
  local brake = electrics.values.brake

  local rpm = engineAV * avToRPM * device.motorDirection
  local torqueRPM = rpm >= 0 and floor(rpm) or 0
  --torque = torque * min(max(throttle * device.maxPowerThrottleMap / (torque * abs(engineAV) + 1e-30), 0), 1) * device.motorDirection

  --basic motor physics (simple PMDC motor)

  --0 AV stall torque Nm with maximum voltage
  local maxStallTorque = 1000
  --AV reached (with no friction or load) with maximum voltage
  local maxFreeAV = 1257 * 1.5 * device.motorDirection

  local freeAV = throttle * maxFreeAV
  local torque = maxStallTorque * (freeAV - engineAV) / maxFreeAV * device.motorDirection

  --how much torque at present AV with maximum voltage
  local maxTorqueAtCurrentAV = maxStallTorque * (maxFreeAV - engineAV) / maxFreeAV * device.motorDirection
  --this is how much torque you could generate with dead short or 0 volts at the motor leads
  local maxBrakingTorqueAtCurrentAV = maxStallTorque * engineAV / maxFreeAV * device.motorDirection

  --simple motor control stuff

  --regen torque cap in normal driving
  local throttleRegenCapCoef = 0.1
  --regen torque cap at max braking
  local brakeRegenCapCoef = 1

  --some crude logic for max regen torque
  local regenCap = maxStallTorque * min(1, throttleRegenCapCoef + brake * (brakeRegenCapCoef - throttleRegenCapCoef))

  --torque curve cap
  local torqueCap = (device.torqueCurve[torqueRPM] or device.torqueCurve[0])

  --cap the gross torque
  torque = max(min(torque, torqueCap), -min(regenCap, torqueCap))

  --I figured engine load should be a ratio of actual max torque, could be wrong though, but I dont use it for efficiency anyways atm
  device.instantEngineLoad = min(max(device.outputTorque1 / (maxTorqueAtCurrentAV + 1e-30), 0), 1)
  device.engineLoad = device.loadSmoother:get(device.instantEngineLoad, dt)

  local dtT = dt * torque
  local grossWork = dtT * (dtT * device.halfInvEngInertia + engineAV)
  device.grossWorkPerUpdate = device.grossWorkPerUpdate + grossWork

  local avSign = fsign(engineAV)
  local frictionTorque = abs(device.friction * avSign + device.dynamicFriction * engineAV)

  --efficiency map values to match Nissan Leaf map
  local kC = 0.13
  local kI = 3
  local kW = 0.000003
  local C = 400

  local absTorque = abs(torque)
  local motorEfficiencyGross = absTorque * engineAV / (absTorque * engineAV + kC * absTorque * absTorque + kI * engineAV + kW * engineAV * engineAV * engineAV + C)
  local motorEfficiencyNet = absTorque * engineAV / (absTorque * engineAV + kC * absTorque * absTorque + kI * engineAV + kW * engineAV * engineAV * engineAV + frictionTorque * engineAV + C)
  device.spentEnergy = device.spentEnergy + motorEfficiencyGross > 0 and grossWork / motorEfficiencyGross or 0

  device.frictionLossPerUpdate = device.frictionLossPerUpdate + dt * engineAV * (device.friction + device.dynamicFriction * engineAV)

  --friction torque is limited for stability
  frictionTorque = min(frictionTorque, abs(engineAV) * device.inertia * 2000) * avSign

  device.outputTorque1 = device.clutchChild.torqueDiff
  device.outputAV1 = (engineAV + dt * (torque - device.outputTorque1 - frictionTorque) * device.invEngInertia) * device.outputAVState

  --print(torque)
  --print(regenCap)
  --print(torqueCap)
  --print(motorEfficiencyGross)
  --print(device.spentEnergy)
end

local function selectUpdates(device)
  device.velocityUpdate = nop
  device.torqueUpdate = updateTorque
end

local function validate(device)
  if not device.children or #device.children < 1 then
    device.clutchChild = {torqueDiff = 0}
  elseif #device.children ~= 1 or not device.children[1].deviceCategories.clutchlike then
    log("E", "electricMotor.validate", "Can't find clutch like child device...")
    log("E", "electricMotor.validate", "Actual children:")
    log("E", "electricMotor.validate", powertrain.dumpsDeviceData(device.children))
    return false
  else
    device.clutchChild = device.children[1]
    device.invEngInertia = 1 / (device.inertia + (device.clutchChild.additionalEngineInertia or 0))
    device.halfInvEngInertia = device.invEngInertia * 0.5
  end

  table.insert(powertrain.engineData, {maxRPM = device.maxRPM, torqueReactionNodes = device.torqueReactionNodes})

  return true
end

local function onBreak(device)
  device:lockUp()
end

local function setTempRevLimiter(device, revLimiterAV, maxOvershootAV)
  device.tempRevLimiterAV = revLimiterAV
  device.tempRevLimiterMaxAVOvershoot = maxOvershootAV or device.tempRevLimiterAV * 0.01
  device.invTempRevLimiterRange = 1 / device.tempRevLimiterMaxAVOvershoot
  device.isTempRevLimiterActive = true
end

local function resetTempRevLimiter(device)
  device.tempRevLimiterAV = 999999999
  --device.maxAV * 10
  device.tempRevLimiterMaxAVOvershoot = device.tempRevLimiterAV * 0.01
  device.invTempRevLimiterRange = 1 / device.tempRevLimiterMaxAVOvershoot
  device.isTempRevLimiterActive = false
end

local function registerStorage(device, storageName)
  local storage = energyStorage.getStorage(storageName)
  if storage and storage.storedEnergy > 0 then
    device.storageWithEnergyCounter = device.storageWithEnergyCounter + 1
    table.insert(device.registeredEnergyStorages, storageName)
    device:updateEnergyStorageRatios()
  end
  device.previousEnergyLevels[storageName] = storage.storedEnergy
end

local function calculateInertia(device)
  local outputInertia = 0
  if device.children and #device.children > 0 then
    outputInertia = device.children[1].cumulativeInertia
  end

  device.cumulativeInertia = outputInertia
end

local function initSounds(device)
  if not sounds.usesOldCustomSounds then
    if device.jbeamData.soundConfig then
      local soundConfig = v.data[device.jbeamData.soundConfig]
      if soundConfig and not sounds.usesOldCustomSounds then
        device.engineSoundID = powertrain.getEngineSoundID()
        local rpmInRate = soundConfig.rpmSmootherInRate or 15
        local rpmOutRate = soundConfig.rpmSmootherOutRate or 25
        device.soundRPMSmoother = newTemporalSmoothingNonLinear(rpmInRate, rpmOutRate)
        local loadInRate = soundConfig.loadSmootherInRate or 20
        local loadOutRate = soundConfig.loadSmootherOutRate or 20
        device.soundLoadSmoother = newTemporalSmoothingNonLinear(loadInRate, loadOutRate)
        device.soundMaxLoadMix = soundConfig.maxLoadMix or 1
        device.soundMinLoadMix = soundConfig.minLoadMix or 0
        local onLoadGain = soundConfig.onLoadGain or 1
        local offLoadGain = soundConfig.offLoadGain or 1

        local sampleName = soundConfig.sampleName
        if sampleName then
          local samplePath = "art/sound/blends/" .. sampleName .. ".sfxBlend2D.json"
          obj:queueGameEngineLua(string.format("core_sounds.initEngineSound(%d,%d,%q,%s,%f,%f)", objectId, device.engineSoundID, samplePath, device.engineNodeID, offLoadGain, onLoadGain))

          local main_gain = soundConfig.mainGain or 0

          local eq_a_freq = sounds.hzToFMODHz(soundConfig.lowCutFreq or 20)
          local eq_b_freq = sounds.hzToFMODHz(soundConfig.highCutFreq or 10000)
          local eq_c_freq = sounds.hzToFMODHz(soundConfig.eqLowFreq or 500)
          local eq_c_gain = soundConfig.eqLowGain or 0
          local eq_c_reso = soundConfig.eqLowWidth or 0
          local eq_d_freq = sounds.hzToFMODHz(soundConfig.eqHighFreq or 2000)
          local eq_d_gain = soundConfig.eqHighGain or 0
          local eq_d_reso = soundConfig.eqHighWidth or 0
          local eq_e_gain = soundConfig.eqFundamentalGain or 0
          local eq_e_reso = soundConfig.eqFundamentalWidth or 1

          local params = {
            main_gain = main_gain,
            eq_a_freq = eq_a_freq,
            eq_b_freq = eq_b_freq,
            eq_c_freq = eq_c_freq,
            eq_c_gain = eq_c_gain,
            eq_c_reso = eq_c_reso,
            eq_d_freq = eq_d_freq,
            eq_d_gain = eq_d_gain,
            eq_d_reso = eq_d_reso,
            eq_e_gain = eq_e_gain,
            eq_e_reso = eq_e_reso
          }
          --dump(params)

          obj:queueGameEngineLua(string.format("core_sounds.setEngineSoundParameterList(%d,%d,%s)", objectId, device.engineSoundID, serialize(params)))

          device.updateSounds = updateSounds
        end
        --dump(sounds)
        sounds.disableOldEngineSounds()
      else
        log("E", "electricMotor.init", "Can't find sound config: " .. device.jbeamData.soundConfig)
      end
    end
  else
    log("W", "electricMotor.init", "Disabling new sounds, found old custom engine sounds...")
  end
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
    gearRatio = jbeamData.gearRatio,
    friction = jbeamData.friction or 0,
    cumulativeGearRatio = jbeamData.cumulativeGearRatio,
    isPhysicallyDisconnected = true,
    isPropulsed = true,
    outputAV1 = 0,
    inputAV = 0,
    outputTorque1 = 0,
    virtualMassAV = 0,
    isBroken = false,
    electricsThrottleName = jbeamData.electricsThrottleName or "throttle",
    electricsThrottleFactorName = jbeamData.electricsThrottleFactorName or "throttleFactor",
    throttle = 0,
    dynamicFriction = jbeamData.dynamicFriction or 0,
    inertia = jbeamData.inertia or 0.1,
    idleAV = 0, --we keep these for compat with logic that expects an ICE
    idleRPM = 0,
    outputTorqueState = 1,
    outputAVState = 1,
    isDisabled = false,
    ignitionCoef = 1,
    isStalled = false,
    instantEngineLoad = 0,
    engineLoad = 0,
    loadSmoother = newTemporalSmoothing(1, 1),
    grossWorkPerUpdate = 0,
    frictionLossPerUpdate = 0,
    spentEnergy = 0,
    storageWithEnergyCounter = 0,
    registeredEnergyStorages = {},
    previousEnergyLevels = {},
    initSounds = initSounds,
    updateSounds = nop,
    onBreak = onBreak,
    validate = validate,
    calculateInertia = calculateInertia,
    updateGFX = updateGFX,
    scaleFriction = scaleFriction,
    scaleOutputTorque = scaleOutputTorque,
    activateStarter = nop,
    deactivateStarter = nop,
    setIgnition = nop,
    cutIgnition = nop,
    setTempRevLimiter = setTempRevLimiter,
    resetTempRevLimiter = resetTempRevLimiter,
    sendTorqueData = sendTorqueData,
    getTorqueData = getTorqueData,
    lockUp = lockUp,
    disable = disable,
    enable = enable,
    updateEnergyUsage = updateEnergyUsage,
    updateEnergyStorageRatios = updateEnergyStorageRatios,
    registerStorage = registerStorage
  }

  device.jbeamData = jbeamData

  device.motorDirection = 1

  device.torqueReactionNodes = jbeamData["torqueReactionNodes_nodes"]

  device.maxRPM = 0

  if not jbeamData.torque then
    log("E", "electricMotor.init", "Can't find torque table... Powertrain is going to break!")
  end
  local torqueTable = tableFromHeaderTable(jbeamData.torque)
  local points = {}
  for _, v in pairs(torqueTable) do
    table.insert(points, {v.rpm, v.torque})
    device.maxRPM = max(device.maxRPM, v.rpm)
  end
  device.torqueCurve = createCurve(points)
  device.maxAV = device.maxRPM * rpmToAV

  device.invEngInertia = 1 / device.inertia
  device.halfInvEngInertia = device.invEngInertia * 0.5

  local tempElectricalEfficiencyTable = nil
  if not jbeamData.electricalEfficiency or type(jbeamData.electricalEfficiency) == "number" then
    tempElectricalEfficiencyTable = {{0, jbeamData.electricalEfficiency or 1}, {1, jbeamData.electricalEfficiency or 1}}
  elseif type(jbeamData.electricalEfficiency) == "table" then
    tempElectricalEfficiencyTable = deepcopy(jbeamData.electricalEfficiency)
  end

  local copy = deepcopy(tempElectricalEfficiencyTable)
  tempElectricalEfficiencyTable = {}
  for k, v in pairs(copy) do
    if type(k) == "number" then
      table.insert(tempElectricalEfficiencyTable, {v[1] * 100, v[2]})
    end
  end

  tempElectricalEfficiencyTable = createCurve(tempElectricalEfficiencyTable)
  device.electricalEfficiencyTable = {}
  for k, v in pairs(tempElectricalEfficiencyTable) do
    device.electricalEfficiencyTable[k * 0.01] = v
  end

  device.requiredEnergyType = "electricEnergy"
  device.energyStorage = jbeamData.energyStorage

  if device.torqueReactionNodes and #device.torqueReactionNodes == 3 then
    local pos1 = vec3(v.data.nodes[device.torqueReactionNodes[1]].pos)
    local pos2 = vec3(v.data.nodes[device.torqueReactionNodes[2]].pos)
    local pos3 = vec3(v.data.nodes[device.torqueReactionNodes[3]].pos)
    local avgPos = (((pos1 + pos2) / 2) + pos3) / 2
    device.visualPosition = {x = avgPos.x, y = avgPos.y, z = avgPos.z}
  end

  device:resetTempRevLimiter()

  --dump(jbeamData)

  device.torqueData = getTorqueData(device)
  device.maxPower = device.torqueData.maxPower
  device.maxTorque = device.torqueData.maxTorque
  device.maxPowerThrottleMap = device.torqueData.maxPower * psToWatt

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  selectUpdates(device)

  return device
end

M.new = new

return M
