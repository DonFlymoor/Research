-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local min, max = math.min, math.max
local M = {}

M.enableFFB = true
M.wheelFFBForceCoef = 400 -- regular force coef (at speed)
M.wheelFFBForceCoefLowSpeed = 400 -- force coef used at parking speeds
M.wheelFFBForceCoefCurrent = M.wheelFFBForceCoefLowSpeed -- updated over time depending on speed (start at parking speed)
M.wheelPowerSteeringCoef = 1
M.wheelFFBForceLimit = 2 -- The FFB steady force limits (in Newton)
M.wheelFFBSmoothing = 100 -- low freq
M.wheelFFBSmoothingHF = 50 -- high freq

M.hydros = {}
local hydroCount = 0
M.forceAtWheel = 0
M.forceAtDriver = 0
M.curForceLimit = 0

local vehicleFFBForceCoef = 1
local responseCurve = 0
local responseCorrected = false
local FFBsmooth = newExponentialSmoothing(M.wheelFFBSmoothing)
local FFBHydros = {}
local FFBRest = {}
local FFBRestCount = 0
local FFBHydrosExist = false
local FFBID    = -1 -- >=0 are valid IDs
local wheelpos = 0
local curForceLimitSmoother = newTemporalSmoothingNonLinear(10) -- prevent spikes when resetting vehicle (and ideally also when window focus is lost/gained)
local FFBperiodms = 0 -- how small period the steering wheel drivers can cope with, before they crash and burn
local lastDriverUpdate = 0 -- last time we sent an update to the drivers
local hp = HighPerfTimer()
local FFmax = 10
local FFstep = FFmax / 256
local action = "steering"
local ffbSpeedFast = 10 / 3.6

local steeringHydro = nil

local function toInputSpace(h, state)
  if state > h.center then
    return (state - h.center) * h.invMultOut
  else
    return (state - h.center) * h.invMultIn
  end
end

local function FFquantum(f)
  return math.floor(f/FFstep)
end

-- process the response correction curve that getDriverForce will use. happens only once
function processResponseCurve(rCurve)
  if tableSize(rCurve) < 2 then
    log("W", "", "FFB response functionality disabled due to invalid curve table size: "..dumps(rCurve))
    responseCorrected = false
    return
  end

  -- find table range (for later normalization)
  local maxx = 0
  local maxy = 0
  for _,p in ipairs(rCurve) do
    if p[1] > maxx then maxx = p[1] end
    if p[2] > maxy then maxy = p[2] end
  end
  if maxx == 0 or maxy == 0 then
    log("W", "", "FFB response functionality disabled due to flat curve: "..dumps(rCurve))
    responseCorrected = false
    return
  end

  -- normalize table, from 0..N to 0..1
  table.insert(rCurve, 1, {0,0})
  for i, p in pairs(rCurve) do
    p[1] = p[1]/maxx
    p[2] = p[2]/maxy
  end

  -- convert into strictly increasing values. this also removes initial force deadzone, and rectifies any ending downslope
  local result = { {1,1} }
  for i=tableSize(rCurve),1,-1 do
    if rCurve[i][1] < result[1][1] and
    rCurve[i][2] < result[1][2]
    then
      table.insert(result, 1, rCurve[i])
    end
  end

  if tableSize(result) < 2 then
    log("W", "", "FFB response functionality disabled due to invalid normalized curve: "..dumps(result))
    responseCorrected = false
    return
  end
  return result
end

-- use response correction table to figure out what value to feed the drivers with
local function getDriverForce(force)
  if not responseCorrected then return force end

  local normForce = math.abs(force) / FFmax
  local prev = {0,0}
  local nxt = nil
  -- find current section (previous and next datapoint) in response curve
  for i = 1, #responseCurve do
    nxt = responseCurve[i]
    if nxt[2] > normForce then break end
    if nxt[2] == 1 then break end
    prev = nxt
  end
  -- map from desired wheel force, to necessary driver force, after taking into account hardware response
  local normResult = prev[1] + (normForce - prev[2]) * ((nxt[1] - prev[1]) / (nxt[2] - prev[2]))
  return fsign(force) * normResult * FFmax
end

local function FFBcalc(wheelDispl)
  local lastForce = M.forceAtWheel
  M.forceAtWheel = M.wheelFFBForceCoefCurrent * vehicleFFBForceCoef * wheelDispl * M.wheelPowerSteeringCoef

  -- TODO: why check for ffb and controller presence (steering wheel hardware) this late, instead of at the beginning of function?
  -- TODO: or better yet, remove this check, and move FFBCalc() call to inside the hydros calculation in update(dtSim) function?
  if FFBID >= 0 and playerInfo.anyPlayerSeated then
    -- compute the force that should be output by (and measured at) the steering wheel hardware

    -- filter 'huge' spikes from going into the smoother; otherwise, it'll take a while to come back from that far away (in later calls to FFBsmooth:get)
    -- we use a multiplier value of 10; this way the return value of :get() won't be overly smoothed when driving on the limit, i.e. approaching the limit of ffb, i.e. near curForceLimit and towards it
    -- TODO: instead, maybe we can re-set the smoother when we've gone over the limit and use getUncapped? (just like the fix for lag in skidding sound smoothers)
    -- reminder: FFBsmooth must run at a constant rate, such as 2KHz (replace with a temporal smoother otherwise)
    local limit = 10 * M.curForceLimit
    M.forceAtWheel = FFBsmooth:getWindow(math.max(math.min(M.forceAtWheel, limit), -limit),
      sign(M.forceAtWheel) ~= sign(lastForce) and M.wheelFFBSmoothingHF or M.wheelFFBSmoothing)

    -- drivers will struggle if sending too many updates per wall clock second, so we throttle them here (according to FFBperiodms)
    local now = hp:stop() -- important, this must be wall clock time, not sim time (steering wheel drivers don't care about sim time)
    -- TODO: FFBperidoms is literally the avg time it takes for udpates to run when drivers are overloaded, which we assume is close to the max rate the drivers can handle. is that a correct assumption in all cases?
    -- TODO: also, should we add some wiggle room here? maybe use FFBperiodms*1.5 or something like that instead?
    if (now - lastDriverUpdate) > FFBperiodms then

      -- limit how much torque is output at the wheel (following the binding configuration of curForceLimit)
      local forceAtWheel = sign(M.forceAtWheel) * math.min(math.abs(M.forceAtWheel), M.curForceLimit)

      -- figure out the fake number that the drivers want to hear, in order to really output the desired torque at the wheel
      local newForceAtDriver = getDriverForce(forceAtWheel)

      -- send force only if the driver will see any difference (i.e. skip when still in the same driver ffb quantum step as last time)
      if FFquantum(newForceAtDriver) ~= FFquantum(M.forceAtDriver) then
        -- send update to driver
        obj:sendForceFeedback(FFBID, newForceAtDriver)
        lastDriverUpdate = now

        -- remember data for future calculations
        M.forceAtWheel = forceAtWheel
        M.forceAtDriver = newForceAtDriver
      end
    end
  end
end

local function updateGFX(dt) -- dt in seconds
  -- update the source command value
  for i = 1, hydroCount do
    local h = M.hydros[i]
    h.cmd = min(max(electrics.values[h.inputSource] or 0, h.inputInLimit), h.inputOutLimit) * h.inputFactor

    if h.cmd ~= h.inputCenter or h.analogue == true then
      h._inrate = h.inRate
      h._outrate = h.outRate
    else
      -- set autocenter rate
      h._inrate = h.autoCenterRate
      h._outrate = h.autoCenterRate
    end

    if h.cmd >= h.inputCenter then
      h.cmd = h.cOut + h.cmd * h.multOut
    else
      h.cmd = h.cIn + h.cmd * h.multIn
    end

    h.hydroDirState = toInputSpace(h, h.state)
  end

  if FFBHydrosExist then
    wheelpos = electrics.values.steering_input or 0
    M.curForceLimit = curForceLimitSmoother:getWithRate(M.wheelFFBForceLimit, dt, 10)
    local speed = electrics.values.airspeed
    speed = speed < 0.25 and 0 or speed

    if speed < ffbSpeedFast and math.abs(electrics.values.wheelspeed) < ffbSpeedFast then
      local minForce = M.wheelFFBForceCoefLowSpeed
      M.wheelFFBForceCoefCurrent = minForce + speed * (M.wheelFFBForceCoef-minForce) / ffbSpeedFast -- approach maxForce as we get closer to the fast speed threshold
    else
      M.wheelFFBForceCoefCurrent = M.wheelFFBForceCoef
    end
  end

  -- update electrics steering
  if steeringHydro then
    electrics.values.steering = -steeringHydro.hydroDirState * v.data.input.steeringWheelLock
  end
end

local function update(dtSim)
  -- state: the state of the hydro from -1 to 1
  -- cmd the input value
  -- note: state is scaled to the ratio as the last step
  local hydros = M.hydros
  local hcount = hydroCount

  if FFBHydrosExist then
    local FFBhpos = 0
    local FFBhcount = 0

    if FFBID >= 0 and playerInfo.anyPlayerSeated then
      hydros = FFBRest
      hcount = FFBRestCount

      for i = 1, #FFBHydros do
        local h = FFBHydros[i]

        if h.cmd ~= h.state then -- elide expensive core call
          if h.cmd < h.state then
            h.state = max(h.state - dtSim * h._inrate, h.cmd)
          else
            h.state = min(h.state + dtSim * h._outrate, h.cmd)
          end
          obj:setBeamLengthRefRatio(h.bcid, h.state)
        end

        local hbcid = h.bcid
        if not obj:beamIsBroken(hbcid) then
          FFBhcount = FFBhcount + 1
          FFBhpos = FFBhpos + toInputSpace(h, obj:getBeamLength(hbcid) * h.invFFBHydroRefL)
        end
      end
    end

    local wheeldispl
    if FFBhcount == 0 then
      wheeldispl = 0
    else
      wheeldispl = wheelpos - FFBhpos / FFBhcount -- note: atm, wheelpos is updated as often as vlua queue is run, not at 2KHz
    end

    -- TODO: move 2 line above? (see TODO near the first 'if' inside FFBcalc)
    FFBcalc(wheeldispl)
  end

  for i = 1, hcount do
    local h = hydros[i]
    if h.cmd ~= h.state then -- elide expensive core call
      -- slowly approach the desired value
      if h.cmd < h.state then
        h.state = max(h.state - dtSim * h._inrate, h.cmd)
      else
        h.state = min(h.state + dtSim * h._outrate, h.cmd)
      end
      obj:setBeamLengthRefRatio(h.bcid, h.state)
    end
  end
end

local function onFFBConfigChanged(newFFBConfig)
  if FFBID >= 0 then
    obj:sendForceFeedback(FFBID, 0)
  end
  FFBID = -1
  if #FFBHydros ~= 0 then
    FFBHydrosExist = true
    FFBsmooth:set(0)
    curForceLimitSmoother:set(0)
    log("D", "hydros.init", "Response to FFB config request: "..dumps(newFFBConfig))

    if newFFBConfig == nil or newFFBConfig[action] == nil then
      return
    end

    local ffbConfig = newFFBConfig[action]

    if M.enableFFB then
      FFBID = ffbConfig.FFBID or -1
    end

    if FFBID >= 0 then
      if ffbConfig.ff_max_force and ffbConfig.ff_max_force ~= 0 then
        FFmax = ffbConfig.ff_max_force
        M.wheelFFBForceLimit = math.min(M.wheelFFBForceLimit, FFmax)
        if ffbConfig.ff_res == 0 then
          ffbConfig.ff_res = 256
          log("W", "", "Steering wheel drivers didn't provide any FFB resolution information. Defaulting to "..dumps(ffbConfig.ff_res).. " steps")
        end
        FFstep = FFmax / ffbConfig.ff_res
        local ffbparams = ffbConfig.ffbParams
        if ffbparams then
          local maxFFBrate = 0
          if ffbparams[  "forceCoef"] ~= nil then M.wheelFFBForceCoef   = ffbparams["forceCoef"]   end
          if ffbparams["forceCoefLowSpeed"] ~= nil then M.wheelFFBForceCoefLowSpeed = ffbparams["forceCoefLowSpeed"]   end
          if ffbparams[ "forceLimit"] ~= nil then M.wheelFFBForceLimit  = ffbparams["forceLimit"]  end
          if ffbparams[  "smoothing"] ~= nil then M.wheelFFBSmoothing   = ffbparams["smoothing"]   end
          if ffbparams["smoothingHF"] ~= nil then M.wheelFFBSmoothingHF = ffbparams["smoothingHF"] end
          if ffbparams[  "frequency"] ~= nil then maxFFBrate = tonumber(ffbparams["frequency"])  end
          if ffbparams["responseCorrected"] ~= nil then responseCorrected = ffbparams["responseCorrected"] end
          if ffbparams["responseCurve"]~=nil then responseCurve       = ffbparams["responseCurve"]end
          if responseCorrected then
            responseCurve = processResponseCurve(responseCurve)
          end
          if maxFFBrate == 0 or maxFFBrate == nil then
            -- try to not overload the FFB drivers with too many updates
            -- some steering wheels drivers accept 2KHz updates but will show incorrect behaviour, in those cases the automatic detection (frequency == 0) can be overriden with custom rates (frequency > 0)
            if ffbConfig.ffbSendms ~= nil and ffbConfig.ffbSendms >= 0 then
              local safeSendPeriod = ffbConfig.ffbSendms * 2.5 / 1000 -- convert from ms to s, and leave time for actual physics computation too
              local safeFrequency = 1/safeSendPeriod
              maxFFBrate = math.min(2000, math.max(30, safeFrequency)) -- at least 30Hz, at most 2000Hz)
            else
              maxFFBrate = 60 -- default to a reasonable figure when timing is not available in automatic mode
            end
          end
          FFBperiodms = 1000.0/maxFFBrate
          log("D", "hydros.init", "Force Feedback motor found for '"..action.."' hydro (physicsID: "..dumps(obj:getID())..", FFBID: "..dumps(FFBID)..", ForceCoef "..M.wheelFFBForceCoef..", ForceLimit "..M.wheelFFBForceLimit..", Smoothing "..M.wheelFFBSmoothing..", SmoothingHF "..M.wheelFFBSmoothingHF..", Period "..FFBperiodms.." ms / "..maxFFBrate.."Hz ("..(ffbparams["frequency"]==0 and "auto" or "manual")..", ffbSendMs "..dumps(ffbConfig.ffbSendms).."))")
          gui.message("Controller with force feedback detected<br>Disabling "..action.." from the other controllers", 5, "hydros")
          obj:sendForceFeedback(FFBID, 0)
          --TODO: we should probably set the lastDriverUpdate time here, to prevent momentary overload of drivers
        else
          FFBID = -1
          log("E", "hydros.init", "Couldn't find FFB params in ffbconfig: "..dumps(ffbparams).."\n"..dumps(ffbConfig.ffbParams))
        end
      else
        FFBID = -1
        log("E", "hydros.init", "Couldn't parse FFB config:\n"..dumps(ffbConfig))
      end
    end
  end
end

-- nop'ed functions
M.updateGFX = updateGFX
M.update = update

local function init()
  if v.data.hydros == nil or (v.data.hydros ~= nil and tableSize(v.data.hydros) == 0) then
    M.updateGFX = nop
    M.update = nop
    M.hydros = {}
    hydroCount = 0
    return
  end

  if v.data.input and v.data.input.FFBcoef ~= nil then
    vehicleFFBForceCoef = v.data.input.FFBcoef
  end

  M.hydros = {}
  for _, v in pairs(v.data.hydros) do
    table.insert(M.hydros, v)
  end

  hydroCount = 0
  for _, h in pairs (M.hydros) do
    hydroCount = hydroCount + 1
    h.inputCenter = h.inputCenter * h.inputFactor
    h.inputInLimit = h.inputInLimit * h.inputFactor
    h.inputOutLimit = h.inputOutLimit * h.inputFactor
    local inputFactorSign = sign(h.inputFactor)

    if h.inputFactor < 0 then
      h.inputInLimit, h.inputOutLimit = h.inputOutLimit, h.inputInLimit
    end

    local inputMiddle = (h.inputOutLimit + h.inputInLimit) * 0.5
    if h.inputCenter >= inputMiddle then
      h.center = 1 + (h.outLimit - 1) * (h.inputCenter - inputMiddle) / (h.inputOutLimit - inputMiddle)
    else
      h.center = 1 - (1 - h.inLimit) * (inputMiddle - h.inputCenter) / (inputMiddle - h.inputInLimit)
    end
    h.state = h.center + 1e-28 -- so as it initializes correctly
    h.multOut = (h.outLimit - h.center) / (h.inputOutLimit - h.inputCenter)
    h.cOut = h.center - h.inputCenter * h.multOut
    h.multIn = (h.center - h.inLimit) / (h.inputCenter - h.inputInLimit)
    h.cIn = h.center - h.inputCenter * h.multIn
    h.cmd = h.inputCenter
    h.invMultOut = 1 / (h.outLimit - h.center) * inputFactorSign
    h.invMultIn = 1 / (h.center - h.inLimit) * inputFactorSign
    h._inrate = h.inRate
    h._outrate = h.outRate
    h.hydroDirState = 0
    h.bcid = h.beam.cid

    -- little workaround
    if h.inputSource == action then
      h.inputSource = action.."_input"
    end

    if h.inputSource == action.."_input" then
      h[action] = true
    end

    if h.inputSource == "steering_input" then
      steeringHydro = h
    end
  end

  if hydroCount == 0 then
    M.updateGFX = nop
    M.update = nop
  end

  FFBHydros = {}
  FFBRest = {}
  for _,h in pairs(M.hydros) do
    if h[action] then
      h.invFFBHydroRefL = 1 / obj:getBeamRefLength(h.beam.cid)
      table.insert(FFBHydros, h)
    else
      table.insert(FFBRest, h)
    end
  end

  FFBRestCount = #FFBRest
  hydroCount = #M.hydros
  M.reset()
end

local function reset()
  if v.data.hydros == nil or (v.data.hydros ~= nil and tableSize(v.data.hydros) == 0) then
    M.updateGFX = nop
    M.update = nop
    return
  else
    M.updateGFX = updateGFX
    M.update = update
  end

  for _,h in pairs(M.hydros) do
    h.state = h.center + 1e-28 -- so as it initializes correctly
    h.cmd = h.inputCenter
    h._inrate = h.inRate
    h._outrate = h.outRate
  end

  FFBsmooth:set(0)
  curForceLimitSmoother:set(0)
  if FFBID >= 0 then
    obj:sendForceFeedback(FFBID, 0)
    --TODO: we should probably set the lastDriverUpdate time here, to prevent momentary overload of drivers
  end
end

local function sendHydroStateToGUI()
  obj:executeJS("HookManager.trigger('HydrosUpdate', "..encodeJson(M.hydros)..");")
end

-- public interface
M.init = init
M.reset = reset
M.sendHydroStateToGUI = sendHydroStateToGUI
M.onFFBConfigChanged = onFFBConfigChanged
return M
