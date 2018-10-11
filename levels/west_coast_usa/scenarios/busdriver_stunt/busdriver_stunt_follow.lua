local M = {}

local helper = require('scenario/scenariohelper')
local logTag = 'Mountain_race'

local finalWaypointName = 'stfinish'
local playerInstance = 'scenario_player0'
local aiInstance = 'scenario_crew'
local running = false
local playerWon = false
local aiWon = false
local aiArrived = false
local damageFail = false
local messageText = ""
local lastMessage = ""
local distance = 0
local playerDamage = 0
local aiDamage = 0

local function reset()
  running = false
  playerWon = false
  aiWon = false
  damageFail = false
  aiArrived = false
  playerDamage = 0
  aiDamage = 0
  distance = 0
  lastMessage = ""
end

local function fail(reason)
  scenario_scenarios.finish({failed = reason})
  reset()
end

local function success(reason)
  scenario_scenarios.finish({msg = reason})
  reset()
end

local function onRaceResult(outcome)
  if aiWon then
    fail('scenarios.west_coast_usa.busdriver_stunt.busdriver_stunt_follow.fail.msg')
  end
  if damageFail then
    fail('scenarios.west_coast_usa.busdriver_stunt.busdriver_stunt_follow.damage.msg')
  end
  if playerWon then
    success('scenarios.west_coast_usa.busdriver_stunt.busdriver_stunt_follow.win.msg')
  end
end

local function onCountdownStarted()
  reset()

  local arg = {vehicleName = 'scenario_crew',
              waypoints = {'stcheck_0', 'stcheck_1', 'stcheck_2', 'stcheck_3', 'stcheck_4', 'stcheck_5', 'stcheck_6', 'stfinish_ai'},
              routeSpeed = 70/3.6,
              routeSpeedMode = 'limit',
              driveInLane = 'on',
              aggression = 1, -- aggression here acts as a multiplier to the Ai default aggression i.e. 0.7.
              resetLearning = true -- leave blank or set to false if not needed
              }
  helper.setAiPath(arg)
end

local function onRaceStart()
  -- log('I', logTag,'onRaceStart called')
	running = true
end

local function onPreRender(dt)

  if running == true then
    local playerVehicle = scenetree.findObject(playerInstance)
    local playerVehicleData = map.objects[playerVehicle:getID()]
    playerDamage = playerVehicleData.damage
    local playerVehiclePos = playerVehicle:getPosition()

    local aiVehicle = scenetree.findObject(aiInstance)
    local aiVehicleData = map.objects[aiVehicle:getID()]
    aiDamage = aiVehicleData.damage
    local aiVehiclePos = aiVehicle:getPosition()
    distance = (playerVehiclePos - aiVehiclePos):len()
  end

  if playerDamage > 10000 or aiDamage > 2000 then
    onRaceResult()
    damageFail = true
  end

  if distance > 140 then
    messageText = "Keep up with the film crew!"
  else
    messageText = ""
  end

  if messageText ~= lastMessage then
    helper.realTimeUiDisplay(messageText)
    lastMessage = messageText
  end

end

local function onRaceWaypointReached(data)
  --log('I', logTag,'onRaceWaypointReached called ')
  --dump(data)
  local playerVehicleId = be:getPlayerVehicleID(0)

  if data.vehicleId == playerVehicleId then
  end
  if data.waypointName == finalWaypointName then
    local playerVehicleId = be:getPlayerVehicleID(0)
    if data.vehicleId ~= playerVehicleId and distance > 200 then
      aiWon = true
      onRaceResult()
    else
      playerWon = true
      onRaceResult()
    end
  end
end

M.onPreRender = onPreRender
M.onCountdownStarted = onCountdownStarted
M.onRaceStart = onRaceStart
M.onRaceWaypointReached = onRaceWaypointReached
M.onRaceResult = onRaceResult
return M