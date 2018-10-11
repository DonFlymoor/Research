local M = {}

local helper = require('scenario/scenariohelper')
local logTag = 'Derby_Asphalt'

local finalWaypointName = 'drifttrack_wp0'
local playerInstance = 'scenario_player0'
local running = false
local playerWon = false
local aiWon = false
local noOfLaps = 5
local lapsCompleted = {}

local function reset()
  lapsCompleted['scenario_player0'] = 0
  lapsCompleted['scenario_opponent1'] = 0
  lapsCompleted['scenario_opponent2'] = 0
  lapsCompleted['scenario_opponent3'] = 0

  running = false
  playerWon = false
  aiWon = false
end

local function fail(reason)
  scenario_scenarios.finish({failed = reason})
  reset()
end

local function success(reason)
  scenario_scenarios.finish({msg = reason})
  reset()
end

local function onRaceStart()

  scenario_scenarios.trackVehicleMovementAfterDamage(playerInstance, {waitTimerLimit=10})

	running = true
end

local function onCountdownStarted()
  reset()

  local arg = {vehicleName = 'scenario_opponent1',
              waypoints = {'drifttrack_wp1', 'drifttrack_wp2', 'drifttrack_wp3', 'drifttrack_wp4', "drifttrack_wp0", 'drifttrack_wp1'},
              lapCount = noOfLaps,
              aggression = 1.4} -- aggression here acts as a multiplier to the Ai default aggression i.e. 0.7.

  helper.setAiPath(arg)

  arg.vehicleName = 'scenario_opponent2'
  arg.aggression = 1.3

  helper.setAiPath(arg)

  arg.vehicleName = 'scenario_opponent3'
  arg.aggression = 1.1

  helper.setAiPath(arg)
end

local function onRaceWaypointReached(data)
  --log('I', logTag,'onRaceWaypointReached called ')
  if data.waypointName == finalWaypointName then
    lapsCompleted[data.vehicleName] = lapsCompleted[data.vehicleName] + 1
    if lapsCompleted[data.vehicleName] == noOfLaps then
      if data.vehicleName == playerInstance and not aiWon then
        playerWon = true
      elseif not playerWon then
        aiWon = true
      end
    end
  end
end

local function onRaceResult()
  if playerWon then
    success('scenarios.utah.chapter_2.chapter_2_6_canyon.pass.msg')
  else
    fail('scenarios.utah.chapter_2.chapter_2_6_canyon.fail.msg')
  end
end

local function onVehicleStoppedMoving(vehicleID, damaged)
  if running then
    local playerVehicleID = scenetree.findObject(playerInstance):getID()
    if vehicleID == playerVehicleID and damaged and not playerWon then
      fail('scenarios.utah.chapter_2.chapter_2_6_canyon.fail.msg')
    end
  end
end

M.onRaceStart = onRaceStart
M.onCountdownStarted = onCountdownStarted
M.onRaceWaypointReached = onRaceWaypointReached
M.onRaceResult = onRaceResult
M.onVehicleStoppedMoving = onVehicleStoppedMoving
return M