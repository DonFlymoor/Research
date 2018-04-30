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

--Turbo related stuff
local curTurboAV = 0
local maxTurboAV = 1
local invMaxTurboAV = 1
local invTurboInertia = 0
local turboInertiaFactor = 1
local turboPressure = 0
local maxTurboPressure = 1
local maxExhaustPower = 1
local backPressureCoef = 0
local frictionCoef = 0
local turboWhineLoop = nil
local turboWhinePitchPerAV = 0
local turboWhineVolumePerAV = 0

-- Wastegate
local wastegateStart = 0
local wastegateLimit = 0
local wastegateFactor = 1
local wastegateRange = 1

-- blow off valve
local bovEnabled = true
local bovEngaged = false
local lastBOVValue = false
local lastEngineLoad = 0
local bovOpenChangeThreshold = 0
local bovOpenThreshold = 0
local bovSoundVolumeCoef = 1
local bovSoundPitchCoef = 1
local bovSoundFileName = nil
local bovTimer = 0
local ignitionCutSmoother = nil

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
    local turboVolume = curTurboAV * turboWhineVolumePerAV
    local turboPitch = curTurboAV * turboWhinePitchPerAV
    obj:setVolumePitch(turboWhineLoop, turboVolume, turboPitch)
  end
end

local function update(dt)
  --calculate wastegate factor
  wastegateFactor = bovEngaged and 0 or wastegateSmoother:getUncapped(clamp((1 - (max(turboPressure - wastegateStart, 0) / wastegateRange)), 0, 1), dt)
end

local function updateGFX(dt)
  --Some verification stuff
  if assignedEngine.engineDisabled then
    M.updateGFX = nop
    electrics.values.turboRpmRatio = 0
    electrics.values.turboBoost = 0
    turboPressure = 0
    curTurboAV = 0
    return
  end

  --calculate an arbitary "turbo temp" that reflects the effects of oil and coolant cooling on the actual temps inside the turbo
  local turboTemp = assignedEngine.thermals.exhaustTemperature + assignedEngine.thermals.coolantTemperature + assignedEngine.thermals.oilTemperature
  --calculate turbo damage using our turbo temp
  if turboTemp > turboDamageThresholdTemperature then
    frictionCoef = frictionCoef * (1 + (turboTemp - turboDamageThresholdTemperature) * 0.001 * dt)
    damageTracker.setDamage("engine", "turbochargerHot", true)
  else
    damageTracker.setDamage("engine", "turbochargerHot", false)
  end

  --open the BOV if we have very little load or if the engine load drops significantly
  local loadLow = assignedEngine.instantEngineLoad < bovOpenThreshold
  local highLoadDrop = (lastEngineLoad - assignedEngine.instantEngineLoad) > bovOpenChangeThreshold
  local notInRevLimiter = assignedEngine.revLimiterWasActiveTimer > 0.1
  local notExternallyThrottled = (electrics.values[assignedEngine.electricsThrottleFactorName] or 1) >= 1
  local ignitionNotCut = ignitionCutSmoother:getUncapped(assignedEngine.ignitionCutTime > 0 and 1 or 0, dt) <= 0
  bovEngaged = bovEnabled and (loadLow or highLoadDrop) and notInRevLimiter and notExternallyThrottled and ignitionNotCut

  bovTimer = max(bovTimer - dt, 0)
  if bovEngaged and not lastBOVValue and bovTimer <= 0 then
    local relativePressure = min(max(turboPressure / maxTurboPressure, 0), 1)
    local bovVolume = relativePressure * relativePressure * relativePressure * bovSoundVolumeCoef
    obj:playSFXOnce(bovSoundFileName, assignedEngine.engineNodeID, bovVolume, bovSoundPitchCoef)
    bovTimer = 0.5
  end

  local engAV = max(1, assignedEngine.outputAV1)
  local engAvRatio = min(engAV * invEngMaxAV, 1)

  --Torque on the turbo's axis
  local exhaustPower = (0.1 + assignedEngine.engineLoad * 0.8) * assignedEngine.throttle * assignedEngine.throttle * engAvRatio * (turbo.turboExhaustCurve[floor(assignedEngine.outputRPM)] or 1) * maxExhaustPower * dt
  local friction = frictionCoef * dt  --simulate some friction and stuff there
  local backPressure = curTurboAV * curTurboAV * backPressureCoef * (bovEngaged and 0.4 or 1) * dt  --back pressure from compressing the air
  local turboTorque = (exhaustPower * wastegateFactor) - backPressure - friction

  --calculate angular velocity
  curTurboAV = min(max((curTurboAV + dt * turboTorque * invTurboInertia), 0), maxTurboAV)

  local turboRPM = curTurboAV * avToRPM
  local rawPressure = assignedEngine.isStalled and 0 or ((turbo.turboPressureCurve[floor(turboRPM)] * psiToPascal) or turboPressure)
  turboPressure = pressureSmoother:getUncapped(rawPressure, dt)

  if bovEngaged then --if the BOV is supposed to be open and we have positive pressure, we don't actually have any pressure ;)
    turboPressure = 0
    pressureSmoother:getUncapped(turboPressure, dt)
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
  lastBOVValue = bovEngaged

  -- Update streams
  if streams.willSend("forcedInductionInfo") then
    gui.send("forcedInductionInfo", {
        rpm = curTurboAV * avToRPM,
        coef = assignedEngine.forcedInductionCoef,
        --send kPa to UI
        boost = turboPressure * 0.001,
        maxBoost = wastegateLimit * 0.001,
        --specific stuff
        exhaustPower = exhaustPower / dt,
        friction = frictionCoef,
        backpressure = backPressure / dt,
        bovEngaged = (bovEngaged and 1 or 0) * 10,
        wastegateFactor = wastegateFactor * 10,
        turboTemp = turboTemp,
      })
  end
end

local function reset()
  curTurboAV = 0
  turboPressure = 0
  bovEngaged = false
  lastBOVValue = false
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

local function init(device, data)
  turbo = data
  if turbo == nil then
    M.turboUpdate = nop
    return
  end

  assignedEngine = device

  --log("D", "Turbo", "Initializing turbo subsystem")

  curTurboAV = 0
  turboPressure = 0
  bovEngaged = false
  lastBOVValue = false
  lastEngineLoad = 0
  wastegateFactor = 1
  bovTimer = 0

  maxTurboAV = 1

  -- add the turbo pressure curve
  -- define y PSI at x RPM
  local pressurePSIcount = #turbo.pressurePSI
  local tpoints = table.new(pressurePSIcount, 0)
  if turbo.pressurePSI then
    for i=1, pressurePSIcount do
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
    for i=1, engineDefcount do
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

  wastegateStart = turbo.wastegateStart * psiToPascal or 0
  wastegateLimit = max(turbo.wastegateLimit * psiToPascal or 0, wastegateStart)

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
  wastegateRange = wastegateLimit - wastegateStart
  pressureSmoother = newTemporalSmoothing(100 * psiToPascal, (turbo.pressureRatePSI or 30) * psiToPascal)
  wastegateSmoother = newTemporalSmoothing(5, 0.4)
  ignitionCutSmoother = newTemporalSmoothing(1, 10)
  bovEnabled = (turbo.bovEnabled == nil or turbo.bovEnabled)
  bovOpenThreshold = turbo.bovOpenThreshold or 0.05
  bovOpenChangeThreshold = turbo.bovOpenChangeThreshold or 0.3
  maxTurboPressure = wastegateStart * invPascalToPSI * (1 + (wastegateRange * invPascalToPSI) * 0.01) * psiToPascal

  damageTracker.setDamage("engine", "turbochargerHot", false)

  M.updateGFX = updateGFX
  M.update = update
  M.updateSounds = updateSounds
end

local function initSounds()
  --local turboWhineLoopFilename = --"event:>Vehicle>Forced_Induction>Turbo_02"
  local turboWhineLoopFilename = turbo.turboLoopName or "event:>Vehicle>Forced_Induction>Turbo_original"

  turboWhineLoop = obj:createSFXSource(turboWhineLoopFilename, "AudioDefaultLoop3D", "TurbochargerWhine", assignedEngine.engineNodeID)

  turboWhinePitchPerAV = (turbo.pitchPer10kRPM or 0.095) * 0.01 * rpmToAV
  turboWhineVolumePerAV = (turbo.volumePer10kRPM or 0.04) * 0.01 * rpmToAV

  bovSoundVolumeCoef = min(max(turbo.bovSoundVolumeCoef or 0.5, 0), 1)
  --bovSoundFileName = turbo.bovSoundFileName or "event:>Vehicle>Bov_04"
  bovSoundFileName = turbo.bovSoundFileName or "event:>Vehicle>Forced_Induction>Bov_original"
  bovSoundPitchCoef = turbo.bovSoundPitchCoef or 1
end

local function resetSounds()

end

local function getTorqueCoefs()
  local coefs = {}
  local lastPressure = 0
  local maxAV = 0 --actual estimated max av of turbo while running
  --we can't know the actual wastegate limit for sure since it's a feedback loop with the pressure, so we just estimate it.
  --lower wastegate ranges lead to more accurate results.
  local estimatedWastegateLimit = wastegateStart * invPascalToPSI * (1 + (wastegateRange * invPascalToPSI) * 0.03)

  for k,_ in pairs(assignedEngine.torqueCurve) do
    if type(k) == "number" and k < assignedEngine.maxRPM then
      local rpm = floor(k)
      local turboAV = sqrt(max((0.9 * rpm * rpmToAV * invEngMaxAV * (turbo.turboExhaustCurve[rpm] or 1) * maxExhaustPower - frictionCoef), 0) / backPressureCoef)
      turboAV = min(turboAV, maxTurboAV)
      local turboRPM = floor(turboAV * avToRPM)
      local pressure = turbo.turboPressureCurve[turboRPM] or 0 --pressure without respecting the wastegate
      local actualPressure = min(pressure, estimatedWastegateLimit) --limit the pressure to what the wastegate allows
      if actualPressure > lastPressure then
        maxAV = turboAV
        lastPressure = actualPressure
      end

      coefs[k + 1] = (1 + 0.0000087 * actualPressure * psiToPascal * (turbo.turboEfficiencyCurve[rpm] or 0))
    end
  end

  return coefs
end

-- public interface
M.init          = init
M.initSounds    = initSounds
M.resetSounds   = resetSounds
M.updateSounds  = nop
M.reset         = reset
M.updateGFX     = nop
M.update        = nop
M.getTorqueCoefs = getTorqueCoefs

return M