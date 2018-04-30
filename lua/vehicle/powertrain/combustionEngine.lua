-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {engine = true}

local delayLine = require("delayLine")

local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor
local random = math.random

local rpmToAV = 0.104719755
local avToRPM = 9.549296596425384
local torqueToPower = 0.0001404345295653085
local psToWatt = 735.499
local hydrolockThreshold = 0.9

local function getTorqueData(device)
  local curves = {}
  local curveCounter = 1
  local maxTorque = 0
  local maxPower = 0
  local maxRPM = device.maxRPM

  local turboCoefs = nil
  local superchargerCoefs = nil
  local nitrousTorques = nil

  local torqueCurve = {}
  local powerCurve = {}

  for k,v in pairs(device.torqueCurve) do
    if type(k) == "number" and k < maxRPM then
      torqueCurve[k + 1] = v - device.friction - (device.dynamicFriction * k * rpmToAV)
      powerCurve[k + 1] = torqueCurve[k + 1] * k * torqueToPower
      maxTorque = math.max(maxTorque, torqueCurve[k + 1])
      maxPower = math.max(maxPower, powerCurve[k + 1])
    end
  end

  table.insert(curves, curveCounter, {torque = torqueCurve, power = powerCurve, name = "NA", priority = 10})

  if device.nitrousOxideInjection.isExisting then
    local torqueCurveNitrous = {}
    local powerCurveNitrous = {}
    nitrousTorques = device.nitrousOxideInjection.getAddedTorque()

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveNitrous[k + 1] = v + (nitrousTorques[k] or 0) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveNitrous[k + 1] = torqueCurveNitrous[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveNitrous[k + 1])
        maxPower = math.max(maxPower, powerCurveNitrous[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveNitrous, power = powerCurveNitrous, name = "N2O", priority = 20})
  end

  if device.turbocharger.isExisting then
    local torqueCurveTurbo = {}
    local powerCurveTurbo = {}
    turboCoefs = device.turbocharger.getTorqueCoefs()

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveTurbo[k + 1] = (v * (turboCoefs[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveTurbo[k + 1] = torqueCurveTurbo[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveTurbo[k + 1])
        maxPower = math.max(maxPower, powerCurveTurbo[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveTurbo, power = powerCurveTurbo, name = "Turbo", priority = 30})
  end

  if device.supercharger.isExisting then
    local torqueCurveSupercharger = {}
    local powerCurveSupercharger = {}
    superchargerCoefs = device.supercharger.getTorqueCoefs()

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveSupercharger[k + 1] = (v * (superchargerCoefs[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveSupercharger[k + 1] = torqueCurveSupercharger[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveSupercharger[k + 1])
        maxPower = math.max(maxPower, powerCurveSupercharger[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveSupercharger, power = powerCurveSupercharger, name = "SC", priority = 40})
  end

  if device.turbocharger.isExisting and device.supercharger.isExisting then
    local torqueCurveFinal = {}
    local powerCurveFinal = {}

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveFinal[k + 1] = (v * (turboCoefs[k] or 0) * (superchargerCoefs[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveFinal[k + 1] = torqueCurveFinal[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveFinal[k + 1])
        maxPower = math.max(maxPower, powerCurveFinal[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveFinal, power = powerCurveFinal, name = "Turbo + SC", priority = 50})
  end

  if device.turbocharger.isExisting and device.nitrousOxideInjection.isExisting then
    local torqueCurveFinal = {}
    local powerCurveFinal = {}

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveFinal[k + 1] = (v * (turboCoefs[k] or 0) + (nitrousTorques[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveFinal[k + 1] = torqueCurveFinal[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveFinal[k + 1])
        maxPower = math.max(maxPower, powerCurveFinal[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveFinal, power = powerCurveFinal, name = "Turbo + N2O", priority = 60})
  end

  if device.supercharger.isExisting and device.nitrousOxideInjection.isExisting then
    local torqueCurveFinal = {}
    local powerCurveFinal = {}

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveFinal[k + 1] = (v * (superchargerCoefs[k] or 0) + (nitrousTorques[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveFinal[k + 1] = torqueCurveFinal[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveFinal[k + 1])
        maxPower = math.max(maxPower, powerCurveFinal[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveFinal, power = powerCurveFinal, name = "SC + N2O", priority = 70})
  end

  if device.turbocharger.isExisting and device.supercharger.isExisting and device.nitrousOxideInjection.isExisting then
    local torqueCurveFinal = {}
    local powerCurveFinal = {}

    for k,v in pairs(device.torqueCurve) do
      if type(k) == "number" and k < maxRPM then
        torqueCurveFinal[k + 1] = (v * (turboCoefs[k] or 0) * (superchargerCoefs[k] or 0) + (nitrousTorques[k] or 0)) - device.friction - (device.dynamicFriction * k * rpmToAV)
        powerCurveFinal[k + 1] = torqueCurveFinal[k + 1] * k * torqueToPower
        maxTorque = math.max(maxTorque, torqueCurveFinal[k + 1])
        maxPower = math.max(maxPower, powerCurveFinal[k + 1])
      end
    end

    curveCounter = curveCounter + 1
    table.insert(curves, curveCounter, {torque = torqueCurveFinal, power = powerCurveFinal, name = "Turbo + SC + N2O", priority = 80})
  end

  table.sort(curves, function(a,b)
      local ra, rb = a.priority, b.priority
      if ra == rb then
        return a.name < b.name
      else
        return ra > rb
      end
    end)

  local dashes = {nil, {10, 4}, {8, 3, 4, 3}, {6, 3, 2, 3}, {5,3}}
  for k,v in ipairs(curves) do
    v.dash = dashes[k]
    v.width = 2
  end

  return {maxRPM = maxRPM, curves = curves, maxTorque = maxTorque, maxPower = maxPower, finalCurveName = 1, deviceName = device.name, vehicleID = obj:getID()}
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

local function scaleOutputTorque(device, state, maxReduction)
  device.outputTorqueState = max(device.outputTorqueState * state, maxReduction or 0)
  damageTracker.setDamage("engine", "engineReducedTorque", device.outputTorqueState < 1)
end

local function disable(device)
  device.outputTorqueState = 0
  device.isDisabled = true
  damageTracker.setDamage("engine", "engineDisabled", true)
end

local function enable(device)
  device.outputTorqueState = 1
  device.isDisabled = false
  damageTracker.setDamage("engine", "engineDisabled", false)
end

local function lockUp(device)
  device.outputTorqueState = 0
  device.outputAVState = 0
  device.isDisabled = true
  damageTracker.setDamage("powertrain", device.name, true)
  damageTracker.setDamage("engine", "engineLockedUp", true)
end

local function updateSounds(device, dt)
  local rpm = device.soundRPMSmoother:get(abs(device.outputAV1 * avToRPM), dt)
  local engineLoad = min(max(device.soundLoadSmoother:get(device.instantEngineLoad * device.instantEngineLoad, dt), device.soundMinLoadMix), device.soundMaxLoadMix)
  --rpm = abs(rpm - (device.lastSoundRPM or 0)) > 100 and rpm or (device.lastSoundRPM or 0)
  --engineLoad = abs(engineLoad - (device.lastSoundLoad or 0)) > 1.99 and engineLoad or (device.lastSoundLoad or 0)
  --print(abs(rpm - (device.lastSoundRPM or 0)))
--  if abs(rpm - (device.lastSoundRPM or 0)) > rpm * 0.0015 or abs(engineLoad - (device.lastSoundLoad or 0)) > 0.05 then
--    obj:setEngineSound(0, rpm, engineLoad, sounds.hzToFMODHz(rpm / 20), device.engineVolumeCoef)
--    device.lastSoundRPM = rpm
--    device.lastSoundLoad = engineLoad
--  end

  obj:setEngineSound(device.engineSoundID, rpm, engineLoad, sounds.hzToFMODHz(rpm * device.fundamentalFrequencyRPMCoef), device.engineVolumeCoef)
  device.turbocharger.updateSounds()
  device.supercharger.updateSounds()
end

local function checkHydroLocking(device, dt)
  if device.floodLevel > hydrolockThreshold then return end

  -- engine starts flooding if ALL of the waterDamage nodes is underwater
  local isFlooding = device.canFlood
  for _,n in ipairs(device.waterDamageNodes) do
    isFlooding = isFlooding and obj:inWater(n)
    if not isFlooding then break end
  end

  damageTracker.setDamage("engine", "engineIsHydrolocking", isFlooding)

  -- calculate flooding speed (positive) or drying speed (negative, and arbitrarily slower than flooding after some testing)
  local wetspeed = 1
  local dryspeed = -wetspeed/2
  local floodSpeed = (isFlooding and wetspeed or dryspeed) * (abs(device.outputAV1) / device.maxAV) -- TODO use torque instead of RPM (when torque calculation becomes more realistic)

  -- actual check for engine dying. in the future we may want to implement stalling too
  device.floodLevel = min(1, max(0, device.floodLevel + dt * floodSpeed))
  if device.floodLevel > hydrolockThreshold then
    damageTracker.setDamage("engine", "engineHydrolocked", true)
    -- avoid piston movement, simulate broken connecting rods
    device:lockUp()
    return
  end

  -- we compute the flooding percentage in steps of 10%...
  local currPercent = floor(0.5 + device.floodLevel * 10) * 10
  -- ...and use that to check when to perform UI updates
  if currPercent ~= device.prevFloodPercent then
    if currPercent > device.prevFloodPercent then
      gui.message({txt="vehicle.drivetrain.engineFlooding", context = { percent = currPercent }}, 4, "vehicle.damage.flood")
    else
      if currPercent < 10 then
        gui.message("vehicle.drivetrain.engineDried", 4, "vehicle.damage.flood")
      else
        gui.message({txt="vehicle.drivetrain.engineDrying", context = { percent = currPercent }}, 4, "vehicle.damage.flood")
      end
    end
  end
  device.prevFloodPercent = currPercent
end

local function updateEnergyStorageRatios(device)
  for _,s in pairs(device.registeredEnergyStorages) do
    local storage = energyStorage.getStorage(s)
    if storage and storage.energyType == device.requiredEnergyType then
      if storage.storedEnergy > 0 then
        device.energyStorageRatios[storage.name] = 1 / device.storageWithEnergyCounter
      else
        device.energyStorageRatios[storage.name] = 0
      end
    end
  end
end

local function updateFuelUsage(device)
  if not device.energyStorage then
    return
  end

  local hasFuel = false
  local previousTankCount = device.storageWithEnergyCounter
  for _,s in pairs(device.registeredEnergyStorages) do
    local storage = energyStorage.getStorage(s)
    if storage and storage.energyType == device.requiredEnergyType then
      local previous = device.previousEnergyLevels[storage.name]
      storage.storedEnergy = max(storage.storedEnergy - (device.spentEnergy * device.energyStorageRatios[storage.name]), 0)
      if previous > 0 and storage.storedEnergy <= 0 then
        device.storageWithEnergyCounter = device.storageWithEnergyCounter - 1
      elseif previous <= 0 and storage.storedEnergy > 0 then
        device.storageWithEnergyCounter = device.storageWithEnergyCounter + 1
      end
      device.previousEnergyLevels[storage.name] = storage.storedEnergy
      hasFuel = hasFuel or (storage and storage.storedEnergy > 0 or false)
    end
  end

  if previousTankCount ~= device.storageWithEnergyCounter then
    device:updateEnergyStorageRatios()
  end

  if not hasFuel and device.hasFuel then
    device:disable()
  elseif hasFuel and not device.hasFuel then
    device:enable()
  end

  device.hasFuel = hasFuel
end

local function updateGFX(device, dt)
  device:updateFuelUsage()

  device.outputRPM = device.outputAV1 * avToRPM

  device.starterThrottleKillTimer = max(device.starterThrottleKillTimer - dt, 0)
  if device.starterEngagedCoef > 0 then
    device.starterTimeout = device.starterTimeout + dt

    if device.starterThrottleKillCoef < 1 and device.starterThrottleKillTimer <= 0 then
      device.starterThrottleKillCoef = 1
    end
    if device.outputAV1 > device.starterMaxAV * 1.1 then
      device.starterThrottleKillTimer = 0
      device.starterEngagedCoef = 0
      device.starterThrottleKillCoef = 1
      device.starterTimeout = 0
      device.starterDisabled = false
      obj:stopSFX(device.engineStarterSound.startSound)
    end
    if device.starterTimeout >= device.starterThrottleKillTime * 20 then
      device.starterDisabled = true
      device.starterThrottleKillTimer = 0
      device.starterEngagedCoef = 0
      device.starterThrottleKillCoef = 1
      device.starterTimeout = 0
      if device.outputAV1 < device.starterMaxAV * 0.5 then
        device:lockUp()
      end
    end
  end

  if device.outputAV1 < device.starterMaxAV * 0.8 and device.ignitionCoef > 0 then
    device.stallTimer = max(device.stallTimer - dt, 0)
    if device.stallTimer <= 0 and not device.isStalled then
      device.isStalled = true
    end
  else
    device.isStalled = false
    device.stallTimer = 1
  end

  device.revLimiterWasActiveTimer = min(device.revLimiterWasActiveTimer + dt, 1000)

  local rpmTooHigh = abs(device.outputAV1) > device.maxPhysicalAV
  damageTracker.setDamage("engine", "overRevDanger", rpmTooHigh)
  if rpmTooHigh then
    device.overRevDamage = min(max(device.overRevDamage + (abs(device.outputAV1) - device.maxPhysicalAV) * dt / device.maxOverRevDamage, 0), 1)
    local lockupChance = random(40, 100) * 0.01
    local valveHitChance = random(10, 100) * 0.01
    if lockupChance <= device.overRevDamage and not damageTracker.getDamage("engine", "catastrophicOverrevDamage") then
      device:lockUp()
      damageTracker.setDamage("engine", "catastrophicOverrevDamage", true)
      gui.message({txt="vehicle.drivetrain.engineCatastrophicOverrevDamage", context = {}}, 4, "vehicle.damage.catastrophicOverrev")

      if #device.engineBlockNodes >= 2 then
        sounds.playSoundOnceAtNode("CrashTestSound", device.engineBlockNodes[1], 5)
        sounds.playSoundOnceAtNode("CrashTestSound", device.engineBlockNodes[2], 5)

        for i = 1, 50 do
          local rnd = random()
          obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], i * rnd, 39, 0, 1)
          obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], -i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], -i * rnd, 39, 0, 1)
        end
      end
    end
    if valveHitChance <= device.overRevDamage and not damageTracker.getDamage("engine", "mildOverrevDamage") then
      device:scaleOutputTorque(0.90, 0.2)
      damageTracker.setDamage("engine", "mildOverrevDamage", true)
      gui.message({txt="vehicle.drivetrain.engineMildOverrevDamage", context = {}}, 4, "vehicle.damage.mildOverrev")
    end
  end

  if device.maxTorqueRating > 0 then
    damageTracker.setDamage("engine", "overTorqueDanger", device.combustionTorque > device.maxTorqueRating)
    if device.combustionTorque > device.maxTorqueRating then
      local torqueDifference = device.combustionTorque - device.maxTorqueRating
      device.overTorqueDamage = min(device.overTorqueDamage + torqueDifference * dt, device.maxOverTorqueDamage)
      if device.overTorqueDamage >= device.maxOverTorqueDamage and not damageTracker.getDamage("engine", "catastrophicOverTorqueDamage") then
        device:lockUp()
        damageTracker.setDamage("engine", "catastrophicOverTorqueDamage", true)
        gui.message({txt="vehicle.drivetrain.engineCatastrophicOverTorqueDamage", context = {}}, 4, "vehicle.damage.catastrophicOverTorque")

        if #device.engineBlockNodes >= 2 then
          sounds.playSoundOnceAtNode("CrashTestSound", device.engineBlockNodes[1], 4)
          sounds.playSoundOnceAtNode("CrashTestSound", device.engineBlockNodes[2], 4)

          for i = 1, 50 do
            local rnd = random()
            obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], i * rnd, 43, 0, 1)
            obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], i * rnd, 39, 0, 1)
            obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], -i * rnd, 43, 0, 1)
            obj:addParticleByNodesRelative(device.engineBlockNodes[2], device.engineBlockNodes[1], -i * rnd, 39, 0, 1)
          end
        end
      end
    end
  end

  if device.friction > device.maxTorque then
    --if our friction is higher than the biggest torque we can output, the engine WILL lock up automatically
    --however, we need to communicate that with other subsystems to prevent issues, so in this case we ADDITIONALLY lock it up manually
    device:lockUp()
  end

  --push our summed fuels into the delay lines (shift fuel does not have any delay and therefore does not need a line)
  if device.shiftAfterFireFuel <= 0 then
    if device.instantAfterFireFuel > 0 then
      device.instantAfterFireFuelDelay:push(device.instantAfterFireFuel / dt)
    end
    if device.sustainedAfterFireFuel > 0 then
      device.sustainedAfterFireFuelDelay:push(device.sustainedAfterFireFuel / dt)
    end
  end

  if device.sustainedAfterFireTimer > 0 then
    device.sustainedAfterFireTimer = device.sustainedAfterFireTimer - dt
  elseif device.instantEngineLoad > 0 then
    device.sustainedAfterFireTimer = device.sustainedAfterFireTime
  end

  device.forcedInductionCoef = 1 -- reset turbo/SC coef
  device.nitrousOxideTorque = 0 -- reset N2O torque
  device.engineVolumeCoef = 1 -- reset volume coef
  device.invBurnEfficiencyCoef = 1 -- reset burn efficiency coef

  device.turbocharger.updateGFX(dt)
  device.supercharger.updateGFX(dt)
  device.nitrousOxideInjection.updateGFX(dt)

  device.thermals.updateGFX(dt)

  device.intakeAirDensityCoef = obj:getRelativeAirDensity()

  device:checkHydroLocking(dt)

  device.idleAVReadError = device.idleAVReadErrorSmoother:getUncapped(device.idleAVReadErrorRangeHalf - random(device.idleAVReadErrorRange), dt)
  device.idleAVStartOffset = device.idleAVStartOffsetSmoother:get(device.idleAV * device.idleStartCoef * device.starterEngagedCoef, dt)

  device.spentEnergy = 0
  device.spentEnergyNitrousOxide = 0
  device.engineWorkPerUpdate = 0
  device.frictionLossPerUpdate = 0
  device.pumpingLossPerUpdate = 0

  device.instantAfterFireFuel = 0
  device.sustainedAfterFireFuel = 0
  device.shiftAfterFireFuel = 0
  device.continuousAfterFireFuel = 0
end

local function setTempRevLimiter(device, revLimiterAV, maxOvershootAV)
  device.tempRevLimiterAV = revLimiterAV
  device.tempRevLimiterMaxAVOvershoot = maxOvershootAV or device.tempRevLimiterAV * 0.01
  device.invTempRevLimiterRange = 1 / device.tempRevLimiterMaxAVOvershoot
  device.isTempRevLimiterActive = true
end

local function resetTempRevLimiter(device)
  device.tempRevLimiterAV = device.maxAV * 10
  device.tempRevLimiterMaxAVOvershoot = device.tempRevLimiterAV * 0.01
  device.invTempRevLimiterRange = 1 / device.tempRevLimiterMaxAVOvershoot
  device.isTempRevLimiterActive = false
end

local function revLimiterDisabledMethod(device, engineAV, throttle, dt)
  return throttle
end

local function revLimiterSoftMethod(device, engineAV, throttle, dt)
  return -throttle * min(max(engineAV - device.maxAV, 0), device.revLimiterMaxAVOvershoot) * device.invRevLimiterRange + throttle
end

local function revLimiterTimeMethod(device, engineAV, throttle, dt)
  if device.revLimiterActive then
    device.revLimiterActiveTimer = device.revLimiterActiveTimer - dt
    --Deactivate the limiter once below the deactivation threshold
    device.revLimiterActive = device.revLimiterActiveTimer > 0 and engineAV > device.revLimiterAVThreshold
    device.revLimiterWasActiveTimer = 0
    return 0
  end

  if engineAV > device.maxAV and not device.revLimiterActive then
    device.revLimiterActiveTimer = device.revLimiterCutTime
    device.revLimiterActive = true
    device.revLimiterWasActiveTimer = 0
    return 0
  end

  return throttle
end

local function revLimiterRPMDropMethod(device, engineAV, throttle, dt)
  if device.revLimiterActive or engineAV > device.maxAV then
    --Deactivate the limiter once below the deactivation threshold
    device.revLimiterActive = engineAV > device.revLimiterAVThreshold
    device.revLimiterWasActiveTimer = 0
    return 0
  end

  return throttle
end

--velocity update is always nopped for engines

local function updateTorque(device, dt)
  local engineAV = device.outputAV1
  local throttle = (electrics.values[device.electricsThrottleName] or 0) * (electrics.values[device.electricsThrottleFactorName] or 1)

  local idleAVError = max(device.idleAV - engineAV + device.idleAVReadError + device.idleAVStartOffset, 0)
  local idleThrottle = max(throttle, min(idleAVError * 0.01, device.maxIdleThrottle))
  throttle = min(max(idleThrottle * device.starterThrottleKillCoef * device.ignitionCoef, 0), 1)

  throttle = device:applyRevLimiter(engineAV, throttle, dt)
  throttle = min(max(-throttle * min(max(engineAV - device.tempRevLimiterAV, 0), device.tempRevLimiterMaxAVOvershoot) * device.invTempRevLimiterRange + throttle, 0), 1)

  --smooth our actual throttle value to simulate various effects in a real engine that do not allow immediate throttle changes
  throttle = device.throttleSmoother:getUncapped(throttle, dt)

  local torque = (device.torqueCurve[floor(engineAV * avToRPM)] or 0) * device.intakeAirDensityCoef
  local maxCurrentTorque = torque - device.friction - (device.dynamicFriction * engineAV)
  --blend pure throttle with the constant power map
  local throttleMap = min(max(throttle + throttle * device.maxPowerThrottleMap / (torque * device.forcedInductionCoef * engineAV + 1e-30) * (1-throttle), 0), 1)

  local ignitionCut = device.ignitionCutTime > 0
  torque = ((torque * device.forcedInductionCoef * throttleMap) + device.nitrousOxideTorque) * device.outputTorqueState * (ignitionCut and 0 or 1)

  local lastInstantEngineLoad = device.instantEngineLoad
  device.instantEngineLoad = min(max(torque / ((maxCurrentTorque + 1e-30) * device.forcedInductionCoef), 0), 1)
  device.engineLoad = device.loadSmoother:get(device.instantEngineLoad, dt)

  local absEngineAV = abs(engineAV)
  local dtT = dt * torque
  local dtTNitrousOxide = dt * device.nitrousOxideTorque

  local burnEnergy = dtT * (dtT * device.halfInvEngInertia + engineAV)
  local burnEnergyNitrousOxide = dtTNitrousOxide * (dtTNitrousOxide * device.halfInvEngInertia + engineAV)
  device.engineWorkPerUpdate = device.engineWorkPerUpdate + burnEnergy
  device.frictionLossPerUpdate = device.frictionLossPerUpdate + device.friction * absEngineAV * dt
  device.pumpingLossPerUpdate = device.pumpingLossPerUpdate + device.dynamicFriction * engineAV * engineAV * dt
  local invBurnEfficiency = device.invBurnEfficiencyTable[floor(device.instantEngineLoad * 100) * 0.01] * device.invBurnEfficiencyCoef
  device.spentEnergy = device.spentEnergy + burnEnergy * invBurnEfficiency
  device.spentEnergyNitrousOxide = device.spentEnergyNitrousOxide + burnEnergyNitrousOxide * invBurnEfficiency

  local avSign = fsign(engineAV)
  --friction torque is doubled when throttle is off to represent engine braking effect
  local frictionTorque = device.friction * (3 - throttle * 2) + device.dynamicFriction * absEngineAV
  --friction torque is limited for stability
  frictionTorque = min(frictionTorque, absEngineAV * device.inertia * 2000) * avSign

  local starterTorque = device.starterEngagedCoef * device.starterTorque * min(max(1 - engineAV / device.starterMaxAV, -0.5), 1)

  device.outputTorque1 = device.clutchChild.torqueDiff
  device.outputAV1 = (engineAV + dt * (torque - device.outputTorque1 - frictionTorque + starterTorque) * device.invEngInertia) * device.outputAVState
  device.throttle = throttle
  device.combustionTorque = torque - frictionTorque

  local inertialTorque = (device.outputAV1 - device.lastOutputAV1) * device.inertia / dt
  obj:applyTorqueAxisCouple(inertialTorque, device.torqueReactionNodes[1], device.torqueReactionNodes[2], device.torqueReactionNodes[3])
  device.lastOutputAV1 = device.outputAV1

  local dLoad = min((device.instantEngineLoad - lastInstantEngineLoad) / dt, 0)
  local instantAfterFire = engineAV > device.idleAV * 2 and max(device.instantAfterFireCoef * -dLoad * lastInstantEngineLoad * absEngineAV, 0) or 0
  local sustainedAfterFire = (device.instantEngineLoad <= 0 and device.sustainedAfterFireTimer > 0) and max(engineAV * device.sustainedAfterFireCoef, 0) or 0

  device.instantAfterFireFuel = device.instantAfterFireFuel + instantAfterFire
  device.sustainedAfterFireFuel = device.sustainedAfterFireFuel + sustainedAfterFire
  device.shiftAfterFireFuel = device.shiftAfterFireFuel + instantAfterFire * (ignitionCut and 1 or 0)

  device.lastOutputTorque = torque
  device.ignitionCutTime = max(device.ignitionCutTime - dt, 0)

  device.turbocharger.update(dt)
end

local function selectUpdates(device)
  device.velocityUpdate = nop
  device.torqueUpdate = updateTorque
end

local function validate(device)
  if not device.children or #device.children < 1 then
    device.clutchChild = {torqueDiff = 0}
  elseif #device.children ~= 1 or not device.children[1].deviceCategories.clutchlike then
    log("E", "combustionEngine.validate", "Can't find clutch like child device...")
    log("E", "combustionEngine.validate", "Actual children:")
    log("E", "combustionEngine.validate", powertrain.dumpsDeviceData(device.children))
    return false
  else
    device.clutchChild = device.children[1]
    device.inertia = device.inertia + (device.clutchChild.additionalEngineInertia or 0)
    device.invEngInertia = 1 / device.inertia
    device.halfInvEngInertia = device.invEngInertia * 0.5
  end

  table.insert(powertrain.engineData,
    {
      maxRPM = device.maxRPM,
      maxSoundRPM = device.hasRevLimiter and device.maxRPM or device.maxAvailableRPM,
      torqueReactionNodes = device.torqueReactionNodes
    })

  return true
end

local function activateStarter(device)
  if device.ignitionCoef > 0 and not device.isStalled and device.starterEngagedCoef ~= 1 then
    device.ignitionCoef = 0
  else
    device.ignitionCoef = 1
    if device.starterEngagedCoef ~= 1 and not device.isDisabled then
      device.starterThrottleKillCoef = 0
      device.starterThrottleKillTimer = device.starterThrottleKillTime
      device.starterEngagedCoef = 1
      device.starterTimeout = 0
      obj:setVolume(device.engineStarterSound.startSound, device.engineStarterSound.starterVolume)
      obj:playSFX(device.engineStarterSound.startSound)
      device.engineStarterSound.loopTimer = device.engineStarterSound.loopTime
    end
  end
end

local function cutIgnition(device, time)
  device.ignitionCutTime = time
end

local function deactivateStarter(device)
  device.starterThrottleKillTimer = 0
  device.starterEngagedCoef = 0
  device.starterTimeout = 0
  obj:stopSFX(device.engineStarterSound.startSound)
end

local function setIgnition(device, value)
  device.ignitionCoef = value > 0 and 1 or 0
  if value == 0 then
    device.starterThrottleKillTimer = 0
    device.starterEngagedCoef = 0
    device.starterTimeout = 0
  end
end

local function onBreak(device)
  device:lockUp()
end

local function beamBroke(device, id)
  device.thermals.beamBroke(id)
end

local function registerStorage(device, storageName)
  local storage = energyStorage.getStorage(storageName)
  if not storage then
    return
  end
  if storage.type == "n2oTank" then
    device.nitrousOxideInjection.registerStorage(storageName)
  else
    if storage.storedEnergy > 0 then
      device.storageWithEnergyCounter = device.storageWithEnergyCounter + 1
      table.insert(device.registeredEnergyStorages, storageName)
      device:updateEnergyStorageRatios()
    end
    device.hasFuel = true
    device.previousEnergyLevels[storageName] = storage.storedEnergy
  end
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

  device.cumulativeInertia = outputInertia
  device.cumulativeGearRatio = cumulativeGearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio
end

local function resetSounds(device)
  if not sounds.usesOldCustomSounds then
    if device.jbeamData.soundConfig then
      local soundConfig = v.data[device.jbeamData.soundConfig]
      if soundConfig then
        device.soundRPMSmoother:reset()
        device.soundLoadSmoother:reset()
        device.engineVolumeCoef = 1
        --dump(sounds)
        sounds.disableOldEngineSounds()
      else
        log("E", "combustionEngine.init", "Can't find sound config: "..device.jbeamData.soundConfig)
      end
      obj:stopSFX(device.engineStarterSound.startSound)
    end
  else
    log("W", "combustionEngine.init", "Disabling new sounds, found old custom engine sounds...")
  end

  device.turbocharger.resetSounds()
  device.supercharger.resetSounds()
end

local function reset(device)
  local jbeamData = device.jbeamData
  device.friction = jbeamData.friction or 0

  device.outputAV1 = jbeamData.idleRPM * rpmToAV
  device.inputAV = 0
  device.outputTorque1 = 0
  device.virtualMassAV = 0
  device.isBroken = false
  device.combustionTorque = 0
  device.nitrousOxideTorque = 0

  device.electricsThrottleName = jbeamData.electricsThrottleName or "throttle"
  device.electricsThrottleFactorName = jbeamData.electricsThrottleFactorName or "throttleFactor"

  device.throttle = 0
  device.ignitionCoef = 1
  device.dynamicFriction = jbeamData.dynamicFriction or 0

  device.idleAVReadError = 0
  device.inertia = jbeamData.inertia or 0.1
  device.idleAVStartOffset = 0

  device.starterEngagedCoef = 0
  device.starterThrottleKillCoef = 1
  device.starterThrottleKillTimer = 0
  device.starterTimeout = 0
  device.starterDisabled = false

  device.stallTimer = 1
  device.isStalled = false

  device.floodLevel = 0
  device.prevFloodPercent = 0

  device.forcedInductionCoef = 1
  device.intakeAirDensityCoef = 1
  device.outputTorqueState = 1
  device.outputAVState = 1
  device.isDisabled = false
  device.lastOutputAV1 = jbeamData.idleRPM * rpmToAV
  device.lastOutputTorque = 0

  device.loadSmoother:reset()
  device.throttleSmoother:reset()
  device.engineLoad = 0
  device.instantEngineLoad = 0
  device.ignitionCutTime = 0

  device.sustainedAfterFireTimer = 0
  device.instantAfterFireFuel = 0
  device.sustainedAfterFireFuel = 0
  device.shiftAfterFireFuel = 0
  device.continuousAfterFireFuel = 0
  device.instantAfterFireFuelDelay:reset()
  device.sustainedAfterFireFuelDelay:reset()

  device.overRevDamage = 0

  device.overTorqueDamage = 0

  device.engineWorkPerUpdate = 0
  device.frictionLossPerUpdate = 0
  device.pumpingLossPerUpdate = 0
  device.spentEnergy = 0
  device.spentEnergyNitrousOxide = 0
  device.storageWithEnergyCounter = 0
  device.registeredEnergyStorages = {}
  device.previousEnergyLevels = {}
  device.energyStorageRatios = {}
  device.hasFuel = true

  device.revLimiterActive = false
  device.revLimiterWasActiveTimer = 999

  device.brakeSpecificFuelConsumption = 0

  device:resetTempRevLimiter()

  device.thermals.reset()

  device.turbocharger.reset()
  device.supercharger.reset()
  device.nitrousOxideInjection.reset()

  device.torqueData = getTorqueData(device)
  device.maxPower = device.torqueData.maxPower
  device.maxTorque = device.torqueData.maxTorque
  device.maxPowerThrottleMap = device.torqueData.maxPower * psToWatt

  damageTracker.setDamage("engine", "engineDisabled", false)
  damageTracker.setDamage("engine", "engineLockedUp", false)
  damageTracker.setDamage("engine", "engineReducedTorque", false)
  damageTracker.setDamage("engine", "catastrophicOverrevDamage", false)
  damageTracker.setDamage("engine", "mildOverrevDamage", false)
  damageTracker.setDamage("engine", "overRevDanger", false)
  damageTracker.setDamage("engine", "catastrophicOverTorqueDamage", false)
  damageTracker.setDamage("engine", "overTorqueDanger", false)
  damageTracker.setDamage("engine", "engineHydrolocked", false)
  damageTracker.setDamage("engine", "engineIsHydrolocking", false)

  selectUpdates(device)
end

local function initSounds(device)
  if not sounds.usesOldCustomSounds then
    if device.jbeamData.soundConfig then
      local soundConfig = v.data[device.jbeamData.soundConfig]
      if soundConfig then
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
        local fundamentalFrequencyCylinderCount = soundConfig.fundamentalFrequencyCylinderCount or 6
        device.fundamentalFrequencyRPMCoef = fundamentalFrequencyCylinderCount / 120
        device.engineVolumeCoef = 1

        local sampleName = soundConfig.sampleName
        local samplePath = "art/sound/blends/"..sampleName..".sfxBlend2D.json"
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

        local al_selection = soundConfig.additionalIdleSampleID or 0
        local al_gain = soundConfig.additionalIdleGain or 0

        local distortion = soundConfig.distortion or 0

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
          eq_e_reso = eq_e_reso,

          al_selection = al_selection,
          al_gain = al_gain,
          onLoadGain = onLoadGain,
          offLoadGain = offLoadGain,

          distortion = distortion,
        }
        --dump(params)

        obj:queueGameEngineLua(string.format("core_sounds.setEngineSoundParameterList(%d,%d,%s)", objectId, device.engineSoundID, serialize(params)))

        device.updateSounds = updateSounds
        --dump(sounds)
        sounds.disableOldEngineSounds()
      else
        log("E", "combustionEngine.init", "Can't find sound config: "..device.jbeamData.soundConfig)
      end
    end
  else
    log("W", "combustionEngine.init", "Disabling new sounds, found old custom engine sounds...")
  end

  device.engineStarterSound = {
    startSound = obj:createSFXSource(device.jbeamData.starterSample or "event:>Engine>Starter>Old_V2", 'AudioDefaultLoop3D', '', device.engineNodeID),
    starterVolume = device.jbeamData.starterVolume or 0.4,
  }
  obj:stopSFX(device.engineStarterSound.startSound)

  device.turbocharger.initSounds()
  device.supercharger.initSounds()
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
    friction = jbeamData.friction or 0,
    cumulativeInertia = 1,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,
    isPropulsed = true,

    outputAV1 = jbeamData.idleRPM * rpmToAV,
    inputAV = 0,
    outputTorque1 = 0,
    virtualMassAV = 0,
    isBroken = false,
    combustionTorque = 0,
    nitrousOxideTorque = 0,

    electricsThrottleName = jbeamData.electricsThrottleName or "throttle",
    electricsThrottleFactorName = jbeamData.electricsThrottleFactorName or "throttleFactor",

    throttle = 0,
    ignitionCoef = 1,
    dynamicFriction = jbeamData.dynamicFriction or 0,

    idleRPM = jbeamData.idleRPM,
    idleAV = jbeamData.idleRPM * rpmToAV,
    maxRPM = jbeamData.maxRPM,
    maxAV = jbeamData.maxRPM * rpmToAV,
    idleAVReadError = 0,
    idleAVReadErrorRange = (jbeamData.idleRPMRoughness or 50) * rpmToAV,
    inertia = jbeamData.inertia or 0.1,
    idleAVStartOffset = 0,
    maxIdleThrottle = jbeamData.maxIdleThrottle or 0.15,

    starterTorque = jbeamData.starterTorque or (jbeamData.friction * 8),
    starterMaxAV = (jbeamData.starterMaxRPM or jbeamData.idleRPM) * rpmToAV,
    starterEngagedCoef = 0,
    starterThrottleKillCoef = 1,
    starterThrottleKillTimer = 0,
    starterThrottleKillTime = jbeamData.starterThrottleKillTime or 0.5,
    starterTimeout = 0,
    starterDisabled = false,

    stallTimer = 1,
    isStalled = false,

    floodLevel = 0,
    prevFloodPercent = 0,

    particulates = jbeamData.particulates,
    thermalsEnabled = jbeamData.thermalsEnabled,
    engineBlockMaterial = jbeamData.engineBlockMaterial,
    oilVolume = jbeamData.oilVolume,

    cylinderWallTemperatureDamageThreshold = jbeamData.cylinderWallTemperatureDamageThreshold,
    headGasketDamageThreshold = jbeamData.headGasketDamageThreshold,
    pistonRingDamageThreshold = jbeamData.pistonRingDamageThreshold,
    connectingRodDamageThreshold = jbeamData.connectingRodDamageThreshold,

    forcedInductionCoef = 1,
    intakeAirDensityCoef = 1,
    outputTorqueState = 1,
    outputAVState = 1,
    isDisabled = false,
    lastOutputAV1 = jbeamData.idleRPM * rpmToAV,
    lastOutputTorque = 0,

    loadSmoother = newTemporalSmoothing(2,2),
    throttleSmoother = newTemporalSmoothing(12,10),
    engineLoad = 0,
    instantEngineLoad = 0,
    ignitionCutTime = 0,

    instantAfterFireCoef = jbeamData.instantAfterFireCoef or 0,
    sustainedAfterFireCoef = jbeamData.sustainedAfterFireCoef or 0,
    sustainedAfterFireTimer = 0,
    sustainedAfterFireTime = jbeamData.sustainedAfterFireTime or 1.5,
    instantAfterFireFuel = 0,
    sustainedAfterFireFuel = 0,
    shiftAfterFireFuel = 0,
    continuousAfterFireFuel = 0,
    instantAfterFireFuelDelay = delayLine.new(0.1),
    sustainedAfterFireFuelDelay = delayLine.new(0.3),

    overRevDamage = 0,
    maxOverRevDamage = jbeamData.maxOverRevDamage or 1500,

    maxTorqueRating = jbeamData.maxTorqueRating or -1,
    overTorqueDamage = 0,
    maxOverTorqueDamage = jbeamData.maxOverTorqueDamage or 1000,

    engineWorkPerUpdate = 0,
    frictionLossPerUpdate = 0,
    pumpingLossPerUpdate = 0,
    spentEnergy = 0,
    spentEnergyNitrousOxide = 0,
    storageWithEnergyCounter = 0,
    registeredEnergyStorages = {},
    previousEnergyLevels = {},
    energyStorageRatios = {},
    hasFuel = true,

    initSounds = initSounds,
    resetSounds = resetSounds,
    reset = reset,
    onBreak = onBreak,
    beamBroke = beamBroke,
    validate = validate,
    calculateInertia = calculateInertia,
    updateGFX = updateGFX,
    updateSounds = nil,
    scaleFriction = scaleFriction,
    scaleOutputTorque = scaleOutputTorque,
    activateStarter = activateStarter,
    deactivateStarter = deactivateStarter,
    sendTorqueData = sendTorqueData,
    getTorqueData = getTorqueData,
    checkHydroLocking = checkHydroLocking,
    lockUp = lockUp,
    disable = disable,
    enable = enable,
    setIgnition = setIgnition,
    cutIgnition = cutIgnition,
    setTempRevLimiter = setTempRevLimiter,
    resetTempRevLimiter = resetTempRevLimiter,
    updateFuelUsage = updateFuelUsage,
    updateEnergyStorageRatios = updateEnergyStorageRatios,
    registerStorage = registerStorage,
  }

  local torqueReactionNodes_nodes = jbeamData.torqueReactionNodes_nodes
  if torqueReactionNodes_nodes and type(torqueReactionNodes_nodes) == 'table' then
    local hasValidReactioNodes = true
    for _,v in pairs(torqueReactionNodes_nodes) do
      if type(v) ~= "number" then
        hasValidReactioNodes = false
      end
    end
    if hasValidReactioNodes then
      device.torqueReactionNodes = torqueReactionNodes_nodes
    end
  end
  if not device.torqueReactionNodes then
    device.torqueReactionNodes = {-1, -1, -1}
  end

  device.waterDamageNodes = jbeamData.waterDamage and jbeamData.waterDamage._engineGroup_nodes or {}

  device.canFlood = device.waterDamageNodes and type(device.waterDamageNodes) == "table" and #device.waterDamageNodes > 0

  device.maxPhysicalAV = device.maxAV * 1.05 --what the engine is physically capable of

  if not jbeamData.torque then
    log("E", "combustionEngine.init", "Can't find torque table... Powertrain is going to break!")
  end

  local baseTorqueTable = tableFromHeaderTable(jbeamData.torque)
  local rawBasePoints = {}
  local maxAvailableRPM = 0
  for _,v in pairs(baseTorqueTable) do
    maxAvailableRPM = max(maxAvailableRPM, v.rpm)
    table.insert(rawBasePoints, {v.rpm, v.torque})
  end
  local rawBaseCurve = createCurve(rawBasePoints)

  local rawTorqueMultCurve = {}
  if jbeamData.torqueModMult then
    local multTorqueTable = tableFromHeaderTable(jbeamData.torqueModMult)
    local rawTorqueMultPoints = {}
    for _,v in pairs(multTorqueTable) do
      maxAvailableRPM = max(maxAvailableRPM, v.rpm)
      table.insert(rawTorqueMultPoints, {v.rpm, v.torque})
    end
    rawTorqueMultCurve = createCurve(rawTorqueMultPoints)
  end

  local rawIntakeCurve = {}
  if jbeamData.torqueModIntake then
    local intakeTorqueTable = tableFromHeaderTable(jbeamData.torqueModIntake)
    local rawIntakePoints = {}
    for _,v in pairs(intakeTorqueTable) do
      maxAvailableRPM = max(maxAvailableRPM, v.rpm)
      table.insert(rawIntakePoints, {v.rpm, v.torque})
    end
    rawIntakeCurve = createCurve(rawIntakePoints)
  end

  local rawExhaustCurve = {}
  if jbeamData.torqueModExhaust then
    local exhaustTorqueTable = tableFromHeaderTable(jbeamData.torqueModExhaust)
    local rawExhaustPoints = {}
    for _,v in pairs(exhaustTorqueTable) do
      maxAvailableRPM = max(maxAvailableRPM, v.rpm)
      table.insert(rawExhaustPoints, {v.rpm, v.torque})
    end
    rawExhaustCurve = createCurve(rawExhaustPoints)
  end

  local rawCombinedCurve = {}
  for i = 0, maxAvailableRPM, 1 do
    local base = rawBaseCurve[i] or 0
    local baseMult = rawTorqueMultCurve[i] or 1
    local intake = rawIntakeCurve[i] or 0
    local exhaust  = rawExhaustCurve[i] or 0
    rawCombinedCurve[i] = base * baseMult + intake + exhaust
  end

  device.maxAvailableRPM = maxAvailableRPM
  device.maxRPM = min(device.maxRPM, maxAvailableRPM)
  device.maxAV = min(device.maxAV, maxAvailableRPM * rpmToAV)



  device.applyRevLimiter = revLimiterDisabledMethod
  device.revLimiterActive = false
  device.revLimiterWasActiveTimer = 999
  device.hasRevLimiter = jbeamData.hasRevLimiter == nil and true or jbeamData.hasRevLimiter
  if device.hasRevLimiter then
    device.revLimiterType = jbeamData.revLimiterType or "rpmDrop" --alternatives: "timeBased", "soft"
    local revLimiterRPM = jbeamData.revLimiterRPM or device.maxRPM
    device.maxRPM = min(maxAvailableRPM, revLimiterRPM)
    device.maxAV = min(maxAvailableRPM * rpmToAV, revLimiterRPM * rpmToAV)

    --purely rpm drop based
    if device.revLimiterType == "rpmDrop" then
      local revLimiterAVDrop = (jbeamData.revLimiterRPMDrop or (jbeamData.maxRPM * 0.03)) * rpmToAV
      device.revLimiterAVThreshold = min(device.maxAV - revLimiterAVDrop, device.maxAV)
      device.applyRevLimiter = revLimiterRPMDropMethod

      --combined both time or rpm drop, whatever happens first
    elseif device.revLimiterType == "timeBased" then
      device.revLimiterCutTime = jbeamData.revLimiterCutTime or 0.15
      local revLimiterMaxAVDrop = (jbeamData.revLimiterMaxRPMDrop or 500) * rpmToAV
      device.revLimiterAVThreshold = min(device.maxAV - revLimiterMaxAVDrop, device.maxAV)
      device.revLimiterActiveTimer = 0
      device.applyRevLimiter = revLimiterTimeMethod

      --soft limiter without any "drop", it just smoothly fades out throttle
    elseif device.revLimiterType == "soft" then
      device.revLimiterMaxAVOvershoot = (jbeamData.revLimiterSmoothOvershootRPM or 50) * rpmToAV
      device.revLimiterMaxAV = device.maxAV + device.revLimiterMaxAVOvershoot
      device.invRevLimiterRange = 1 / (device.revLimiterMaxAV - device.maxAV )
      device.applyRevLimiter = revLimiterSoftMethod

    else
      log("E", "combustionEngine.init", "Unknown rev limiter type: "..device.revLimiterType)
      log("E", "combustionEngine.init", "Rev limiter will be disabled!")
      device.hasRevLimiter = false
    end
  end

  device:resetTempRevLimiter()

  --cut off torque below a certain RPM to help stalling
  for i = 0, device.idleRPM * 0.3, 1 do
    rawCombinedCurve[i] = 0
  end

  local combinedTorquePoints = {}
  for i = 0, device.maxRPM, 1 do
    table.insert(combinedTorquePoints, {i, rawCombinedCurve[i] or 0})
  end

  --past redline we want to gracefully reduce the torque for a natural redline
  device.redlineTorqueDropOffRange = clamp(jbeamData.redlineTorqueDropOffRange or 500, 10, device.maxRPM)

  --last usable torque value for a smooth transition to past-maxRPM-drop-off
  local rawMaxRPMTorque = rawCombinedCurve[device.maxRPM] or 0

  --create the drop off past the max rpm for a natural redline
  table.insert(combinedTorquePoints, {device.maxRPM + device.redlineTorqueDropOffRange * 0.5, rawMaxRPMTorque * 0.7})
  table.insert(combinedTorquePoints, {device.maxRPM + device.redlineTorqueDropOffRange, rawMaxRPMTorque / 5})
  table.insert(combinedTorquePoints, {device.maxRPM + device.redlineTorqueDropOffRange * 2, 0})

  --actually create the final torque curve
  device.torqueCurve = createCurve(combinedTorquePoints)


  device.invEngInertia = 1 / device.inertia
  device.halfInvEngInertia = device.invEngInertia * 0.5

  local idleReadErrorRate = jbeamData.idleRPMRoughnessRate or device.idleAVReadErrorRange * 2
  device.idleAVReadErrorSmoother = newTemporalSmoothing(idleReadErrorRate, idleReadErrorRate)
  device.idleAVReadErrorRangeHalf = device.idleAVReadErrorRange * 0.5

  local idleAVStartOffsetRate = jbeamData.idleRPMStartRate or 1
  device.idleAVStartOffsetSmoother = newTemporalSmoothingNonLinear(idleAVStartOffsetRate, 100)
  device.idleStartCoef = jbeamData.idleRPMStartCoef or 2

  device.brakeSpecificFuelConsumption = 0

  local tempBurnEfficiencyTable = nil
  if not jbeamData.burnEfficiency or type(jbeamData.burnEfficiency) == "number" then
    tempBurnEfficiencyTable = { {0, jbeamData.burnEfficiency or 1}, {1, jbeamData.burnEfficiency or 1}}
  elseif type(jbeamData.burnEfficiency) == "table" then
    tempBurnEfficiencyTable = deepcopy(jbeamData.burnEfficiency)
  end

  local copy = deepcopy(tempBurnEfficiencyTable)
  tempBurnEfficiencyTable = {}
  for k,v in pairs(copy) do
    if type(k) == "number" then
      table.insert(tempBurnEfficiencyTable, {v[1] * 100, v[2]})
    end
  end

  tempBurnEfficiencyTable = createCurve(tempBurnEfficiencyTable)
  device.invBurnEfficiencyTable = {}
  device.invBurnEfficiencyCoef = 1
  for k,v in pairs(tempBurnEfficiencyTable) do
    device.invBurnEfficiencyTable[k * 0.01] = 1 / v
  end

  device.requiredEnergyType = jbeamData.requiredEnergyType or "gasoline"
  device.energyStorage = jbeamData.energyStorage

  if device.torqueReactionNodes and #device.torqueReactionNodes == 3 and device.torqueReactionNodes[1] >= 0 then
    local pos1 = vec3(v.data.nodes[device.torqueReactionNodes[1]].pos)
    local pos2 = vec3(v.data.nodes[device.torqueReactionNodes[2]].pos)
    local pos3 = vec3(v.data.nodes[device.torqueReactionNodes[3]].pos)
    local avgPos = (((pos1 + pos2) / 2) + pos3) / 2
    device.visualPosition = {x = avgPos.x, y = avgPos.y, z = avgPos.z}
  end

  device.engineNodeID = device.torqueReactionNodes and (device.torqueReactionNodes[1] or 0) or 0

  device.engineBlockNodes = {}
  if jbeamData.engineBlock and jbeamData.engineBlock._engineGroup_nodes and #jbeamData.engineBlock._engineGroup_nodes >=2 then
    device.engineBlockNodes = jbeamData.engineBlock._engineGroup_nodes
  end

  --dump(jbeamData)

  local thermalsFileName = jbeamData.thermalsLuaFileName or "powertrain/combustionEngineThermals"
  device.thermals = require(thermalsFileName)
  device.thermals.init(device, jbeamData)

  if jbeamData.turbocharger then
    local turbochargerFileName = jbeamData.turbochargerLuaFileName or "powertrain/turbocharger"
    device.turbocharger = require(turbochargerFileName)
    device.turbocharger.init(device, v.data[jbeamData.turbocharger])
  else
    device.turbocharger = {reset = nop, updateGFX = nop, update = nop, updateSounds = nop, initSounds = nop, resetSounds = nop, isExisting = false}
  end

  if jbeamData.supercharger then
    local superchargerFileName = jbeamData.superchargerLuaFileName or "powertrain/supercharger"
    device.supercharger = require(superchargerFileName)
    device.supercharger.init(device, v.data[jbeamData.supercharger])
  else
    device.supercharger = {reset = nop, updateGFX = nop, updateSounds = nop, initSounds = nop, resetSounds = nop, isExisting = false}
  end

  if jbeamData.nitrousOxideInjection then
    local nitrousOxideFileName = jbeamData.nitrousOxideLuaFileName or "powertrain/nitrousOxideInjection"
    device.nitrousOxideInjection = require(nitrousOxideFileName)
    device.nitrousOxideInjection.init(device, v.data[jbeamData.nitrousOxideInjection])
  else
    device.nitrousOxideInjection = {reset = nop, updateGFX = nop, updateSounds = nop, initSounds = nop, resetSounds = nop, registerStorage = nop, getAddedTorque = nop, isExisting = false}
  end

  device.torqueData = getTorqueData(device)
  device.maxPower = device.torqueData.maxPower
  device.maxTorque = device.torqueData.maxTorque
  device.maxPowerThrottleMap = device.torqueData.maxPower * psToWatt

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  damageTracker.setDamage("engine", "engineDisabled", false)
  damageTracker.setDamage("engine", "engineLockedUp", false)
  damageTracker.setDamage("engine", "engineReducedTorque", false)
  damageTracker.setDamage("engine", "catastrophicOverrevDamage", false)
  damageTracker.setDamage("engine", "mildOverrevDamage", false)
  damageTracker.setDamage("engine", "catastrophicOverTorqueDamage", false)
  damageTracker.setDamage("engine", "mildOverTorqueDamage", false)
  damageTracker.setDamage("engine", "engineHydrolocked", false)
  damageTracker.setDamage("engine", "engineIsHydrolocking", false)

  device.jbeamData = jbeamData

  selectUpdates(device)

  return device
end

M.new = new


--local command = "obj:queueGameEngineLua(string.format('scenarios.getScenario().wheelDataCallback(%s)', serialize({wheels.wheels[0].absActive, wheels.wheels[0].angularVelocity, wheels.wheels[0].angularVelocityBrakeCouple}))"

return M
