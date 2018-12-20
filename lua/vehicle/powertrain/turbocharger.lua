-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local floor = math.floor
local sqrt = math.sqrt
local max = math.max
local min = math.min

local rpmToAV = 0.10471971768
local avToRPM = 9.5493
local invPascalToPSI = 0.00014503773773
local psiToPascal = 6894.757293178

M.isExisting = true

local assignedEngine = nil
local forcedInductionInfoStream = {
  rpm = 0,
  coef = 1,
  boost = 0,
  maxBoost = 0,
  exhaustPower = 0,
  friction = 0,
  backpressure = 0,
  bovEngaged = 0,
  wastegateFactor = 0,
  turboTemp = 0
}

--Turbo related stuff
local curTurboAV = 0
local maxTurboAV = 1
local invMaxTurboAV = 1
local invTurboInertia = 0
local turboInertiaFactor = 1
local turboPressure = 0
local turboPressureRaw = 0
local maxTurboPressure = 1
local maxExhaustPower = 1
local backPressureCoef = 0
local frictionCoef = 0
local turboWhineLoop = nil
local turboHissLoop = nil
local turboWhinePitchPerAV = 0
local turboWhineVolumePerAV = 0
local turboHissVolumePerPascal = 0

-- Wastegate
local wastegateStart = nil
local wastegateLimit = nil
local wastegateFactor = 1
local wastegateRange = nil
local maxWastegateStart = 0
local maxWastegateLimit = 0
local maxWastegateRange = 1

-- blow off valve
local bovEnabled = true
local bovEngaged = false
local lastBOVValue = false
local lastEngineLoad = 0
local bovOpenChangeThreshold = 0
local bovOpenThreshold = 0
local bovSoundVolumeCoef = 1
local bovSoundPressureCoef = 1
local bovTimer = 0
local ignitionCutSmoother = nil
local needsBov = false
local bovSound = nil

local flutterSoundVolumeCoef = 1
local flutterSoundPressureCoef = 1
local flutterSound = nil

--Engine related stuff
local invEngMaxAV = 0

local turbo = nil
local pressureSmoother = nil
local wastegateSmoother = nil
local electricsRPMName = nil
local electricsSpinName = nil
local electricsSpinCoef = nil
local electricsSpinValue = nil

--Damage
local turboDamageThresholdTemperature = 0

local function updateSounds(dt)
  if turboWhineLoop then
    local spindlePitch = curTurboAV * turboWhinePitchPerAV
    local spindleVolume = curTurboAV * turboWhineVolumePerAV
    local hissVolume = max(turboPressure * turboHissVolumePerPascal, 0)
    obj:setVolumePitch(turboHissLoop, hissVolume, 1)
    obj:setVolumePitch(turboWhineLoop, spindleVolume, spindlePitch)
  --print (spindlePitch) --for MK
  --print (spindleVolume) --for MK
  --print (hissVolume) --for MK
  end
end

local function update(dt)
  --calculate wastegate factor
  local gear = electrics.values.gearIndex or 1
  local wastegateStartPerGear = wastegateStart[gear] or maxWastegateStart
  local wastegateRangePerGear = wastegateRange[gear] or maxWastegateRange
  wastegateFactor = bovEngaged and 0 or wastegateSmoother:getUncapped(clamp((1 - (max(turboPressureRaw - wastegateStartPerGear, 0) / wastegateRangePerGear)), 0, 1), dt)
end

local function updateGFX(dt)
  --Some verification stuff
  if assignedEngine.engineDisabled then
    M.updateGFX = nop
    electrics.values.turboRpmRatio = 0
    electrics.values.turboBoost = 0
    turboPressure = 0
    turboPressureRaw = 0
    curTurboAV = 0
    return
  end

  --calculate an arbitary "turbo temp" that reflects the effects of oil and coolant cooling on the actual temps inside the turbo
  local turboTemp = assignedEngine.thermals.exhaustTemperature + (assignedEngine.thermals.coolantTemperature or 0) + assignedEngine.thermals.oilTemperature
  --calculate turbo damage using our turbo temp
  if turboTemp > turboDamageThresholdTemperature then
    frictionCoef = frictionCoef * (1 + (turboTemp - turboDamageThresholdTemperature) * 0.001 * dt)
    damageTracker.setDamage("engine", "turbochargerHot", true)
  else
    damageTracker.setDamage("engine", "turbochargerHot", false)
  end

  --open the BOV if we have very little load or if the engine load drops significantly
  local loadLow = assignedEngine.instantEngineLoad < bovOpenThreshold or assignedEngine.requestedThrottle <= 0
  local highLoadDrop = (lastEngineLoad - assignedEngine.instantEngineLoad) > bovOpenChangeThreshold
  local notInRevLimiter = assignedEngine.revLimiterWasActiveTimer > 0.1
  local ignitionNotCut = ignitionCutSmoother:getUncapped(assignedEngine.ignitionCutTime > 0 and 1 or 0, dt) <= 0
  local bovRequested = needsBov and (loadLow or highLoadDrop) and notInRevLimiter and ignitionNotCut
  bovEngaged = bovEnabled and bovRequested

  bovTimer = max(bovTimer - dt, 0)
  if bovRequested and needsBov and not lastBOVValue and bovTimer <= 0 then
    if bovEnabled then
      local relativePressure = min(max(turboPressure / maxTurboPressure, 0), 1)
      local bovVolume = relativePressure * bovSoundPressureCoef
      --print (bovVolume) -- pressure amount when triggering bov
      --print (bovSoundVolumeCoef) -- this should be a static value
      obj:setVolumePitchCT(bovSound, bovVolume, 1, bovSoundVolumeCoef, 0)
      obj:playSFX(bovSound)
    else
      local relativePressure = min(max(turboPressure / maxTurboPressure, 0), 1)
      local flutterVolume = relativePressure * flutterSoundPressureCoef
      obj:setVolumePitchCT(flutterSound, flutterVolume, 1, flutterSoundVolumeCoef, 0)
      obj:playSFX(flutterSound)
    end
    bovTimer = 0.5
  end

  local engAV = max(1, assignedEngine.outputAV1)
  local engAvRatio = min(engAV * invEngMaxAV, 1)

  --Torque on the turbo's axis
  local exhaustPower = (0.1 + assignedEngine.engineLoad * 0.8) * assignedEngine.throttle * assignedEngine.throttle * engAvRatio * (turbo.turboExhaustCurve[floor(assignedEngine.outputRPM)] or 1) * maxExhaustPower * dt
  local friction = frictionCoef * dt --simulate some friction and stuff there
  local backPressure = curTurboAV * curTurboAV * backPressureCoef * (bovEngaged and 0.4 or 1) * dt --back pressure from compressing the air
  local turboTorque = (exhaustPower * wastegateFactor) - backPressure - friction

  --calculate angular velocity
  curTurboAV = min(max((curTurboAV + dt * turboTorque * invTurboInertia), 0), maxTurboAV)

  local turboRPM = curTurboAV * avToRPM
  turboPressureRaw = assignedEngine.isStalled and 0 or ((turbo.turboPressureCurve[floor(turboRPM)] * psiToPascal) or turboPressure)
  turboPressure = pressureSmoother:getUncapped(turboPressureRaw, dt)

  if bovRequested then --if the BOV is supposed to be open and we have positive pressure, we don't actually have any pressure ;)
    turboPressure = 0
    pressureSmoother:getUncapped(turboPressure, dt)
  elseif lastBOVValue then
    if bovSound then
      obj:stopSFX(bovSound)
    end
    if flutterSound then
      obj:stopSFX(flutterSound)
    end
  end

  -- 1 psi = 6% more power
  -- 1 pascal = 0.00087% more power
  assignedEngine.forcedInductionCoef = assignedEngine.forcedInductionCoef * (1 + 0.0000087 * turboPressure * (turbo.turboEfficiencyCurve[floor(assignedEngine.outputRPM)] or 0))

  electrics.values[electricsRPMName] = turboRPM
  electricsSpinValue = electricsSpinValue + turboRPM * dt
  electrics.values[electricsSpinName] = (electricsSpinValue * electricsSpinCoef) % 360
  -- Update sounds
  electrics.values.turboRpmRatio = curTurboAV * invMaxTurboAV * 580
  electrics.values.turboBoost = turboPressure * invPascalToPSI

  lastEngineLoad = assignedEngine.instantEngineLoad
  lastBOVValue = bovRequested

  -- Update streams
  if streams.willSend("forcedInductionInfo") then
    forcedInductionInfoStream.rpm = curTurboAV * avToRPM
    forcedInductionInfoStream.coef = assignedEngine.forcedInductionCoef
    forcedInductionInfoStream.boost = turboPressure * 0.001
    forcedInductionInfoStream.exhaustPower = exhaustPower / dt
    forcedInductionInfoStream.backpressure = backPressure / dt
    forcedInductionInfoStream.bovEngaged = (bovEngaged and 1 or 0) * 10
    forcedInductionInfoStream.wastegateFactor = wastegateFactor * 10
    forcedInductionInfoStream.turboTemp = turboTemp

    gui.send("forcedInductionInfo", forcedInductionInfoStream)
  end
end

local function reset()
  curTurboAV = 0
  turboPressure = 0
  turboPressureRaw = 0
  bovEngaged = false
  lastBOVValue = true
  lastEngineLoad = 0
  wastegateFactor = 1
  bovTimer = 0
  electricsSpinValue = 0

  frictionCoef = turbo.frictionCoef or 0.01

  pressureSmoother:reset()
  wastegateSmoother:reset()
  ignitionCutSmoother:reset()

  damageTracker.setDamage("engine", "turbochargerHot", false)
end

local function init(device, jbeamData)
  turbo = jbeamData
  if turbo == nil then
    M.turboUpdate = nop
    return
  end

  assignedEngine = device

  --log("D", "Turbo", "Initializing turbo subsystem")

  curTurboAV = 0
  turboPressure = 0
  turboPressureRaw = 0
  bovEngaged = false
  lastBOVValue = true
  lastEngineLoad = 0
  wastegateFactor = 1
  bovTimer = 0

  maxTurboAV = 1

  -- add the turbo pressure curve
  -- define y PSI at x RPM
  local pressurePSIcount = #turbo.pressurePSI
  local tpoints = table.new(pressurePSIcount, 0)
  if turbo.pressurePSI then
    for i = 1, pressurePSIcount do
      local point = turbo.pressurePSI[i]
      tpoints[i] = {point[1], point[2]}
      --Get max turbine rpm
      maxTurboAV = max(point[1] * rpmToAV, maxTurboAV)
    end
  else
    log("E", "Turbo", "No turbocharger.pressurePSI table found!")
    return
  end
  turbo.turboPressureCurve = createCurve(tpoints, true)

  -- add the turbo exhaust curve
  -- simulate pressure factor going between the exhasut and the turbine
  --
  -- add the turbo efficiency curve
  -- simulate power coef per engine RPM
  -- Eg: Small turbos will be more efficient on engine low rpm than high rpm and vice versa
  local engineDefcount = #turbo.engineDef
  local tepoints = table.new(engineDefcount, 0)
  local tipoints = table.new(engineDefcount, 0)
  if turbo.engineDef then
    for i = 1, engineDefcount do
      local point = turbo.engineDef[i]
      tepoints[i] = {point[1], point[2]}
      tipoints[i] = {point[1], min(point[3], 1)}
    end
  else
    log("E", "Turbo", "No turbocharger.engineDef curve found!")
    return
  end
  turbo.turboExhaustCurve = createCurve(tipoints)
  turbo.turboEfficiencyCurve = createCurve(tepoints)

  turboInertiaFactor = (turbo.inertia * 100) or 1

  wastegateStart = {}
  maxWastegateStart = 0
  maxWastegateLimit = 1
  if type(turbo.wastegateStart) == "table" then
    for k, v in pairs(turbo.wastegateStart) do
      wastegateStart[k] = v * psiToPascal
      maxWastegateStart = wastegateStart[k]
    end
  else
    wastegateStart[1] = (turbo.wastegateStart or 0) * psiToPascal
    maxWastegateStart = wastegateStart[1]
  end

  wastegateLimit = {}
  if type(turbo.wastegateLimit) == "table" then
    for k, v in pairs(turbo.wastegateLimit) do
      wastegateLimit[k] = v * psiToPascal
      maxWastegateLimit = wastegateLimit[k]
    end
  else
    wastegateLimit[1] = (turbo.wastegateLimit or 0) * psiToPascal
    maxWastegateLimit = wastegateLimit[1]
  end

  wastegateRange = {}
  maxWastegateRange = 1
  for k, v in pairs(wastegateStart) do
    local start = v
    local limit = wastegateLimit[k] or maxWastegateLimit
    wastegateRange[k] = limit - start
    maxWastegateRange = wastegateRange[k]
  end

  maxExhaustPower = turbo.maxExhaustPower or 1

  backPressureCoef = turbo.backPressureCoef or 0.0005
  frictionCoef = turbo.frictionCoef or 0.01

  turboDamageThresholdTemperature = turbo.damageThresholdTemperature or 1000

  electricsRPMName = turbo.electricsRPMName or "turboRPM"
  electricsSpinName = turbo.electricsSpinName or "turboSpin"
  electricsSpinCoef = turbo.electricsSpinCoef or 0.1
  electricsSpinValue = 0

  --optimizations:
  invMaxTurboAV = 1 / maxTurboAV
  invEngMaxAV = 1 / ((assignedEngine.maxRPM or 8000) * rpmToAV)
  invTurboInertia = 1 / (0.000003 * turboInertiaFactor * 2.5)
  pressureSmoother = newTemporalSmoothing(100 * psiToPascal, (turbo.pressureRatePSI or 30) * psiToPascal)
  wastegateSmoother = newTemporalSmoothing(50, 50)
  ignitionCutSmoother = newTemporalSmoothing(1, 10)
  bovEnabled = (turbo.bovEnabled == nil or turbo.bovEnabled)
  bovOpenThreshold = turbo.bovOpenThreshold or 0.05
  bovOpenChangeThreshold = turbo.bovOpenChangeThreshold or 0.3
  needsBov = assignedEngine.requiredEnergyType ~= "diesel"
  maxTurboPressure = maxWastegateStart * invPascalToPSI * (1 + (maxWastegateRange * invPascalToPSI) * 0.01) * psiToPascal

  forcedInductionInfoStream.friction = frictionCoef
  forcedInductionInfoStream.maxBoost = maxWastegateLimit * 0.001

  damageTracker.setDamage("engine", "turbochargerHot", false)

  M.updateGFX = updateGFX
  M.update = update
  M.updateSounds = updateSounds
end

local function initSounds()
  local turboHissLoopFilename = turbo.hissLoopEvent or "event:>Vehicle>Forced_Induction>Turbo_01>turbo_hiss"
  turboHissLoop = obj:createSFXSource(turboHissLoopFilename, "AudioDefaultLoop3D", "TurbochargerWhine", assignedEngine.engineNodeID)
  local turboWhineLoopFilename = turbo.whineLoopEvent or "event:>Vehicle>Forced_Induction>Turbo_01>turbo_spin"
  turboWhineLoop = obj:createSFXSource(turboWhineLoopFilename, "AudioDefaultLoop3D", "TurbochargerWhine", assignedEngine.engineNodeID)

  turboWhinePitchPerAV = (turbo.whinePitchPer10kRPM or 0.05) * 0.01 * rpmToAV
  turboWhineVolumePerAV = (turbo.whineVolumePer10kRPM or 0.04) * 0.01 * rpmToAV
  turboHissVolumePerPascal = (turbo.hissVolumePerPSI or 0.04) * invPascalToPSI

  bovSoundVolumeCoef = turbo.bovSoundVolumeCoef or 0.3
  bovSoundPressureCoef = turbo.bovSoundPressureCoef or 0.3
  local bovSoundFileName = turbo.bovSoundFileName or "event:>Vehicle>Forced_Induction>Turbo_01>turbo_bov"
  bovSound = obj:createSFXSource(bovSoundFileName, "AudioDefaultLoop3D", "Bov", assignedEngine.engineNodeID)

  flutterSoundVolumeCoef = turbo.flutterSoundVolumeCoef or 0.3
  flutterSoundPressureCoef = turbo.flutterSoundPressureCoef or 0.3
  local flutterSoundFileName = turbo.flutterSoundFileName or "event:>Vehicle>Forced_Induction>Turbo_02>turbo_bov"
  flutterSound = obj:createSFXSource(flutterSoundFileName, "AudioDefaultLoop3D", "Flutter", assignedEngine.engineNodeID)

  obj:setVolume(bovSound, 0)
  obj:setVolume(flutterSound, 0)
  obj:stopSFX(bovSound)
  obj:stopSFX(flutterSound)
end

local function resetSounds()
end

local function getTorqueCoefs()
  local coefs = {}
  local lastPressure = 0
  --we can't know the actual wastegate limit for sure since it's a feedback loop with the pressure, so we just estimate it.
  --lower wastegate ranges lead to more accurate results.
  local estimatedWastegateLimit = maxWastegateStart * invPascalToPSI * (1 + (maxWastegateRange * invPascalToPSI) * 0.03)

  for k, _ in pairs(assignedEngine.torqueCurve) do
    if type(k) == "number" and k < assignedEngine.maxRPM then
      local rpm = floor(k)
      local turboAV = sqrt(max((0.9 * rpm * rpmToAV * invEngMaxAV * (turbo.turboExhaustCurve[rpm] or 1) * maxExhaustPower - frictionCoef), 0) / backPressureCoef)
      turboAV = min(turboAV, maxTurboAV)
      local turboRPM = floor(turboAV * avToRPM)
      local pressure = turbo.turboPressureCurve[turboRPM] or 0 --pressure without respecting the wastegate
      local actualPressure = min(pressure, estimatedWastegateLimit) --limit the pressure to what the wastegate allows
      if actualPressure > lastPressure then
        lastPressure = actualPressure
      end

      coefs[k + 1] = (1 + 0.0000087 * actualPressure * psiToPascal * (turbo.turboEfficiencyCurve[rpm] or 0))
    end
  end

  return coefs
end

-- public interface
M.init = init
M.initSounds = initSounds
M.resetSounds = resetSounds
M.updateSounds = nop
M.reset = reset
M.updateGFX = nop
M.update = nop
M.getTorqueCoefs = getTorqueCoefs

return M
