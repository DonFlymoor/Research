local M = {}

local helper = require('scenario/scenariohelper')
local logTag = 'Mountain_race'

local finalWaypointName = 'scenario_finish1'
local playerInstance = 'scenario_player0'
local running = false
local playerWon = false
local aiWon = false

local function reset()
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
  -- log('I', logTag,'onRaceStart called')
  reset()

  local arg = {vehicleName = 'scenario_opponent',
              waypoints = {'mrace_01', 'mrace_02', 'mrace_03', 'mrace_04', 'mrace_05', 'mrace_06', 'mrace_07',
                           'mrace_08', 'mrace_09', finalWaypointName, 'mrace_01'},
              aggression = 0.8, -- aggression here acts as a multiplier to the Ai default aggression i.e. 0.7.
              aggressionMode = 'rubberBand' -- Aggression decreases with distance from opponent
              }

  helper.setAiPath(arg)

  scenario_scenarios.trackVehicleMovementAfterDamage(playerInstance, {waitTimerLimit=2})

	running = true
end

local function onRaceWaypointReached(data)
  --log('I', logTag,'onRaceWaypointReached called ')
  --dump(data)
  if data.waypointName == finalWaypointName then
    if data.vehicleName == playerInstance and not aiWon then
      playerWon = true
    elseif data.vehicleName == aiInstance and not playerWon then
      aiWon = true
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
    if vehicleID == playerVehicleID and damaged then
      if not playerWon then
        fail('scenarios.utah.chapter_2.chapter_2_6_canyon.fail.msg')
      end
    end
  end
end

M.onRaceStart = onRaceStart
M.onRaceWaypointReached = onRaceWaypointReached
M.onRaceResult = onRaceResult
M.onVehicleStoppedMoving = onVehicleStoppedMoving
return M