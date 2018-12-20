-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min
local abs = math.abs

local rpmToAV = 0.10471971768
local avToRPM = 9.5493
local psiToPascal = 6894.757293178
local pascalToPSI = 1 / psiToPascal

M.isExisting = true

local jbeamData = nil

local forcedInductionInfoStream = {
  rpm = 0,
  coef = 1,
  boost = 0,
  maxBoost = 0,
  pulses = 0,
  loss = 0
}

local dtSum = 0
local twoPi = 2 * math.pi

local assignedEngine = nil

local pressureCurve = {}
local boostControllerCurve = {}
local pressureSmoother = nil
local pulseCoefModifier = 1
local pulseFreqCoef = 0

local blowerRatio = 1
local maxPressure = 0
local blowerPressure = 0
local lastPressure = 0 --pressure at the highest defined blower RPM

local clutchEngageRPM = 0
local invClutchEngageRange = 0
local clutchDisengageRPM = 0
local invClutchDisengageRange = 0
local crankLossPerRPM = 0

local blowerRPM = 0
local blowerAV = 0

local whineLoop = nil
local whinePitchPerAV
local whineVolumePerPascal
local fadeInStartRPM = 1200
local fadeInEndRPM = 2200

local efficiencyCurveRootsTwisted = {b1 = -0.35, b2 = 0, b3 = 1}
local efficiencyCurveRootsNonTwisted = {b1 = -0.55, b2 = 0, b3 = 1}
local efficiencyCurveScrews = {b1 = 0.3, b2 = 0, b3 = 0.7}
local efficiencyCurveCentrifugal = {b1 = 0.6, b2 = 0, b3 = 0.45}

local function updateSounds(dt)
  local volumeFadeIn = min(max((blowerRPM - fadeInStartRPM) / (fadeInEndRPM - fadeInStartRPM), 0), 1)
  local volume = min(max(abs(blowerPressure) * whineVolumePerPascal, 0), 15) * volumeFadeIn
  local pitch = max(blowerAV * whinePitchPerAV, 0)
  obj:setVolumePitch(whineLoop, volume, pitch)
end

local function updateGFX(dt)
  -- Some verification stuff
  if assignedEngine.engineDisabled then
    M.updateGFX = nop
    return
  end

  local engAV = max(assignedEngine.outputAV1, 0)
  local currentThrottle = electrics.values.throttle
  dtSum = dtSum + dt
  if dtSum >= twoPi then
    dtSum = dtSum - twoPi
  end

  local engage = min(max((engAV * avToRPM - clutchEngageRPM) * invClutchEngageRange, 0), 1)
  local disengage = min(max(-(engAV * avToRPM - clutchDisengageRPM) * invClutchDisengageRange + 1, 0), 1)
  local clutchRatio = min(engage, disengage)
  blowerAV = engAV * blowerRatio * clutchRatio
  blowerRPM = blowerAV * avToRPM

  -- calc pulsations
  local pulseFreq = pulseFreqCoef * blowerAV --pulse freq == number of lobes * rpm / 60
  local pulseCoef = math.sin(pulseFreq * dtSum) --make it rotate
  pulseCoef = ((1 + pulseCoef) * 0.5) -- map [-1,1] from sin to [0,1]
  pulseCoef = pulseCoefModifier + ((1 - pulseCoefModifier) * pulseCoef) -- map the final value to [pulseCoefModifier, 1]

  if pulseCoef > 0.9 then
    pulseCoef = 1
  end --add some stability to the output

  blowerPressure = 0
  -- Bypass valve
  if not (currentThrottle < 0.01) then --with very low throttle the SC is bypassed
    local boostControllerCoef = boostControllerCurve[math.floor(currentThrottle * 100)] or 1 --get the throttle vs max boost coef
    local rawPressure = (pressureCurve[math.floor(blowerRPM)] or lastPressure) * pulseCoef --calculate current pressure inlcuding pulse oscillations
    blowerPressure = (rawPressure * psiToPascal) * boostControllerCoef --apply throttle coef
    blowerPressure = pressureSmoother:getUncapped(blowerPressure, dt) --and get the final pressure
  else
    blowerPressure = pressureSmoother:getUncapped(0, dt)
  end

  local lostTorqueCoef = crankLossPerRPM * blowerRPM -- calculate percentage torque loss
  assignedEngine.forcedInductionCoef = assignedEngine.forcedInductionCoef * max(1 + (0.0000087 * blowerPressure) - lostTorqueCoef, 0) --convert pressure to "added" torque and remove some of it again due to losses

  -- Update streams
  if streams.willSend("forcedInductionInfo") then
    forcedInductionInfoStream.rpm = blowerRPM
    forcedInductionInfoStream.coef = assignedEngine.forcedInductionCoef
    forcedInductionInfoStream.boost = blowerPressure * 0.001
    forcedInductionInfoStream.pulses = pulseCoef
    forcedInductionInfoStream.loss = lostTorqueCoef
    gui.send("forcedInductionInfo", forcedInductionInfoStream)
  end
end

local function resetSounds()
end

local function initSounds()
  M.updateSounds = nop
  local whineSample = jbeamData.whineLoopEvent or "event:>Vehicle>Forced_Induction>Supercharger_01>supercharger"
  whineLoop = obj:createSFXSource(whineSample, "AudioDefaultLoop3D", "superchargerWhine", assignedEngine.engineNodeID)

  whinePitchPerAV = (jbeamData.whinePitchPer10kRPM or 0.7) * 0.01 * rpmToAV
  whineVolumePerPascal = (jbeamData.whineVolumePerPSI or 0.01) * pascalToPSI --note this will be almost silent by default

  if whineLoop then
    M.updateSounds = updateSounds
  end
end

local function reset()
  pressureSmoother:reset()
  lastPressure = 0
end

local function init(device, data)
  jbeamData = data

  if jbeamData == nil then
    M.updateGFX = nop
    return
  end

  assignedEngine = device

  blowerRatio = jbeamData.gearRatio or 1
  local maxBlowerRPM = math.ceil(assignedEngine.maxRPM * blowerRatio)

  crankLossPerRPM = (jbeamData.crankLossPer1kRPM or 5) * 0.001

  pulseCoefModifier = 1
  clutchEngageRPM = jbeamData.clutchEngageRPM or 1000
  invClutchEngageRange = 1 / (jbeamData.clutchEngageRange or clutchEngageRPM * 0.2)
  clutchDisengageRPM = jbeamData.clutchDisengageRPM or assignedEngine.maxRPM * 2
  invClutchDisengageRange = 1 / (jbeamData.clutchDisengageRange or clutchDisengageRPM * 0.05)

  local hasTwistedLobes = jbeamData.twistedLobes or false --twisted lobes increase the efficiency at high RPMs for roots rotors
  local numberLobes = min(max(jbeamData.lobes or 3, 2), 4) --the more lobes, the smoother the output is (less pulsation)

  local efficiencyCurve
  local sctype = string.lower(jbeamData.type)

  if sctype == "screws" then
    if numberLobes < 3 then
      log("W", "Supercharger", "Screw type supercharger needs at least 3 lobes")
      numberLobes = 3
    end

    pulseCoefModifier = 0.98 --very little pulsing with screws
    efficiencyCurve = efficiencyCurveScrews
  elseif sctype == "roots" then
    if hasTwistedLobes then
      pulseCoefModifier = 0.95 --improved pulsing with twisted lobes
      efficiencyCurve = efficiencyCurveRootsTwisted
    else
      pulseCoefModifier = 0.9 --quite a bit of pulsing with non twisted lobes
      efficiencyCurve = efficiencyCurveRootsNonTwisted
    end
  elseif sctype == "centrifugal" then
    --typeSound = "turboRpmRatio"
    --soundRpmCoef = 0.45

    numberLobes = 0
    pulseCoefModifier = 1 --no pulsing for the turbo style blower
    efficiencyCurve = efficiencyCurveCentrifugal
  else
    log("E", "Supercharger", "Unknown supercharger type: " .. sctype)
    return
  end

  pulseCoefModifier = jbeamData.pulseCoefModifier or pulseCoefModifier
  pulseFreqCoef = numberLobes * avToRPM * 0.0166

  pressureSmoother = newTemporalSmoothing((jbeamData.pressureRatePSI or 50) * psiToPascal)

  --generate the pressure curve via the pressure slope and the per-type efficiency curve
  local pressurePSIPerRPM = jbeamData.pressurePSIPer1kRPM * 0.001
  local pressureCurveTemp = table.new(maxBlowerRPM + 1, 0)
  for i = 0, maxBlowerRPM, 1 do
    local relativeRPM = i / maxBlowerRPM
    local pressureCoef = efficiencyCurve.b1 * relativeRPM * relativeRPM + efficiencyCurve.b2 * relativeRPM + efficiencyCurve.b3
    local pressure = max(pressureCoef * pressurePSIPerRPM * i, 0)
    --print(pressure)
    maxPressure = max(maxPressure, pressure)
    pressureCurveTemp[i + 1] = {i, pressure}
  end

  pressureCurve = createCurve(pressureCurveTemp)
  lastPressure = pressureCurve[maxBlowerRPM]

  -- Boost Controller a.k.a Boost Control Actuator
  -- Used to limit boost at X throttle
  boostControllerCurve = {}
  local tipoints = {}
  local tipointsidx = 1
  if jbeamData.boostController then
    for k, v in pairs(jbeamData.boostController) do
      if type(k) == "number" then
        tipoints[tipointsidx] = {v[1], v[2]}
        tipointsidx = tipointsidx + 1
      end
    end
  else
    log("E", "Supercharger", "No supercharger.boostController curve found!")
    return
  end
  boostControllerCurve = createCurve(tipoints)

  forcedInductionInfoStream.maxBoost = maxPressure * 6.89475

  M.updateGFX = updateGFX
end

local function getTorqueCoefs()
  local coefs = {}

  for k, _ in pairs(assignedEngine.torqueCurve) do
    if type(k) == "number" and k < assignedEngine.maxRPM then
      local engage = min(max((k - clutchEngageRPM) * invClutchEngageRange, 0), 1) --min 1000, range 100
      local disengage = min(max(-(k - clutchDisengageRPM) * invClutchDisengageRange + 1, 0), 1)
      local clutchRatio = min(engage, disengage)
      local currentBlowerRPM = k * blowerRatio * clutchRatio
      local pressure = pressureCurve[math.floor(currentBlowerRPM)] or 0

      coefs[k + 1] = (1 + (0.0000087 * pressure * psiToPascal) - (crankLossPerRPM * currentBlowerRPM))
    end
  end

  return coefs
end

-- public interface
M.init = init
M.reset = reset
M.initSounds = initSounds
M.resetSounds = resetSounds
M.updateSounds = nop
M.updateGFX = nop
M.getTorqueCoefs = getTorqueCoefs

return M
