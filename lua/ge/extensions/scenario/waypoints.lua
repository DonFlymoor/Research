-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--[[
TODO
 * Move logic for winning the race into onRaceWaypoint path for when a vehicle crosses the last waypoint
 * Branching waypoints - Add an option to suggest best route
 * Improve activateWaypointBranch processing of vehicle waypoint after activation of a branch

]]--

local M = {}

local logTag = 'waypoints'
local vehicleWaypointsData = {}
local nextWpForVehicle = {}
local waypointBranches = {}
local currentWaypointChoise = {}
local currentBranch = nil
local waypointsConfigData = {}
local raceMarker = require("scenario/race_marker")

-- returns the next waypoint
local function getNextWaypoint(w, diff)
  local scenario = scenario_scenarios.getScenario()

  if not scenario then
    return nil, nil
  end

  local testWp = w.cur + diff
  if testWp > #scenario.lapConfig then
    if w.lap + 1 < scenario.lapCount or scenario.lapCount == 0 then
      -- new lap
      return 1, 1
    else
      -- all done
      return nil, nil
    end
  end
  -- no new lap, just new waypoint
  return testWp, 0
end

local function processWaypoint(vid)
  local scenario = scenario_scenarios.getScenario()

  if not scenario then
    return nil
  end

  local bo = be:getObjectByID(vid)

  if not bo then
    return nil
  end

  local w = vehicleWaypointsData[vid]
  -- log('D', logTag, "waypoint: cur:" .. vid .. " = " .. w.cur .. ", next: " .. w.next)
  -- dump(w)

  w.cur = w.next
  local lapDiff = -1
  w.next, lapDiff = getNextWaypoint(w, 1)

  if scenario.rollingStart and w.next == 0 and scenario.startTimerCheckpoint ~= nil then
    w.nextWp = scenario.nodes[scenario.startTimerCheckpoint]
  else
    if not scenario.lapConfig[w.next] then
      if w.next then
        log('E', logTag, 'next waypoint invalid: ' .. tostring(w.next))
      end
      raceMarker.hide(true)
      return nil
    end
    if not scenario.nodes[scenario.lapConfig[w.next]] then
      log('E', logTag, 'waypoint not found: ' .. tostring(scenario.lapConfig[w.next]))
      raceMarker.hide(true)
      return nil
    end
    w.nextWp = scenario.nodes[scenario.lapConfig[w.next]]
  end
  -- log( 'D', logTag,"set next WP for vehicle "..vid)
  -- dump(w.nextWp)

  nextWpForVehicle[vid] = w.next

  w.next2Wp = nil
  raceMarker.clearNextStat()
  w.next2 = getNextWaypoint(w, 2)
  if w.next2 then
    w.next2Wp = scenario.nodes[scenario.lapConfig[w.next2]]
    if not w.next2Wp then
      log('E', logTag, 'Waypoint does not exists in map - ' .. w.next2)
    end
  end

  -- update the 3d markers
  if bo.playerUsable then
    if w.nextWp then
      if w.next2 == nil and waypointsConfigData.highlightLastWaypoint then
        raceMarker.clearStat()
      else
        raceMarker.setPosition(vec3(w.nextWp.pos), w.nextWp.radius)
      end
    end

    if w.next2Wp then
      raceMarker.setNextPosition(vec3(w.next2Wp.pos),  w.next2Wp.radius)
    end
  end

  return lapDiff
end

local function initialiseVehicleData(vid)
  local scenario = scenario_scenarios.getScenario()

  if not scenario then
    return
  end

  local vehicle = be:getObjectByID(vid)
  if vehicle and vehicle.playerUsable or checkVehicleProperty(vid, 'isAIControlled', '1') then
    if scenario.rollingStart and scenario.startTimerCheckpoint ~= nil then
      vehicleWaypointsData[vid] = { cur = -2, next = -1, lap = 0 }
    else
      vehicleWaypointsData[vid] = { cur = -1, next = 0, lap = 0 }
    end
    
    processWaypoint(vid)
  end
end

local function onRaceWaypointReached(data)
  local selected = {}
  currentWaypointChoise = {}
  for k, v in pairs(waypointBranches) do
    if v.action == 'after' and v.location == data.waypointName then
      currentWaypointChoise[k] = v.waypoints[1]
      table.insert(selected, v.waypoints[1])
    end
  end

  local scenario = scenario_scenarios.getScenario()
  if #selected == 0 then return end

  local bo = be:getObjectByID(data.vehicleId)
  if not bo or not bo.playerUsable then return end

  local wp = scenario.nodes[selected[1]]
  if wp then raceMarker.setPosition(vec3(wp.pos), wp.radius, ColorF(1, 1, 0.4, 1)) end

  local wp2 = scenario.nodes[selected[2]]
  if wp2 then raceMarker.setNextPosition(vec3(wp2.pos), wp2.radius, ColorF(1, 1, 0.4, 1)) end
end

-- callback for the waypoint system
-- called when a vehicle drives through the targeted waypoint
local function onScenarioVehicleTrigger(vid, wpData)
  -- decide upon progress here and update the UI
  local scenario = scenario_scenarios.getScenario()

  if not scenario then
    return
  end

  local bo = be:getObjectByID(vid)
  if not bo then return end

  local lapDiff = processWaypoint(vid)
  local w = vehicleWaypointsData[vid]

  if scenario.rollingStart and w.cur == 0 then -- hit the starting line
    scenario_scenarios.rollingStartTriggered()
    if bo.playerUsable then
      Engine.Audio.playOnce('AudioGui', "event:UI_Checkpoint")
      extensions.hook( 'onRaceWaypoint', data)
    end
  elseif w.cur ~= -1 then
  -- log( 'D', logTag, 'onTrigger wp '..tostring(w.cur) )
    local data = {cur = w.cur, curPos = wpData.pos, curRadius = wpData.radius, next = w.next, 
                  vehicleId = vid, vehicleName = bo:getField('name', ''), 
                  waypointName = scenario.lapConfig[w.cur] or "", time = scenario.timer}

    extensions.hook('onRaceWaypointReached', data)

    if bo.playerUsable then
      Engine.Audio.playOnce('AudioGui', "event:UI_Checkpoint")
      extensions.hook( 'onRaceWaypoint', data)
    end
  end

  if w.next == nil then
    -- all done
    scenario_scenarios.endRace()
    return
  end

  if lapDiff and lapDiff > 0 then
    -- changed laps?
    w.lap = w.lap + lapDiff
    scenario.currentLap = w.lap
    --log( 'D', logTag, 'onTriggerLap: '..tostring(w.lap) .. ' time: ' .. string.format("%.3f", scenario.timer) .. 's' )
    extensions.hook('onRaceLap', {lap = w.lap, time = scenario.timer, vehicleId = vid, vehicleName = bo:getField('name', '') } )
  end

  -- dump(w)
end

local function onPreRender(dt)
  -- see if a vehicle has driven through a target waypoint
  for vid, vehWpData in pairs(vehicleWaypointsData) do
    local vehicle = be:getObjectByID(vid)
    local vehicleData = map.objects[vid]
    local nextWp = vehWpData.nextWp -- target waypoint
    if vehicle and vehicleData and nextWp and nextWp.pos then
      local planeNormal = nextWp.rot
      local pos2node = 0.5 * (vec3(vehicle:getCornerPosition(1)) + vec3(vehicle:getCornerPosition(0))) - nextWp.pos

      if pos2node:squaredLength() <= square(nextWp.radius) and pos2node:dot(vehicleData.vel) >= 0 and (planeNormal == nil or pos2node:dot(planeNormal) >= 0) then
        vehWpData.nextWp = nil
        onScenarioVehicleTrigger(vid, nextWp)
      end
    end
  end
end

local function onScenarioChange(scenario)
  -- log('D', logTag, 'onScenarioChange: ' .. tostring(scenario and scenario.state or 'nil'))
  if not scenario then
    vehicleWaypointsData = {}
    nextWpForVehicle = {}
    waypointBranches = {}
    currentWaypointChoise = {}
    currentBranch = nil
    return
  end
end

local function onVehicleSwitched(oldId, newId, player)
  --log( 'I', logTag, 'onVehicleSwitched '..oldId..','..newId..','..player)
  if scenario_scenarios then
    local scenario = scenario_scenarios.getScenario()
    if not scenario then return end
    if not nextWpForVehicle[oldId] then return end

    local vehicle = be:getObjectByID(newId)
    if not vehicle then return end
    local wayPointID = nextWpForVehicle[oldId]
    if waypoint and scenario.lapConfig[wayPointID] then
      local nwp = scenario.nodes[scenario.lapConfig[wayPointID]]
      -- TODO(AK): this is STALE. Update to new approach which is handle in this file.
      -- vehicle:queueLuaCommand('scenario.setTrigger("scenario_waypoints.onScenarioVehicleTrigger", ' .. serialize(nwp.pos) .. ',' .. nwp.radius .. ',' .. serialize(nwp.rot) .. ');')
    end
  end
end

local function insertWaypoints(data)
  -- log('I', logTag,'insertWaypoints called')
  -- dump(data)

  local scenario = scenario_scenarios.getScenario()
  if not scenario or not scenario.lapConfig or not data or not data.waypoints or not data.location then
    return
  end
  -- log('I', logTag,'Before Insert')
  -- dump(scenario.lapConfig)

  local insertionIndex = nil
  local index = nil
  for i,wpName in ipairs(scenario.lapConfig) do
    if wpName == data.location then
      index = i
      break
    end
  end

  if index then
    if data.action == 'after' then
      index = index + 1
    end

    insertionIndex = index

    for _, wpName in ipairs(data.waypoints) do
      table.insert(scenario.lapConfig, index, wpName)
      index = index + 1
    end
  end
  -- log('I', logTag,'After Insert')
  -- dump(scenario.lapConfig)

  return insertionIndex
end

local function removeWaypoints(data)
  -- log('I', logTag,'removeWaypoints called')
  -- dump(data)
  local scenario = scenario_scenarios.getScenario()
  if not scenario or not scenario.lapConfig or not data or not data.waypoints then
    return
  end
  -- log('I', logTag,'Before Remove')
  -- dump(scenario.lapConfig)

  local newLapConfig = {}
  for _,wpName in ipairs(scenario.lapConfig) do
    if not tableContains(data.waypoints, wpName) then
      table.insert(newLapConfig, wpName)
    end
  end

  scenario.lapConfig = newLapConfig

  -- log('I', logTag,'After Remove')
  -- dump(scenario.lapConfig)
end

local function deactivateWaypointBranch(branchName)
  do return end
  local scenario = scenario_scenarios.getScenario()
  if not scenario then return end

  if waypointBranches[branchName] then
    removeWaypoints(waypointBranches[branchName])
  end

  if currentBranch == branchName then
    currentBranch = nil
  end
end

local function activateWaypointBranch(branchName, vehicleID)
  -- log('I', logTag,'activateWaypointBranch called for '..branchName)

  if not branchName or currentBranch == branchName then
    return
  end
  local scenario = scenario_scenarios.getScenario()
  local vehWpData = vehicleWaypointsData[vehicleID]
  local vehicle = be:getObjectByID(vehicleID)
  if not scenario or not vehicle or not vehWpData then
    return
  end

  -- log('I', logTag,'player current waypoint')
  -- dump(vehWpData)

  if currentBranch then
    deactivateWaypointBranch(currentBranch)
  end

  currentBranch = branchName

  if vehWpData.cur > #scenario.lapConfig then
    vehWpData.next = 0
  end

  local insertionData = waypointBranches[branchName]
  local insertIndex = insertWaypoints(insertionData)
  -- log('I', logTag,'insertion index '..tostring(insertIndex))

  -- TODO: useful for cases where we trigger a branch before the user gets there
  -- if vehWpData.next == insertIndex then
  --   vehWpData.next = insertIndex - 1
  -- elseif vehWpData.cur == insertIndex then
  --   vehWpData.next = vehWpData.cur - 1
  -- end

  if insertIndex then
    -- log('I', logTag,'player data ')
    -- dump(vehWpData)

    vehWpData.next = insertIndex - 1
    processWaypoint(vehicleID)

    if vehWpData.next == insertIndex then
      log('I', logTag,'wp to set '..scenario.lapConfig[vehWpData.next])
    end
    if vehWpData.next2 then
      log('I', logTag,'next wp to set '..scenario.lapConfig[vehWpData.next2])
    end
  end
end

local function addWaypointBranch(branchName, waypointsData, action, location)
  -- log('I', logTag,'processWaypointBranch called for '..branchName)
  -- dump(waypointsData)
  -- dump(action)
  -- dump(location)

   local scenario = scenario_scenarios.getScenario()
   if not scenario then return end

  local waypointsProcessed = {}
  for i, v in ipairs(waypointsData) do
    if type(v) == 'string' then
      table.insert(waypointsProcessed, v)
    elseif  type(v) == 'table' then
      addWaypointBranch(v[1], scenario.lapConfigBranches[v[1]], 'after', waypointsProcessed[#waypointsProcessed])
      addWaypointBranch(v[2], scenario.lapConfigBranches[v[2]], 'after', waypointsProcessed[#waypointsProcessed])
    end
  end

  if waypointsProcessed then
    local insertionData = {waypoints=waypointsProcessed, action=action, location=location}
    waypointBranches[branchName] = insertionData
  end
end

local function onRaceStart()
  -- log('I', logTag,'onRaceStart called')
  local scenario = scenario_scenarios.getScenario()
  if scenario then
    scenario.disableWaypointTimes = scenario.lapConfigBranches

    if scenario.BranchLapConfig then
      local lastWaypoint
      for i, v in ipairs(scenario.BranchLapConfig) do
        if type(v) == 'string' then
          lastWaypoint = v
        elseif type(v) == 'table' then
          addWaypointBranch(v[1], scenario.lapConfigBranches[v[1]], 'after', lastWaypoint)
          addWaypointBranch(v[2], scenario.lapConfigBranches[v[2]], 'after', lastWaypoint)
        end
      end
    end
  end
end

local function setupWaypointsData(scenario)
  vehicleWaypointsData = {}
  nextWpForVehicle = {}
  waypointBranches = {}
  currentWaypointChoise = {}

  -- Set waypoint for all vehicles
  if scenario.lapConfig then
    for _, vid in pairs(scenario.vehicleNameToId) do
        initialiseVehicleData(vid)
    end
  end
end

local function onScenarioRestarted(scenario)
  log('I', logTag,'onScenarioRestarted called')

  for branchName,data in pairs(waypointBranches) do
    deactivateWaypointBranch(branchName)
  end

  setupWaypointsData(scenario)

  -- log('I', logTag,'lapConfig: ')
  -- dump(scenario.lapConfig)

  -- log('I', logTag,'player waypoint: ')
  -- local vid = be:getPlayerVehicleID(0)
  -- local w = vehicleWaypointsData[vid]
  -- dump(w)
  -- dump(vehicleWaypointsData)
end

local function initialise()
  if campaign_campaigns and campaign_campaigns.getCampaignActive() then

    local campaign = campaign_campaigns.getCampaign()
    local configData = campaign.meta.waypoints or {}
    waypointsConfigData.highlightLastWaypoint = configData.highlightLastWaypoint and configData.highlightLastWaypoint.enabled == true

    if waypointsConfigData.highlightLastWaypoint then
     local color = configData.highlightLastWaypoint.color or { 0, 0.07, 1, 1}
     waypointsConfigData.lastWaypointColor = ColorF(color[1], color[2], color[3], color[4])
    else
      raceMarker.removeFinalMarker()
    end
  else
      raceMarker.removeFinalMarker()
  end

  local scenario = scenario_scenarios.getScenario()
  setupWaypointsData(scenario)

  -- For Prototype idea of highlighting the final waypoint always
  if waypointsConfigData.highlightLastWaypoint and scenario.lapConfig then
    local numWaypoints = #scenario.lapConfig
    local lastWpName = scenario.lapConfig[numWaypoints]
    local lastWp = scenario.nodes[lastWpName]
    if lastWp then
      raceMarker.setFinalMarkerPosition(vec3(lastWp.pos),  lastWp.radius, waypointsConfigData.lastWaypointColor)
    end
  end
  ---- End of Prototype idea
end

local function onUpdate()
  if not scenario_scenarios then return end
  local scenario = scenario_scenarios.getScenario()
  local veh = be:getPlayerVehicle(0)
  if not scenario or not veh then return end
  for k, v in pairs(currentWaypointChoise) do
    local wpPos = Point3F(scenario.nodes[v].pos.x, scenario.nodes[v].pos.y, scenario.nodes[v].pos.z)
    local dist = (wpPos - veh:getPosition()):len()
    if dist < math.max(25, scenario.nodes[v].radius * 3) then
      activateWaypointBranch(k, veh:getID())
      currentWaypointChoise = {}
      return
    end
  end
end

local function isFinalWaypoint(vehicleId, waypointName)
  local scenario = scenario_scenarios.getScenario()

  if not scenario or not scenario.lapConfig then
    return false
  end

  local vehWaypointData = vehicleWaypointsData[vehicleId]
  if not vehWaypointData then
    return false
  end

  -- log('I', logTag,'isFinalWaypoint called...')
  -- dump(scenario.lapConfig)

  local testWp = {cur = -1, lap = vehWaypointData.lap}
  -- log('I', logTag,'isFinalWaypoint trying to find waypoint: '..waypointName)

  for i,wpName in ipairs(scenario.lapConfig) do
    -- log('I', logTag,'waypoint: '..wpName)
    if wpName == waypointName then
      testWp.cur = i
      break
    end
  end

  if testWp.cur == -1 then
    return true
  end

  -- log('I', logTag,'Found testWp.cur: '..testWp.cur)
  local nextWp = getNextWaypoint(testWp, 1)
  -- log('I', logTag,'isFinalWaypoint returned: '..tostring(nextWp == nil))

  return nextWp == nil
end

local function getVehicleWaypointData(vehicleID)
  local data = deepcopy(vehicleWaypointsData[vehicleID])
  return data
end

local function onSerialize()
  -- log('D', logTag, 'onSerialize called...')
  local data = {}
  data.vehicleWaypointsData = convertVehicleIdKeysToVehicleNameKeys(vehicleWaypointsData)
  data.nextWpForVehicle = convertVehicleIdKeysToVehicleNameKeys(nextWpForVehicle)
  data.waypointBranches = waypointBranches
  data.currentWaypointChoise = currentWaypointChoise
  data.currentBranch = currentBranch
  -- dump(data)
  --writeFile("scenario_waypoints.txt", dumps(data))
  return data
end

local function onDeserialized(data)
  -- log('D', logTag, 'onDeserialized called...')
  vehicleWaypointsData = convertVehicleNameKeysToVehicleIdKeys(data.vehicleWaypointsData)
  nextWpForVehicle = convertVehicleNameKeysToVehicleIdKeys(data.nextWpForVehicle)
  waypointBranches = data.waypointBranches
  currentWaypointChoise = data.currentWaypointChoise
  currentBranch = data.currentBranch
end

local function onVehicleAIStateChanged(data)
  if data and data.aiControlled == true then
    initialiseVehicleData(data.vehicleId)
  end
end

-- public interface
M.onPreRender               = onPreRender
M.onScenarioVehicleTrigger  = onScenarioVehicleTrigger
M.onVehicleSwitched         = onVehicleSwitched
M.onScenarioChange          = onScenarioChange
M.onRaceStart               = onRaceStart
M.onScenarioRestarted       = onScenarioRestarted
M.onRaceWaypointReached     = onRaceWaypointReached
M.onUpdate                  = onUpdate
M.getVehicleWaypointData    = getVehicleWaypointData
M.initialise                = initialise
M.deactivateWaypointBranch  = deactivateWaypointBranch
M.activateWaypointBranch    = activateWaypointBranch
M.addWaypointBranch         = addWaypointBranch
M.isFinalWaypoint           = isFinalWaypoint
M.onSerialize               = onSerialize
M.onDeserialized            = onDeserialized
M.onVehicleAIStateChanged   = onVehicleAIStateChanged
return M

