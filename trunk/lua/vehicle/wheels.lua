local M = {}

M.wheelRotators = {}
M.wheelRotatorCount = 0

M.wheels = {}
M.wheelIDs = {}
M.wheelCount = 0

M.rotators = {}
M.rotatorIDs = {}
M.rotatorCount = 0

M.wheelPower = 0
M.wheelTorque = 0

local settings = require("simplesettings")

local max = math.max
local min = math.min
local abs = math.abs

local kelvinToCelsius = -273.15
local celsiusToKelvin = 273.15
local twoPi = math.pi * 2
local brakeCoreWaterToSteamThresholdTemperature = 70

local initialWheelCountDec = -1
local initialRotatorCountDec = -1
local initialWheelRotatorCountDec = -1
local invWheelCount = 0
local speedoWheelCount = 0
local initialSpeedoWheelCount = 0
local invSpeedoWheelCount = 0
local wheelRotatorTorques = {}
local wheelAVs = {}

local minBrakeMass = 1
local brakeSmokeEfficiencyThreshold = 0.75
local wheelInfo = {}
local axleBeamLookup = {}

local startPosition = nil
local state = "idle"
local targetSpeed = 100 / 3.6

local absBehavior = nil
local maxBrakeTorque = 0
local maxDoubleBrakeTorque = 0
local brakeTorqueLimits = {0, 0}
local brakeTorqueLimitCache = {0, 0}
local absPulse = 0
local absActive = false
local absActiveLastPulse = false
local warningLightsDelayTime = 0.15 --s
local warningLightsTimer = 0 --s

local updateVirtualAirspeedMethod = nop
local virtualAirspeed = 0
local lastVirtualAirspeed = 0
local airspeedMapTimer = 0
local airspeedMapTime = 0.05
local lastBrake = 0
local lastAccSign = 1

local airspeedBrakeThreshold = 0.2
local airspeedThrottleThreshold = 0.3
local airspeedYawThreshold = 1
local airspeedResetTimer = 0
local airspeedResetTime = 0.3
local airspeedResetSpeedThreshold = 1 / 0.7

local padThermalEfficiencyData = {
  ["basic"] =       {w1x1Coef = 0.018462, w2x1Coef = -0.013846, b1 = 3,   b2 = 7,    a = -0.988}, --w1x1Coef = w1 / (2 * x1), w2x1Coef = w2 / (2 * x1)
  ["premium"] =     {w1x1Coef = 0.018462, w2x1Coef = -0.011538, b1 = 3.5, b2 = 7,    a = -0.992},
  ["sport"] =       {w1x1Coef = 0.019231, w2x1Coef = -0.014231, b1 = 2,   b2 = 9.5,  a = -0.996},
  ["semi-race"] =   {w1x1Coef = 0.008462, w2x1Coef = -0.013846, b1 = 1.5, b2 = 10.5, a = -0.985},
  ["full-race"] =   {w1x1Coef = 0.009231, w2x1Coef = -0.016923, b1 = 0.8, b2 = 14,   a = -0.992},
  ["godmode"] =     {w1x1Coef = 0.007692, w2x1Coef = -0.007692, b1 = 10,  b2 = 100,  a = -1.001},
}

local virtualAirspeedMaps =
{
  {acceleration = 0.1,  invGainSum = 0, wheelCoef = 1, correctionCoef = 1.01}, -- stable, idle
  {acceleration = 0,    invGainSum = 0, wheelCoef = 1, correctionCoef = 0.9},  -- heavyBrakingInit, idle
  {acceleration = 1,    invGainSum = 0, wheelCoef = 0, correctionCoef = 1.00}, -- heavyBraking, braking
  {acceleration = 2,    invGainSum = 0, wheelCoef = 0, correctionCoef = 1.01}, -- heavyAcceleration, acceleration
  {acceleration = 0.1,  invGainSum = 0, wheelCoef = 1, correctionCoef = 1}     -- heavyYaw, idle
}

local updateThermalsGFXMethod = nop

local function beamBroke(id)
  local beamName = v.data.beams[id].name
  if not beamName or not axleBeamLookup[beamName] then
    return
  end

  for _,v in ipairs(axleBeamLookup[beamName]) do
    local wd = M.wheelRotators[v]
    if not wd.isBroken then
      wd.isBroken = true
      wd.propulsionTorque = 0
      wd.brakingTorque = 0
      wd.desiredBrakingTorque = 0
      wd.angularVelocity = 0
      wd.angularVelocityBrakeCouple = 0
      wd.obj:setTorqueAndBrakeTorque(0, 0)
      damageTracker.setDamage("wheels", wd.name, true)
      -- Brake damage
      damageTracker.setDamage("wheels", "brake"..wd.name, true);
      if wd.rotatorType == "wheel" then
        M.wheelCount = M.wheelCount - 1
        invWheelCount = M.wheelCount > 0 and 1 / M.wheelCount or 0
        if wd.isSpeedo then
          speedoWheelCount = speedoWheelCount - 1
          invSpeedoWheelCount = speedoWheelCount > 0 and 1 / speedoWheelCount or 0
        end
      elseif wd.rotatorType == "rotator" then
        M.rotatorCount = M.rotatorCount - 1
      end
    end
  end
end

local function scaleBrakeTorque(coef)
  coef = coef or 0
  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    if wd.brakeTorque then
      wd.brakeTorque = wd.initialBrakeTorque * coef
    end
    if wd.parkingTorque then
      wd.parkingTorque = wd.initialParkingTorque * coef
    end
  end
end

local function calculateThermalEfficiency(temperature, config)
  local z1 = config.w1x1Coef * temperature + config.b1
  local z2 = config.w2x1Coef * temperature + config.b2

  local sigma1 = 1 / (1 + math.exp(-z1));
  local sigma2 = 1 / (1 + math.exp(-z2));
  local f = sigma1 + sigma2 + config.a;

  local result = min(max(f, 0), 1)
  return result
end

local function updateThermalsGFX(dt)
  local tEnv = obj:getEnvTemperature() + kelvinToCelsius
  local airSpeed = electrics.values.airspeed
  local updateGUI = streams.willSend("wheelThermalData")
  local updateDamage = damageTracker.willSend()
  if updateGUI then
    table.clear(wheelInfo)
  end
  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    if wd.enableBrakeThermals and not wd.isBroken then
      local isUnderWater = 1 + (obj:inWater(wd.node1) and 20 or 0)
      local avgVelBrakeCouple = wd.angularVelocityBrakeCouple
      local absAvgVelBrakeCouple = abs(avgVelBrakeCouple)
      local wheelSpeed = absAvgVelBrakeCouple * wd.radius
      local energyToBrakeSurface = wd.brakingTorque * absAvgVelBrakeCouple * dt

      local surfaceCoolingCoef = wd.brakeVentingCoef * wd.brakeTypeSurfaceCoolingCoef
      local coreCoolingCoef = wd.brakeVentingCoef * wd.brakeTypeCoreCoolingCoef

      local surfaceCooling = ((40 * wd.brakeTypeSurfaceCoolingCoef) + max(airSpeed, wheelSpeed) * surfaceCoolingCoef * 5.0) * isUnderWater
      local coreCooling = ((20 * wd.brakeTypeCoreCoolingCoef) + max(airSpeed * wd.airSpeedCoreCooling, wheelSpeed * wd.wheelSpeedCoreCooling) * coreCoolingCoef * 3) * isUnderWater

      local energyBrakeSurfaceToAir = (wd.brakeSurfaceTemperature - tEnv) * wd.brakeCoolingArea * surfaceCooling
      local tempSquared = square(wd.brakeSurfaceTemperature + celsiusToKelvin)
      local energyRadiationToAir = square(tempSquared) * wd.kRadiationToAir * wd.brakeCoolingArea
      local energyBrakeSurfaceToCore = (wd.brakeSurfaceTemperature - wd.brakeCoreTemperature) * wd.kSurfaceToCore * wd.brakeCoolingArea
      local energyBrakeCoreToAir = (wd.brakeCoreTemperature - tEnv) * coreCooling * wd.brakeCoolingArea

      wd.brakeSurfaceTemperature = max(wd.brakeSurfaceTemperature + (energyToBrakeSurface - (energyBrakeSurfaceToAir + energyRadiationToAir + energyBrakeSurfaceToCore) * dt) * wd.brakeSurfaceEnergyCoef , tEnv)
      wd.brakeCoreTemperature = max(wd.brakeCoreTemperature + ((energyBrakeSurfaceToCore - energyBrakeCoreToAir) * dt) * wd.brakeCoreEnergyCoef , tEnv)

      wd.isBrakeMolten = wd.brakeCoreTemperature > wd.brakeMeltingPoint or wd.isBrakeMolten

      local thermalEfficiency = wd.isBrakeMolten and 0 or calculateThermalEfficiency(wd.brakeSurfaceTemperature, wd.thermalEfficiencyConfig)
      local slopeSwitchBit = wd.isBrakeMolten and 0 or max(fsign(calculateThermalEfficiency(wd.brakeSurfaceTemperature + 1, wd.thermalEfficiencyConfig) - thermalEfficiency), 0)

      --wd.padGlazingFactor = slopeSwitchBit > 0 and wd.padGlazingFactor or min(wd.padGlazingFactor, thermalEfficiency)
      --local relativeBrakingCoef = wd.obj.brakingTorque * wd.invRelativeBrakingTorqueCoef
      --wd.padGlazingFactor = min(max(wd.padGlazingFactor + relativeBrakingCoef * dt * 0.02,0),1)
      --wd.brakeThermalEfficiency = min(thermalEfficiency, wd.padGlazingFactor)
      wd.brakeThermalEfficiency = thermalEfficiency --glazing disabled for now

      if slopeSwitchBit < 1 and thermalEfficiency <= brakeSmokeEfficiencyThreshold then
        wd.smokeParticleTick = wd.smokeParticleTick > 1 and 0 or wd.smokeParticleTick + dt * 50 * (brakeSmokeEfficiencyThreshold - thermalEfficiency)
        if wd.smokeParticleTick > 1 then
          local particleType  = airSpeed < 10 and 48 or 49
          obj:addParticleByNodesRelative(wd.node1, wd.node2, 1 - math.random(1), particleType, 0, 1)
        end
      end

      if isUnderWater > 1 and wd.brakeSurfaceTemperature > brakeCoreWaterToSteamThresholdTemperature then
        wd.steamParticleTick = wd.steamParticleTick > 1 and 0 or wd.steamParticleTick + dt * 0.05 * (wd.brakeSurfaceTemperature - brakeCoreWaterToSteamThresholdTemperature)
        if wd.steamParticleTick > 1 then
          local particleType  = airSpeed < 10 and 48 or 49
          obj:addParticleByNodesRelative(wd.node1, wd.node2, 1 - math.random(1), particleType, 0, 1)
        end
      end

      if updateDamage then
        damageTracker.setDamage("wheels", "brakeOverHeat"..wd.name, (slopeSwitchBit < 1 and thermalEfficiency < 0.85) and wd.brakeThermalEfficiency or 0)
        if wd.isBrakeMolten then
          damageTracker.setDamage("wheels", "brake"..wd.name, wd.isBrakeMolten)
        end
      end

      if updateGUI then
        wheelInfo[wd.name] = {
          energyToBrakeSurface = energyToBrakeSurface / dt,
          brakeSurfaceTemperature = wd.brakeSurfaceTemperature,
          brakeCoreTemperature = wd.brakeCoreTemperature,
          surfaceCooling = surfaceCooling,
          coreCooling = coreCooling,
          energyBrakeSurfaceToAir = energyBrakeSurfaceToAir,
          energyBrakeSurfaceToCore = energyBrakeSurfaceToCore,
          energyBrakeCoreToAir = energyBrakeCoreToAir,
          energyRadiationToAir = energyRadiationToAir,
          finalBrakeEfficiency = wd.brakeThermalEfficiency,
          brakeThermalEfficiency = thermalEfficiency,
          padGlazingFactor = wd.padGlazingFactor,
          slopeSwitchBit = slopeSwitchBit,
          brakeType = wd.brakeType,
          padMaterial = wd.padMaterial
        }
      end
    elseif wd.isBroken and updateGUI then
      wheelInfo[wd.name] = {
        energyToBrakeSurface = 0,
        brakeSurfaceTemperature = 0,
        brakeCoreTemperature = 0,
        surfaceCooling = 0,
        coreCooling = 0,
        energyBrakeSurfaceToAir = 0,
        energyBrakeSurfaceToCore = 0,
        energyBrakeCoreToAir = 0,
        energyRadiationToAir = 0,
        finalBrakeEfficiency = 0,
        brakeThermalEfficiency = 0,
        padGlazingFactor = 0,
        slopeSwitchBit = 0,
        brakeType = wd.brakeType,
        padMaterial = wd.padMaterial
      }
    end
  end

  if updateGUI then
    gui.send('wheelThermalData', {
        wheels = wheelInfo
      })
  end
end

local function updateWheelsGFX(dt)
  local avgAV = 0
  local avgWheelSpeed = 0

  M.wheelTorque = 0
  M.wheelPower = 0

  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    wd.contactMaterialID1 = -1
    wd.contactMaterialID2 = -1
    wd.lastSlip, wd.slipEnergy = wd.obj:getSlipVelEnergy()
    wd.contactDepth = 0
    wd.downForce = wd.downForceSmoother:get(wd.downForceRaw)
    wd.downForceRaw = 0
    if not wd.isBroken then
      local wheelAV = wd.angularVelocity * wd.wheelDir
      M.wheelPower = M.wheelPower + wd.propulsionTorque * wd.angularVelocity
      M.wheelTorque = M.wheelTorque + wd.propulsionTorque * wd.wheelDir
      if wd.isSpeedo  then
        avgAV = avgAV + wheelAV
        avgWheelSpeed = avgWheelSpeed + wheelAV * wd.radius
      end

      if wd.isTireDeflated then
        wd.deflatedTireAngle = wd.deflatedTireAngle + clamp(wd.angularVelocity, -100, 100) * dt
        if abs(wd.deflatedTireAngle) > twoPi then
          local downForceVolume = clamp(wd.downForce / 5000, 0, 1)
          --print(downForceVolume)
          local speedVolume = 0.3 + clamp(abs(wd.angularVelocity) / 50, 0, 2)
          --print(speedVolume)
          local speedPitch = 0.8 + clamp(abs(wd.angularVelocity) / 200, 0, 1)
          --print(speedPitch)
          obj:playSFXOnce(wd.flatTireSound, wd.node1, downForceVolume * speedVolume, speedPitch)
          wd.deflatedTireAngle = 0
        end
      end
    end
  end

  electrics.values.avgWheelAV = avgAV * invSpeedoWheelCount
  electrics.values.wheelspeed = abs(avgWheelSpeed) * invSpeedoWheelCount

  warningLightsTimer = warningLightsTimer + dt

  if warningLightsTimer >= warningLightsDelayTime then
    absPulse = absActive and bit.bxor(absPulse, 1) or 0
    warningLightsTimer = 0
  end

  electrics.values.abs = absPulse
  electrics.values.absActive = absActive
end

local function updateBrakingDistanceGFX(dt)
  if (input.brake or 0) < 0.2 then
    state = "idle"
  end

  local airspeed = electrics.values.airspeed
  if state == "idle" then
    if input.brake > 0.2 and airspeed > targetSpeed then
      state = "waiting"
    end
  elseif state == "waiting" then
    if airspeed <= targetSpeed then
      startPosition = obj:getPosition()
      state = "measuring"
      gui.message({txt="Measuring braking distance...", context = { }}, 1, "vehicle.brakingdistance")
    end
  elseif state == "measuring" then
    if airspeed <= 1 then
      local endPosition = obj:getPosition()
      local distance = (startPosition - endPosition):length()
      local avgDeceleration = -(square(airspeed) - square(targetSpeed)) / (2 * distance)
      gui.message({txt=string.format("Brakingdistance: %.2fm, G: %.2f", distance, avgDeceleration / 9.81), context = { }}, 5, "vehicle.brakingdistance")
      startPosition = nil
      state = "idle"
    end
  end
end

local function updateGFX(dt)

  updateThermalsGFXMethod(dt)

  updateWheelsGFX(dt)

  --updateBrakingDistanceGFX(dt)
end

local function updateWheelSlip(p)
  if not p then return end
  if not v.data.nodes[p.id1] then return end
  local wheelID = v.data.nodes[p.id1].wheelID
  if wheelID then
    local wd = M.wheelRotators[wheelID]
    -- Smoothed instant energy (E/dt)
    wd.contactMaterialID1 = p.materialID1
    wd.contactMaterialID2 = p.materialID2
    wd.contactDepth = math.max (p.depth, wd.contactDepth)
    wd.downForceRaw = wd.downForceRaw - p.normalForce
  end
end

local function updateVirtualAirspeed(dt)
  local brake = electrics.values.brake
  local wheelspeed = electrics.values.wheelspeed
  local mapId = 1 -- stable

  if lastBrake == 0 and brake > 0 and airspeedMapTimer == 0 and virtualAirspeed > wheelspeed then
    mapId = 2 -- heavyBrakingInit
    airspeedMapTimer = airspeedMapTime
  end

  if (brake > airspeedBrakeThreshold or input.parkingbrake ~= 0) and airspeedMapTimer == 0 then
    mapId = 3 -- heavyBraking
    if lastVirtualAirspeed > wheelspeed * airspeedResetSpeedThreshold then
      airspeedResetTimer = airspeedResetTimer + dt
      if airspeedResetTimer > airspeedResetTime then
        lastVirtualAirspeed = (lastVirtualAirspeed + wheelspeed) * 0.5
        airspeedResetTimer = 0
      end
    end
  end

  if electrics.values.throttle > airspeedThrottleThreshold and brake < airspeedBrakeThreshold and airspeedMapTimer == 0 then
    mapId = 4 -- heavyAcceleration
  end

  if mapId ~= 1 and abs(obj:getYawAngularVelocity()) > airspeedYawThreshold then
    mapId = 5 -- heavyYaw
  end
  local virtualAirspeedMap = virtualAirspeedMaps[mapId]

  lastBrake = brake
  airspeedMapTimer = max(airspeedMapTimer - dt, 0)

  local wheelSpeedSum = 0
  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    wheelSpeedSum = wheelSpeedSum + abs(wd.angularVelocity * wd.radius)
  end
  wheelSpeedSum = wheelSpeedSum * virtualAirspeedMap.wheelCoef

  local accSign = wheelspeed > 2 and fsign(electrics.values.avgWheelAV) or lastAccSign
  lastAccSign = accSign

  local accSpeed = (lastVirtualAirspeed - obj:getSensorY() * dt * accSign) * virtualAirspeedMap.acceleration
  lastVirtualAirspeed = (wheelSpeedSum + accSpeed) * virtualAirspeedMap.invGainSum
  virtualAirspeed = lastVirtualAirspeed * virtualAirspeedMap.correctionCoef

--  if streams.willSend("profilingData") then
--    gui.send('profilingData', {
--        virtualSpeed = { title = "Virtual Speed", color = getContrastColorStringRGB(7), unit = "km/h", value = virtualAirspeed * 3.6},
--        realSpeed = { title = "Real Speed", color = getContrastColorStringRGB(1), unit = "km/h", value = obj:getGroundSpeed() * 3.6},
--        wheelSpeed = { title = "Wheel Speed", color = getContrastColorStringRGB(8), unit = "km/h", value = wheelspeed * 3.6},
--        yaw = { title = "Yaw Rate", color = getContrastColorStringRGB(5), unit = "km/h", value = abs(obj:getYawAngularVelocity()) * 10},
--        mapIndex = { title = "Map Index", color = getContrastColorStringRGB(11), unit = "", value = (mapId-1) * 10},
--      })
--  end
end

local function updateBrakeABS(wd, brake, invAirspeed, airspeed, airspeedCutOff, dt)
  if brake > 0 then
    wd.absTimer = max(wd.absTimer - dt, 0)
    if wd.absTimer <= 0 then
      local absDT = max(dt, wd.absTime) --if the ABS frequency is smaller than the physics step, we need to use the right dt here
      wd.absTimer = wd.absTime
      local slipRatio = min(max((airspeed - (abs(wd.angularVelocityBrakeCouple * wd.wheelDir) * wd.radius)) * invAirspeed, 0), 1)
      local slipRatioTarget = min(2 * invAirspeed + wd.slipRatioTarget, 1)
      local slipError = slipRatioTarget - slipRatio
      local slipErrorDerivative = (slipError - wd.lastSlipError) / absDT
      wd.slipErrorIntegral = max(min(wd.slipErrorIntegral + slipError * absDT, 1), -1)
      local ABSCoef = airspeedCutOff and min(max(slipError * 5 + wd.slipErrorIntegral * 0.3 + slipErrorDerivative * 0.05, 0), 1) or 1

      local nonABSBrakingTorque = wd.brakeTorque * (min(brake, wd.brakeInputSplit) + max(brake - wd.brakeInputSplit, 0) * wd.brakeSplitCoef)
      local desiredBrakingTorque = nonABSBrakingTorque * ABSCoef

      brakeTorqueLimitCache[wd.oppositeSide] = max(desiredBrakingTorque * 1.15, brakeTorqueLimitCache[wd.oppositeSide])
      desiredBrakingTorque = min(desiredBrakingTorque, brakeTorqueLimits[wd.ownSide])
      wd.absActive = desiredBrakingTorque < nonABSBrakingTorque * 0.9
      absActive = wd.absActive or absActive
      absActiveLastPulse = absActive
      wd.lastSlipError = slipError

      return desiredBrakingTorque
    else
      brakeTorqueLimitCache[wd.oppositeSide] = brakeTorqueLimits[wd.oppositeSide]
      absActive = absActive or absActiveLastPulse
      return wd.desiredBrakingTorque
    end
  else
    wd.slipErrorIntegral = 0
    wd.lastSlipError = 0
    brakeTorqueLimitCache[wd.oppositeSide] = maxDoubleBrakeTorque
    return 0
  end
end

local function updateBrakeNonABS(wd, brake, invAirspeed, airspeed, airspeedCutOff, dt)
  local brakeInputSplit = wd.brakeInputSplit
  return wd.brakeTorque * (min(brake, brakeInputSplit) + max(brake - brakeInputSplit, 0) * wd.brakeSplitCoef)
end

local function updateWheelVelocities(dt)
  updateVirtualAirspeedMethod(dt)

  local airspeed = absBehavior == "arcade" and electrics.values.airspeed or virtualAirspeed
  local invAirspeed = 1 / (airspeed + 1e-30)
  local airspeedCutOffSpeed = 5
  local airspeedCutOff = airspeed > airspeedCutOffSpeed

  local brake = electrics.values.brake or 0
  local parkingbrakeInput = input.parkingbrake
  absActive = false

  obj:getAVandBrakeCoupleAVs(wheelAVs)

  brakeTorqueLimitCache[1] = 0
  brakeTorqueLimitCache[2] = 0

  local wheels = M.wheels
  for i = 0, initialWheelCountDec do
    local wd = wheels[i]
    if not wd.isBroken then
      local cid2 = wd.cid2
      wd.angularVelocity = wheelAVs[cid2]
      wd.angularVelocityBrakeCouple = wheelAVs[cid2 + 1]
      -- composite brake (normal + parking)
      wd.desiredBrakingTorque = max(wd:updateBrake(brake, invAirspeed, airspeed, airspeedCutOff, dt), wd.parkingTorque * parkingbrakeInput)
    end
  end

  brakeTorqueLimits[1] = brakeTorqueLimitCache[1]
  brakeTorqueLimits[2] = brakeTorqueLimitCache[2]

  local rotators = M.rotators
  for i = 0, initialRotatorCountDec do
    local wd = rotators[i]
    if not wd.isBroken then
      local cid2 = wd.cid2
      wd.angularVelocity = wheelAVs[cid2]
      wd.angularVelocityBrakeCouple = wheelAVs[cid2 + 1]
    end
  end
end

local function updateWheelTorques(dt)
  controller.updateWheelsIntermediate(dt)

  local torqueReactionCoefs = powertrain.torqueReactionCoefs
  local wheelRotators = M.wheelRotators
  local torques = wheelRotatorTorques
  for i = 0, initialWheelRotatorCountDec do
    local wd = wheelRotators[i]
    local brakingTorque = wd.brakePressureDelay:get(wd.desiredBrakingTorque) * wd.brakeThermalEfficiency
    wd.brakingTorque = brakingTorque
    local cid4 = wd.cid4
    if wd.isBroken then
      torques[cid4] = 0
      torques[cid4 + 1] = 0
      torques[cid4 + 2] = 0
    else
      local propulsionTorque = wd.propulsionTorque
      torques[cid4] = propulsionTorque
      torques[cid4 + 1] = brakingTorque + wd.frictionTorque
      torques[cid4 + 2] = abs(propulsionTorque) * torqueReactionCoefs[wd.torsionReactorIdx]
    end
  end

  obj:setWheelsTorqueBrakeEngine(torques)
end

local function setABSBehavior(behavior)
  absBehavior = behavior
  local needsVirtualAirspeed = false
  for i = 0, M.wheelRotatorCount - 1 do
    local wd = M.wheelRotators[i]
    wd.updateBrake = updateBrakeNonABS
    if (wd.hasABS and behavior ~= "off") or behavior == "arcade" then
      needsVirtualAirspeed = behavior == "realistic"
      wd.updateBrake = updateBrakeABS
    end
    wd.absTime = behavior == "realistic" and 1 / wd.absFrequency or 0.01
  end

  updateVirtualAirspeedMethod = needsVirtualAirspeed and updateVirtualAirspeed or nop
end

local function resetABSBehavior()
  setABSBehavior(settings.getValue("absBehavior") or "realistic")
end

local function setWheelRotatorType(wheelID, rotatorType)
  M.wheelRotators[wheelID].rotatorType = rotatorType
end

local function resetThermals()
  local tEnv = obj:getEnvTemperature() + kelvinToCelsius
  local startPreHeated = settings.getValue("startBrakeThermalsPreHeated")

  for _,wd in pairs(M.wheelRotators) do
    if wd.enableBrakeThermals then
      wd.brakeThermalEfficiency = 1
      wd.padGlazingFactor = 1
      wd.smokeParticleTick = 0
      wd.steamParticleTick = 0
      wd.isBrakeMolten = false

      local startTemp = tEnv
      if startPreHeated and string.find(wd.padMaterial, "race") then
        local efficiency = 0
        repeat
          startTemp = startTemp + 1
          efficiency = calculateThermalEfficiency(startTemp, wd.thermalEfficiencyConfig)
        until efficiency >= 0.95
        startTemp = startTemp + 50
      end

      wd.brakeSurfaceTemperature = startTemp
      wd.brakeCoreTemperature = startTemp

      -- Reset brake damage values
      damageTracker.setDamage("wheels", "brake"..wd.name, false);
      -- Reset brake overheating values
      damageTracker.setDamage("wheels", "brakeOverHeat"..wd.name, 0);
    end
  end
end

local function resetWheels()
  startPosition = nil
  state = "idle"

  M.wheelRotatorCount = initialWheelRotatorCountDec + 1

  electrics.values.avgWheelAV = 0
  electrics.values.wheelspeed = 0

  for i = 0, initialWheelRotatorCountDec do
    local wd = M.wheelRotators[i]
    wd.lastTorqueMode = 0
    wd.lastSlip = 0
    wd.slipEnergy = 0
    wd.contactMaterialID1 = -1
    wd.contactMaterialID2 = -1
    wd.contactDepth = 0
    wd.downForceRaw = 0
    wd.downForceSmoother:reset()
    wd.slipEnergySmoother:reset()
    wd.slipSkidFadeSmoother:reset()
    wd.slipSkidVolSmoother:reset()
    wd.slipSkidPitchSmoother:reset()
    wd.tireContactSmoother:reset()
    wd.downForce = 0
    wd.isTireDeflated = false
    wd.deflatedTireAngle = 0

    wd.slipErrorIntegral = 0
    wd.lastSlipError = 0
    wd.isBroken = false
    wd.absTimer = 0


    wd.propulsionTorque = 0
    wd.brakingTorque = 0
    wd.frictionTorque = 0
    wd.desiredBrakingTorque = 0
    wd.angularVelocity = 0
    wd.angularVelocityBrakeCouple = 0

    wd.brakePressureDelay:reset()
    wd.brakeThermalEfficiency = 1

    --make sure to reset brake torques to initial values in case they were altered
    if wd.initialBrakeTorque then
      wd.brakeTorque = wd.initialBrakeTorque
    end
    if wd.initialParkingTorque then
      wd.parkingTorque = wd.initialParkingTorque
    end
  end

  setABSBehavior(absBehavior)

  brakeTorqueLimits[1] = maxBrakeTorque * 2
  brakeTorqueLimits[2] = maxBrakeTorque * 2

  for k,_ in ipairs(wheelRotatorTorques) do
    wheelRotatorTorques[k] = 0
  end

  for k,_ in ipairs(wheelAVs) do
    wheelAVs[k] = 0
  end
end

local function reset()
  resetWheels()
  resetThermals()
end

local function initThermals()
  M.updateThermalsGFX = nop

  local tEnv = obj:getEnvTemperature() + kelvinToCelsius
  local brakeThermalsEnabled = false

  local startPreHeated = settings.getValue("startBrakeThermalsPreHeated")

  for _,wd in pairs(M.wheelRotators) do
    if wd.enableBrakeThermals then
      brakeThermalsEnabled = true
      wd.brakeMass = max(wd.brakeMass or 10, minBrakeMass)
      wd.brakeDiameter = wd.brakeDiameter or 0.35

      wd.brakeType = wd.brakeType or "vented-disc"
      if wd.brakeType == "vented-disc" then
        wd.brakeCoolingArea = math.pi * wd.brakeDiameter * wd.brakeDiameter / 2 * 0.7
        wd.brakeTypeSurfaceCoolingCoef = 1
        wd.brakeTypeCoreCoolingCoef = 1
        wd.wheelSpeedCoreCooling = 1
        wd.airSpeedCoreCooling = 0.2
      elseif wd.brakeType == "disc" then
        wd.brakeCoolingArea = math.pi * wd.brakeDiameter * wd.brakeDiameter / 2 * 0.7
        wd.brakeTypeSurfaceCoolingCoef = 1
        wd.brakeTypeCoreCoolingCoef = 0.01
        wd.wheelSpeedCoreCooling = 0
        wd.airSpeedCoreCooling = 0.01
      elseif wd.brakeType == "drum" then
        --perimeter * width + some side
        --wd.brakeCoolingArea = math.pi * wd.brakeDiameter * wd.brakeDiameter * 0.22
        wd.brakeCoolingArea = math.pi * (wd.brakeDiameter * (wd.brakeDiameter * 0.22) + wd.brakeDiameter * wd.brakeDiameter / 4 * 0.25)
        wd.brakeTypeSurfaceCoolingCoef = 0.25
        wd.brakeTypeCoreCoolingCoef = 1 --because brake drum "core" is in primary airflow
        wd.wheelSpeedCoreCooling = 1
        wd.airSpeedCoreCooling = 1
      else
        log("E", "wheels.initThermals", "Found unknown brake type: "..wd.brakeType..", disabling brake thermals...")
        brakeThermalsEnabled = false
        break
      end

      wd.rotorMaterial = wd.rotorMaterial or "steel"
      if wd.rotorMaterial == "steel" then
        wd.brakeSpecHeat = 450
        wd.kSurfaceToCore = 55 / 0.01
        wd.kRadiationToAir = 0.0000000567 * 0.75
        wd.brakeMeltingPoint = 1500
      elseif (wd.rotorMaterial == "aluminum" or wd.rotorMaterial == "aluminium") then
        wd.brakeSpecHeat = 910
        wd.kSurfaceToCore = 150 / 0.01 --reduce K a bit from textbook value because aluminum brake still needs steel friction lining
        wd.kRadiationToAir = 0.0000000567 * 0.5
        wd.brakeMeltingPoint = 660
      elseif wd.rotorMaterial == "ceramic" then
        wd.brakeSpecHeat = 750
        wd.kSurfaceToCore = 50 / 0.01
        wd.kRadiationToAir = 0.0000000567 * 0.9
        wd.brakeMeltingPoint = 1800
      else
        log("E", "wheels.initThermals", "Found unknown rotor material: "..wd.rotorMaterial..", disabling brake thermals...")
        brakeThermalsEnabled = false
        break
      end

      wd.padMaterial = wd.padMaterial or "basic"
      wd.thermalEfficiencyConfig = padThermalEfficiencyData[wd.padMaterial] or padThermalEfficiencyData["basic"]

      wd.brakeVentingCoef = wd.brakeVentingCoef or 1

      wd.brakeSurfaceEnergyCoef = 1 / (wd.brakeMass * 0.15 * wd.brakeSpecHeat)
      wd.brakeCoreEnergyCoef = 1 / (wd.brakeMass * 0.85 * wd.brakeSpecHeat)
      wd.invRelativeBrakingTorqueCoef = 1 / wd.brakeTorque
      wd.brakeThermalEfficiency = 1
      wd.padGlazingFactor = 1
      wd.smokeParticleTick = 0
      wd.steamParticleTick = 0
      wd.isBrakeMolten = false

      local startTemp = tEnv
      if startPreHeated and string.find(wd.padMaterial, "race") then
        local efficiency = 0
        repeat
          startTemp = startTemp + 1
          efficiency = calculateThermalEfficiency(startTemp, wd.thermalEfficiencyConfig)
        until efficiency >= 0.95
        startTemp = startTemp + 50
      end

      wd.brakeSurfaceTemperature = startTemp
      wd.brakeCoreTemperature = startTemp

      -- Initialising brake damage values
      damageTracker.setDamage("wheels", "brake"..wd.name, false);
      -- Initialising brake overheating values
      damageTracker.setDamage("wheels", "brakeOverHeat"..wd.name, 0);
    end
  end

  if brakeThermalsEnabled then
    updateThermalsGFXMethod = updateThermalsGFX
  end
end

local function initWheels()
  startPosition = nil
  state = "idle"
  electrics.values.avgWheelAV = 0
  electrics.values.wheelspeed = 0

  local brakesFound = false
  maxBrakeTorque = 0
  maxDoubleBrakeTorque = 0
  axleBeamLookup = {}

  M.wheelRotators = {}
  M.wheelRotatorCount = 0
  M.wheels = {}

  M.treadNodeLookup = {}

  local dtPhysics = obj:getPhysicsDt()
  local maxWheelCid = 0

  local count = tableSize(v.data.wheels)
  for i = 0, count - 1, 1 do
    local wd = v.data.wheels[i]
    local wobj = obj:getWheel(wd.wheelID)

    if wobj then
      wobj:setBrakeSpring(max(wd.brakeTorque or 0, wd.parkingTorque or 0, 1) * (wd.brakeSpring or 10))
      brakesFound = brakesFound or (wd.brakeTorque ~= nil)
      maxBrakeTorque = max(maxBrakeTorque, wd.brakeTorque or 0)
      maxDoubleBrakeTorque = max(maxBrakeTorque * 2, maxDoubleBrakeTorque)
      M.wheelRotatorCount = M.wheelRotatorCount + 1
      maxWheelCid = max(maxWheelCid, wd.cid)
      local wheel = {
        rotatorType = wd.rotatorType or "wheel",
        name = wd.name,
        wheelID = wd.wheelID,
        wheelDir = wd.wheelDir,
        radius = (wd.hasTire or wd.hasTire == nil) and wd.radius or (wd.hubRadius or wd.radius), --use radius if there is a tire, if not use hub radius, if there is no hubradius, it might be a rotator, use normal radius then again...
        node1 = wd.node1,
        node2 = wd.node2,
        brakeMass = wd.brakeMass,
        padMaterial = wd.padMaterial,
        enableBrakeThermals = wd.enableBrakeThermals,
        brakeVentingCoef = wd.brakeVentingCoef,
        brakeType = wd.brakeType,
        brakeDiameter = wd.brakeDiameter,
        rotorMaterial = wd.rotorMaterial,
        nodes = wd.nodes,
        treadNodes = wd.treadNodes,
        torsionReactor = {name="", outputTorque1 = 0},
        torsionReactorIdx = 1,
        lastTorqueMode = 0,
        lastSlip = 0,
        slipEnergy = 0,
        contactMaterialID1 = -1,
        contactMaterialID2 = -1,
        contactDepth = 0,
        downForceRaw = 0,
        isTireDeflated = false,
        deflatedTireAngle = 0,
        flatTireSound = wd.flatTireSound or "event:>Surfaces>Flat_Tire",
        downForceSmoother = newExponentialSmoothing(30),
        slipEnergySmoother = newTemporalSmoothing(),
        slipSkidFadeSmoother  = newTemporalSmoothingNonLinear(15),
        slipSkidVolSmoother   = newTemporalSmoothingNonLinear(15),
        slipSkidPitchSmoother = newTemporalSmoothingNonLinear(15),
        tireContactSmoother = newTemporalSmoothing(),
        downForce = 0,
        obj = wobj,
        cid = wd.cid,
        cid2 = wd.cid * 2,
        cid4 = wd.cid * 4,
        slipErrorIntegral = 0,
        lastSlipError = 0,
        slipRatioTarget = 0.2,
        isBroken = false,
        isSpeedo = wd.speedo or wd.speedo == nil,
        hasABS = wd.enableABSactuator or wd.enableABS or false,
        absTimer = 0,
        absFrequency = wd.absHz or 100,
        absTime = 1 / (wd.absHz or 100),
        minABSCoef = 1 - (wd.minABSCoef or 0.1),

        brakeTorque = wd.brakeTorque or 0,
        initialBrakeTorque = wd.brakeTorque or 0,
        parkingTorque =  wd.parkingTorque or 0,
        initialParkingTorque = wd.parkingTorque or 0,

        propulsionTorque = 0,
        brakingTorque = 0,
        frictionTorque = 0,
        desiredBrakingTorque = 0,
        angularVelocity = 0,
        angularVelocityBrakeCouple = 0,
        brakeInputSplit = math.max(math.min(wd.brakeInputSplit or 1, 1), 0),
        brakeSplitCoef = math.max(math.min(wd.brakeSplitCoef or 1, 1), 0),
        brakePressureDelay = newLinearSmoothing(dtPhysics, (wd.brakeTorque or 0) / ((wd.brakePressureInDelay or 0.05) + 1e-30), (wd.brakeTorque or 0) / ((wd.brakePressureOutDelay or 0.1) + 1e-30)),
        brakeThermalEfficiency = 1,
      }

      table.insert(M.wheelRotators, i, wheel)
      if wd.axleBeams then
        for _,name in pairs(wd.axleBeams) do
          if not axleBeamLookup[name] then
            axleBeamLookup[name] = {}
          end
          table.insert(axleBeamLookup[name], wd.wheelID)
        end
      end
      --insert as wheels as well (temporary) for better backwards compat (controller init right after wheels init, no second stage init done yet)
      table.insert(M.wheels, i, wheel)
    else
      log('W', "drivetrain.init", 'Wheel "'..wd.name..'" could not be added to drivetrain')
    end
  end

  local absMode = settings.getValue("absBehavior") or "realistic"
  setABSBehavior(absMode)

  wheelRotatorTorques = table.new(maxWheelCid * 4 + 1,0)
  for i = 0, maxWheelCid * 4 + 1 do
    wheelRotatorTorques[i] = 0
  end

  wheelAVs = table.new(maxWheelCid * 2 + 1,0)
  for i = 0, maxWheelCid * 2 + 1 do
    wheelAVs[i] = 0
  end

  brakeTorqueLimits = {}
  brakeTorqueLimits[1] = maxBrakeTorque * 2
  brakeTorqueLimits[2] = maxBrakeTorque * 2
end

local function init()
  initWheels()
  initThermals()
end

local function resetSecondStage()
  M.wheelCount = initialWheelCountDec + 1
  M.rotatorCount = initialRotatorCountDec + 1
  M.wheelPower = 0

  invWheelCount = M.wheelCount > 0 and 1 / M.wheelCount or 0
  speedoWheelCount = initialSpeedoWheelCount
  invSpeedoWheelCount = speedoWheelCount > 0 and 1 / speedoWheelCount or 0

  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    damageTracker.setDamage("wheels", wd.name, false)
    damageTracker.setDamage("wheels", "tire"..wd.name, false)
  end

  airspeedMapTimer = 0
  lastBrake = 0
  lastVirtualAirspeed = 0
  lastAccSign = 1
  airspeedResetTimer = 0
end

local function initSecondStage()
  M.wheels = {}
  M.wheelIDs = {}
  M.wheelCount = 0
  invWheelCount = 0
  invSpeedoWheelCount = 0
  speedoWheelCount = 0
  M.wheelPower = 0

  M.rotators = {}
  M.rotatorIDs = {}
  M.rotatorCount = 0

  local avgWheelPos = vec3(0,0,0)
  for _,rotator in pairs(M.wheelRotators) do
    if rotator.rotatorType == "wheel" then
      table.insert(M.wheels, M.wheelCount, rotator)
      M.wheelCount = M.wheelCount + 1
      M.wheelIDs[rotator.name] = rotator.wheelID
      if rotator.isSpeedo then
        speedoWheelCount = speedoWheelCount + 1
      end
      local wheelNodePos = v.data.nodes[rotator.node1].pos --find the wheel position
      avgWheelPos = avgWheelPos + wheelNodePos --sum up all positions

    elseif rotator.rotatorType == "rotator" then
      table.insert(M.rotators, M.rotatorCount, rotator)
      M.rotatorCount = M.rotatorCount + 1
      M.rotatorIDs[rotator.name] = rotator.wheelID
    end
  end

  initialWheelRotatorCountDec = M.wheelRotatorCount - 1
  initialWheelCountDec = M.wheelCount - 1
  initialRotatorCountDec = M.rotatorCount - 1
  invWheelCount = M.wheelCount > 0 and 1 / M.wheelCount or 0
  invSpeedoWheelCount = speedoWheelCount > 0 and 1 / speedoWheelCount or 0
  initialSpeedoWheelCount = speedoWheelCount
  avgWheelPos = avgWheelPos * invWheelCount --make the average of all positions

  local vectorForward = vec3(v.data.nodes[v.data.refNodes[0].ref].pos) - vec3(v.data.nodes[v.data.refNodes[0].back].pos) --vector facing forward
  local vectorUp = vec3(v.data.nodes[v.data.refNodes[0].up].pos) - vec3(v.data.nodes[v.data.refNodes[0].ref].pos)
  local vectorRight = vectorForward:cross(vectorUp) --vector facing to the right

  for i = 0, initialWheelCountDec do
    local wd = M.wheels[i]
    local wheelNodePos = vec3(v.data.nodes[wd.node1].pos) --find the wheel position
    local wheelVector = wheelNodePos - avgWheelPos --create a vector from our "center" to the wheel
    local dotLeft = vectorRight:dot(wheelVector) --calculate dot product of said vector and left vector

    if dotLeft >= 0 then
      wd.ownSide = 2
      wd.oppositeSide = 1 -- left
    else
      wd.ownSide = 1
      wd.oppositeSide = 2 -- right
    end

    damageTracker.setDamage("wheels", wd.name, false)
    damageTracker.setDamage("wheels", "tire"..wd.name, false)
  end

  for _,v in ipairs(virtualAirspeedMaps) do
    local gainSum = (v.acceleration + M.wheelCount * v.wheelCoef)
    v.invGainSum = gainSum > 0 and 1 / gainSum or 0
  end

  airspeedMapTimer = 0
  lastBrake = 0
  lastVirtualAirspeed = 0
  lastAccSign = 1
  airspeedResetTimer = 0

  --dump(M.wheels)
  --dump(M.rotators)
end

M.init = init
M.reset = reset
M.initSecondStage = initSecondStage
M.resetSecondStage = resetSecondStage
M.setABSBehavior = setABSBehavior
M.resetABSBehavior = resetABSBehavior
M.beamBroke = beamBroke
M.updateGFX = updateGFX
M.updateWheelTorques = updateWheelTorques
M.updateWheelVelocities = updateWheelVelocities
M.setWheelRotatorType = setWheelRotatorType
M.updateWheelSlip = updateWheelSlip
M.scaleBrakeTorque = scaleBrakeTorque

return M