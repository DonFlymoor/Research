-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.keys = {} -- Backwards compatibility
M.state = {}
M.filterSettings = {}

M.FILTER_KBD    = 0
M.FILTER_PAD    = 1
M.FILTER_DIRECT = 2
M.FILTER_KBD2   = 3

--set kbd initial rates (derive these from the menu options eventually)
local kbdInRate = 2.2
local kbdOutRate = 1.6

--set kbd understeer limiting effect (A value of 1 will achieve min steering speed of 0*kbdOutRate)
local kbdUndersteerMult = 0.5
--set kbd oversteer help effect (A value of 1 will achieve max steering speed of 2*kbdOutRate)
local kbdOversteerMult = 0.7

local rateMult = nil
local kbdOutRateMult = 0
local kbdInRateMult = 0
local padSmoother = nil
local vehicleSteeringWheelLock = 450

local function init()
  --scale rates based on steering wheel degrees
  local foundSteeringHydro = false

  if hydros then
    for _, h in pairs (hydros.hydros) do
      --check if it's a steering hydro
      if h.inputSource == "steering_input" then
        foundSteeringHydro = true
        --if the value is present, scale the values
        if h.steeringWheelLock then
          vehicleSteeringWheelLock = math.abs(h.steeringWheelLock)
          break
        end
      end
    end
  end

  if v.data.input and v.data.input.steeringWheelLock ~= nil then
    vehicleSteeringWheelLock = v.data.input.steeringWheelLock
  elseif foundSteeringHydro then
    if v.data.input == nil then v.data.input = {} end
    v.data.input.steeringWheelLock = vehicleSteeringWheelLock
  end

  rateMult = 5 / 8
  if vehicleSteeringWheelLock ~= 1 then
    rateMult = 450 / vehicleSteeringWheelLock
  end

  kbdOutRateMult = math.min(kbdOutRate * rateMult, 2)
  kbdInRateMult = math.min(kbdInRate * rateMult, 3)
  padSmoother = newTemporalSmoothing()

  --inRate (towards the center), outRate (away from the center), autoCenterRate, startingValue
  M.state = {
    steering = { val = 0, filter = 0,
      smootherKBD = newTemporalSmoothing(),
      smootherPAD = newTemporalSmoothing(),
      minLimit = -1, maxLimit = 1 },
    throttle = { val = 0, filter = 0,
      smootherKBD = newTemporalSmoothing(3, 3, 1000, 0),
      smootherPAD = newTemporalSmoothing(100, 100, nil, 0),
      minLimit =  0, maxLimit = 1 },
    brake = { val = 0, filter = 0,
      smootherKBD = newTemporalSmoothing(3, 3, 1000, 0),
      smootherPAD = newTemporalSmoothing(100, 100, nil, 0),
      minLimit =  0, maxLimit = 1 },
    parkingbrake = { val = 0, filter = 0,
      smootherKBD = newTemporalSmoothing(10, 10, nil, 0),
      smootherPAD = newTemporalSmoothing(10, 10, nil, 0),
      minLimit =  0, maxLimit = 1 },
    clutch = { val = 0, filter = 0,
      smootherKBD = newTemporalSmoothing(10, 20, 20, 0),
      smootherPAD = newTemporalSmoothing(10, 10, nil, 0),
      minLimit =  0, maxLimit = 1 },
  }
  M.reset()
end

local function dynamicInputRateKbd(v, dt, curx)
  local signv = sign(v)
  local signx = sign(curx)
  local gx = sensors.gx
  local signgx = sign(gx)
  local absgx = math.abs(gx)

  local gs = padSmoother:getWithRateUncapped(0, dt, 3)
  if absgx > gs then
    gs = absgx
    padSmoother:set(gs)
  end

  -- centering by lifting key:
  if v == 0 then
    return kbdInRateMult
  end

  local g = math.abs(obj:getGravity())
  --reduce steering speed only when steered into turn and pressing key into direction of turn (help limit the understeer)
  if signx == -signgx and signv == -signgx then
    padSmoother:set(0)
    local gLateral = math.min(absgx, g) / (g + 1e-30)
    return kbdOutRateMult - (kbdOutRateMult * kbdUndersteerMult * gLateral)
  end

  --increase steering speed when pressing key out of direction of turn (help save the car from oversteer)
  if signv == signgx then
    local gLateralSmooth = math.min(gs, g) / (g + 1e-30)
    return kbdOutRateMult + (kbdOutRateMult * kbdOversteerMult * gLateralSmooth)
  end

  return kbdOutRateMult
end

local function dynamicInputRateKbd2(v, curx)
  local signv = sign(v)
  local signx = sign(curx)
  local gx = sensors.gx
  local signgx = sign(gx)
  local mov = v-curx
  local signmov = sign(mov)
  local speed = electrics.values['wheelspeed']

  -- centering by lifting key:
  if v == 0 then return kbdInRateMult end

  -- centering by pressing opposite key:
  if signmov ~= signx then return kbdInRateMult * 1.5 end

  -- recovering from oversteer:
  if signv == signgx or signmov == signgx or signx == signgx then return kbdInRateMult * 1.8 end

  -- not enough data, fallback case
  if speed == nil then return kbdInRateMult end

  -- regular steering:
  speed = math.abs(speed)
  local g = math.abs(obj:getGravity())
  return kbdOutRateMult * (1.4 - math.min(speed / 12, 1) * math.min(sensors.gxSmoothMax, g) / (g + 1e-30)) / 1.4
end

local function dynamicInputRatePad(v, dt, curx)
  local ps = padSmoother:getWithRateUncapped(0, dt, 0.2)
  local diff = v - curx
  local absdiff = math.abs(diff) * 0.9
  if absdiff > ps then
    ps = absdiff
    padSmoother:set(ps)
  end

  local baserate = (math.min(absdiff * 1.7, 3) + ps + 0.35)
  if diff * sign(curx) < 0 then
    return math.min(baserate * 2, 5) * rateMult
  else
    return baserate * rateMult
  end
end

local function update(dt)
  -- map the values
  for k, e in pairs(M.state) do
    local ival = 0
    if e.filter == M.FILTER_DIRECT then
      if e.angle == nil or e.angle == 0 then
        ival = e.val
      else
        local vehicleAngle = vehicleSteeringWheelLock * 2 -- convert from jbeam scale (half range) to input scale (full range)
        local relation = e.angle / vehicleAngle
        -- ival = linear + nonlinear
        ival = e.val * relation + fsign(e.val) * square(2*math.max(0.5,math.abs(e.val))-1) * math.max(0, 1 - relation)
      end
    else
      ival = math.min(math.max(e.val, -1), 1)
      if e.filter == M.FILTER_PAD then -- joystick / game controller - smoothing without autocentering
        if k == 'steering' then
          ival = e.smootherPAD:getWithRate(ival, dt, dynamicInputRatePad(ival, dt, e.smootherPAD:value()))
        else
          ival = e.smootherPAD:get(ival, dt)
        end
      elseif e.filter == M.FILTER_KBD then
        if k == 'steering' then
          ival = e.smootherKBD:getWithRate(ival, dt, dynamicInputRateKbd(ival, dt, e.smootherKBD:value()))
        else
          ival = e.smootherKBD:get(ival, dt)
        end
      elseif e.filter == M.FILTER_KBD2 then
        if k == 'steering' then
          ival = e.smootherKBD:getWithRate(ival, dt, dynamicInputRateKbd2(ival, e.smootherKBD:value()))
        else
          ival = e.smootherKBD:get(ival, dt)
        end
      end
    end
    if e.clearOnThrottle and k == 'parkingbrake' and (M.parkingbrake or e.minLimit) > 0.5 and (controller.mainController.throttle or e.minLimit) > 0.5 then
      e.clearOnThrottle = nil
      e.val = 0
    end

    if k == "steering" then
      local f = M.filterSettings[e.filter] -- speed-sensitive steering limit
      ival = ival * math.min(1, math.max(f.limitMultiplier, f.limitM * electrics.values.airspeed + f.limitB ))
    end

    ival = math.min(math.max(ival, e.minLimit), e.maxLimit)

    M[k] = ival
    electrics.values[k..'_input'] = ival
  end
end

local function reset()
  for k, e in pairs(M.state) do
    e.smootherKBD:reset()
    e.smootherPAD:reset()
  end
  M:settingsChanged()
end

local function getDefaultState(itype)
  return { val = 0, filter = 0,
    smootherKBD = newTemporalSmoothing(10, 10, nil, 0),
    smootherPAD = newTemporalSmoothing(10, 10, nil, 0),
    minLimit = -1, maxLimit = 1 }
end

local function event(itype, ivalue, filter, angle)
  if M.state[itype] == nil then -- probably a vehicle-specific input
    log("W", "", "Creating vehicle-specific input event type '"..dumps(itype).."' using default values")
    M.state[itype] = getDefaultState(itype)
  end
  if itype=="clutch" or itype=="throttle" or itype =="brake" then
   -- sounds.playSoundOnceAtNode("event:>Light_Test_1", v.data.refNodes[0].ref, 1)
  end
  M.state[itype].val = ivalue
  M.state[itype].filter = filter
  M.state[itype].clearOnThrottle = nil
  M.state[itype].angle = angle
end

local function toggleEvent(itype)
  if M.state[itype] == nil then return end
  if M.state[itype].val > 0.5 then
    M.state[itype].val = 0
  else
    M.state[itype].val = 1
  end
  M.state[itype].filter = 0
  M.state[itype].clearOnThrottle = nil
end

-- will smartly decide whether the user is actually parking the car (toggle), or just drifting around (temporary brake)
local function smartParkingBrake(ivalue, filter)
  -- gather some stats
  local speed = electrics.values['wheelspeed']
  if speed == nil then return event('parkingbrake', ivalue, filter) end -- not a typical car, so just set the pbrake as instructed
  local energy = 0
  for wi,wd in pairs(wheels.wheels) do energy = energy + wd.slipEnergy end
  energy = energy / tableSize(wheels.wheels)

  -- are we sliding or rolling?
  local isAxis = filter == M.FILTER_DIRECT or filter == M.FILTER_PAD
  local parkingSpeed = 10/3.6 --km/h to m/s
  local rolling = math.abs(speed) > parkingSpeed
  local skiddingThreshold = 50
  local skidding = energy > skiddingThreshold

  -- decide what to do, based on context
  if rolling or skidding or isAxis then return event('parkingbrake', ivalue, filter) end -- transparent use / temporary pbrake
  if ivalue > 0.5 then return toggleEvent('parkingbrake') end -- car is parked, use onDown to toggle pbrake
  if M.state['parkingbrake'].val > 0.5 then M.state['parkingbrake'].clearOnThrottle = true end -- car is left parked with smart brake, let user use throttle to accelerate out of parking situation
end

-- keyboard (multi-key) compatibility
local kbdSteerLeft = 0
local kbdSteerRight = 0
local function kbdSteer(isRight, val, filter)
  if isRight then kbdSteerRight = val
  else            kbdSteerLeft  = val end
  event('steering', kbdSteerRight-kbdSteerLeft, filter)
end

-- gamepad( (mono-axis) compatibility
local function padAccelerateBrake(val, filter)
  if val > 0 then
    event('throttle',  val, filter)
    event('brake',    0, filter)
  else
    event('throttle',    0, filter)
    event('brake', -val, filter)
  end
end

-- save the input state: persists the paring brake between reloads
local function onSerialize()
  -- try to save the values only
  local res = {}
  for kk,vv in pairs(M.state) do
    res[kk] = { val = vv.val, clearOnThrottle = vv.clearOnThrottle }
  end
  return res
end

-- restore the values
local function onDeserialize(data)
  local res = {}
  for kk,vv in pairs(data) do
    if M.state[kk] == nil then
      M.state[kk] = getDefaultState(kk)
    end
    M.state[kk].val = vv.val
    M.state[kk].clearOnThrottle = vv.clearOnThrottle
  end
end
local function settingsChanged()
  M.filterSettings = {}
  for i,v in ipairs({ M.FILTER_KBD, M.FILTER_PAD, M.FILTER_DIRECT, M.FILTER_KBD2 }) do
    local f = {}
    local limitEnabled= settings.getValue("filter"..tostring(v).."_limitEnabled"   , false)
    if limitEnabled then
      local startSpeed = math.max(0,math.min(100,settings.getValue("filter"..tostring(v).."_limitStartSpeed",     0))) -- 0..100 m/s
      local endSpeed   = math.max(0,math.min(100,settings.getValue("filter"..tostring(v).."_limitEndSpeed"  ,   100))) -- 0..100 m/s
      f.limitMultiplier= math.max(0,math.min(  1,settings.getValue("filter"..tostring(v).."_limitMultiplier",     1))) -- 0..1 multi
      if startSpeed > endSpeed then
        log("W", "", "Invalid speeds for speed sensitive filter #"..dumps(v)..", sanitizing by swapping: ["..dumps(startSpeed)..".."..dumps(endSpeed).."]")
        startSpeed, endSpeed = endSpeed, startSpeed
      end

      f.limitM = (f.limitMultiplier - 1) / (endSpeed - startSpeed)
      f.limitB = 1 - f.limitM * startSpeed
    else
      f.limitMultiplier = 1
      f.limitM = 0
      f.limitB = 1
    end
    M.filterSettings[v] = f
  end
end

-- public interface
M.update = update
M.init = init
M.reset = reset
M.event = event
M.toggleEvent = toggleEvent
M.kbdSteer = kbdSteer
M.padAccelerateBrake = padAccelerateBrake
M.smartParkingBrake = smartParkingBrake
M.settingsChanged = settingsChanged

M.onSerialize = onSerialize
M.onDeserialize = onDeserialize

return M
