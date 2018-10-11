local M = {}

local settings = require("simplesettings")

local max = math.max
local min = math.min
local abs = math.abs
local random = math.random
local sqrt = math.sqrt

local conversion = {
  kelvinToCelsius = -273.15,
  celsiusToKelvin = 273.15,
  avToRPM = 9.549296596425384
}

local parentEngine = nil
local jbeamData = nil
local tEnv = 0

--Thermal variables
M.engineBlockTemperature = 0
M.cylinderWallTemperature = 0
M.coolantTemperature = 0
M.oilTemperature = 0
M.exhaustTemperature = 0
M.radiatorFanSpin = 0

M.exhaustEndNodes = {}

local energyCoef = {
  engineBlock = nil,
  cylinderWall = nil,
  oil = nil,
  coolant = nil,
  exhaust = nil
}

local thermalsEnabled = false

local engineBlockMeltingTemperature = 0
local cylinderWallMeltingTemperature = 0
local coolantMass = 0
local invInitialCoolantMass = 0
local burnEfficiencyCoef = 0
local engineBlockAirCoolingEfficiency = 0
local blockFanMaxAirSpeed = 0
local blockFanRPMCoef = 0

--Radiator
local radiatorFanType = nil
local radiatorFanMaxAirSpeed = 0
local radiatorFanTemperature = 0
local thermostatTemperature = 0
local oilThermostatTemperature = 0
local fanAirSpeed = 0
local mechanicalRadiatorFanRPMCoef = 0
local radiatorCoef = 0
local oilRadiatorCoef = 0
local hasCoolantRadiator = false
local hasOilRadiator = false
local electricalRadiatorFanSmoother = nil
local mechanicalFanRPMCoef = 0

--Damage
local damageThreshold = {
  headGasket = 0,
  pistonRing = 0,
  connectingRod = 0,
  engineBlockTemperature = 0,
  cylinderWallTemperature = 0
}

M.engineBlockOverheatDamage = 0
M.oilOverheatDamage = 0
M.cylinderWallOverheatDamage = 0
M.headGasketBlown = false
M.pistonRingsDamaged = false
M.connectingRodBearingsDamaged = false
M.radiatorDamage = 0
M.engineBlockMelted = false
M.cylinderWallsMelted = false
local coolantOverpressureLeakRate = 0
local coolantHeadGasketLeakRate = 0
local radiatorLeakRate = 0
local radiatorDamageDeformGroup = "radiator_damage"
local radiatorDeformThreshold = 0
local oilStarvingTimer = 0
local oilStarvingTimerThreshold = 5
local oilStarvingDamage = 0
local hasOilStarvingDamage = false

--Particles & Sound
local engineSteamParticleTick = 0
local exhaustSteamParticleTick = 0
local exhaustOilParticleTick = 0
local exhaustSmokeParticleTick = 0
local radiatorSteamParticleTick = 0
local knockSoundTick = 0
local particulates = 0
local idleParticulates = 0

local startPreHeated = true

--Thermal constants
local constants = {
  preHeatTemperature = 80,
  oilSpecHeat = 1800,
  coolantSpecHeat = 4000,
  exhaustSpecHeat = 500,
  minimumCoolantMass = 1.5,
  coolantTemperatureDamageThreshold = 120,
  maxCoolantTemperature = 130,
  oilTemperatureDamageThreshold = 150,
  exhaustCondensationThresholdEnvTemp = 15,
  exhaustCondensationThresholdBlockTemp = 60
}

--Nodes
local coolantCapNodes = {}
local radiatorNodes = {}
local engineNodes = {}
local exhaustNodes = {}
local invExhaustNodeCount = 0
local exhaustStartNodes = {}
local exhaustBeams = nil
local exhaustTrees = {}

local afterFire = nil

local updateThermalsGFXMethod = nop
local updateExhaustGFXMethod = nop
local updateMechanicsGFXMethod = nop

local function emitBigAfterFireParticles(node1, node2, smokeParticleType)
  obj:addParticleByNodesRelative(node1, node2, -15, 61, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -10, 62, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -20, 63, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -8, 64, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -12, 65, 0, 1)

  obj:addParticleByNodesRelative(node1, node2, -5, smokeParticleType, 0, 1)
  obj:addParticleByNodesRelative(node1, node2, -3, smokeParticleType, 0, 1)
end

local function updateExhaustGFX(dt)
  local absEngineRPM = abs(parentEngine.outputAV1 * conversion.avToRPM)
  local particleAirspeed = electrics.values.airspeed
  local particulateEmission = (particulates * parentEngine.engineLoad) + idleParticulates
  local lightSmokeParticleType = particleAirspeed < 10 and 40 or 41
  local heavySmokeParticleType = particleAirspeed < 10 and 42 or 43
  local condensationParticleType = particleAirspeed < 10 and 46 or 47
  local exhaustGrayParticleType = particleAirspeed < 10 and 44 or 45
  local steamParticleType = particleAirspeed < 10 and 34 or 39
  local oilParticleType = particleAirspeed < 10 and 36 or 38

  --exhaust emission
  afterFire.afterFireSoundTimer = max(afterFire.afterFireSoundTimer - dt, 0)
  afterFire.instantAfterFireFuel = afterFire.instantAfterFireFuel + parentEngine.instantAfterFireFuelDelay:popSum(dt) * dt
  afterFire.sustainedAfterFireFuel = afterFire.sustainedAfterFireFuel + parentEngine.sustainedAfterFireFuelDelay:popSum(dt) * dt
  afterFire.shiftAfterFireFuel = afterFire.shiftAfterFireFuel + parentEngine.shiftAfterFireFuel --no * dt here, design already covers the timeframe

  local maxFuel = max(afterFire.instantAfterFireFuel, max(afterFire.sustainedAfterFireFuel, afterFire.shiftAfterFireFuel))
  local reason = maxFuel == afterFire.shiftAfterFireFuel and 2 or (maxFuel == afterFire.sustainedAfterFireFuel and 1 or 0)

  local tmpAfterFireTime = 0
  local emitSmallParticulates = exhaustSmokeParticleTick > 1 and particulateEmission > 0.05 and particulateEmission < 0.3
  local emitLargeParticulates = exhaustSmokeParticleTick > 1 and particulateEmission >= 0.3
  for _, n in pairs(exhaustNodes) do
    --regular exhaust smoke
    if emitSmallParticulates then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, lightSmokeParticleType, 0, 1)
    end
    if emitLargeParticulates then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, heavySmokeParticleType, 0, 1)
    end

    local exhaustAudioEndFuel = n.afterFireAudioCoef * maxFuel
    local exhaustVisualEndFuel = n.afterFireVisualCoef * maxFuel
    local exhaustNodeInWater = obj:inWater(n.finish)
    if (exhaustVisualEndFuel > 0 or exhaustAudioEndFuel > 0) and not exhaustNodeInWater then
      --print(maxFuel)
      --print(reason)
      if afterFire.afterFireSoundTimer <= 0 then
        if reason == 0 then --Single bang
          --print("bang (audio): "..exhaustAudioEndFuel)
          --print("bang (visual): "..exhaustVisualEndFuel)
          if exhaustAudioEndFuel > afterFire.audibleThresholdInstant then --Single bang
            obj:playSFXOnce(afterFire.instantAudioSample, n.finish, n.afterFireAudioCoef * afterFire.instantVolumeCoef * invExhaustNodeCount, 1.0)
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdInstant then --Single bang
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.0 + random(100) * 0.001)
        elseif reason == 2 then -- transmission ignition cut sounds
          --print("shift (audio): "..exhaustAudioEndFuel)
          --print("shift (visual): "..exhaustVisualEndFuel)
          if exhaustAudioEndFuel > afterFire.audibleThresholdShift then
            obj:playSFXOnce(afterFire.shiftAudioSample, n.finish, n.afterFireAudioCoef * afterFire.shiftVolumeCoef * invExhaustNodeCount, 1)
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdShift then
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.5)
        elseif reason == 1 and parentEngine.instantEngineLoad <= 0 then --popcorn single bang
          --print("popcorn (audio): "..exhaustAudioEndFuel)
          --print("popcorn (visual): "..exhaustVisualEndFuel)
          if exhaustAudioEndFuel > afterFire.audibleThresholdSustained then --popcorn single bang
            obj:playSFXOnce(afterFire.sustainedAudioSample, n.finish, n.afterFireAudioCoef * afterFire.sustainedVolumeCoef * invExhaustNodeCount, 1.0)
          end

          if exhaustVisualEndFuel > afterFire.visualThresholdSustained then --popcorn single bang
            emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
          end

          tmpAfterFireTime = max(tmpAfterFireTime, 0.05 + random(100) * 0.001)
        end
      end
    end

    if parentEngine.continuousAfterFireFuel > 0 and not exhaustNodeInWater then
      emitBigAfterFireParticles(n.finish, n.start, exhaustGrayParticleType)
    end

    --steam from broken head gasket
    if M.headGasketBlown and exhaustSteamParticleTick > 1 and coolantMass > constants.minimumCoolantMass and not (parentEngine.isDisabled or parentEngine.isStalled) and hasCoolantRadiator then
      --also emit steam from all exhaust ends because we are actually vaporizing coolant in the combustion chamber
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 3, steamParticleType, 0, 1)
    end

    if tEnv <= constants.exhaustCondensationThresholdEnvTemp and M.engineBlockTemperature <= constants.exhaustCondensationThresholdBlockTemp and exhaustSteamParticleTick > 1 then
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 1.3, condensationParticleType, 0, 1)
    end

    --blue smoke from broken piston rings
    if M.pistonRingsDamaged and exhaustOilParticleTick > 1 and not (parentEngine.isDisabled or parentEngine.isStalled) then
      --emit blue smoke from all exhaust ends because we are burning oil with damaged piston rings
      obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 2, oilParticleType, 0, 1)
    end
  end

  if afterFire.afterFireSoundTimer <= 0 and tmpAfterFireTime > 0 then
    afterFire.instantAfterFireFuel = 0
    afterFire.sustainedAfterFireFuel = 0
    afterFire.shiftAfterFireFuel = 0
  end
  afterFire.afterFireSoundTimer = tmpAfterFireTime > 0 and tmpAfterFireTime or afterFire.afterFireSoundTimer
end

local function updateThermalsAirGFX(dt)
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --k "spring" values
  local kExhaustToAir = 0.00001
  local kCylinderWallToOil = 200
  local kOilToAir = 60
  local kOilToBlock = 250
  local kCylinderWallToBlock = 5000

  local engineRPM = parentEngine.outputAV1 * conversion.avToRPM
  local absEngineRPM = abs(engineRPM)

  local airSpeedThroughVehicle = obj:getFrontAirflowSpeed()

  local oilRadiatorActive = min((hasOilRadiator and M.oilTemperature > oilThermostatTemperature and not parentEngine.isDisabled) and M.oilTemperature - oilThermostatTemperature or 0, 1)
  --Efficiency of the cooling system drops with decreasing coolant mass and raising temps above damage threshold

  local underWaterBlockCoolingCoef = 1
  --if a node is underwater we want to increase the block to air cooling to simulate water cooling of the block
  for _, v in pairs(engineNodes) do
    underWaterBlockCoolingCoef = underWaterBlockCoolingCoef + (obj:inWater(v) and 1000 or 0)
  end

  --Step 1: Calculate the "forces" with our "spring" k values
  local currentEngineEfficiency = burnEfficiencyCoef[math.floor(parentEngine.engineLoad * 100) * 0.01]
  local burnEnergyPerUpdate = parentEngine.engineWorkPerUpdate * currentEngineEfficiency

  local energyToCylinderWall = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToExhaust = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToOil = parentEngine.frictionLossPerUpdate

  local radiatorAirSpeed = max(airSpeedThroughVehicle * 0.7, fanAirSpeed) --reduce actual airspeed because the rad blocks part of the air
  local radiatorAirSpeedCoef = max(radiatorAirSpeed / (10 + radiatorAirSpeed), 0.01)

  local blockFanAirSpeedCoef = 1 + blockFanMaxAirSpeed * min(max(engineRPM * blockFanRPMCoef, 0), 1)

  local energyOilToBlock = (M.oilTemperature - M.engineBlockTemperature) * kOilToBlock
  local energyCylinderWallToBlock = (M.cylinderWallTemperature - M.engineBlockTemperature) * kCylinderWallToBlock

  local energyCylinderWallToOil = (M.cylinderWallTemperature - M.oilTemperature) * kCylinderWallToOil
  local energyOilSumpToAir = (M.oilTemperature - tEnv) * kOilToAir * radiatorAirSpeedCoef
  local energyOilToAir = (M.oilTemperature - tEnv) * oilRadiatorCoef * radiatorAirSpeedCoef * oilRadiatorActive
  local energyBlockToAir = (M.engineBlockTemperature - tEnv) * blockFanAirSpeedCoef * engineBlockAirCoolingEfficiency * underWaterBlockCoolingCoef
  local exhaustTempDiff = M.exhaustTemperature - tEnv
  local exhaustTempSquared = exhaustTempDiff * exhaustTempDiff
  local energyExhaustToAir = exhaustTempSquared * exhaustTempSquared * kExhaustToAir
  --local energyFireToBlock       = 0

  --Step 2: The integrator
  M.cylinderWallTemperature = max(M.cylinderWallTemperature + (energyToCylinderWall - (energyCylinderWallToOil + energyCylinderWallToBlock) * dt) * energyCoef.cylinderWall, tEnv)
  M.oilTemperature = max(M.oilTemperature + (energyToOil + (energyCylinderWallToOil - energyOilToAir - energyOilSumpToAir - energyOilToBlock) * dt) * energyCoef.oil, tEnv)
  M.engineBlockTemperature = max(M.engineBlockTemperature + (energyCylinderWallToBlock - energyBlockToAir + energyOilToBlock) * energyCoef.engineBlock * dt, tEnv)
  M.exhaustTemperature = max(M.exhaustTemperature + (energyToExhaust - energyExhaustToAir * dt) * energyCoef.exhaust, tEnv)

  local particleAirspeed = electrics.values.airspeed
  local engineRunning = (parentEngine.isDisabled or parentEngine.isStalled or parentEngine.ignitionCoef < 1) and 0 or 1
  exhaustOilParticleTick = exhaustOilParticleTick > 1 and 0 or exhaustOilParticleTick + dt * (0.01 * absEngineRPM + 0.1 * particleAirspeed) * engineRunning
  exhaustSmokeParticleTick = exhaustSmokeParticleTick > 1 and 0 or exhaustSmokeParticleTick + dt * (0.02 + (0.02 * absEngineRPM + 0.02 * particleAirspeed)) * engineRunning

  if M.engineBlockTemperature > damageThreshold.engineBlockTemperature then
    M.engineBlockOverheatDamage = min(M.engineBlockOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.headGasket)
    if M.engineBlockOverheatDamage >= damageThreshold.headGasket and not M.headGasketBlown then
      --if we reach the headgasket damage threshold, we will lose more coolant
      M.headGasketBlown = true
      --without a working headgasket we don't have full compression anymore -> less torque
      parentEngine:scaleOutputTorque(0.8)
      damageTracker.setDamage("engine", "headGasketDamaged", true)

      --implement nice steam "explosion" here
      if #parentEngine.engineBlockNodes >= 2 then
        for i = 1, 10 do
          local rnd = random()
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 39, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 39, 0, 1)
        end
      end
    end

    if M.engineBlockTemperature > engineBlockMeltingTemperature and not M.engineBlockMelted then
      parentEngine:scaleFriction(10000) --essentially kill the engine
      M.engineBlockMelted = true
      damageTracker.setDamage("engine", "blockMelted", true)
    end
  end

  if M.oilTemperature > constants.oilTemperatureDamageThreshold then
    local diff = M.oilTemperature - constants.oilTemperatureDamageThreshold
    --increase engine friction relative to temperature of overheated oil
    local frictionCoef = 1 + diff * dt * 0.005
    parentEngine:scaleFriction(frictionCoef)
    M.oilOverheatDamage = min(M.oilOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.connectingRod)
    if M.oilOverheatDamage >= damageThreshold.connectingRod and not M.connectingRodBearingsDamaged then
      M.connectingRodBearingsDamaged = true
      damageTracker.setDamage("engine", "rodBearingsDamaged", true)
    end

    damageTracker.setDamage("engine", "oilHot", true)
  elseif damageTracker.getDamage("engine", "oilHot", true) then
    damageTracker.setDamage("engine", "oilHot", false)
  end

  if M.cylinderWallTemperature > damageThreshold.cylinderWallTemperature then
    M.cylinderWallOverheatDamage = min(M.cylinderWallOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.pistonRing)
    --if our cylinder wall gets too hot, the piston rings will be damaged eventually
    if M.cylinderWallOverheatDamage >= damageThreshold.pistonRing and not M.pistonRingsDamaged then
      M.pistonRingsDamaged = true
      --Damaged piston rings cause a loss of compression and therefore less torque
      parentEngine:scaleOutputTorque(0.8)
      damageTracker.setDamage("engine", "pistonRingsDamaged", true)
    end

    if M.cylinderWallTemperature > cylinderWallMeltingTemperature and not M.cylinderWallsMelted then
      parentEngine:scaleFriction(10000) --essentially kill the engine
      M.cylinderWallsMelted = true
      damageTracker.setDamage("engine", "cylinderWallsMelted", true)
    end
  end

  if M.connectingRodBearingsDamaged then
    knockSoundTick = knockSoundTick > 1 and 0 or knockSoundTick + dt * absEngineRPM * 0.008333
    if knockSoundTick > 1 then
      --make a knocking sound if the bearings are damaged
      sounds.playSoundOnceAtNode("Knock", engineNodes[1], 0.1)
    end
  end

  if streams.willSend("engineThermalData") then
    gui.send(
      "engineThermalData",
      {
        coolantTemperature = M.coolantTemperature,
        oilTemperature = M.oilTemperature,
        engineBlockTemperature = M.engineBlockTemperature,
        cylinderWallTemperature = M.cylinderWallTemperature,
        exhaustTemperature = M.exhaustTemperature,
        radiatorAirSpeed = radiatorAirSpeed,
        radiatorAirSpeedEfficiency = radiatorAirSpeedCoef,
        fanActive = fanAirSpeed > 0,
        thermostatStatus = 0,
        oilThermostatStatus = oilRadiatorActive,
        coolantLeakRate = 0,
        coolantEfficiency = 0,
        engineEfficiency = 1 / (currentEngineEfficiency + 1),
        energyToCylinderWall = energyToCylinderWall,
        energyToOil = energyToOil,
        energyToExhaust = energyToExhaust,
        energyCoolantToAir = 0,
        energyCylinderWallToCoolant = 0,
        energyCoolantToBlock = 0,
        energyCylinderWallToBlock = energyCylinderWallToBlock * dt,
        energyCylinderWallToOil = energyCylinderWallToOil * dt,
        energyOilToAir = energyOilToAir * dt,
        energyOilToBlock = energyOilToBlock * dt,
        energyOilSumpToAir = energyOilSumpToAir * dt,
        energyBlockToAir = energyBlockToAir * dt,
        energyExhaustToAir = energyExhaustToAir * dt,
        engineBlockOverheatDamage = M.engineBlockOverheatDamage,
        oilOverheatDamage = M.oilOverheatDamage,
        cylinderWallOverheatDamage = M.cylinderWallOverheatDamage,
        headGasketBlown = M.headGasketBlown,
        pistonRingsDamaged = M.pistonRingsDamaged,
        connectingRodBearingsDamaged = M.connectingRodBearingsDamaged,
        engineBlockMelted = M.engineBlockMelted,
        cylinderWallsMelted = M.cylinderWallsMelted,
        thermostatTemperature = thermostatTemperature,
        oilThermostatTemperature = oilThermostatTemperature
      }
    )
  end
end

local function updateThermalsCoolantGFX(dt)
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --k "spring" values
  local kExhaustToAir = 0.00001
  local kCylinderWallToCoolant = 28000
  local kCylinderWallToOil = 200
  local kOilToAir = 60
  local kOilToBlock = 250
  local kCoolantToBlock = 24000
  local kCylinderWallToBlock = 5000

  local engineRPM = parentEngine.outputAV1 * conversion.avToRPM
  local absEngineRPM = abs(engineRPM)

  if hasCoolantRadiator then
    --get radiator damage (if there is any) and calculate coolant leak rate based on that
    M.radiatorDamage = max(beamstate.deformGroupDamage[radiatorDamageDeformGroup] and (beamstate.deformGroupDamage[radiatorDamageDeformGroup].damage - radiatorDeformThreshold) or 0, 0)

    if M.radiatorDamage > 0 and not damageTracker.getDamage("engine", "radiatorLeak") then
      damageTracker.setDamage("engine", "radiatorLeak", true)
    end
    radiatorLeakRate = M.radiatorDamage * 10
  end

  local radiatorFanRPM = 0
  if radiatorFanType == "electric" then
    --eletric fans are either on or off, depending on coolant temperature
    if M.coolantTemperature >= radiatorFanTemperature then
      fanAirSpeed = radiatorFanMaxAirSpeed
    elseif M.coolantTemperature <= thermostatTemperature * 1.05 then
      fanAirSpeed = 0
    end
    radiatorFanRPM = electricalRadiatorFanSmoother:getUncapped(fanAirSpeed > 0 and 2500 or 0, dt)
  elseif radiatorFanType == "mechanical" then
    --mechanical fans are tied to the RPM but at some point they won't go any faster (because they are linked with a clutch)
    radiatorFanRPM = engineRPM * mechanicalFanRPMCoef
    fanAirSpeed = radiatorFanMaxAirSpeed * min(max(engineRPM * mechanicalRadiatorFanRPMCoef, 0), 1)
  end
  M.radiatorFanSpin = (M.radiatorFanSpin + radiatorFanRPM * dt) % 360

  local airSpeedThroughVehicle = obj:getFrontAirflowSpeed()

  --radiator is only actually used above a certain temperature
  local radiatorActive = min((hasCoolantRadiator and M.coolantTemperature > thermostatTemperature and not parentEngine.isDisabled) and M.coolantTemperature - thermostatTemperature or 0, 1)
  local oilRadiatorActive = min((hasOilRadiator and M.oilTemperature > oilThermostatTemperature and not parentEngine.isDisabled) and M.oilTemperature - oilThermostatTemperature or 0, 1)
  --Efficiency of the cooling system drops with decreasing coolant mass and raising temps above damage threshold
  local coolantEfficiency = (coolantMass > constants.minimumCoolantMass or M.coolantTemperature < constants.maxCoolantTemperature) and (coolantMass * invInitialCoolantMass * max(min((constants.maxCoolantTemperature - M.coolantTemperature) * 0.1, 1), 0)) or 0

  local underWaterBlockCoolingCoef = 1
  --if a node is underwater we want to increase the block to air cooling to simulate water cooling of the block
  for _, v in pairs(engineNodes) do
    underWaterBlockCoolingCoef = underWaterBlockCoolingCoef + (obj:inWater(v) and 1000 or 0)
  end

  --Step 1: Calculate the "forces" with our "spring" k values
  local currentEngineEfficiency = burnEfficiencyCoef[math.floor(parentEngine.engineLoad * 100) * 0.01]
  local burnEnergyPerUpdate = parentEngine.engineWorkPerUpdate * currentEngineEfficiency

  local energyToCylinderWall = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToExhaust = 0.5 * burnEnergyPerUpdate + 0.5 * parentEngine.pumpingLossPerUpdate
  local energyToOil = parentEngine.frictionLossPerUpdate

  local radiatorAirSpeed = max(airSpeedThroughVehicle * 0.7, fanAirSpeed) --reduce actual airspeed because the rad blocks part of the air
  local radiatorAirSpeedCoef = max(radiatorAirSpeed / (10 + radiatorAirSpeed), 0.01)

  local blockFanAirSpeedCoef = 1 + blockFanMaxAirSpeed * min(max(engineRPM * blockFanRPMCoef, 0), 1)
  local cylinderWallToCoolantAirCooledCoef = blockFanMaxAirSpeed > 0 and 0 or 1 --kill the energy transfer from wall to coolant on an air cooled engine (no coolant)

  local energyCylinderWallToCoolant = (M.cylinderWallTemperature - M.coolantTemperature) * kCylinderWallToCoolant * coolantEfficiency * cylinderWallToCoolantAirCooledCoef
  local energyCoolantToAir = (M.coolantTemperature - tEnv) * radiatorCoef * radiatorActive * radiatorAirSpeedCoef * coolantEfficiency
  local energyCoolantToBlock = (M.coolantTemperature - M.engineBlockTemperature) * kCoolantToBlock * coolantEfficiency * cylinderWallToCoolantAirCooledCoef
  local energyOilToBlock = (M.oilTemperature - M.engineBlockTemperature) * kOilToBlock
  local energyCylinderWallToBlock = (M.cylinderWallTemperature - M.engineBlockTemperature) * kCylinderWallToBlock

  local energyCylinderWallToOil = (M.cylinderWallTemperature - M.oilTemperature) * kCylinderWallToOil
  local energyOilSumpToAir = (M.oilTemperature - tEnv) * kOilToAir * radiatorAirSpeedCoef
  local energyOilToAir = (M.oilTemperature - tEnv) * oilRadiatorCoef * radiatorAirSpeedCoef * oilRadiatorActive
  local energyBlockToAir = (M.engineBlockTemperature - tEnv) * blockFanAirSpeedCoef * engineBlockAirCoolingEfficiency * underWaterBlockCoolingCoef
  local exhaustTempDiff = M.exhaustTemperature - tEnv
  local exhaustTempSquared = exhaustTempDiff * exhaustTempDiff
  local energyExhaustToAir = exhaustTempSquared * exhaustTempSquared * kExhaustToAir
  --local energyFireToBlock         = 0

  --We can lose coolant in different places, sum up all the rates and calculate the new mass
  local overallLeakRate = coolantOverpressureLeakRate + coolantHeadGasketLeakRate + radiatorLeakRate

  --Step 2: The integrator
  M.cylinderWallTemperature = max(M.cylinderWallTemperature + (energyToCylinderWall - (energyCylinderWallToOil + energyCylinderWallToCoolant + energyCylinderWallToBlock) * dt) * energyCoef.cylinderWall, tEnv)
  M.coolantTemperature = min(max(M.coolantTemperature + (energyCylinderWallToCoolant - energyCoolantToAir - energyCoolantToBlock) * energyCoef.coolant * dt, tEnv), constants.maxCoolantTemperature)
  M.oilTemperature = max(M.oilTemperature + (energyToOil + (energyCylinderWallToOil - energyOilToAir - energyOilSumpToAir - energyOilToBlock) * dt) * energyCoef.oil, tEnv)
  M.engineBlockTemperature = max(M.engineBlockTemperature + (energyCoolantToBlock + energyCylinderWallToBlock - energyBlockToAir + energyOilToBlock) * energyCoef.engineBlock * dt, tEnv)
  M.exhaustTemperature = max(M.exhaustTemperature + (energyToExhaust - energyExhaustToAir * dt) * energyCoef.exhaust, tEnv)
  coolantMass = max(coolantMass - overallLeakRate * dt, constants.minimumCoolantMass)

  local particleAirspeed = electrics.values.airspeed
  local engineRunning = (parentEngine.isDisabled or parentEngine.isStalled or parentEngine.ignitionCoef < 1) and 0 or 1
  engineSteamParticleTick = engineSteamParticleTick > 1 and 0 or engineSteamParticleTick + dt * 4
  radiatorSteamParticleTick = radiatorSteamParticleTick > 1 and 0 or radiatorSteamParticleTick + dt * (200 * M.radiatorDamage + 2 * particleAirspeed)
  exhaustSteamParticleTick = exhaustSteamParticleTick > 1 and 0 or exhaustSteamParticleTick + dt * (0.01 * absEngineRPM + 0.2 * particleAirspeed) * engineRunning
  exhaustOilParticleTick = exhaustOilParticleTick > 1 and 0 or exhaustOilParticleTick + dt * (0.01 * absEngineRPM + 0.1 * particleAirspeed) * engineRunning
  exhaustSmokeParticleTick = exhaustSmokeParticleTick > 1 and 0 or exhaustSmokeParticleTick + dt * (0.02 + (0.02 * absEngineRPM + 0.02 * particleAirspeed)) * engineRunning

  --airspeed depending particle type selection
  local coolantHeavyParticleType = particleAirspeed < 10 and 35 or 37
  local coolantLightParticleType = particleAirspeed < 10 and 48 or 49
  local rand = random(1) --some random value for particle emission

  if M.coolantTemperature > constants.coolantTemperatureDamageThreshold then
    --our coolant is too hot, so our radiator cap is releasing pressure/steam and therefore coolant mass
    coolantOverpressureLeakRate = 0.01 --10g/s

    if engineSteamParticleTick > 1 then
      --emit steam as long as there is still coolant left
      obj:addParticleByNodesRelative(coolantCapNodes[1], coolantCapNodes[2], 1 - rand, coolantHeavyParticleType, 0, 1)
    end

    damageTracker.setDamage("engine", "coolantHot", true)
  elseif damageTracker.getDamage("engine", "coolantHot") then
    --if the coolant cools down again, we don't leak anymore because of overpressure
    coolantOverpressureLeakRate = 0
    damageTracker.setDamage("engine", "coolantHot", false)
  end

  if M.engineBlockTemperature > damageThreshold.engineBlockTemperature then
    M.engineBlockOverheatDamage = min(M.engineBlockOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.headGasket)
    if M.engineBlockOverheatDamage >= damageThreshold.headGasket and not M.headGasketBlown then
      --if we reach the headgasket damage threshold, we will lose more coolant
      M.headGasketBlown = true
      --without a working headgasket we don't have full compression anymore -> less torque
      parentEngine:scaleOutputTorque(0.8)
      coolantHeadGasketLeakRate = 0.1 --100g/s
      --let's get rid of a bit of coolant immediately
      coolantMass = coolantMass * 0.9
      damageTracker.setDamage("engine", "headGasketDamaged", true)

      --implement nice steam "explosion" here
      if #parentEngine.engineBlockNodes >= 2 then
        for i = 1, 10 do
          local rnd = random()
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], i * rnd, 39, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 43, 0, 1)
          obj:addParticleByNodesRelative(parentEngine.engineBlockNodes[2], parentEngine.engineBlockNodes[1], -i * rnd, 39, 0, 1)
        end
      end
    end

    if M.engineBlockTemperature > engineBlockMeltingTemperature and not M.engineBlockMelted then
      parentEngine:scaleFriction(10000) --essentially kill the engine
      M.engineBlockMelted = true
      damageTracker.setDamage("engine", "blockMelted", true)
    end
  end

  if M.oilTemperature > constants.oilTemperatureDamageThreshold then
    local diff = M.oilTemperature - constants.oilTemperatureDamageThreshold
    --increase engine friction relative to temperature of overheated oil
    local frictionCoef = 1 + diff * dt * 0.005
    parentEngine:scaleFriction(frictionCoef)
    M.oilOverheatDamage = min(M.oilOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.connectingRod)
    if M.oilOverheatDamage >= damageThreshold.connectingRod and not M.connectingRodBearingsDamaged then
      M.connectingRodBearingsDamaged = true
      damageTracker.setDamage("engine", "rodBearingsDamaged", true)
    end

    damageTracker.setDamage("engine", "oilHot", true)
  elseif damageTracker.getDamage("engine", "oilHot", true) then
    damageTracker.setDamage("engine", "oilHot", false)
  end

  if M.cylinderWallTemperature > damageThreshold.cylinderWallTemperature then
    M.cylinderWallOverheatDamage = min(M.cylinderWallOverheatDamage + parentEngine.engineWorkPerUpdate, damageThreshold.pistonRing)
    --if our cylinder wall gets too hot, the piston rings will be damaged eventually
    if M.cylinderWallOverheatDamage >= damageThreshold.pistonRing and not M.pistonRingsDamaged then
      M.pistonRingsDamaged = true
      --Damaged piston rings cause a loss of compression and therefore less torque
      parentEngine:scaleOutputTorque(0.8)
      damageTracker.setDamage("engine", "pistonRingsDamaged", true)
    end

    if M.cylinderWallTemperature > cylinderWallMeltingTemperature and not M.cylinderWallsMelted then
      parentEngine:scaleFriction(10000) --essentially kill the engine
      M.cylinderWallsMelted = true
      damageTracker.setDamage("engine", "cylinderWallsMelted", true)
    end
  end

  if M.radiatorDamage > 0 and radiatorSteamParticleTick > 1 and M.coolantTemperature >= 70 and hasCoolantRadiator then
    --emit steam from the radiator if it's damaged and we have coolant left
    if #radiatorNodes >= 2 then
      local coolantLeakParticle = M.coolantTemperature > 95 and coolantHeavyParticleType or coolantLightParticleType
      obj:addParticleByNodesRelative(radiatorNodes[1], radiatorNodes[2], rand, coolantLeakParticle, 0, 1)
    end
  end

  if M.headGasketBlown then
    --emit steam from the engine since we can't keep the coolant under control anymore
    if engineSteamParticleTick > 1 and hasCoolantRadiator then
      obj:addParticleByNodesRelative(engineNodes[2], engineNodes[1], rand * 3, coolantHeavyParticleType, 0, 1)
    end
  end

  if M.connectingRodBearingsDamaged then
    knockSoundTick = knockSoundTick > 1 and 0 or knockSoundTick + dt * absEngineRPM * 0.008333
    if knockSoundTick > 1 then
      --make a knocking sound if the bearings are damaged
      sounds.playSoundOnceAtNode("Knock", engineNodes[1], 0.1)
    end
  end

  if streams.willSend("engineThermalData") then
    gui.send(
      "engineThermalData",
      {
        coolantTemperature = M.coolantTemperature,
        oilTemperature = M.oilTemperature,
        engineBlockTemperature = M.engineBlockTemperature,
        cylinderWallTemperature = M.cylinderWallTemperature,
        exhaustTemperature = M.exhaustTemperature,
        radiatorAirSpeed = radiatorAirSpeed,
        radiatorAirSpeedEfficiency = radiatorAirSpeedCoef,
        fanActive = fanAirSpeed > 0,
        thermostatStatus = radiatorActive,
        oilThermostatStatus = oilRadiatorActive,
        coolantLeakRate = overallLeakRate,
        coolantEfficiency = coolantEfficiency,
        engineEfficiency = 1 / (currentEngineEfficiency + 1),
        energyToCylinderWall = energyToCylinderWall,
        energyToOil = energyToOil,
        energyToExhaust = energyToExhaust,
        energyCoolantToAir = energyCoolantToAir * dt,
        energyCylinderWallToCoolant = energyCylinderWallToCoolant * dt,
        energyCoolantToBlock = energyCoolantToBlock * dt,
        energyCylinderWallToBlock = energyCylinderWallToBlock * dt,
        energyCylinderWallToOil = energyCylinderWallToOil * dt,
        energyOilToAir = energyOilToAir * dt,
        energyOilToBlock = energyOilToBlock * dt,
        energyOilSumpToAir = energyOilSumpToAir * dt,
        energyBlockToAir = energyBlockToAir * dt,
        energyExhaustToAir = energyExhaustToAir * dt,
        engineBlockOverheatDamage = M.engineBlockOverheatDamage,
        oilOverheatDamage = M.oilOverheatDamage,
        cylinderWallOverheatDamage = M.cylinderWallOverheatDamage,
        headGasketBlown = M.headGasketBlown,
        pistonRingsDamaged = M.pistonRingsDamaged,
        connectingRodBearingsDamaged = M.connectingRodBearingsDamaged,
        engineBlockMelted = M.engineBlockMelted,
        cylinderWallsMelted = M.cylinderWallsMelted,
        thermostatTemperature = thermostatTemperature,
        oilThermostatTemperature = oilThermostatTemperature
      }
    )
  end
end

local function updateMechanicsGFX(dt)
  --check if our oil is still in the oil sump or if it's forced towards the top of the sump
  local oilStarvingSeverness = min(max(hasOilStarvingDamage and sensors.gz2 or 0, -9.81), 9.81) * 0.1019368
  oilStarvingTimer = min(max(oilStarvingTimer + oilStarvingSeverness * dt, 0), oilStarvingTimerThreshold)

  if oilStarvingTimer >= oilStarvingTimerThreshold and not (parentEngine.isDisabled or parentEngine.isStalled) then
    local absEngineRPM = abs(parentEngine.outputAV1 * conversion.avToRPM)
    oilStarvingDamage = oilStarvingDamage + 0.00000001 * dt * absEngineRPM
    parentEngine:scaleFriction(1 + oilStarvingDamage)

    local oilParticleType = electrics.values.airspeed < 10 and 36 or 38

    for _, n in pairs(exhaustNodes) do
      if exhaustOilParticleTick > 1 and not parentEngine.isDisabled then
        --emit blue smoke from all exhaust ends because we are burning oil with damaged piston rings
        obj:addParticleByNodesRelative(n.finish, n.start, absEngineRPM * -0.0004 - 2, oilParticleType, 0, 1)
      end
    end

    if not damageTracker.getDamage("engine", "oilStarvation") then
      gui.message("vehicle.engine.starvedOfOil", 10, "vehicle.damage.oilstarvation")
      damageTracker.setDamage("engine", "oilStarvation", true)
    end
  elseif damageTracker.getDamage("engine", "oilStarvation") then
    damageTracker.setDamage("engine", "oilStarvation", false)
  end
end

local function getExhaustEndNodes(startNode, exhaustTree)
  local branch = exhaustTree.children[startNode]
  local endNodes = {}

  for k, child in pairs(branch.children) do
    --if at this point something broke away or we reached the original end of the branch
    if (child.childrenCount ~= child.initialChildrenCount or child.initialChildrenCount == 0) and not child.isStartNode then
      --save the nodes as exit nodes
      table.insert(
        endNodes,
        {
          start = child.previous,
          finish = child.cid,
          afterFireAudioCoef = child.afterFireAudioCoef,
          afterFireVisualCoef = child.afterFireVisualCoef
        }
      )
    end
    --if we have children left and we are not broken
    if child.childrenCount > 0 and not child.isBroken then
      --continue to search for more exit nodes in this branch
      arrayConcat(endNodes, getExhaustEndNodes(k, branch))
    end
  end

  return endNodes
end

local function parseExhaustTree(currentBranch, exhaustBeams, startNodeLookup)
  --copy table to not mess with the original one
  local beams = shallowcopy(exhaustBeams)
  local currentBeamKey, currentBeam = next(beams, nil)
  currentBranch.childrenCount = 0
  currentBranch.children = {}

  if not currentBranch.previous then
    local nodeData = v.data.nodes[currentBranch.cid]
    currentBranch.afterFireAudioCoef = (nodeData.afterFireAudioCoef or 1)
    currentBranch.afterFireVisualCoef = (nodeData.afterFireVisualCoef or 1)
  end

  while currentBeam ~= nil do
    --if your node connects to the current beam (via node1 or node2)
    if currentBranch.cid == currentBeam.id1 then
      beams[currentBeamKey] = nil --beam is handled, ignore further down the line
      --build child branch based on current beam
      local nodeData = v.data.nodes[currentBeam.id2]
      local node = {
        cid = currentBeam.id2,
        previous = currentBranch.cid,
        beam = currentBeam.cid,
        level = currentBranch.level + 1,
        afterFireAudioCoef = currentBranch.afterFireAudioCoef * (nodeData.afterFireAudioCoef or 1),
        afterFireVisualCoef = currentBranch.afterFireVisualCoef * (nodeData.afterFireVisualCoef or 1)
      }
      currentBranch.children[currentBeam.id2] = parseExhaustTree(node, beams, startNodeLookup)
      currentBranch.childrenCount = currentBranch.childrenCount + 1
    elseif currentBranch.cid == currentBeam.id2 then
      --same as above but with switched id1 <-> id2
      beams[currentBeamKey] = nil
      local nodeData = v.data.nodes[currentBeam.id1]
      local node = {
        cid = currentBeam.id1,
        previous = currentBranch.cid,
        beam = currentBeam.cid,
        level = currentBranch.level + 1,
        afterFireAudioCoef = currentBranch.afterFireAudioCoef * (nodeData.afterFireAudioCoef or 1),
        afterFireVisualCoef = currentBranch.afterFireVisualCoef * (nodeData.afterFireVisualCoef or 1)
      }
      currentBranch.children[currentBeam.id1] = parseExhaustTree(node, beams, startNodeLookup)
      currentBranch.childrenCount = currentBranch.childrenCount + 1
    end

    currentBeamKey, currentBeam = next(beams, currentBeamKey)
  end

  currentBranch.initialChildrenCount = currentBranch.childrenCount
  currentBranch.isStartNode = startNodeLookup[currentBranch.cid] and true or false
  return currentBranch
end

local function buildExhaustTree()
  exhaustStartNodes = {}
  exhaustBeams = {}
  local exhaustBeamCache = {}
  local startNodeLookup = {}

  --search for the exhaust start node
  for _, n in pairs(v.data.nodes) do
    if n.isExhaust and (type(n.isExhaust) == "boolean" or n.isExhaust == parentEngine.name) then
      table.insert(exhaustStartNodes, n)
      startNodeLookup[n.cid] = true
    end
  end

  if #exhaustStartNodes <= 0 then
    log("E", "engine.buildExhaustTree", "No exhaust start node(s) specified")
    return false
  end

  --find all exhaust beams
  for _, b in pairs(v.data.beams) do
    if b.isExhaust and (type(b.isExhaust) == "boolean" or b.isExhaust == parentEngine.name) then
      --one table for immediate use
      table.insert(exhaustBeamCache, b)
      --one table for look ups when a beam breaks
      exhaustBeams[b.cid] = true
    end
  end

  exhaustTrees = {}
  for _, n in ipairs(exhaustStartNodes) do
    --build exhaust tree recursively
    local exhaustTree = {children = {}, startCid = n.cid}
    exhaustTree.children[n.cid] = parseExhaustTree({cid = n.cid, level = 0}, exhaustBeamCache, startNodeLookup)
    table.insert(exhaustTrees, exhaustTree)
  end

  local tmpExhaustNodes = {}
  for _, t in ipairs(exhaustTrees) do
    --find initial exhaust end points
    local treeEndNodes = getExhaustEndNodes(t.startCid, t)
    tmpExhaustNodes = arrayConcat(tmpExhaustNodes, treeEndNodes)
  end
  --dump(tmpExhaustNodes)

  exhaustNodes = {}
  local exhaustNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustNodes) do
    if not exhaustNodeDeDuplicate[v.finish] then
      table.insert(exhaustNodes, v)
      exhaustNodeDeDuplicate[v.finish] = true
    end
  end
  invExhaustNodeCount = #exhaustNodes > 0 and 1 / sqrt(#exhaustNodes) or 0
  --print(invExhaustNodeCount)
  --dump(exhaustNodes)
  M.exhaustEndNodes = exhaustNodes

  if #exhaustNodes <= 0 then
    log("E", "engine.buildExhaustTree", "No exhaust end nodes found")
    return false
  end

  --dump(exhaustTrees)
  --print(afterFire.exhaustMaxLevel)

  return true
end

local function exhaustBeamBroken(id, exhaustTree)
  for _, v in pairs(exhaustTree.children) do
    --if the broken beam matches one of our tree beams
    if v and v.beam == id then
      --break off this branch
      v.isBroken = true
      exhaustTree.childrenCount = exhaustTree.childrenCount - 1
    elseif v and v.children then
      exhaustBeamBroken(id, v)
    end
  end
end

local function beamBroke(id)
  if exhaustBeams and exhaustBeams[id] then
    exhaustBeams[id] = false
    local tmpExhaustNodes = {}
    for _, t in ipairs(exhaustTrees) do
      --break off a tree branch
      exhaustBeamBroken(id, t)
      --and find the new exit nodes
      local treeEndNodes = getExhaustEndNodes(t.startCid, t)
      tmpExhaustNodes = arrayConcat(tmpExhaustNodes, treeEndNodes)
    end
    --dump(tmpExhaustNodes)

    exhaustNodes = {}
    local exhaustNodeDeDuplicate = {}
    for _, v in ipairs(tmpExhaustNodes) do
      if not exhaustNodeDeDuplicate[v.finish] then
        table.insert(exhaustNodes, v)
        exhaustNodeDeDuplicate[v.finish] = true
      end
    end
    invExhaustNodeCount = #exhaustNodes > 0 and 1 / sqrt(#exhaustNodes) or 0
  --dump(exhaustNodes)
  end
end

local function resetExhaustTree(exhaustTree)
  for _, v in pairs(exhaustTree.children) do
    --if one of the children are already broken
    if v then
      if v.isBroken then
        --repair this branch
        v.isBroken = false
        exhaustTree.childrenCount = exhaustTree.childrenCount + 1
      end
      if v.children then
        resetExhaustTree(v)
      end
    end
  end
end

local function reset()
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  --default temperatures, can be adjusted to fit whatever our goal is (starting up with cold vs warm car)
  local startingTemperature = startPreHeated and constants.preHeatTemperature or tEnv
  M.engineBlockTemperature = startingTemperature
  M.cylinderWallTemperature = startingTemperature
  M.oilTemperature = startingTemperature
  M.coolantTemperature = startingTemperature
  M.exhaustTemperature = startingTemperature

  if not thermalsEnabled then
    --disable the whole thing unless stated otherwise
    --log("D", "engine.initThermals", "Engine thermals are disabled since they are missing in JBeam")
    return
  end

  fanAirSpeed = 0
  M.engineBlockOverheatDamage = 0
  M.oilOverheatDamage = 0
  M.cylinderWallOverheatDamage = 0
  M.headGasketBlown = jbeamData.headGasketBlownOverride or false
  M.pistonRingsDamaged = jbeamData.pistonRingsDamagedOverride or false
  M.connectingRodBearingsDamaged = jbeamData.connectingRodBearingsDamagedOverride or false
  M.radiatorDamage = 0
  M.cylinderWallsMelted = false
  M.engineBlockMelted = false
  M.radiatorFanSpin = 0
  coolantOverpressureLeakRate = 0
  coolantHeadGasketLeakRate = 0
  radiatorLeakRate = 0
  oilStarvingTimer = 0
  oilStarvingDamage = 0
  engineSteamParticleTick = 0
  exhaustSteamParticleTick = 0
  exhaustOilParticleTick = 0
  exhaustSmokeParticleTick = 0
  knockSoundTick = 0

  afterFire.afterFireSoundTimer = 0
  afterFire.instantAfterFireFuel = 0
  afterFire.sustainedAfterFireFuel = 0
  afterFire.shiftAfterFireFuel = 0

  --default to some little coolant mass to prevent any divide by 0 issues
  coolantMass = max(jbeamData.coolantVolume or 0, constants.minimumCoolantMass)

  electricalRadiatorFanSmoother:reset()

  for k, _ in pairs(exhaustBeams) do
    exhaustBeams[k] = true
  end

  local tmpExhaustNodes = {}
  for _, t in ipairs(exhaustTrees) do
    --break off a tree branch
    resetExhaustTree(t)
    --and find the new exit nodes
    local treeEndNodes = getExhaustEndNodes(t.startCid, t)
    tmpExhaustNodes = arrayConcat(tmpExhaustNodes, treeEndNodes)
  end

  exhaustNodes = {}
  local exhaustNodeDeDuplicate = {}
  for _, v in ipairs(tmpExhaustNodes) do
    if not exhaustNodeDeDuplicate[v.finish] then
      table.insert(exhaustNodes, v)
      exhaustNodeDeDuplicate[v.finish] = true
    end
  end
  --dump(tmpExhaustNodes)
  M.exhaustEndNodes = exhaustNodes
  invExhaustNodeCount = #exhaustNodes > 0 and 1 / sqrt(#exhaustNodes) or 0

  if hasCoolantRadiator then
    damageTracker.setDamage("engine", "radiatorLeak", false)
  end
  damageTracker.setDamage("engine", "coolantHot", false)
  damageTracker.setDamage("engine", "oilHot", false)
  damageTracker.setDamage("engine", "headGasketDamaged", M.headGasketBlown)
  damageTracker.setDamage("engine", "rodBearingsDamaged", M.connectingRodBearingsDamaged)
  damageTracker.setDamage("engine", "pistonRingsDamaged", M.pistonRingsDamaged)
  damageTracker.setDamage("engine", "cylinderWallsMelted", false)
  damageTracker.setDamage("engine", "blockMelted", false)
  damageTracker.setDamage("engine", "oilStarvation", false)
end

local function initThermals()
  thermalsEnabled = false
  tEnv = obj:getEnvTemperature() + conversion.kelvinToCelsius
  startPreHeated = settings.getValue("startThermalsPreHeated")
  --default temperatures, can be adjusted to fit whatever our goal is (starting up with cold vs warm car)
  local startingTemperature = startPreHeated and constants.preHeatTemperature or tEnv
  M.engineBlockTemperature = startingTemperature
  M.cylinderWallTemperature = startingTemperature
  M.oilTemperature = startingTemperature
  M.coolantTemperature = startingTemperature
  M.exhaustTemperature = startingTemperature
  if not jbeamData.thermalsEnabled then
    --disable the whole thing unless stated otherwise
    --log("D", "engine.initThermals", "Engine thermals are disabled since they are missing in JBeam")
    return
  end

  fanAirSpeed = 0
  M.engineBlockOverheatDamage = 0
  M.oilOverheatDamage = 0
  M.cylinderWallOverheatDamage = 0
  M.headGasketBlown = jbeamData.headGasketBlownOverride or false
  M.pistonRingsDamaged = jbeamData.pistonRingsDamagedOverride or false
  M.connectingRodBearingsDamaged = jbeamData.connectingRodBearingsDamagedOverride or false
  M.radiatorDamage = 0
  M.cylinderWallsMelted = false
  M.engineBlockMelted = false
  M.radiatorFanSpin = 0
  coolantOverpressureLeakRate = 0
  coolantHeadGasketLeakRate = 0
  radiatorLeakRate = 0
  oilStarvingTimer = 0
  oilStarvingDamage = 0
  engineSteamParticleTick = 0
  exhaustSteamParticleTick = 0
  exhaustOilParticleTick = 0
  exhaustSmokeParticleTick = 0
  knockSoundTick = 0

  particulates = jbeamData.particulates or 0
  idleParticulates = jbeamData.idleParticulates or 0

  afterFire = {
    afterFireSoundTimer = 0,
    instantAfterFireFuel = 0,
    sustainedAfterFireFuel = 0,
    shiftAfterFireFuel = 0,
    instantAudioSample = jbeamData.instantAfterFireSound or "event:>Vehicle>Afterfire>01_Single_EQ1",
    sustainedAudioSample = jbeamData.sustainedAfterFireSound or "event:>Vehicle>Afterfire>01_Single_EQ1",
    shiftAudioSample = jbeamData.shiftAfterFireSound or "event:>Vehicle>Afterfire>01_Multi_EQ1",
    instantVolumeCoef = jbeamData.instantAfterFireVolumeCoef or 1,
    sustainedVolumeCoef = jbeamData.sustainedAfterFireVolumeCoef or 1,
    shiftVolumeCoef = jbeamData.shiftAfterFireVolumeCoef or 4,
    audibleThresholdInstant = jbeamData.afterFireAudibleThresholdInstant or 500000,
    audibleThresholdSustained = jbeamData.afterFireAudibleThresholdSustained or 40000,
    audibleThresholdShift = jbeamData.afterFireAudibleThresholdShift or 250000,
    visualThresholdInstant = jbeamData.afterFireVisualThresholdInstant or 500000,
    visualThresholdSustained = jbeamData.afterFireVisualThresholdSustained or 150000,
    visualThresholdShift = jbeamData.afterFireVisualThresholdShift or 1000000
  }

  --default to some little coolant mass to prevent any divide by 0 issues
  coolantMass = max(jbeamData.coolantVolume or 0, constants.minimumCoolantMass)
  invInitialCoolantMass = 1 / coolantMass
  local oilMass = (jbeamData.oilVolume or 5) * 0.86
  burnEfficiencyCoef = {}
  for k, v in pairs(parentEngine.invBurnEfficiencyTable) do
    burnEfficiencyCoef[k] = v - 1
  end
  mechanicalRadiatorFanRPMCoef = 1 / (parentEngine.maxRPM * 0.7)

  local engineBlockMaterial = jbeamData.engineBlockMaterial or "iron"
  local engineBlockSpecHeat
  local cylinderWallSpecHeat
  if engineBlockMaterial == "iron" then
    engineBlockSpecHeat = 450
    cylinderWallSpecHeat = 450
    engineBlockMeltingTemperature = 1100
    cylinderWallMeltingTemperature = 1200
  elseif engineBlockMaterial == "aluminium" or engineBlockMaterial == "aluminum" then
    engineBlockSpecHeat = 910
    cylinderWallSpecHeat = 910
    engineBlockMeltingTemperature = 660
    cylinderWallMeltingTemperature = 700
  else
    log("E", "engine.initThermals", "Unknown engine block material specified: " .. engineBlockMaterial)
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  engineBlockAirCoolingEfficiency = jbeamData.engineBlockAirCoolingEfficiency or 3
  blockFanMaxAirSpeed = jbeamData.blockFanMaxAirSpeed or 0
  blockFanRPMCoef = 1 / parentEngine.maxRPM
  radiatorFanType = jbeamData.radiatorFanType
  local radiatorArea = jbeamData.radiatorArea or 0
  local isAirCooledOnly = jbeamData.isAirCooledOnly or false
  radiatorFanMaxAirSpeed = jbeamData.radiatorFanMaxAirSpeed or 0
  mechanicalFanRPMCoef = jbeamData.mechanicalFanRPMCoef or 0.5
  local radiatorEffectiveness = jbeamData.radiatorEffectiveness or 0
  radiatorFanTemperature = jbeamData.radiatorFanTemperature or 110
  thermostatTemperature = jbeamData.thermostatTemperature or 90
  oilThermostatTemperature = jbeamData.oilThermostatTemperature or 110
  local oilRadiatorArea = jbeamData.oilRadiatorArea or 0
  local oilRadiatorEffectiveness = jbeamData.oilRadiatorEffectiveness or 0
  damageThreshold.cylinderWallTemperature = jbeamData.cylinderWallTemperatureDamageThreshold or 160
  damageThreshold.headGasket = jbeamData.headGasketDamageThreshold or 2000000
  damageThreshold.pistonRing = jbeamData.pistonRingDamageThreshold or 2000000
  damageThreshold.connectingRod = jbeamData.connectingRodDamageThreshold or 2000000
  damageThreshold.engineBlockTemperature = jbeamData.engineBlockTemperatureDamageThreshold or 140
  radiatorDeformThreshold = jbeamData.radiatorDeformThreshold or 0.015
  hasCoolantRadiator = radiatorArea > 0 and radiatorEffectiveness > 0
  hasOilRadiator = oilRadiatorArea > 0 and oilRadiatorEffectiveness > 0
  hasOilStarvingDamage = (jbeamData.hasOilStarvingDamage == nil or jbeamData.hasOilStarvingDamage)

  if radiatorFanType and radiatorFanType ~= "electric" and radiatorFanType ~= "mechanical" then
    log("E", "engine.initThermals", "Unknown radiator fan type specified: " .. radiatorFanType)
  end
  electricalRadiatorFanSmoother = newTemporalSmoothing(500, 1000)

  local engineBlockMass = 0

  if not jbeamData.engineBlock or not jbeamData.engineBlock._engineGroup_nodes then -- little hack to make it not fail while the jbeam parsing is broken
    log("E", "engine.initThermals", "No engineBlock node group specified")
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end
  for _, n in pairs(jbeamData.engineBlock._engineGroup_nodes) do
    engineBlockMass = engineBlockMass + v.data.nodes[n].nodeWeight
  end

  local cylinderWallMass = math.max(engineBlockMass / 100, 4)
  local exhaustMass = math.max(engineBlockMass / 10, 5)

  energyCoef.coolant = 1 / (coolantMass * constants.coolantSpecHeat)
  energyCoef.oil = 1 / (oilMass * constants.oilSpecHeat)
  energyCoef.cylinderWall = 1 / (cylinderWallMass * cylinderWallSpecHeat)
  energyCoef.engineBlock = 1 / (engineBlockMass * engineBlockSpecHeat)
  energyCoef.exhaust = 1 / (constants.exhaustSpecHeat * exhaustMass)
  radiatorCoef = radiatorEffectiveness * radiatorArea
  oilRadiatorCoef = oilRadiatorEffectiveness * oilRadiatorArea

  coolantCapNodes = {}
  radiatorNodes = {}
  engineNodes = {}

  if hasCoolantRadiator then
    if not jbeamData.radiator then
      log("E", "engine.initThermals", "No radiator node group specified")
      log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
      return
    else
      arrayConcat(radiatorNodes, jbeamData.radiator._engineGroup_nodes or {})
    end
  end

  arrayConcat(coolantCapNodes, jbeamData.engineBlock._engineGroup_nodes or {})
  arrayConcat(engineNodes, jbeamData.engineBlock._engineGroup_nodes or {})

  if #coolantCapNodes < 2 then
    log("D", "engine.initThermals", "Wrong number of coolant cap nodes found. Should be at least 2, is: " .. #coolantCapNodes)
  end

  if #engineNodes < 2 then
    log("E", "engine.initThermals", "Wrong number of engine nodes found. Should be at least 2, is: " .. #engineNodes)
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  if hasCoolantRadiator and #radiatorNodes < 2 then
    log("D", "engine.initThermals", "Wrong number of radiator nodes found. Should be at least 2, is: " .. #radiatorNodes)
  end

  if not buildExhaustTree() then
    log("E", "engine.initThermals", "Building the exhaust tree failed, please look above for the actual reason")
    log("E", "engine.initThermals", "Engine thermals are disabled due to above error")
    return
  end

  if hasCoolantRadiator then
    damageTracker.setDamage("engine", "radiatorLeak", false)
  end
  damageTracker.setDamage("engine", "coolantHot", false)
  damageTracker.setDamage("engine", "oilHot", false)
  damageTracker.setDamage("engine", "headGasketDamaged", M.headGasketBlown)
  damageTracker.setDamage("engine", "rodBearingsDamaged", M.connectingRodBearingsDamaged)
  damageTracker.setDamage("engine", "pistonRingsDamaged", M.pistonRingsDamaged)
  damageTracker.setDamage("engine", "cylinderWallsMelted", false)
  damageTracker.setDamage("engine", "blockMelted", false)
  damageTracker.setDamage("engine", "oilStarvation", false)

  if isAirCooledOnly then
    updateThermalsGFXMethod = updateThermalsAirGFX
  else
    updateThermalsGFXMethod = updateThermalsCoolantGFX
  end
  updateExhaustGFXMethod = updateExhaustGFX
  updateMechanicsGFXMethod = updateMechanicsGFX

  thermalsEnabled = true
end

local function updateGFX(dt)
  updateThermalsGFXMethod(dt)
  updateExhaustGFXMethod(dt)
  updateMechanicsGFXMethod(dt)
end

local function init(engine, engineJbeamData)
  parentEngine = engine
  jbeamData = engineJbeamData
  initThermals()
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX
M.beamBroke = beamBroke

return M
