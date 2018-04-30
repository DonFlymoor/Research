-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local scenario = nil
local logTag = 'scenarios'

local allowUnassigned = false -- allows specific devices to NOT be assigned to any vehicle. cannot be enabled until input system supports it

local debugDrawDistance = 200
local delayCameraPath = nil
local scenarioStateAtPauseEvent = nil
local displayEndUITimer = 0
local endUIDisplayed = false


local inputActionFilter = require('input_action_filter')
inputActionFilter.setGroup('camera_blacklist', {"toggleCamera", "switch_camera_next", "dropCameraAtPlayer"} )
inputActionFilter.setGroup('default_blacklist_scenario', {"switch_next_vehicle", "switch_previous_vehicle", "loadHome", "saveHome", "recover_vehicle", "reload_vehicle",
  "vehicle_selector", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender", "slower_motion", "faster_motion", "realtime_motion", "slow_motion"} )
inputActionFilter.setGroup('default_whitelist_scenario', {} )
inputActionFilter.setGroup('default_whitelist_campaign', {} )

if gdcdemo then
  local filters = inputActionFilter.getGroup('default_blacklist_scenario')
  table.insert(filters, 'toggleMenues')
end

local helper = require('scenario/scenariohelper')
local raceMarker = require("scenario/race_marker")

local finalTime = 0
local raceTickTimer = 0
local endRaceCountdown = 0
local needFreezeVehicles = false

-- Time conversion
local function timeToString(finalTime)
  local minutes = math.floor(finalTime / 60);
  local seconds = finalTime - (minutes * 60);
  local timeStr = string.format("%02.0f:%05.2f", minutes, seconds)
  return timeStr
end

-- freezing of the vehicles before the countdown is done
local function freezeAll(state)

  if not scenario then
    log('D', logTag, 'Freeze all did not find a scenario....')
    return
  end

  if scenario.vehicleNameToId then
    for k, vid in pairs(scenario.vehicleNameToId) do
      local bo = be:getObjectByID(vid)
      if bo then
        bo:queueLuaCommand('controller.setFreeze('..tostring(state) ..')')
      end
    end
  else
    log('W', logTag, 'There are no vehicles to freeze.')
  end
end

local function initVehicleAIState()
  math.randomseed(os.time())
  for vName, vObjId in pairs(scenario.vehicleNameToId) do
    if scenario.vehicles[vName] then
      local targetvehicle,targetVehId
      if scenario.vehicles[vName].driver["fleeTarget"] then
       targetvehicle = scenetree.findObject(scenario.vehicles[vName].driver["fleeTarget"])
       targetVehId = targetvehicle:getID()
       helper.queueLuaCommandByName(vName,'ai.setTargetVehicleID('..targetVehId..')')
      end
      if scenario.vehicles[vName].driver["ModeAI"] then
        helper.setAiMode(vName, scenario.vehicles[vName].driver["ModeAI"])
      end
      if scenario.vehicles[vName].driver["roadDrivability"] then
        helper.setCutOffDrivability(vName, scenario.vehicles[vName].driver["roadDrivability"])
      end
      if scenario.vehicles[vName].driver["command"] then
        if type(scenario.vehicles[vName].driver["command"]) == "table" then
          for i,v in pairs (scenario.vehicles[vName].driver["command"]) do
            helper.queueLuaCommandByName(vName, scenario.vehicles[vName].driver["command"][i])
          end
        elseif type(scenario.vehicles[vName].driver["command"]) == "string" then
          helper.queueLuaCommandByName(vName, scenario.vehicles[vName].driver["command"])
        end
      end
      if scenario.vehicles[vName].driver["targetAI"] then
        local targetName = scenario.vehicles[vName].driver["targetAI"][math.random(#scenario.vehicles[vName].driver["targetAI"])]
        scenario.targetName=targetName
        helper.setAiTarget(vName,targetName)
      end
      if scenario.vehicles[vName].driver["AiAggression"] then
        helper.setAiAggression(vName,scenario.vehicles[vName].driver["AiAggression"])
      end
      if scenario.vehicles[vName].driver["frozen"] then
        local carName = helper.getVehicleByName(vName)
        carName:queueLuaCommand('controller.setFreeze(1)')
      end
    end
  end
end

local function changeState(newState)
  if not scenario then return end
  log('D', logTag, 'changeState: ' .. tostring(newState))

  scenario.state = newState

  if scenario.state == 'pre-start' then
    -- Collisions should always be enabled during scenarios
    -- log('I', logTag, 'enabling dynamicCollision...')
    be:setDynamicCollisionEnabled(true)

    needFreezeVehicles = true

    if scenario.showCountdown == nil then scenario.showCountdown = true end

    scenario.showCountdown = scenario.showCountdown and not scenario.rollingStart
  elseif scenario.state == 'pre-running' then
    -- scenario is still in introduction phase
    guihooks.trigger('ScenarioResetTimer')
    guihooks.trigger('setQuickRaceMode')
    guihooks.trigger("HotlappingResetApp")
    scenario.raceState = ''
    scenario.currentLap = 0
    scenario.timerActive = true

    raceMarker.init()
    if scenario_raceGoals then scenario_raceGoals.initialiseGoals() end
    scenario_waypoints.initialise()

    freezeAll(1)
  elseif scenario.state == 'running' and scenario.raceState == '' then
    -- the scenario just entered running state
    scenario.raceState = 'countdown'

    -- start the countdown
    scenario.timer = 0

     -- this states will be removed after countdown
    if not scenario.showCountdown then
      scenario.countDownTime = 1.5
    else
      scenario.countDownTime = 3.5
    end

    scenario.countDownShowed = false

    initVehicleAIState()

    extensions.hook("onRaceInit")
  elseif scenario.state == 'finished' then
    extensions.hook('onScenarioFinished', scenario)
  elseif scenario.state == 'post' then
    -- scenario just finished
    scenario.raceState = 'done'
    raceMarker.hide(true)
  end

  extensions.hook('onScenarioChange', scenario)
end

local function getRaceDistance(scenario)
  if not scenario or not scenario.lapConfig then
    return 0
  end

  local distance = 0

  -- get the last entry in the list, this is usually the last waypoint in the path
  local numWaypoints = #scenario.lapConfig -- tableSize(scenario.lapConfig)
  -- log('I', 'scenario.race', 'number of waypoint '..numWaypoints)

  local mapDataNodes = map.getMap().nodes
  for i = 1, numWaypoints - 1 do
    local node1 = mapDataNodes[scenario.lapConfig[i]]
    local node2 = mapDataNodes[scenario.lapConfig[i + 1]]

    local pos1
    if not node1 then
      node1 = scenetree.findObject(scenario.lapConfig[i])
      pos1 = node1:getPosition()
    else
      pos1 = node1.pos
    end

    local pos2
    if not node2 then
      node2 = scenetree.findObject(scenario.lapConfig[i + 1])
      pos2 = node2:getPosition()
    else
      pos2 = node2.pos
    end

    -- log('I', 'scenario.race', 'node1: '..scenario.lapConfig[i])
    -- log('I', 'scenario.race', 'node2: '..scenario.lapConfig[i + 1])

    if node2 and node1 then
      distance = distance + (pos2 - pos1):len()
    else
      if not node2 then
        log('I', 'scenario.race', 'node2 is null: '..scenario.lapConfig[i + 1])
      end
      if not node1 then
        log('I', 'scenario.race', 'node1 is null: '..scenario.lapConfig[i])
      end
    end
  end

  return distance
end

local function stopRaceTimer()
  if not scenario then return end
  scenario.timerActive = false
end

local function pauseScenario()
  -- freezeAll(1)
  bullettime.pause(true)
end

local function continueScenario()
  -- freezeAll(0)
  bullettime.pause(false)
end

local function onRaceEnd()

end

local function endRace(countDownTime)
  log('I', logTag, 'endRace called...'..tostring(countDownTime))

  if not scenario then return end

  if scenario.state ~= 'finished' and scenario.state ~= 'post' then
    changeState('finished')
    endRaceCountdown = countDownTime or scenario.endCountDownTime or 3;
    finalTime = scenario.timer
    raceMarker.hide(true)
  end
end

local function prepareStartUI()
  if scenario then
    scenario.displayStartUIRefs = 0
  end
end

local initialLevelState = nil -- store the orginal level environment state

-- restore the original environment state of the level
local function restoreLevelState()
  if not initialLevelState then return end
  for objName, objFields in pairs(initialLevelState) do
    local levelObj = scenetree.findObject(objName)
    if levelObj and levelObj.obj then
      for field, value in pairs(objFields) do
        --log('D', logTag, 'setting [' .. tostring(objName)..'] field:'..tostring(field)..' value:'..tostring(value))
        levelObj:setField(field, "", tostring(value))
      end
      levelObj:postApply()
    end
  end
  initialLevelState = nil
end

-- set the modifications to level state from json and store original values
local function changeLevelState()
  if initialLevelState then
    restoreLevelState()
  end

  initialLevelState = {}
  if type(scenario.levelObjects) ~= 'table' then return end
  for objName, objFields in pairs(scenario.levelObjects) do
    local levelObj = scenetree.findObject(objName)
    if levelObj and levelObj.obj then
      initialLevelState[objName] = initialLevelState[objName] or {}
      for field, value in pairs(objFields) do
        --log('D', logTag, 'setting [' .. tostring(objName)..'] field:'..tostring(field)..' value:'..tostring(value))
        initialLevelState[objName][field] = levelObj:getField(field, "0")
        levelObj:setField(field, "", tostring(value))
      end
      levelObj:postApply()
    else
      log('E', logTag, 'unable to find obj: ' .. tostring(objName))
    end
  end
end

-- stops and unloads any scenario completely
local function stop()
  if not scenario then return end

  --disable multiseat after scenario
  if settings.getValue( 'multiseat' ) == true then
    log('D', logTag, "Disabling multiseat")
    settings.setState( { multiseat = false } )
    extensions.unload("core_multiseatCamera")
  end

  -- unload any loaded extensions
  log('D', logTag, "Unloading any scenario extensions")
  if scenario and scenario.extensions then
    for _, e in ipairs(scenario.extensions) do
      if type(e) == 'table' and e.loaded then
        extensions.unload(scenario.directory.."/"..e.name)
      elseif type(e) == 'string' then
        extensions.unload('scenario_' .. e)
      else
        log('D', logTag, "Can't unload scenario extension:" .. dumps(e))
      end
    end
  end

  -- TODO: Remove this once bulletTime is no more
  -- Make sure bullettime is also aware to reset its internal data.
  bullettime.set(1)

  --make sure bullet time is reset
  be:setSimulationTimeScale(1)

  -- revert filtered bindings
  inputActionFilter.clear(0)

  restoreLevelState()

  scenario = nil

  guihooks.trigger('ScenarioChange', scenario)

  extensions.hook('onScenarioChange')
end

local function gatherEndStats()
  log('D', logTag, 'gatherEndStats called')
  local statsData = {title=''}

  if campaign_campaigns and campaign_campaigns.getCampaignActive() then
    statsData.campaigntitle = campaign_campaigns.getCampaignTitle()
  end

  statsData.title = scenario.name

  -- statsData.achievments= {'Not [br] Implemented'}

  local buttonLabel = nil
  if scenario.result.failed then
    statsData.text=scenario.result.failed
    buttonLabel = 'ui.common.skip'
  else
    statsData.text=scenario.result.msg

    buttonLabel = 'ui.common.next'
  end

  statsData.time = scenario.result.finalTimeStr
  if campaign_campaigns and campaign_campaigns.getCampaignActive() then
    if campaign_campaigns.isCampaignOver(scenario) then
      buttonLabel = 'ui.common.finish'
    end
    statsData.buttons={{label='ui.common.retry', cmd='campaign_campaigns.uiEventRetry()', active = scenario.result.failed}, {label='ui.common.menu', cmd='openMenu'}, {label=buttonLabel, cmd='campaign_campaigns.uiEventNext()', active = not scenario.result.failed}}
  elseif scenario_quickRace then
    statsData.buttons={{label='ui.common.retry', cmd='scenario_scenarios.uiEventRetry()', active = scenario.result.failed}, {label='ui.scenarios.end.freeroam', cmd='scenario_scenarios.uiEventFreeRoam()'}, {label='ui.common.menu', cmd='openMenu'}, {label='ui.quickrace.changeConfig', cmd='openQuickrace'}}
  else
    statsData.buttons={{label='ui.common.retry', cmd='scenario_scenarios.uiEventRetry()', active = scenario.result.failed}, {label='ui.scenarios.end.freeroam', cmd='scenario_scenarios.uiEventFreeRoam()'}, {label='ui.common.menu', cmd='openMenu'}, {label='ui.dashboard.scenarios', cmd='openScenarios'}}
  end

  if gdcdemo then
    for i, v in ipairs(statsData.buttons) do
      if v.label == 'ui.common.menu' then
        table.remove(statsData.buttons, i)
      end
    end
  end

  statsData.overall= statistics_statistics.getScenarioOverallStat(scenario)
  statsData.stats = {}
  local vid = be:getPlayerVehicleID(0)
  local fullStats = statistics_statistics.getVehicleStat(vid)

  -- no points for failed scenarios
  if scenario.result.failed then statsData.overall.points = 0 end

  -- filter the stats
  if fullStats then
    for index, entry in ipairs(fullStats) do
      local needed = false
      if entry.required and entry.failed then
        needed = true
        entry.relativePoints = 100
      end
      needed = needed or (not scenario.result.failed and entry.maxPoints and entry.points)

      if entry.maxPoints and entry.maxPoints < 0 then
        entry.failed = true -- show as red on interface
      end

      if needed then table.insert(statsData.stats, entry) end
    end
  end
  return statsData
end

local function loadStatsHelper (player, community, max)
  if max and max > 0 then
    return (player / max) * 100, (community / max) * 100
  else
    return 100, 100
  end
end

local function loadStats (stats)
  local fileData = readJsonFile('settings/playerStatistics.json') or {}
  local data = fileData[scenario.scenarioName]
  local statData = deepcopy(stats)

  if data ~= nil and data.overall ~= nil then
    statData.overall.player, statData.overall.community = loadStatsHelper(stats.overall.player, data.overall.value, data.overall.max)
  else
    statData.overall.player, statData.overall.community = 100, nil
  end

  for _, v in pairs(statData.stats) do
    if data ~= nil then
      if data.stats[v.label] ~= nil and v.value ~= nil then
        v.player, v.community = loadStatsHelper(v.value, data.stats[v.label].value, data.stats[v.label].max)
        v.maxValue = data.stats[v.label].max
      elseif v.failed ~= nil then
        v.numPassed = data.stats[v.label].value * 100
      end
    else
      v.player, v.community = 100, nil
    end
  end

  return statData
end

local function saveStatsHelper (obj, key, val)
  if not val then return end
  if obj[key] ~= nil then
    obj[key].value = ((obj[key].value * obj[key].numPlayed) + val) / (obj[key].numPlayed + 1)
    obj[key].numPlayed = obj[key].numPlayed + 1
    obj[key].max = math.max(val, obj[key].max or 0)
    obj[key].min = math.min(val, obj[key].min or 999999)
  elseif key then
    obj[key] = {
      value = val,
      max = val,
      min = val,
      numPlayed = 1
    }
  end
end

local function saveStats (stats)
  local data = readJsonFile('settings/playerStatistics.json') or {}

  if data.header == nil then
    data.header = {
                    version = 1,
                    name = "Statistics  File",
                    comments = "// Each scenario has an entry. Entry contains 2 objects - one for Overall stat and the other for the stats. In stats, we store 1 entry per relevant stat"
                  }
  end

  if data[scenario.scenarioName] == nil then
    data[scenario.scenarioName] = {
      stats = {}
    }
  end

  -- log('I', logTag, 'saveStats called.....')
  -- dump(stats)

  for _, v in pairs (stats.stats) do
    local value = v.value or 0
    if v.failed ~= nil then
      if v.failed then
        value = 0
      else
        value = 1
      end
    end
    if data[scenario.scenarioName].stats[v.label] == nil and v.failed ~= nil then
      data[scenario.scenarioName].stats[v.label] = {
        max = 1,
        min = 0,
        value = value,
        numPlayed = 1
      }
    else
      saveStatsHelper(data[scenario.scenarioName].stats, v.label, value)
    end
  end

  saveStatsHelper(data[scenario.scenarioName], 'overall', stats.overall.player)

  serializeJsonToFile('settings/playerStatistics.json', data)
end

-- called by the game logic to end the scenario in some way
-- result table structure:
-- failed: if not nil, the scenario is considered to be failed. Contains a string with the failure reason
-- msg: the message to be displayed if successful
-- tl;dr: set 'failed'  to a string on failure, otherwise do not specify it. Set msg on success.
local function finish(result)
  if scenario.state == 'post' then
    if not scenario.displayedMultipleFinished then
      log('W', logTag, 'Scenario: '..scenario.name..' already finished. Aborting extra finish call.')
      scenario.displayedMultipleFinished = true
    end
    return
  end

  scenario.cachedFinshResult = result
  endRace(0)
end

-- called on level unloading
local function onClientEndMission(mission)
  log('I', logTag, 'onClientEndMission called - mision = '.. tostring(mission)..' scenario.mission = '..tostring(scenario and scenario.mission or 'nil'))
  if scenario ~= nil and mission == scenario.mission then
    stop()
  end

  be:setSimulationTimeScale(1)

  local disableDynamicCollision = settings.getValue('disableDynamicCollision', true)
  be:setDynamicCollisionEnabled(not disableDynamicCollision)
end

-- 0 = unload
-- 1 = add, but not load
-- 2 = add and load
local function deprecatedSpawnPrefab(val, objName, objFileName, objPos, objRotation, objScale)
  log('W', logTag, 'scenario_scenarios.spawnPrefab is deprecated. Please use spawnPrefab from ge_utils')
  if val == 2 then
    return spawnPrefab(objName, objFileName, objPos, objRotation, objScale)
  elseif val == 1 then
    return addPrefab(objName, objFileName, objPos, objRotation, objScale)
  else
    removePrefab(objName)
  end
end

-- Setup the path camera if one exists in level
local function setupPathCamera()
  local democam = scenetree.findObject('democam')
  if democam and democam.className == 'SimPath' then
    local initData = {}
    initData.hasIntro = scenetree.findObject("democam_intro") ~= nil
    initData.hasDemo = scenetree.findObject("democam") ~= nil
    initData.hasCampaignIntro = scenetree.findObject("democam_campaign_intro") ~= nil
    initData.getNextPath = nop
    if initData.hasDemo or initData.hasIntro then
      initData.loopCount = 0
      initData.reset = function(this)
        this.loopCount = 0
      end
      initData.getNextPath = function(this)
        if this.hasCampaignIntro then
          this.hasCampaignIntro = nil
          return "democam_campaign_intro"
        end
        if this.hasDemo and this.loopCount > 0 then
          if this.loopCount == 1 then guihooks.trigger("scenarioStart:showStartButton", true) end
          this.loopCount = this.loopCount -1
          return "democam"
        end
        this.loopCount = 2
        if this.hasIntro then
          return "democam_intro"
        end
        return nil
      end
    end

    core_camera.setByName(0, "path", false, initData)
    core_camera.resetCamera(0)
  end
end

local function addBackwardCompatibility(sc)
  if not sc then return end

  sc.vehiclesByName = nil
  sc.vehiclesByID = nil
  sc.vehicleInitialTransform = nil
  local backwardCompatibility = {
    __index = function(tbl, key)
      if key == 'vehiclesByName' then
        if not tbl.warnedDeprecatedVehiclesByName then
          log('W', logTag, 'vehiclesByName field is deprecated. Please use field vehicleNameToId')
          tbl.warnedDeprecatedVehiclesByName = true
        end
        return rawget(tbl, 'vehicleNameToId')
      end
      if key == 'vehiclesByID' then
        if not tbl.warnedDeprecatedVehiclesByID then
          log('W', logTag, 'vehiclesByID field is deprecated. Please use either field vehicleNameToId or vehicleIdToName')
          tbl.warnedDeprecatedVehiclesByID = true
        end
        return {}
      end
      if key == 'vehicleInitialTransform' then
        if not tbl.warnedDeprecatedVehicleInitialTransform then
          log('W', logTag, "vehicleInitialTransform field is deprecated. Please use field startingTransforms with vehicle's name as the key")
          tbl.warnedDeprecatedVehicleInitialTransform = true
        end
        return {}
      end

      return rawget(tbl, key)
    end
  }
  setmetatable(sc, backwardCompatibility)
end

local function processVehicleStartingTransform()
  if not scenario then return end
  scenario.startingTransforms = {}
  for vecName, vid in pairs(scenario.vehicleNameToId) do
    local vehicle = be:getObjectByID(vid)
    scenario.startingTransforms[vecName] = {pos = vehicle:getPosition(), rot = vehicle:getRotation()}
  end
end

local function processVehiclesInScene()
  -- now iterate over all vehicles in the scene and put them into an order
  -- this also searches for the player vehicle
  if not scenario then return end

  local vehicles = scenetree.findClassObjects('BeamNGVehicle')
  log('D', logTag, "found " .. #vehicles .. " vehicles")
  scenario.vehicleNameToId = {}
  scenario.vehicleIdToName = {}
  scenario.playerUsableVehicles = {}

  local playerVehicleFound = false
  for k, vecName in ipairs(vehicles) do
    local to = scenetree.findObject(vecName)
    if to and to.obj and to.obj:getID() and prefabIsChildOfGroup(to.obj, 'ScenarioObjectsGroup') then
      local vehicleConf = scenario.vehicles['*']
      if scenario.vehicles[vecName] then
        vehicleConf = scenario.vehicles[vecName]
      end

      if vehicleConf then
        if not vehicleConf.driver then vehicleConf.driver = {} end
        -- determine if its usable by the player (if you can switch to it)
        if vehicleConf.playerUsable or vehicleConf.driver.player then
          to.obj.playerUsable = true
        else
          to.obj.playerUsable = false
        end

        -- determine the starting (player 0) vehicle
        local player = 0 -- TODO: may need to loop through all human players if/when we spawn levels with several vehicles?
        if vehicleConf.startFocus or (vehicleConf.driver.player and vehicleConf.driver.startFocus) then
            be:enterVehicle(player, to.obj)
            commands.setGameCamera()
            scenario.focusSlot = to.obj:getID()
            playerVehicleFound = true
        end

        -- load any scenario vehicle extensions
        if type(vehicleConf.extensions) == 'table' then
          for vek, ve in pairs(vehicleConf.extensions) do
            to.obj:queueLuaCommand('extensions.scenario_' .. vek  .. '.onVehicleScenarioData(' .. serialize(ve) .. ')')
          end
        end

        if to.obj.playerUsable then
          table.insert(scenario.playerUsableVehicles, vecName)
        end
      end

      --reset bullet time
      bullettime.set(1)

      scenario.vehicleNameToId[vecName] = to.obj:getID()
      scenario.vehicleIdToName[to.obj:getID()] = vecName
      log('D', logTag, tostring(to.obj:getID()) .. ' = ' .. tostring(vecName))
    end
  end
  addBackwardCompatibility(scenario)

  if not playerVehicleFound then
    log('E', logTag, 'Player vehicle not found. Please check if your vehicle in the prefab has the same name as in the json.')
  end
end

local function processWaypointsInScene()
  -- we are figuring out the waypoints and build the node graph with the positions of the level
  -- first step: complete the node graph with the spawned waypoints
  scenario.nodes = {}
  for k, nodeName in ipairs(scenetree.findClassObjects('BeamNGWaypoint')) do
    --log('D', logTag, tostring(k) .. ' = ' .. tostring(nodeName))
    local o = scenetree.findObject(nodeName)
    if o then
      if scenario.nodes[nodeName] == nil then
        local rota = nil
        if o:getField('directionalWaypoint',0) == '1' then
           rota = quat(o:getRotation())*vec3(1,0,0)
        end

        scenario.nodes[nodeName] = {
          pos = vec3(o:getPosition()),
          radius = getSceneWaypointRadius(o),
          rot = rota
        }

      end
    else
      log('E', logTag, 'waypoint not found: ' .. tostring(nodeName))
    end
  end

  --reset map to make sure waypoints from the prefab are also considered
  map.load()

  -- second step: try to find the waypoint in the AI graph
  local mapData = map.getMap()

  if mapData and scenario.lapConfig then
    local aiRadFac = (scenario.radiusMultiplierAI or 1)
    for _, wp in ipairs(scenario.lapConfig) do
      if scenario.nodes[wp] == nil then
        if mapData.nodes[wp] ~= nil then
          scenario.nodes[wp] = deepcopy(mapData.nodes[wp])
          scenario.nodes[wp].radius = scenario.nodes[wp].radius * aiRadFac
          scenario.nodes[wp].pos = vec3(scenario.nodes[wp].pos)
          scenario.nodes[wp].rot = vec3(scenario.nodes[wp].rot)
        else
          log('E', logTag, 'unable to find waypoint: ' .. tostring(wp))
        end
      end
    end
  else
    log('W', logTag, 'no ai graph for this map found')
  end
end

-- this function is called when the level that the scenario needs loaded successfully
local function onClientStartMission(mission)

  core_environment.reset_init()
  inputActionFilter.clear(0)

  -- cleanup any remaining scenario objects by deleting the whole group
  -- cleanup needs to happen here not on endmission as they are not called in the correct order
  --log('D', logTag, 'executing TS: ' .. ts)
  if(scenetree.ScenarioObjectsGroup) then scenetree.ScenarioObjectsGroup:delete() end
  TorqueScript.setVar( '$preventPlayerSpawning', '' )
  if scenario == nil then
    --log('D', logTag, 'no scenario loaded')
    return
  end
  log('D', logTag, 'Starting scenario : '..tostring(translateLanguage(scenario.name, scenario.name)))
  log('D', logTag, 'Scenario path : '..tostring(scenario.sourceFile))

  local path = 'levels/' .. scenario.levelName .. '/'

  -- create the special simgroup where we put all objects of the scenario in
  --log('D', logTag, 'executing TS: ' .. ts)
  --TODO need to change player delete() for carrier mode
  if(scenetree.thePlayer) then scenetree.thePlayer:delete() end
  local ScenarioObjectsGroup = createObject('SimGroup')
  if not ScenarioObjectsGroup then
    log('E', logTag, 'ScenarioObjectsGroup not existing')
    return
  end

  local MissionGroup = scenetree.MissionGroup
  if not MissionGroup then
    log('E', logTag, 'MissionGroup not existing')
    return
  end

  ScenarioObjectsGroup:registerObject('ScenarioObjectsGroup')
  ScenarioObjectsGroup.canSave = false
  MissionGroup:addObject(ScenarioObjectsGroup.obj)

  -- spawn the prefabs of the scenario
  log('D', logTag, 'spawning prefabs ...')
  for i, filename in ipairs(scenario.prefabs) do
    if filename:find('.prefab') == nil then
      filename = filename .. '.prefab'
    end
    if not FS:fileExists(filename) then
      log('E', logTag, 'Prefab file not existing: '.. tostring(filename) .. ' - IGNORING IT')
    else
      local objName = string.gsub(filename, "(.*/)(.*)%.prefab", "%2")
      if not scenetree.findObject(objName) then
        --log('D', logTag, 'executing TS: ' .. ts)
        local prefabObj = spawnPrefab(objName, filename, '0 0 0', '0 0 1', '1 1 1')
        ScenarioObjectsGroup:addObject(prefabObj.obj)
      else
        log('E', logTag, 'Prefab: '..objName..' already exist in level')
      end
    end
  end

  -- Spawn any user selected vehicles
  if scenario.userSelectedVehicle then
    local model = scenario.userSelectedVehicle.model
    local config = scenario.userSelectedVehicle.config
    local color = scenario.userSelectedVehicle.color
    local licenseText = scenario.userSelectedVehicle.licenseText
    scenario.userSpawningData = createPlayerSpawningData(model, config, color, licenseText)
    local currentUserVehicle = be:getPlayerVehicle(0)
    if currentUserVehicle then
      core_vehicles.replaceVehicle(scenario.userSpawningData.model, scenario.userSpawningData.options)
    else
      core_vehicles.spawnNewVehicle(scenario.userSpawningData.model, scenario.userSpawningData.options)
    end
  end

  extensions.hook('onLoadCustomPrefabs', scenario)

  -- TODO(AK): Move all the processing below out of this function and into a different stage to allow the user
  --           Selected vehicle to spawn and get added to the scene
  -- TODO(AK): Do not depend on the list of vehicles in the scenario, user can now add a different vehicle to the scenario
  processVehiclesInScene()
  processVehicleStartingTransform()
  processWaypointsInScene()

  -- next step: apply the attribute changes for this scenario
  changeLevelState()

  -- load blackListed actions: essentially disabling hotkeys for the user
  inputActionFilter.clear(0)
  if type(scenario.blackListActions) == 'table' then
    for i, action in ipairs( scenario.blackListActions ) do
      --log('D', logTag, 'add action to blackList: ' .. tostring(action))
      inputActionFilter.addAction(0, action, true)
    end
  end
  if type(scenario.whiteListActions) == 'table' then
    for i, action in ipairs( scenario.whiteListActions ) do
      --log('D', logTag, 'add action to whiteList: ' .. tostring(action))
      inputActionFilter.addAction(0, action, false)
    end
  end

  if scenario.camera and scenario.camera.name then
    -- set free camera and use camera bookmark
    local cameraMark = scenetree.findObject(scenario.camera.name)
    if cameraMark then
      commands.setFreeCamera()
      local game = commands.getGame()
      local camera = commands.getCamera(game)
      camera:setTransform(cameraMark:getTransform())
      if scenario.camera.mode == "Stationary" then
        TorqueScript.eval( 'Game.core_camera.controlMode = "Stationary";' )
      else
        TorqueScript.eval( 'Game.core_camera.controlMode = "Fly";' )
      end
    end
  end

  -- autoenable multiseat for scenario with multiple players
  local isMultiseat = scenario.playersCountRange.min > 1
  settings.setValue('multiseat', isMultiseat)

  -- Tell others the scenario is fully loaded
  extensions.hook('onScenarioLoaded', scenario)
  prepareStartUI()
end

local function showIntroPrefab(visible)
  local introPrefab = scenetree.findObject(scenario.scenarioName..'_intro')
  if not introPrefab then return end
  if visible then
    introPrefab:load()
  else
    introPrefab:unload()
  end
end

local function onCameraHandlerSet()
  if scenario and not scenario.state then
    changeState('pre-start')
    setCEFFocus(false) -- focus the game now
  end
end

local function loadExtentions(scenario)
  if scenario and scenario.extensions then

    for _, e in ipairs(scenario.extensions) do
      if type(e) == 'table' then
        local moduleFullPath = scenario.directory.."/"..e.name
        if FS:fileExists(moduleFullPath.. '.lua') then
          extensions.load({{extName = moduleFullPath, globalAlias = 'scenario_'..e.name}})
          e.loaded = true
        elseif not e.optional then
          log('E', logTag, 'required extension missing: ' .. moduleFullPath.. '.lua')
        end
      elseif type(e) == 'string' then
        -- Looks in ge/extensions/scenario for these type of modules
        if not extensions.load('scenario_' .. e) then
          log('E', logTag, 'unable to load extension: scenario_' .. e)
        end
      end
    end
    --extensions.restoreModulePath()
  else
    log('D', logTag, 'no extensions specified')
    return
  end
end

local function executeScenario(sc)
  if scenario then
    stop()
  end

  if not sc then return end

  scenario = sc

  scenario.displayEndUIRefs = 0
  scenario.stats = nil
  displayEndUITimer = 0
  endUIDisplayed = false

  -- improve the data a little bit
  scenario.mission = 'levels/'..scenario.levelName..'/main.level.json'

  if not FS:fileExists(scenario.mission) then
    -- Fallback to old MIS file
    scenario.mission = 'levels/'..scenario.levelName..'/'..scenario.levelName..'.mis'
  end

  --load the scenario extension
  loadExtentions(scenario)

  -- do we need to change the level?
  local loadedMissionFile = getMissionFilename()
  if scenario.mission ~= loadedMissionFile then
    -- yes, change level, but disable the player autospawning
    log('D', logTag, 'loading level: ' .. scenario.mission)
    TorqueScript.eval('$preventPlayerSpawning="1";')

    beamng_cef.startLevel('levels/'..scenario.levelName..'/')--Tested&Works
  else
    -- already in the level, just load the scenario
    log('D', logTag, 'no need to load the level, already in there')
    onClientStartMission(scenario.mission)
  end
end

-- restarts the currently loaded scenario from the very start, unloading everything and loading everything again
-- important that this stays a reload and does not become an onload, since otherwise the reloading auto start bug happens again
local function restartScenario()
  guihooks.trigger('ScenarioNotRunning')

  displayEndUITimer = 0
  endUIDisplayed = false

  if not scenario then return end
  scenario.state = nil
  scenario.result = nil
  scenario.vehicleTrackingTable = nil
  scenario.playerIsDamaged = nil
  scenario.playerHasStopped = nil
  scenario.displayEndUIRefs = 0
  scenario.stats = nil
  scenario.cachedFinshResult = nil
  scenario.lapConfig = deepcopy(scenario.initialLapConfig)

  -- TODO(AK): This is such a bad approach. If you add a temp field and forget to delete it like those above, it persists to next try
  --           We should just have pre-saved version of the scenario data when it is first loaded (clean slate) and deepCopy that one instead
  --           of tweaking a used one with all sorts of modified state.

  local tmp = deepcopy(scenario)
  stop()

  scenario = tmp
  scenario.restartStage = 0
  changeState('restart')
end


-- draws a debug visualization on the screen that should help the author of the scenario
local function onDrawDebug(focusPos)
  if not scenario then return end

  local drawDebug = tonumber(getTSVar('$isEditorEnabled')) == 1 and tonumber(getTSVar('$pref::BeamNGRace::drawDebug')) == 1

  if drawDebug and scenario.nodes then
    for nid, n in pairs(scenario.nodes) do
      if (n.pos - focusPos):length() < debugDrawDistance then
        -- draw nodes
        local pp = n.pos:toPoint3F()
        debugDrawer:drawSphere(pp, n.radius, ColorF(0.5,0.5,0.5,0.3))
        debugDrawer:drawText(pp, String(tostring(nid)), ColorF(0,0,0,1))
      end
    end
  end
end

local function isMultiseatScenario()
    return scenario and scenario.playersCountRange.max > 1
end

-- return next playable vehicle (or '0' for unassigned vehicle)
local function getNextVehicleIndex( index, step )
  -- log("I", logTag, "getNextVehicleIndex called....")

  if allowUnassigned then
    -- the extra choice is "no vehicle assigned", represented by number 0
    local nChoices = tableSize(scenario.playerUsableVehicles) + 1
    return (index + step) % nChoices
  else
    local nChoices = tableSize(scenario.playerUsableVehicles)
    return ((index - 1 + step) % nChoices) + 1 -- vehicleIds range is 1..N
  end
end

local function getMultiseatConfigState()
  -- log("I", logTag, "getMultiseatConfigState called....")
  local state = {}
  state.invalidVehicles = {}
  state.players = {}
  local validVehicles = 0
  local vehicleDeviceCount = {}
  for _, assignment in ipairs(scenario.multiseatInput) do
    local devName = assignment.device
    local vehicleIndex = assignment.vehicleIndex
    local vehicleName = assignment.vehicleName

    vehicleDeviceCount[vehicleIndex] = vehicleDeviceCount[vehicleIndex] or 0
    if devName ~= "" then
      state.players[devName] = vehicleIndex
      vehicleDeviceCount[vehicleIndex] = vehicleDeviceCount[vehicleIndex] + 1
    end

    if not state.errorMessage then
      if vehicleDeviceCount[vehicleIndex] > 1 then
        state.invalidVehicles[vehicleName] = true
        state.errorMessage = vehicleName..' cannot be controlled by several players'
      end

      if vehicleName and scenario.vehicles[vehicleName].driver.required and vehicleDeviceCount[vehicleIndex] ~= 1 then
        state.invalidVehicles[vehicleName] = true
        state.errorMessage = "At least one player must drive vehicle "..vehicleName
      end

      if vehicleDeviceCount[vehicleIndex] == 1 and vehicleName and not state.invalidVehicles[vehicleName] then
        validVehicles = validVehicles + 1
      end
    end
  end

  if not state.errorMessage and validVehicles < scenario.playersCountRange.min then
    state.errorMessage = 'At least '..tostring(scenario.playersCountRange.min)..' players are required'
  end

  if not state.errorMessage and validVehicles > scenario.playersCountRange.max then
    state.errorMessage = 'Only up to '..tostring(scenario.playersCountRange.max)..' players are allowed'
  end

  return state
end

local function updatePlayersUI()
  -- log("I", logTag, "updatePlayersUI called....")
  if not isMultiseatScenario() then return end

  local state = getMultiseatConfigState()
  local data = { vehicles = {}, players = state.players, playerValid = state.errorMessage == nil, inv = state.invalidVehicles, invalidMsg = state.errorMessage, devices = bindings.devices }

  data.vehicles[0] = allowUnassigned and 'Unassigned' or "" -- empty string tells UI to hide that column
  for index, vehicleName in ipairs(scenario.playerUsableVehicles) do
    data.vehicles[index] = vehicleName
    local vehicleObj = scenetree.findObject(vehicleName)
    if vehicleObj and vehicleObj.internalName and vehicleObj.internalName ~= "" then
      data.vehicles[index] = vehicleObj.internalName
    end
  end

  guihooks.trigger('PlayersChanged', data )
end

local function initMultiseatPlayers()
  -- log("I", logTag, "initMultiseatPlayers called....")
  scenario.multiseatInput = {}

  local assignedPlayers = bindings.getAssignedPlayers()
  local defaultIndex = allowUnassigned and 0 or 1
  local nextIndex = 1
  local maxPlayers = scenario.playersCountRange.max
  for devName, _ in pairs(assignedPlayers) do
    local devicetype = string.split(devName, "%D+")[1] -- strip trailing number, if it exists (xinput0 -> xinput)
    local vehName = scenario.playerUsableVehicles[defaultIndex]
    if devicetype ~= "mouse" then
      table.insert(scenario.multiseatInput, {device=devName, vehicleName=vehName, vehicleIndex=defaultIndex, lastInputMS=0})
      nextIndex = nextIndex + 1
    end
  end

  for index=nextIndex,maxPlayers do
    local vehName = scenario.playerUsableVehicles[index]
    table.insert(scenario.multiseatInput, {device="", vehicleName=vehName, vehicleIndex=index, lastInputMS=0})
  end

  updatePlayersUI()
end

local function onFilteredInputChanged( devName, action, value )
  -- log("I", logTag, "onFilteredInputChanged called....")
  if not isMultiseatScenario() then return end

  -- discard non-steering events
  if action ~= 'steering' and action ~= 'steer_left' and action ~= 'steer_right' then return end

  if math.abs(value) < 0.2 then return end -- stop cycling vehicles when control is centered

  local assignedInput = nil
  for _,assignment in ipairs(scenario.multiseatInput) do
    if assignment.device == devName then
      assignedInput = assignment
      goto continue
    end
  end

  ::continue::
  if assignedInput then
    local now = Engine.Platform.getRealMilliseconds()
    local deltaMS = now - (assignedInput.lastInputMS or 0)
    -- discard events that are too soon in time
    if deltaMS < 500 then return end
    assignedInput.lastInputMS = now
    -- process event - move player to new vehicle
    local step = (value > 0) and 1 or -1
    if action == "steer_left"  then step = -1 end
    if action == "steer_right" then step =  1 end
    local vehicleIndexSwapped = assignedInput.vehicleIndex
    local vehicleNameSwapped = assignedInput.vehicleName
    assignedInput.vehicleIndex = getNextVehicleIndex(assignedInput.vehicleIndex, step)
    assignedInput.vehicleName = scenario.playerUsableVehicles[assignedInput.vehicleIndex]


    for _,assignment in ipairs(scenario.multiseatInput) do
      if assignment.device == '' and assignment.vehicleIndex == assignedInput.vehicleIndex and assignment.vehicleName == assignedInput.vehicleName then
        assignment.vehicleIndex = vehicleIndexSwapped
        assignment.vehicleName = vehicleNameSwapped
      end
    end

    updatePlayersUI()
  end
end

local function deleteVehicle(vehicleName)
  local vehicle = scenetree.findObject(vehicleName)
  if vehicle then
    local vid = vehicle.obj:getID()
    local vehicleData = extractVehicleData(vid)
    scenario.multiseatDeletedVehicles[vehicleName] = vehicleData
    scenario.vehicleNameToId[vehicleName] = nil
    scenario.vehicleIdToName[vid] = nil
    -- for index, name in pairs(scenario.playerUsableVehicles) do
    --   if name == vehicleName then
    --     scenario.playerUsableVehicles[index] = nil
    --     goto continue
    --   end
    -- end
    ::continue::
    vehicle.obj:delete()
  else
    log("E", logTag, "could not find: "..vehicleName)
  end
end

local function restoreDeletedVehicle(vehicleName)
  local vehicle = scenetree.findObject(vehicleName)
  if not vehicle then
    local vehicleData = scenario.multiseatDeletedVehicles[vehicleName]
    if vehicleData then
      local spawningData = createPlayerSpawningData(vehicleData.model, vehicleData.config, vehicleData.color, vehicleData.licenseText)
      core_vehicles.spawnNewVehicle(spawningData.model, spawningData.options)
    end
  else
    log("E", logTag, "Cannot restore vehicle. A vehicle with this name already exists: "..vehicleName)
  end
end

local function finalizePreRunning()
  -- log("I", logTag, "finalizePreRunning called....")

  if isMultiseatScenario() then
    -- remove vehicles not assigned a controller
    scenario.multiseatDeletedVehicles = {}
    for _, assignment in ipairs(scenario.multiseatInput) do
      local vehicleName = assignment.vehicleName
      if assignment.device == "" and scenario.vehicles[vehicleName].driver.removeIfEmpty then
        deleteVehicle(vehicleName)
      end
    end

    -- reseat players in their new vehicles
    local assignedPlayers = bindings.getAssignedPlayers()
    for _,assignment in ipairs(scenario.multiseatInput) do
      local devName = assignment.device
      if devName ~= "" then
        local vehicleIndex = assignment.vehicleIndex

        local player = assignedPlayers[devName]
        if vehicleIndex == 0 then
          be:exitVehicle(player)
        else
          local vehicleName = assignment.vehicleName
          local vehicle = scenetree.findObject(vehicleName)
          if vehicle then
            be:enterVehicle(player, vehicle.obj)
          else
            log("E", logTag, "Couldn't find vehicle: "..dumps(vehicleName))
          end
        end
      end
    end
  end
end

-- callback from the UI
local function onScenarioUIReady(state)
  -- log('D', logTag, 'onScenarioUIReady('..tostring(state) .. ')')
  if not scenario then return end

  if state == 'start' and scenario.state == 'pre-start' then

    if isMultiseatScenario() then
      initMultiseatPlayers()
    end

    showIntroPrefab(true)

    -- initial UI update
    guihooks.trigger('ScenarioChange', scenario)

    -- init camera paths
    delayCameraPath = 10

    local democam = scenetree.findObject('democam')
    if democam and democam.className == 'SimPath' then
      guihooks.trigger("scenarioStart:showStartButton", false)
    end

    scenario.extraTime = 0

    -- start the race subsystem
    changeState('pre-running')
  end

  if state == 'play' and scenario.state == 'pre-running'then
    finalizePreRunning()

    local lastCameraMode = scenario.lastModeName
    if not lastCameraMode then
      lastCameraMode = 'orbit'
    end
    core_camera.setByName(0, lastCameraMode) -- change back to the correct camera just before the countdown starts
    if lastCameraMode ~= 'relative' then
      core_camera.resetCamera(0)
    end

    showIntroPrefab(false)

    changeState('running')
  end

  guihooks.trigger('ScenarioChange', scenario)
end

local function getScenario()
  return scenario
end

local function onCameraModeChanged(modeName)
  if not scenario then return end
  if modeName and modeName ~= 'path' and modeName ~= 'observer' then
    scenario.lastModeName = modeName
  end
end

-- dialog stuff:
local dialog;
local dialogQueue

local function processdialogQueue ()
  if #dialogQueue > 0 then
    dialog = table.remove(dialogQueue, 1);

    if dialog.type == 'dialog' then
      guihooks.trigger('loadDialog', {path = dialog.path})
    end

    if dialog.type == 'images' then
      guihooks.trigger('ChangeState', {state ='imageviewer', params = {useKeys = true}})
    end

    if dialog.type == 'dialogImgs' then
      guihooks.trigger('ChangeState', {state ='imageviewer', params = {useKeys = false}})
    end
  else
    guihooks.trigger('ScenarioFlashMessage', {{3,1, true},{2,1, true},{1,1, true},{"go!", 1, "extensions.hook('onContinueScenario')", true}})
  end
end

local function onRaceWaypointReached (data)
  local playerVehicleId = be:getPlayerVehicleID(0)
  if data.vehicleId ~= playerVehicleId then return end

  dialog = nil -- just in case
  dialogQueue = nil -- just in case

  if scenario.dialogs and scenario.dialogs[data.waypointName] ~= nil  then
    dialogQueue = scenario.dialogs[data.waypointName];
    extensions.hook('onPauseScenario')
    log('D', logTag, 'Found dialog option. paused physics')
    processdialogQueue()
  end
end

local function onDespawnObject(id, isReloading)
  --print('onDespawnObject '..tostring(id)..' '..tostring(isReloading))
end

-- finish the scenario and let goals and custom lua decide about the result
local function endScenario(countDownTime)
  endRace(countDownTime)
  extensions.hook('onEndScenario', countDownTime)
  if bullettime.get() > 1/8 then bullettime.set(1/8) end -- use slowmotion during end screen
end

local function TransitionToFreeroam()
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then
    log('W',logTag, 'there is no player vehicle.')
    return
  end

  core_vehicles.removeAllWithProperty('isAIControlled', "1")

  stop()
end

local function uiEventRetry()
  log('D', logTag, 'uiEventRetry Triggered')
  be:resetVehicle(0);
  prepareStartUI()
end

local function uiEventFreeRoam()
  initialLevelState = nil -- dont reset level state
  TransitionToFreeroam()
  core_gamestate.setGameState('freeroam', 'freeroam', 'freeroam')
  guihooks.trigger('MenuHide')
  guihooks.trigger('ChangeState', 'menu')
end

local function HasVehicleSustainedDamage(vehicleID, initialDamage)
  local vehicle = be:getObjectByID(vehicleID)
  if vehicle then
    local vehicleData = map.objects[vehicleID]
    -- log('A',logTag, 'vehicle Damage for '..vehicleID..' : '..vehicleData.damage ..' initialDamage: '..initialDamage..' Diff: '..math.abs(vehicleData.damage - initialDamage))
    if vehicleData and math.abs(vehicleData.damage - initialDamage) > 0 then
      return true
    end
  end
  return false
end

local function HasVehicleStoppedMoving(vehicleID, data)
  local vehicle = be:getObjectByID(vehicleID)
  if vehicle then
    local currentVehPos = vehicle:getPosition()
    local distance = (currentVehPos - data.startPos):len()
    local hasMovedFromInitialPosition = distance > 1
    -- log('I', logTag, 'HasVehicleStoppedMoving '..vehicleID..' Dist: ' ..distance)
    if hasMovedFromInitialPosition then
      local vehMomentum = (currentVehPos - data.lastPos):len()
      -- log('A',logTag, 'vehMomentum for '..vehicleID..' : '..vehMomentum)
      local vehMomentumLimit = data.vehMomentumLimit or 0.004
      if vehMomentum <= vehMomentumLimit then
        return true
      end
    end
  end
  return false
end

local function getVehicleName(vehicleID)
  return scenario and scenario.vehicleIdToName[vehicleID]
end

local function trackVehicleMovementAfterDamage(vehicleName, trackingOptions)
  log('A', logTag, 'trackVehicleMovementAfterDamage called....')
  if scenario then
    if not  scenario.vehicleTrackingTable then
       scenario.vehicleTrackingTable = {}
    end
    local vehicle = scenetree.findObject(vehicleName)
    if vehicle then
      local vehicleDamage = 0
      if map.objects[vehicle:getID()] then
        vehicleDamage = map.objects[vehicle:getID()].damage
      end

      local waitTimerLimit = trackingOptions and trackingOptions.waitTimerLimit
      local vehMomentumLimit = trackingOptions and trackingOptions.vehMomentumLimit
      scenario.vehicleTrackingTable[vehicleName] = {startPos=vehicle:getPosition() , lastPos=vehicle:getPosition(),
                                                    initialDamage=vehicleDamage, lastDamage=vehicleDamage,
                                                    vehMomentumLimit=vehMomentumLimit, waitTimerLimit=waitTimerLimit, crashedWaitTimer=0.0}
    else
      log('W', logTag, 'could not find vehicle: '..vehicleName)
    end
    --dump(scenario.vehicleTrackingTable)
  end
end

local function displayStartUI()
  guihooks.trigger('ChangeState', 'scenario-start')
  scenario.displayStartUIRefs = nil
end

local function displayEndUI()
  guihooks.trigger('ChangeState', {state = 'menu'})
  scenario.displayEndUIRefs = nil
end

local function processRaceStart()
  scenario.failureTimer = 0.0
  scenario.failureTimerActive = true

  if scenario.trackPlayerVehicle  then
    local playerVehicle = be:getPlayerVehicle(0)
    local vehicleName = scenario.vehicleIdToName[playerVehicle:getID()]
    trackVehicleMovementAfterDamage(vehicleName)
  end

  for vName, vObjId in pairs(scenario.vehicleNameToId) do
    if scenario.vehicles[vName] then
      if scenario.vehicles[vName].driver["frozen"] then
          local carName = helper.getVehicleByName(vName)
          carName:queueLuaCommand('controller.setFreeze(1)')
       end
    end
  end

  extensions.hook('onRaceStart')
  guihooks.trigger('RaceStart')
end

local function rollingStartTriggered()
  scenario.timer = 0
  processRaceStart()
end

local function tickPreStart(dt, dtSim)
  if needFreezeVehicles then
    needFreezeVehicles = false
    freezeAll(1)
  end

  if scenario.displayStartUIRefs == 0 then
    -- show start UI
    local isMultiseat = scenario.playersCountRange.min > 1
    local isRestricted = settings.getValue('restrictScenarios', true) or (campaign_campaigns and campaign_campaigns.getCampaignActive())

    core_gamestate.setGameState(isMultiseat and "multiseatscenario" or "scenario", scenario.uilayout or 'scenario', isRestricted and 'scenario' or 'freeroam')

    if campaign_campaigns and campaign_campaigns.getCampaignActive() then
      campaign_campaigns.scenarioStarted(scenario)
    else
      displayStartUI()
    end
  end
end

local function tickPreRunning(dt, dtSim)
  -- Path Camera
  if delayCameraPath then
    delayCameraPath = delayCameraPath - dt
    local playerVehicle = be:getPlayerVehicle(0)
    if (playerVehicle and playerVehicle:isRenderMaterialsReady() and delayCameraPath < 10) or delayCameraPath < 0 then
      delayCameraPath = nil
      setupPathCamera()
    end
  end

  raceMarker.render()
end

local function tickRunning(dt, dtSim)
  -- countdown state
  if scenario.countDownTime and scenario.raceState == 'countdown' then
    scenario.countDownTime = scenario.countDownTime - dtSim
    if scenario.countDownTime <= 3 and not scenario.countDownShowed and scenario.showCountdown then
      -- tell the UI to actually count down
      guihooks.trigger('ScenarioFlashMessageReset')
      guihooks.trigger('ScenarioFlashMessage', {{3,1, "Engine.Audio.playOnce('AudioGui', 'event:UI_Countdown1')", true},
                                                {2,1, "Engine.Audio.playOnce('AudioGui', 'event:UI_Countdown2')", true},
                                                {1,1, "Engine.Audio.playOnce('AudioGui', 'event:UI_Countdown3')", true}})

      scenario.countDownShowed = true
      extensions.hook("onCountdownStarted")
    elseif scenario.countDownTime < 1 and not scenario.countDownShowed and not scenario.showCountdown then
      guihooks.trigger('ScenarioFlashMessageReset')
      guihooks.trigger('ScenarioFlashMessage', {{'Ready...',1, "", true}})
      scenario.countDownShowed = true
    elseif scenario.countDownTime <= 0 then
      guihooks.trigger('ScenarioFlashMessageReset')
      guihooks.trigger('ScenarioFlashMessage', {{"GO!", 1, "Engine.Audio.playOnce('AudioGui', 'event:UI_CountdownGo')", true}})

      scenario.countDownTime = nil
      scenario.countDownShowed = nil

      scenario.raceState = 'racing'

      -- unlock all vehicles
      freezeAll(0)

      -- reset the timers
      scenario.timer = 0
      raceTickTimer = 0

      extensions.hook("onCountdownEnded")

      if not scenario.rollingStart then
        -- let everyone know that we finally started
        -- but only if we have no rolling start
        processRaceStart()
      end
    end
    return
  end

  -- scenario time
  if be:getEnabled() then
    local raceTickTime = 0.25
    if scenario.raceState == 'racing' and scenario.timerActive and not bullettime.getPause() then
      scenario.timer = scenario.timer + dtSim
      local showTime = scenario.timer
      local maxTime = 0
      if scenario.maxTime then
        maxTime = math.max(0, scenario.maxTime + scenario.extraTime)
        if scenario.reverseTime then
          showTime = math.max(0, maxTime - showTime)
        end
      end
      guihooks.trigger('raceTime', {time=showTime, reverseTime=scenario.reverseTime})

      if scenario.maxTime and scenario.timer > maxTime then
        endRace()
      end
    end
    -- blend the marker
    raceMarker.render()

    -- the race tick implementation
    raceTickTimer = raceTickTimer + dtSim

    if raceTickTimer > raceTickTime then
      raceTickTimer = raceTickTimer - raceTickTime
      extensions.hook('onRaceTick', raceTickTime, scenario.timer)
    end
  end

  -- check for collisions and report
  if scenario.vehicleTrackingTable then
    -- log('A', logTag, 'Checking Collisions')
    -- dump(scenario.vehicleTrackingTable)
    local reportedEvents = {}
    for vehName,data in pairs(scenario.vehicleTrackingTable) do
      local vehicle = scenetree.findObject(vehName)
      if vehicle then
        local vehicleID = vehicle:getID()
        local vehicleData = map.objects[vehicleID]
        -- log('A', logTag, 'vehName: '..vehName..', No. Collisions: '..tableSize(vehicleData.objectCollisions))
        -- dump(vehicleData.objectCollisions)
        if vehicleData and tableSize(vehicleData.objectCollisions) > 0 then
          -- log('A', logTag, 'vehicleData.objectCollisions')
          -- dump(vehicleData.objectCollisions)
          for otherObjID,state in pairs(vehicleData.objectCollisions) do
            -- log('A', logTag, 'otherObjID: '..otherObjID..', State: '..state)
            if state == 1 then
              local vehEventTable = reportedEvents[vehicleID]
              if not vehEventTable then
                vehEventTable = {}
                reportedEvents[vehicleID] = vehEventTable
              end

              local otherEventTable = reportedEvents[otherObjID]
              if not otherEventTable then
                otherEventTable = {}
                reportedEvents[otherObjID] = otherEventTable
              end
              -- dump(otherEventTable)
              -- dump(vehEventTable)

              if not otherEventTable[vehicleID] and not vehEventTable[otherObjID] then
                otherEventTable[vehicleID] = true
                vehEventTable[otherObjID] = true
                extensions.hook('onObjectCollision', vehicleID, otherObjID)
              end
            end
          end
        end
      end
    end
  end

  -- Check if tracked vehicles are still moving after taking damage
  if scenario.vehicleTrackingTable then
    for vehName,data in pairs(scenario.vehicleTrackingTable) do
      local vehicle = scenetree.findObject(vehName)
      if vehicle then
        local vehicleID = vehicle:getID()

        if HasVehicleStoppedMoving(vehicleID, data) then
          data.crashedWaitTimer = data.crashedWaitTimer + dt
          local timerLimit = data.waitTimerLimit or 1.0
          if data.crashedWaitTimer >= timerLimit then
            if HasVehicleSustainedDamage(vehicleID, data.initialDamage) then
              extensions.hook('onVehicleStoppedMoving', vehicleID, true)
            else
              extensions.hook('onVehicleStoppedMoving', vehicleID, false)
            end
          end
        else
          data.crashedWaitTimer = 0.0
        end

        data.lastPos = vehicle:getPosition()
      end
    end
  end

  -- Check if tracked vehicles have sustained damage
  if scenario.vehicleTrackingTable then
   for vehName,data in pairs(scenario.vehicleTrackingTable) do
      local vehicle = scenetree.findObject(vehName)
      if vehicle then
        local vehicleID = vehicle:getID()
        local vehicleData = map.objects[vehicleID]
        if vehicleData then
          local delataDamage = math.abs(vehicleData.damage - data.lastDamage)
          if delataDamage > 0 then
            data.lastDamage = vehicleData.damage
            extensions.hook('onVehicleTakenDamage', vehicleID, delataDamage)
          end
        end
      end
    end
  end

  -- Check failure limit
  if scenario.failureTriggerTime and scenario.failureTimerActive then
    scenario.failureTimer = scenario.failureTimer + dt
    if scenario.failureTimer >= scenario.failureTriggerTime then
      -- log('A', logTag,'failureTrigger triggered for '..scenario.state)
      extensions.hook('onFailureTimerFired', scenario.failureTriggerTime)
      scenario.failureTimerActive = false
    end
  end
end

local function tickFinished(dt, dtSim)
  if scenario.state ~= 'finished' then
    return
  end

  endRaceCountdown = endRaceCountdown - dt
  if endRaceCountdown > 0 then
    return
  end

  log( 'I', logTag, 'endRaceCountdown triggered...' )
  endRaceCountdown = 0

  finalTime = finalTime or scenario.timer or 0
  local timeStr = timeToString(finalTime)

  extensions.hook('onRaceResult', { finalTime = finalTime } )

  local result =  scenario.cachedFinshResult or {msg = scenario.defaultWin} or {msg = {txt = 'extensions.scenario.onRaceEnd.default.win', context = {timeStr = timeStr}}}
  result.finalTime = finalTime
  result.finalTimeStr = timeStr

  -- TODO(AK): Discuss and decide if we should be doing this. It prevents all the messages from LUA from appearing in the end screen.
  -- This should use the failed message if result messages fields are blank
  if result.failed == true and scenario.failedMessage then
    result.failed = scenario.failedMessage
  elseif not result.msg and scenario.passedMessage then
    result.msg = scenario.passedMessage
  end

  scenario.result = result
  changeState('post')

  --Set the delay time used to prospone showing the end ui screen
  displayEndUITimer = scenario.endUIDelayTime or 0

  if raceGoals then
    raceGoals.updateGoalsFinalStatus()
  end

  statistics_statistics.stopStatsGathering(scenario)
  scenario.stats = gatherEndStats()

  saveStats(scenario.stats)

  if scenario.isQuickRace then
    scenario.endScreenController = function()
      if bullettime.get() > 1/8 then bullettime.set(1/8) end -- use slowmotion during end screen
      -- This must be the last thing triggered, allows all other systems to process scenario state POST
      guihooks.trigger('ChangeState', {state = 'quickrace-end', params = {stats = loadStats(scenario.stats)}});
    end
  else
    scenario.endScreenController = function()
      if bullettime.get() > 1/8 then bullettime.set(1/8) end -- use slowmotion during end screen
      -- This must be the last thing triggered, allows all other systems to process scenario state POST
      local scenarioStats = loadStats(scenario.stats)
      guihooks.trigger('ChangeState', {state = 'scenario-end', params = {stats = scenarioStats, rewards = scenario.scenarioRewards}});
    end
  end

  if campaign_campaigns and campaign_campaigns.getCampaignActive() then
    campaign_campaigns.scenarioFinished(scenario)
  end

end

local function tickPost(dt, dtSim)
  if not endUIDisplayed then
    displayEndUITimer = math.max(0, displayEndUITimer - dt)
    local displayEndUI = displayEndUITimer <= 0

    if displayEndUI and not campaign_campaigns then
      scenario_scenarios.displayEndUI()
    end

    displayEndUI = displayEndUI and not scenario.displayEndUIRefs

    if scenario.trackPlayerVehicle then
      if scenario.playerIsDamaged and scenario.playerHasStopped and displayEndUITimer > 1 then
        displayEndUITimer = 1
      end

      displayEndUI = displayEndUI and (scenario.playerHasStopped or scenario.result)
    end

    --log('A', logTag, 'displayEndUITimer: '..displayEndUITimer)
    if displayEndUI then
      endUIDisplayed = true
      if scenario.endScreenController and type(scenario.endScreenController) == 'function' then
        scenario.endScreenController()
      end
    end
  end
end

local function onVehicleSpawned(vehicleId)
  -- log('I', logTag, 'onVehicleSpawned called for '..vehicleId)
  local spawnedVehicle = be:getObjectByID(vehicleId)
  local spawnedVehicleData = extractVehicleData(vehicleId)

  if scenario and isMultiseatScenario() and scenario.multiseatDeletedVehicles then
    local matchFound = true
    for vehicleName,vehicleData in pairs(scenario.multiseatDeletedVehicles or {}) do
      matchFound = true
      for k,v in pairs(vehicleData) do
        matchFound = matchFound and spawnedVehicleData[k] == v
      end
      if matchFound then
        -- log('I', logTag, 'matchFound: '..vehicleName)
        spawnedVehicle:setField('name', '', vehicleName)
        local initialTransform = scenario.startingTransforms[vehicleName]
        if initialTransform then
          local pos = initialTransform.pos
          local rot = initialTransform.rot
          spawnedVehicle:setPositionRotation(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)

          if scenario and scenario.state == 'restart' and scenario.restartStagePendingResets > 0 then
            scenario.restartStagePendingResets = scenario.restartStagePendingResets - 1
          end
        end

        goto continue
      end
    end
    ::continue::
  elseif scenario and scenario.userSelectedVehicle and scenario.userSpawningData then
    local playerVehId = be:getPlayerVehicleID(0)
    log('I', logTag, 'onVehicleSpawned PlayerID: '..tostring(playerVehId)..' Spawned: '..tostring(vehicleId))
    -- TODO(AK): Find a match instead of assuming it is correct
    if not playerVehId or (vehicleId == playerVehId) then
        spawnedVehicle:setField('name', '', 'scenario_player0')
        scenetree.ScenarioObjectsGroup:addObject(spawnedVehicle)
        -- TODO(AK): Remove this and extract for the spawning data
        if scenario.spawnLocation then
          local pos = scenario.spawnLocation.pos
          local rot = scenario.spawnLocation.rot
          if scenario.spawnLocation.rotAngAxisF then
            rot = scenario.spawnLocation.rotAngAxisF
            -- degrees to radians
            rot = AngAxisF(rot.x, rot.y, rot.z, (rot.w * 3.1459) / 180.0 ):toQuatF()
          end

          spawnedVehicle:setPositionRotation(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
        end
    end
  end
end

local function onVehicleResetted(vehicleID)
  -- log('I', logTag, 'onVehicleResetted called for '..vehicleID)
  if scenario and scenario.state == 'restart' and scenario.restartStagePendingResets > 0 then
    scenario.restartStagePendingResets = scenario.restartStagePendingResets - 1
  end
end

local function tickRestart(dt, dtSim)
  -- log( 'I', logTag, 'tickRestart called....')
  local controlVehicle = be:getPlayerVehicle(0)
  if scenario.restartStage == 0 then
    -- for k,v in pairs(scenario.startingTransforms) do
    --   log('I', logTag, 'v.pos: '..tostring(v.pos.x)..','..tostring(v.pos.y)..','..tostring(v.pos.z))
    --   log('I', logTag, 'v.rot: '..tostring(v.rot.x)..','..tostring(v.rot.y)..','..tostring(v.rot.z)..','..tostring(v.rot.w))
    -- end

    loadExtentions(scenario)

    inputActionFilter.clear(0)
    if type(scenario.blackListActions) == 'table' then
      for i, action in ipairs( scenario.blackListActions ) do
        --log('D', logTag, 'add action to blackList: ' .. tostring(action))
        inputActionFilter.addAction(0, action, true)
      end
    end

    if type(scenario.whiteListActions) == 'table' then
      for i, action in ipairs( scenario.whiteListActions ) do
        --log('D', logTag, 'add action to whiteList: ' .. tostring(action))
        inputActionFilter.addAction(0, action, false)
      end
    end

    -- reset everything - EXCEPT the player vehicle
    -- otherwise, the setTrigger on the first waypoint is lost in the reset
    scenario.restartStagePendingResets = 1 -- we have already asked for the player to reset
    for _, vid in pairs(scenario.vehicleNameToId or {}) do
      if vid ~= scenario.focusSlot then
        local bo = be:getObjectByID(vid)
        if bo then
          bo:queueLuaCommand('obj:requestReset(RESET_PHYSICS)')
          bo:resetBrokenFlexMesh()
          scenario.restartStagePendingResets = scenario.restartStagePendingResets + 1
        end
      end
    end

    if isMultiseatScenario() then
      -- Because we delete vehicle that are not assigned to a controller,
      -- we need to respawn those that were deleted
       log('D', logTag, 'respawing deleted vehicles')
       for vehicleName, _ in pairs(scenario.multiseatDeletedVehicles or {}) do
         restoreDeletedVehicle(vehicleName)
         scenario.restartStagePendingResets = scenario.restartStagePendingResets + 1
       end
    end

    scenario.restartStage = 1
  elseif scenario.restartStage == 1 then
    if scenario.restartStagePendingResets == 0 then
      scenario.restartStage = 2
    end
  elseif scenario.restartStage == 2 then
    for vName, vObjId in pairs(scenario.vehicleNameToId) do
      local vehicle = scenetree.findObject(vName)
      if vehicle then
        vehicle:queueLuaCommand('electrics.toggle_lightbar_signal()')

        local initialTransform = scenario.startingTransforms[vName]
        if initialTransform then
          local pos = initialTransform.pos
          local rot = initialTransform.rot
          --TODO(AK): We have a better function which we will call when the reset system is completed
          vehicle:setPositionRotation(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
        else
          log('E', logTag, 'Reseting failed to find starting transform for vehicle: '..vName)
        end
      else
        log('E', logTag, 'Reseting failed to find vehicle: '..vName)
      end
    end

    scenario.restartStage = 3
  elseif scenario.restartStage == 3 then
    scenario.restartStage = nil

    local isMultiseat = scenario.playersCountRange.min > 1
    settings.setValue('multiseat', isMultiseat)

    if isMultiseatScenario() then
      core_camera.setByName(0, 'orbit')
    end

    setupPathCamera()

    changeState('pre-start')
    extensions.hook('onScenarioRestarted', scenario)

    be:enterVehicle(0, controlVehicle)
    commands.setGameCamera()
    prepareStartUI()
    -- guihooks.trigger('ScenarioChange', scenario)
  end
end

local lastState = nil
local function onPreRender(dt, dtSim)
  if not scenario then return end

  if lastState ~= scenario.state then
    lastState = scenario.state
  end

  if scenario.state == 'pre-start' then
    tickPreStart(dt, dtSim)
  elseif scenario.state == 'pre-running' then
    tickPreRunning(dt, dtSim)
  elseif scenario.state == 'running' then
    tickRunning(dt, dtSim)
  elseif scenario.state == 'finished' then
    tickFinished(dt, dtSim)
  elseif scenario.state == 'post' then
    tickPost(dt, dtSim)
  elseif scenario.state == 'restart' then
    tickRestart(dt, dtSim)
  end
end

local function onVehicleStoppedMoving(vehicleID)
  if not scenario then return end

  if scenario.trackPlayerVehicle then
    local playerVehicle = be:getPlayerVehicle(0)
    if vehicleID == playerVehicle:getID() then
      scenario.playerIsDamaged = true
      scenario.playerHasStopped = true
    end
  end
end

-- called on physics engine events
local function onPhysicsEngineEvent(type, a1)
  if not scenario then return end

  --log( 'D', logTag, 'onPhysicsEngineEvent: '..tostring(type)..', '..tostring(a1) )
  if type == 'reset' then
    -- handle inestabilities
    if not be:getEnabled() then be:toggleEnabled() end

    restartScenario()
  end
end

local function onPhysicsUnpaused()
  --log('A', logTag, 'onPhysicsUnpaused called....')
  if scenario and scenarioStateAtPauseEvent then
    scenario.state = scenarioStateAtPauseEvent
    scenarioStateAtPauseEvent = nil
  end
end

local function onPhysicsPaused()
 --log('A', logTag, 'onPhysicsPaused called....')
 if scenario then
    scenarioStateAtPauseEvent = scenario.state
    scenario.state = 'physicsPaused'
  end
end

local function onSerialize()
  -- log('D', logTag, 'onSerialize called...')
  local data = {}

  if scenario then
    data.sourceFile = scenario.sourceFile
    data.scenarioKey = scenario.scenarioKey
    data.vehicleTrackingTable = scenario.vehicleTrackingTable
    data.failureTimerActive = scenario.failureTimerActive
    data.currentLap = scenario.currentLap
    data.countDownTime = scenario.countDownTime
    data.state = scenario.state
    data.timerActive = scenario.timerActive
    data.timer = scenario.timer
    data.displayEndUIRefs = scenario.displayEndUIRefs
    data.raceState = scenario.raceState
    data.failureTimer = scenario.failureTimer
    data.lastModeName = scenario.lastModeName
    data.goals = scenario.goals
    data.extensions = scenario.extensions
    data.startingTransforms = scenario.startingTransforms
    -- serializeJsonToFile("scenario_data.txt", data, true)
  end

  -- dump(data)
  return data
end

local function onDeserialized(data)
  -- log('D', logTag, 'onDeserialized called...')
  -- dump(data)
  if not data.sourceFile then return end

  local newScenario = scenario_scenariosLoader.loadScenario(data.sourceFile, data.scenarioKey)

  if newScenario then
    newScenario.vehicleTrackingTable = data.vehicleTrackingTable
    newScenario.failureTimerActive = data.failureTimerActive
    newScenario.currentLap = data.currentLap
    newScenario.countDownTime = data.countDownTime
    newScenario.state = data.state
    newScenario.timerActive = data.timerActive
    newScenario.timer = data.timer
    newScenario.displayEndUIRefs = data.displayEndUIRefs
    newScenario.raceState = data.raceState
    newScenario.failureTimer = data.failureTimer
    newScenario.lastModeName = data.lastModeName
    newScenario.goals = data.goals
    -- newScenario.extensions = data.extensions
    newScenario.startingTransforms = data.startingTransforms
    -- dump(newScenario)

    scenario = newScenario

    processVehiclesInScene()
    processWaypointsInScene()
  end
end

local function onExtensionUnloaded()
  stop()
  scenario_race = nil
end

local function onExtensionLoaded()
  local scenario_race = {}
  local backwardCompatibility = {
    __index = function(tbl, key)
      if scenario_scenarios and scenario_scenarios[key] and type(scenario_scenarios[key]) == 'function' then
        return function(...)
                 log('E', 'scenario', 'scenario_race.'..key..' API is deprecated. Please use scenario_scenarios.'..key)
                 local args = {...}
                 return scenario_scenarios[key](unpack(args))
               end
      end

      return nil
    end
  }
  setmetatable(scenario_race, backwardCompatibility)
  rawset(_G, 'scenario_race', scenario_race) -- rawset avoids global setter wrapper detections
end

local function updateVehicleAiState(vehicleName, data)
  -- log('I',logTag, 'updateVehicleAiState called...'..tostring(vehicleName))
  -- dump(data)

  local vehicle = scenetree.findObject(vehicleName)
  if vehicle and data then
    local vehId = vehicle:getID()
    local info = {vehicleId = vehId, vehicleName = vehicleName}
    if data.mode and data.mode == 'disable' then
      setVehicleProperty(vehId, 'isAIControlled', '0')
      info.aiControlled = false
      -- scenario_waypoints.removeVehicleData(vehId)
    else
      setVehicleProperty(vehId, 'isAIControlled', '1')
      info.aiControlled = true
    end

    extensions.hook('onVehicleAIStateChanged', info)
  end
end

-- public interface
M.spawnPrefab                     = deprecatedSpawnPrefab
M.executeScenario                 = executeScenario
M.stop                            = stop
M.finish                          = finish
M.endScenario                     = endScenario
M.getScenario                     = getScenario
M.onClientStartMission            = onClientStartMission
M.onClientEndMission              = onClientEndMission
M.onScenarioUIReady               = onScenarioUIReady
M.onDrawDebug                     = onDrawDebug
M.onCameraHandlerSet              = onCameraHandlerSet
M.onPhysicsEngineEvent            = onPhysicsEngineEvent
M.changeState                     = changeState
M.onRaceWaypointReached           = onRaceWaypointReached
M.onDespawnObject                 = onDespawnObject
M.prepareStartUI                  = prepareStartUI
M.uiEventRetry                    = uiEventRetry
M.uiEventFreeRoam                 = uiEventFreeRoam
M.onCameraModeChanged             = onCameraModeChanged
M.getVehicleName                  = getVehicleName
M.trackVehicleMovementAfterDamage = trackVehicleMovementAfterDamage
M.onPreRender                     = onPreRender
M.onVehicleStoppedMoving          = onVehicleStoppedMoving
M.restartScenario                 = restartScenario
M.onPhysicsUnpaused               = onPhysicsUnpaused
M.onPhysicsPaused                 = onPhysicsPaused
M.onFilteredInputChanged          = onFilteredInputChanged
M.onSerialize                     = onSerialize
M.onDeserialized                  = onDeserialized
M.onExtensionUnloaded             = onExtensionUnloaded
M.displayStartUI                  = displayStartUI
M.displayEndUI                    = displayEndUI
M.updateVehicleAiState            = updateVehicleAiState
M.rollingStartTriggered           = rollingStartTriggered

M.freezeAll = freezeAll
M.endRace = endRace
M.onExtensionLoaded = onExtensionLoaded
M.stopRaceTimer = stopRaceTimer
M.pauseScenario = pauseScenario
M.continueScenario = continueScenario
M.getRaceDistance = getRaceDistance
M.onVehicleResetted = onVehicleResetted
M.onVehicleSpawned  = onVehicleSpawned

return M