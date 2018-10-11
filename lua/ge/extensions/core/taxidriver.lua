local M = {}

local passenger
local destPos
local dest = {}
local newPassenger = true
local timeSet = false
local playerVehicle

local coolDown = 0

local state = {
  earnings = 0,
  distance = 0,
  fare = 0,
  tip = 0,
  mood = 0,
  status = "",
  message = "",
  timeLeft = 0,
  g = 0,
  newCustomer = true,
  passengerColor = {1, 1, 1}
}

local function getDistance (pos1, pos2)
  local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-pos2.y))

  if distance ~= distance then
    distance = 0
  end

  return distance
end

local function createPassenger(pos)
  passenger = scenetree.findObject('Passenger')

  if passenger == nil then
    passenger = createObject('TSStatic')
  end

  passenger:setPosition(pos)
  passenger:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_base.dae")
  passenger.scale = Point3F(4, 4, 20)
  passenger.useInstanceRenderData = true

  if newPassenger then
    state.passengerColor = {math.random(0,10)/10, math.random(0,10)/10, math.random(0,10)/10}
    passenger:setField('instanceColor', 0, tostring(state.passengerColor[1]) .. ' ' .. tostring(state.passengerColor[2]) .. ' ' .. tostring(state.passengerColor[3]) .. ' ' .. '1')
  end

  passenger:setField('collisionType', 0, "Collision Mesh")
  passenger:setField('decalType', 0, "Collision Mesh")
  passenger.canSave = false
  passenger:registerObject('Passenger')

  if not playerVehicle then return end

  local vpos = playerVehicle:getPosition()

  if newPassenger == false then
    state.tip = 0
    state.fare = 0
    state.status = "Deliver customer to location" -- TODO i18n
    if state.mood == 1 then
      state.message = "Can you hurry up? I'm running late!"
    elseif state.mood == 2 then
      state.message = "Could you try driving carefully?"
      state.tip = math.random(5, 20)
    end
    state.newCustomer = true
    guihooks.trigger('TaxiStatsUpdate', state)
  end
  newPassenger = not newPassenger
end

local function endJob()
  if state.timeLeft > 0 and state.mood == 1 then
      state.tip = math.random(5, 20)
  end

  state.earnings = state.earnings + state.fare + state.tip
  state.status = "Pick up new customer"

  if state.mood == 1 and state.tip > 0 then
    state.message = "That was fast! You can keep the rest."
  elseif state.mood == 2 and state.tip > 0  then
    state.message = "That was one smooth ride."
  elseif state.fare > 0 then
    state.message = "Thanks a lot!"
  end

  state.newCustomer = false
  guihooks.trigger('TaxiStatsUpdate', state)
  guihooks.trigger('TaxiStatsSum', state)
  state.tip = 0
end

local function newJob()
  playerVehicle = be:getPlayerVehicle(0)
  if map == nil then return end
  local nodes = map.getMap().nodes
  local node = nil
  local timeOut = 0
  timeSet = false
  coolDown = 0

  if newPassenger then
    endJob()
    state.mood = math.random(0, 2) -- neutral, speed, comfort
    state.distance = 0
  end

  state.message = ""

  local cont = true

  while cont do
    timeOut = timeOut + 1

    if timeOut > 50 then
      cont = false
    end

    passenger = nil

    if core_groundMarkers ~= nil then
      core_groundMarkers.setFocus(nil)
      core_groundMarkers.onClientEndMission()
    end

    node = nodes[tableChooseRandomKey(nodes)]
    local node2 = nodes[tableChooseRandomKey(nodes)]

    if node ~= nil then
      --local vpos = vec3(playerVehicle:getPosition())
      dest = tableChooseRandomKey(node.links)
      if (dest ~= "" or next(dest) ~= nil) and dest ~= nil then
        destPos = node.pos--vpos + vec3(math.random(-15,15), math.random(-15,15), 0)
        cont = false
        createPassenger(Point3F(destPos.x, destPos.y, destPos.z))
      end
    end
  end
end

local function resetStats()
  newPassenger = true
  coolDown = 0
  --state.earnings = 0
  state.distance = 0
  state.fare = 0
  state.tip = 0
  state.mood = 0
  state.status = ""
  --state.message = ""
  state.timeLeft = 0
  state.g = 0
  state.newCustomer = true
end

local lastPos
local lastVel = 0
local cumAcc = 0
local count = 0

local prevVel = nil
local prevPos = nil
local prevAcc = nil

-- Stolen and modified from busdriver.lua
-- Returns smoothed acceleration and current one without smoothing
local function getAcceleration(dtSim)
  if dtSim == 0 then return {0, 0} end
  if not playerVehicle then return end
  local fwd  = vec3(playerVehicle:getDirectionVector()):normalized()
  local up   = vec3(playerVehicle:getDirectionVectorUp()):normalized()
  local currPos = vec3(playerVehicle:getPosition())
  local currVel = (prevPos and (currPos - prevPos) or vec3()) / dtSim
  local currAcc = (prevVel and (currVel - prevVel) or vec3()) / dtSim
  local currJer = (prevAcc and (currAcc - prevAcc) or vec3()) / dtSim
  if not smootherAcc then smootherAcc = newTemporalSmoothing(30, 10) end
  prevVel = currVel
  prevPos = currPos
  prevAcc = currAcc
  if core_environment == nil then
    extensions.load('core_environment');
  end
  local g = math.abs(smootherAcc:getUncapped(math.sqrt(math.pow(currAcc.x, 2) + math.pow(currAcc.y, 2) + math.pow(currAcc.z, 2)), dtSim) / core_environment.getGravity())
  local peakG = math.abs(math.sqrt(math.pow(currAcc.x, 2) + math.pow(currAcc.y, 2) + math.pow(currAcc.z, 2)) / core_environment.getGravity())
  return {g, peakG}
end

local function onUpdate(dtReal, dtSim, dtRaw)
  playerVehicle = be:getPlayerVehicle(0)

  if playerVehicle == nil then return end

  if passenger == nil then return end

  guihooks.trigger('TaxiStatsUpdate', state)

  if state.mood == 2 and state.tip > 0 then
    local acc = getAcceleration(dtSim, 10)
    state.g = acc[1]
    local peakG = acc[2]
    -- Use small cooldown to get rid of some nasty incorrect accelerations in the beginning
    if coolDown > 100 then
      if type(state.g) ~= "number" or state.g == nil then
        state.g = 0
      end
      -- g is used to detect mad driving
      if state.g > 0.8 then
        state.tip = state.tip - state.g * 0.025
        state.message = "Can you slow down?"
      end
      -- peakG is used to detect crashes
      if peakG > 5 then
        state.g = peakG;
        state.tip = 0
        state.message = "That's it, you can forget about the tip!"
      end
    end
  end

  if newPassenger and state.mood == 2 and coolDown < 101 then
    coolDown = coolDown + 1;
  end

  local vpos = playerVehicle:getPosition()

  if newPassenger and lastPos ~= nil then
    state.distance = state.distance + getDistance(vpos, lastPos)
    state.fare = 5 + 2 * state.distance/1000 -- Base price of 5cr, 2cr per 1km
  end

  lastPos = vpos

  if getDistance(vpos, destPos) < 5 then
    if playerVehicle:getVelocity():len() < 1 then
      newJob()
    else
      if not newPassenger then
        state.message = "I'm here! Stop so I can hop in."
      else
        state.message = "This is the place! Stop so I can get out."
      end
    end
  end
end

local function onVehicleResetted()
  playerVehicle = be:getPlayerVehicle(0)
  resetStats()
  newJob()
  guihooks.trigger('TaxiStatsUpdate', state)
end

local function onPreRender(dtReal, dtSim, dtRaw)
  if playerVehicle == nil then return end

  if state.timeLeft > 0 and state.mood == 1 then
    state.timeLeft = state.timeLeft - dtSim
  end

  local dist = core_groundMarkers.getPathLength()

  if core_groundMarkers ~= nil then
    core_groundMarkers.setFocus({dest}, 8, 50, 200, destPos, nil, state.passengerColor)
    if timeSet == false or state.timeLeft == 0 or state.timeLeft == nan then
      state.timeLeft = dist/16.67 -- groundmarkers path distance is always ~1.5 times longer than actual driven distance
      if state.timeLeft > 0 then state.timeLeft = state.timeLeft + 10 end
      timeSet = true
    end
  else
    extensions.load('core_groundMarkers');
  end
end

local function onExtensionUnloaded()
  if core_groundMarkers ~= nil then
    core_groundMarkers.setFocus(nil)
    core_groundMarkers.onClientEndMission()
  end
  if passenger then passenger.hidden = true end
end

local function onExtensionLoaded()
  resetStats()
  newJob()
  guihooks.trigger('TaxiStatsUpdate', state)
end

M.onExtensionUnloaded = onExtensionUnloaded
M.onExtensionLoaded = onExtensionLoaded
M.onVehicleResetted = onVehicleResetted
M.onUpdate = onUpdate
M.onPreRender = onPreRender

return M
