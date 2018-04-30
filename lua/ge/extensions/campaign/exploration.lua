-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.dependencies = {'campaign_campaigns'}
M.state = {}

local spawningPlayer = nil
local nextSpawnTrigger = nil
local logTag = 'exploration'

local inputActionFilter = require('input_action_filter')
inputActionFilter.setGroup('default_blacklist_exploration', {"switch_next_vehicle", "switch_previous_vehicle", "loadHome", "saveHome", "reload_vehicle", "vehicle_selector", "parts_selector", "dropPlayerAtCamera"} )

local function createScenarioMarker(id, position, scale, color)
  local marker = createObject("TSStatic")
  marker.shapeName = 'art/shapes/interface/checkpoint_marker_base.dae'
  marker.position = position
  marker.scale = scale
  marker.useInstanceRenderData = 1
  marker.instanceColor = color:asLinear4F()
  marker:registerObject(id)
  scenetree.ScenarioTriggersGroup:addObject(marker.obj)
  return marker
end

local function setFocusPOI(poi)
  if not poi then core_groundMarkers.setFocus(nil) end
  local state = M.state
  if state.focusExplorationPOI then
    local marker = scenetree[state.focusExplorationPOI..'_marker']
    if marker then marker.instanceColor = ColorF(1, 1, 1, 1):asLinear4F() end
  end

  state.focusExplorationScenario = poi
  state.focusExplorationPOI = nil
  state.closestRoad = {}

  local subsection = campaign_campaigns.getActiveSubsection()
  if subsection then
    for k,v in pairs(subsection.locations) do
      if k == poi then
        state.focusExplorationPOI = v.entryMarker
      end
    end
  end

  if state.focusExplorationPOI then
    local marker = scenetree[state.focusExplorationPOI..'_marker']
    if marker then marker.instanceColor = ColorF(0.7, 1, 0.7, 1):asLinear4F() end
  end
end

local function queryRoadNodeToPosition(vehicle, position, owner)
  -- log('I',logTag, 'queryRoadNodeToPosition called...')

  local pos = vec3(position)
  local first, second, distance = map.findClosestRoad(pos)
  local state = M.state

  -- log('D', logTag, 'queryRoadNodeToPosition '..owner..': '..first..','..second..','..distance)
  state.closestRoad[owner] = {position=position}
  if first ~= 'nil' and second ~= 'nil' then
    state.closestRoad[owner].first = first
    state.closestRoad[owner].next = second

    local mapData = map.getMap()
    local node1 = mapData.nodes[first]
    local node2 = mapData.nodes[second]
    if node1 and node2 then
      -- find which node is closest to the owner
      local sqrDist1 = (pos - node1.pos):squaredLength()
      local sqrDist2 = (pos - node2.pos):squaredLength()

      if sqrDist1 < sqrDist2 then
        state.closestRoad[owner].best = first
      else
        state.closestRoad[owner].best = second
      end
    end
  end
end

local function buildRoadIndicator()
  local state = M.state
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle or not state.focusExplorationPOI or not state.focusExplorationScenario then
    return
  end

  local locationData = campaign_campaigns.getActiveSubsectionLocationData(state.focusExplorationScenario)

  local vehiclePos = vehicle:getPosition()
  queryRoadNodeToPosition(vehicle, vehiclePos, 'player')

  local trigger = scenetree[state.focusExplorationPOI]
  --log('A', logTag, 'buildRoadIndicator '..state.focusExplorationPOI)
  if trigger and locationData.entryMarker then
    local triggerPos = trigger:getPosition()-- - vehiclePos
    queryRoadNodeToPosition(vehicle, triggerPos, state.focusExplorationPOI)
  end
end

local function getExplorationActive()
  return campaign_campaigns and campaign_campaigns.getCampaignActive() and M.state.inExploration
end

local function testDecals()
  local data = {}
  data.texture = 'art/arrow_decal.dds'
  data.position = Point3F(0, 1, 0)
  data.color = ColorF(1, 0, 0, 0.75)
  data.forwardVec = Point3F(0, 1, 0)
  data.scale = Point3F(2, 1, 1)
  Engine.Render.DynamicDecalMgr.addDecal(data)

  data.texture = 'art/arrow_decal.dds'
  data.position = Point3F(0, 2, 0)
  data.color = ColorF(0, 1, 0, 0.75)
  data.forwardVec = Point3F(0, 1, 0)
  data.scale = Point3F(2, 1, 1)
  Engine.Render.DynamicDecalMgr.addDecal(data)

  data.texture = 'art/arrow_decal.dds'
  data.position = Point3F(0, 3, 0)
  data.color = ColorF(0, 0, 1, 0.75)
  data.forwardVec = Point3F(0, 1, 0)
  data.scale = Point3F(2, 1, 1)
  Engine.Render.DynamicDecalMgr.addDecal(data)
end

local lastQuery = 10
local function onPreRender(dt)
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then return end

  --testDecals()

  if getExplorationActive() then
    lastQuery = lastQuery  - dt
    if lastQuery <= 0 then
      local vehiclePos = vehicle:getPosition()
      queryRoadNodeToPosition(vehicle, vehiclePos, 'player')
      lastQuery = 2.0
    end

    local state = M.state

    local colorTable = {ColorF(0.7,0.2,0.2,1.0), ColorF(0.2,0.7,0.2,1.0), ColorF(0.2,0.2,0.7,1.0), ColorF(0.7,0.7,0.2,1.0), ColorF(0.7,0.2,0.7,1.0), ColorF(0.2,0.7,0.7,1.0)}
    local playerRoadData = state.closestRoad['player']
    if playerRoadData and playerRoadData.first and playerRoadData.first ~= 'nil' then
      -- dump(playerRoadData)
      local colorIndex = 1
      local mapData = map.getMap()
       for key, data in pairs(state.closestRoad) do
          if key ~= 'player' and data.best then
            core_groundMarkers.setFocus(data.best)
            if false then
              data.path = map.getPath(playerRoadData.best, data.best)
              local pathSize = tableSize(data.path)
              local color = colorTable[colorIndex]
              local lineRadius = 0.05
              colorIndex = colorIndex + 1
              for i=1, (pathSize - 1) do
                local a = vec3(mapData.nodes[data.path[i]].pos)
                local b = vec3(mapData.nodes[data.path[i + 1]].pos)
                a.z = a.z + lineRadius*2
                b.z = b.z + lineRadius*2
                if i == 1 then debugDrawer:drawSphere(a:toPoint3F(), 0.5, color) end
                debugDrawer:drawSphere(b:toPoint3F(), 0.5, color)
                debugDrawer:drawCylinder(a:toPoint3F(), b:toPoint3F(), lineRadius, color)
              end
            end
          end
        end
    end
  end
end

local function findEndTrigger(locationKey)
  log('D', logTag, 'findEndTrigger called with name '..locationKey)
  local locationData = campaign_campaigns.getActiveSubsectionLocationData(locationKey)
  if locationData then
    return scenetree[locationData.exitLocation]
  end
  return nil
end

local function openShortLocationInfo(locationKey)
  log('I', logTag, 'openShortLocationInfo called....'..tostring(locationKey))

  local campaign = campaign_campaigns.getCampaign()
  if not campaign then
    return
  end
  local locationData = campaign_campaigns.getActiveSubsectionLocationData(locationKey)

  if locationData and locationData.info then
    local locationInfo = locationData.info
    local buttonsTable = {}
    table.insert(buttonsTable, {action = 'accept', text = 'More Info', cmd = 'campaign_exploration.accept()'})
    guihooks.trigger('MissionInfoUpdate',{title = locationInfo.title, type=locationInfo.type, buttons = buttonsTable})
    M.state.locationInfoDisplayed = false
  end
end

local function refreshLocationMarkers(subsection)
  local state = M.state  
  for k,v in pairs(subsection.locations) do
    if v.entryMarker then
      local trigger = scenetree[v.entryMarker]
      if trigger then
        local markerName = v.entryMarker..'_marker'
        local completed = campaign_campaigns.isLocationCompleted(k)
        if v.info.subtype == 'missionGiver' and completed then
          trigger:deleteObject()
        elseif not scenetree[markerName] then
          state.locationTriggers[trigger.name] = k
          if v.info.type == 'site' then
            if v.info.subtype ~= 'missionGiver' or (campaign_campaigns.canStartScenario(k) and not completed) then
              createScenarioMarker(markerName, trigger.position, trigger.scale, ColorF(1, 1, 0, 1))
            end
          elseif campaign_campaigns.canStartScenario(k) and campaign_campaigns.canImproveResult(k) then
            createScenarioMarker(markerName, trigger.position, trigger.scale, ColorF(1, 1, 1, 1))
          end
        end
      else
        log('E', logTag, 'Trigger missing for scnario : '..k..' Trigger name: '..tostring(v.entryMarker) )
      end
    end
  end
end

local function createSubsectionPrefabs(subsection, triggers)
  -- log('I', logTag, 'createSubsectionPrefabs called...')

  local campaign = campaign_campaigns.getCampaign()
  if not campaign then
    log('E', logTag, 'could not find a campaign')
    return
  end

  local missionGroup = scenetree.MissionGroup
  if not missionGroup then
    log('E', logTag, 'MissionGroup does not exist')
    return
  end

  if not triggers then
    log('E', logTag, 'triggers list for prefab was not specified.')
    return
  end

  local scenarioTriggersGroup = createObject('SimGroup')
  if not scenarioTriggersGroup then
    log('E', logTag, 'could not create scenarioTriggersGroup')
    return
  end

  local state = M.state
  scenarioTriggersGroup:registerObject('ScenarioTriggersGroup')
  scenarioTriggersGroup.canSave = false
  missionGroup:addObject(scenarioTriggersGroup.obj)

  local prefabObjects = {}
  -- Spawn the prefab for the triggers
  for _,prefabPath in ipairs(triggers) do
    local prefabName = string.gsub(prefabPath, "(.*/)(.*)%.prefab", "%2")
    log('A', logTag, 'Spawning: '..prefabPath..' with name: '..prefabName)

    if FS:fileExists(prefabPath) then
      if not scenetree.findObject(prefabName) then
        local prefabObj = spawnPrefab(prefabName, prefabPath, '0 0 0', '0 0 1', '1 1 1')
        scenarioTriggersGroup:addObject(prefabObj.obj)
        table.insert(prefabObjects, prefabObj)
      else
        log('E', logTag, 'Prefab: '..prefabName..' already exist in level')
      end
    else
      log('E', logTag, 'Prefab file not existing: '.. prefabPath .. ' - IGNORING IT')
    end
  end

  state.locationTriggers = {}

  refreshLocationMarkers(subsection)
end

local function destroySubsectionPrefabs()
  if scenetree.ScenarioTriggersGroup then
    scenetree.ScenarioTriggersGroup:delete()
  end
end

local function endSubsectionExploration()
  log('I', logTag, 'endSubsectionExploration called...')
  -- unload prefabs for campaign triggers
  destroySubsectionPrefabs()

  if scenetree.ExplorationGroup then
    scenetree.ExplorationGroup.obj:delete()
  end

  -- Delete the player's vehicles used
  core_vehicles.removeCurrent()
  M.state = {}
  core_groundMarkers.setFocus(nil)
  guihooks.trigger('MissionInfoUpdate', nil)

  local ExplorationCheckpoints = scenetree.findObject("ExplorationCheckpointsActionMap")
  if ExplorationCheckpoints then
    ExplorationCheckpoints:pop()
  end

  local ExplorationMissionUI = scenetree.findObject("ExplorationMissionUIActionMap")
  if ExplorationMissionUI then
    ExplorationMissionUI:pop()
  end

  local ExplorationGeneral = scenetree.findObject("ExplorationGeneralActionMap")
  if ExplorationGeneral then
    ExplorationGeneral:pop()
  end       
end

local function isValidSubsection(campaign, subsectionName)
  -- log('D', logTag, 'isValidSubsection called for name: '..subsectionName)
  if campaign then
    local subsections = campaign.meta.subsections or {}
    for k,_ in pairs(subsections) do
      if k == subsectionName then
        return true
      end
    end
  end
  return false
end

local function isValidLocation(campaign, subsectionName, locationKey)
  if campaign then
    local locations = (campaign.meta.subsections and subsectionName and campaign.meta.subsections[subsectionName].locations) or {}
    for key,_ in pairs(locations) do
      if key == locationKey then
        return true
      end
    end
  end
  return false
end

local function processExploreSubsection(spawningData, transitioningFromScenario)
  local campaign = campaign_campaigns.getCampaign()
  if not campaign then return end

  if not spawningData or not spawningData.subsectionKey then
    log('W', logTag, 'subsectionName is null')
    return
  end

  local subsection = campaign.meta.subsections[spawningData.subsectionKey]
  if not subsection then
    log('W', logTag, 'Cannot find subsection : '..dumps(spawningData.subsectionKey))
    return
  end

  local missionGroup = scenetree.MissionGroup
  if not missionGroup then
    log('E', logTag, 'MissionGroup does not exist')
    return
  end

  local explorationGroup = createObject('SimGroup')
  if not explorationGroup then
    log('E', logTag, 'could not create explorationGroup')
    return
  end

  local state = M.state

  ----------------exploreSubsection(subsectionName)------------------------------
  campaign.state.activeSubsection = spawningData.subsectionKey
  campaign.state.currentLocation = spawningData.subsectionKey

  createSubsectionPrefabs(subsection, subsection.triggers)
 
  setFocusPOI(nil)
  -------------------------------------------------------------------------------

  -----------------enterExplorationMode(spawningData)------------------------------
  explorationGroup:registerObject('ExplorationGroup')
  explorationGroup.canSave = false
  missionGroup:addObject(explorationGroup.obj)

  if shipping_build then
    core_gamestate.setGameState('exploration', 'exploration', 'scenario') --{context = 'campaign'} context doesn't seem to be used anywhere -- todo: find out if missed somewhere -yh
  else
    -- Debug. Only to help development
    core_gamestate.setGameState('exploration', 'scenario', 'freeroam')
  end

  guihooks.trigger('MenuHide')
  state.inExploration = true
  state.minimapOpen = false

  -- spawn new player vehicle
  -- log('I', logTag, 'Spawning Player in exploration : ')
  -- dump(spawningData)
  spawningPlayer = spawningData
  core_vehicles.spawnNewVehicle(spawningPlayer.model, spawningPlayer.options)

  if transitioningFromScenario then
    be:reloadCollision()
  end

  ui_message('extensions.campaign.exploration.mapHint', 600, 'MINIMAP_HELP', nil)

  inputActionFilter.clear(0)
  inputActionFilter.addAction(0, 'default_blacklist_exploration', true)

  local ExplorationCheckpoints = scenetree.findObject("ExplorationCheckpointsActionMap")
  if ExplorationCheckpoints then
    ExplorationCheckpoints:push()
  end  
  local ExplorationGeneral = scenetree.findObject("ExplorationGeneralActionMap")
  if ExplorationGeneral then
    ExplorationGeneral:push()
  end 
  ---------------------------------------------------------------------------------
  local minimap = subsection.minimap
  if minimap then
    --log('I', logTag, 'updating minimap....')
    local border = (minimap.worldCoord.border or 50)
    local halfWidth = (0.5 * minimap.worldCoord.w) - border
    local halfHeight = (0.5 * minimap.worldCoord.h) - border
    for k,v in pairs(subsection.locations) do
      if v.entryMarker and scenetree[v.entryMarker..'_marker'] then
        local pos = scenetree[v.entryMarker]:getPosition()

        if math.abs(pos.x) >= halfWidth then
          minimap.worldCoord.w = 2.0 * (math.abs(pos.x) + border)
        end

        if math.abs(pos.y) >= halfHeight then
          minimap.worldCoord.h = 2.0 * (math.abs(pos.y) + border)
        end
      end
    end
    minimap.worldCoord.x = -0.5 * minimap.worldCoord.w
    minimap.worldCoord.y = -0.5 * minimap.worldCoord.h
    --dump(minimap)
  end

  campaign_campaignsLoader.saveCampaign(campaign)  
end

local function onClientStartMission(mission)

  -- Disclaimer message for campaign mode.
  -- guihooks.trigger('toastrMsg', {type="warning", title="Work in Progress", msg = "Campaign mode is a work in progress and is still subject to further changes.", config = {timeOut = 0}})

  local state = M.state
  if state.pendingSpawningData then
    log('D', logTag, 'onClientStartMission called....with sectionName '..tostring(state.pendingSpawningData.subsectionKey))
    local tempData = state.pendingSpawningData
    state.pendingSpawningData = nil
    processExploreSubsection(tempData)
  end
end

local function onClientEndMission(mission)
  if not M.state.pendingSpawningData then
    endSubsectionExploration()
  end
end

local function startSubsectionExploration(subsectionKey, locationMarker, spawningData)
  log('D', logTag, 'startSubsectionExploration called ' .. tostring(subsectionKey)..', '..tostring(locationMarker))

  local levelName = campaign_campaigns.getSubsection(subsectionKey).level
  if not levelName then
    log('W', logTag, 'No level specified for subsection ' .. subsectionKey)
    return
  end

  if not spawningData then
    log('W', logTag, 'No spawning data specified when starting subsection ' .. subsectionKey)
    return
  end

  local state = M.state
  local transitioningFromScenario = false
  if scenetree.ScenarioObjectsGroup then
    scenetree.ScenarioObjectsGroup:deleteAllObjects()
    transitioningFromScenario = true
  end

  spawningData.subsectionKey = subsectionKey
  spawningData.locationMarker = locationMarker

  local levelPath = string.lower('levels/'..levelName..'/info.json')
  local loadedMissionFile = string.lower(getMissionFilename())
  -- log('D', logTag, 'levelPath: ' .. tostring(levelPath)..'   loadedMissionFile: ' .. tostring(loadedMissionFile))

  if levelPath ~= loadedMissionFile then
    state.pendingSpawningData = spawningData

    log('D', logTag, 'loading level: ' .. levelPath)
    TorqueScript.eval('$preventPlayerSpawning="1";')

    beamng_cef.startLevel(levelPath)
  else
    processExploreSubsection(spawningData, transitioningFromScenario)
  end
end

local function locationRequiresExtraUI(locationKey)
  -- log('I', logTag, 'locationRequiresExtraUI called '..tostring(locationKey))

  local locationData = campaign_campaigns.getActiveSubsectionLocationData(locationKey)
  if locationData and locationData.info then
    -- dump(locationData)
    local locationInfo = locationData.info
    if locationInfo.type == 'site' then
      return (locationInfo.subtype == 'playerHQ') or (locationInfo.subtype == 'vendor')
    end
    if locationInfo.type == 'race' then
      return (locationInfo.subtype == 'timeTrial')
    end
  end
  return false
end

local function openLocationExtraUI(locationKey)
  local state = M.state

  if state.missionExtraUiOpened then return end

  local locationData = campaign_campaigns.getActiveSubsectionLocationData(state.locationKey)
  if locationData and locationData.info then
    local locationInfo = locationData.info
    if locationInfo.type == 'race' and locationInfo.subtype == 'timeTrial' then
      local raceLevel = scenario_quickRaceLoader.getLevel(locationInfo.levelName)
      if not raceLevel then
        log('E', logTag, 'Could not find time trail level '..tostring(locationInfo.levelName)..' for campaign scenario '..tostring(locationKey))
        return
      end

      local vehicle = be:getPlayerVehicle(0)
      vehicle:queueLuaCommand('controller.setFreeze(1)')
      bindings.menuActive(true)
      state.missionExtraUiOpened = true

      local raceTrack = scenario_quickRaceLoader.getLevelTrack(locationInfo.levelName, locationInfo.trackName)
      local ownedVehicles = core_inventory.getItemList('$$$_VEHICLES')
      -- Note: 'campaign.quickraceOverview' is also used in UIStateChange, make sure to keep in sync if changing
      guihooks.trigger('ChangeState', {state = 'campaign.quickraceOverview', params = {level = raceLevel , track = raceTrack, vehicles = ownedVehicles }})
    end

    if locationInfo.type == 'site' and (locationInfo.subtype == 'playerHQ' or locationInfo.subtype == 'vendor') then
      core_gamestate.setGameState("scenario", {}, 'freeroam')
      local vehicle = be:getPlayerVehicle(0)
      vehicle:queueLuaCommand('controller.setFreeze(1)')
      bindings.menuActive(true)
      state.missionExtraUiOpened = true

      local mode
      local vehiclesList
      local money
      if locationInfo.subtype == 'playerHQ' then
        mode = 'garage'
        vehiclesList = core_inventory.getItemList('$$$_VEHICLES')
      else
        mode = 'dealer'
        vehiclesList = campaign_dealer.getStock('$$$_VEHICLES')
        money = core_inventory.getItemList('$$$_MONEY')
      end

      guihooks.trigger('ChangeState', {state = 'garageProto.menu.select', params = {vehicles = vehiclesList, mode=mode, money = money}})
    end
  end
end

local function processOnEvent(onEventData)
end

local function missionGiverCallback()
  log('I', logTag, 'missionGiverCallback called...')
  local state = M.state
  if state.inSideMissionTrigger and state.locationKey then
    local subsection = campaign_campaigns.getActiveSubsection()
    local locationData = campaign_campaigns.getLocationData(subsection.key, state.locationKey)
    dump(locationData)
    if locationData.info.type == "site" and locationData.info.subtype == "missionGiver" then
      campaign_campaigns.markCompleted(subsection, state.locationKey)

      local markerName = locationData.entryMarker..'_marker'
      if scenetree[markerName] then
        scenetree[markerName]:deleteObject()
      end

      if scenetree[locationData.entryMarker] then
        scenetree[locationData.entryMarker]:deleteObject()
      end

      processOnEvent(locationData)

      state.locationKey = nil
      state.inSideMissionTrigger = false
      refreshLocationMarkers(subsection)
    end
  end
end

local function scenarioAcceptCallback()
  log('I', logTag, 'scenarioAcceptCallback accepted....')
  local state = M.state
  if state.inSideMissionTrigger and state.locationKey then
    local secondaryUiRequired = locationRequiresExtraUI(state.locationKey)
    if secondaryUiRequired then
      log('I', logTag, 'Opening mission extra UI....')
      openLocationExtraUI(state.locationKey)
    else
      state.loadNextScenario = true
    end
  end
end

local function siteLocationCallback()
  log('I', logTag, 'siteLocationCallback accepted....')
  local state = M.state
  if state.inSideMissionTrigger and state.locationKey then
    local secondaryUiRequired = locationRequiresExtraUI(state.locationKey)
    if secondaryUiRequired then
      log('I', logTag, 'Opening mission extra UI....')
      openLocationExtraUI(state.locationKey)
    end
  end
end

local function handleScenarioTrigger(vehicleID, subsectionKey, locationKey)
  -- log('I', logTag, 'onBeamNGTrigger for campaign lua in trigger '..data.triggerName)
  local state = M.state
  local completed = campaign_campaigns.isLocationCompleted(locationKey)
  local canImprove = campaign_campaigns.canImproveResult(locationKey)
  local allowed = campaign_campaigns.canStartScenario(locationKey)
  if allowed and (not completed or canImprove) then
    state.triggerCallback = scenarioAcceptCallback
    state.locationKey = locationKey
    state.inSideMissionTrigger = true
    openShortLocationInfo(locationKey)
  end
end

local function handleSiteTrigger(vehicleID, subsectionKey, locationKey)
  -- log('I', logTag, 'handleSiteTrigger called...'..subsectionKey..' , '..locationKey)
  local state = M.state

  local locationData = campaign_campaigns.getLocationData(subsectionKey, locationKey)

  if campaign_campaigns.isTransitionPoint(subsectionKey, locationKey) then
    if state.transitionPointData == nil then
      local entryPointParts = campaign_campaignsLoader.splitFieldByToken(locationData.info.entryPoint, '.')

      local vehicleData = extractVehicleData(vehicleID)
      local spawningData = createPlayerSpawningData(vehicleData.model, vehicleData.config, vehicleData.color, vehicleData.licenseText)

      state.transitionPointData = {locationMarker = entryPointParts[2]}

      startSubsectionExploration(entryPointParts[1], entryPointParts[2], spawningData)
    end
  elseif campaign_campaigns.isMissionGiver(subsectionKey, locationKey) then
    local completed = campaign_campaigns.isLocationCompleted(locationKey)
    local allowed = campaign_campaigns.canStartScenario(locationKey)
    if allowed and not completed then
      state.triggerCallback = missionGiverCallback
      state.locationKey = locationKey
      state.inSideMissionTrigger = true
      openShortLocationInfo(locationKey)
    end
  else --if campaign_campaigns.isPlayerHQ(subsectionKey, locationKey) then
    state.triggerCallback = siteLocationCallback
    state.locationKey = locationKey
    state.inSideMissionTrigger = true
    openShortLocationInfo(locationKey)
  end
end

local function onBeamNGTrigger(data)
  -- log('I', logTag, 'onBeamNGTrigger for exploration lua')
  -- only trigger on the player vehicle
  local vid = be:getPlayerVehicleID(0)
  if not vid or not data or not data.subjectID or data.subjectID ~= vid then
    return
  end

  -- log('D', logTag, 'vid: ' ..vid)
  -- dump(data)
  local state = M.state
  if state.locationTriggers then
    local subsectionKey = campaign_campaigns.getActiveSubsection().key
    local locationKey = state.locationTriggers[data.triggerName]
    if subsectionKey and locationKey then
      if data.event == 'enter' and not state.inSideMissionTrigger then
        if campaign_campaigns.isSiteLocation(subsectionKey, locationKey) then
          handleSiteTrigger(data.subjectID, subsectionKey, locationKey)
        else
          handleScenarioTrigger(data.subjectID, subsectionKey, locationKey)
        end
        local ExplorationMissionUI = scenetree.findObject("ExplorationMissionUIActionMap")
        if ExplorationMissionUI then
          ExplorationMissionUI:push()
        end
      elseif data.event == 'exit' and state.inSideMissionTrigger and state.locationKey == locationKey then
        state.inSideMissionTrigger = false
        state.locationInfoDisplayed = false
        state.transitionPointData = nil
        state.locationKey = nil
        guihooks.trigger('MissionInfoUpdate', nil)
        local ExplorationMissionUI = scenetree.findObject("ExplorationMissionUIActionMap")
        if ExplorationMissionUI then
          ExplorationMissionUI:pop()
        end    
      end
    end
  end
  --dump(campaign)
end

local function startSelectedScenario(processedScenario)
  local state = M.state

  if state.locationKey then
    local nextScenario = state.locationKey
    state.locationKey = nil
    state.inSideMissionTrigger = false
    state.missionExtraUiOpened = false
    state.locationInfoDisplayed = false
    inputActionFilter.clear(0)
    setFocusPOI(nil)
    campaign_campaigns.startScenarioFromKey(nextScenario, processedScenario)
  else
    log('E', logTag, 'start selected scenario called with null scenario key')
  end
end

-- executed every frame, also when not rendering 3d in the menu
local function onUpdate()
  local campaign = campaign_campaigns.getCampaign()
  if not campaign then
    return
  end

  local state = M.state

  if state.inSideMissionTrigger and state.loadNextScenario then
    state.loadNextScenario = false
    state.inSideMissionTrigger = false
    startSelectedScenario()
  end
end

local function accept()
  local state = M.state

  if getExplorationActive() and state.inSideMissionTrigger then
    if not state.locationInfoDisplayed then
      log('I', logTag, 'Displaying mission info for '..tostring(state.locationKey))
      local buttonsTable = {}
      table.insert(buttonsTable, {action = 'accept', text = 'Accept', cmd = 'campaign_exploration.accept()'})
      table.insert(buttonsTable, {action = 'decline',text = 'Decline', cmd = 'campaign_exploration.decline()'})

      local scenarioData = campaign_campaigns.getActiveSubsectionLocationData(state.locationKey)
      if scenarioData and scenarioData.info then
        local locationInfo = scenarioData.info
        local dataTable = {}

        if locationInfo.distance then
          table.insert(dataTable,{label = 'distance',  value = locationInfo.distance})
        end

        local rewards = campaign_rewards.getScenarioReward(scenarioData, 'onSucceed')
        if rewards and #rewards > 0 then
          table.insert(dataTable,{label = 'rewards', value = rewards[1].name})
        end
        table.insert(dataTable,{label = 'description', value = locationInfo.description})

        guihooks.trigger('MissionInfoUpdate',{title = locationInfo.title,
                                              type = locationInfo.type,
                                              data = dataTable,
                                              buttons = buttonsTable})

        state.locationInfoDisplayed = true
        --guihooks.trigger('PlayerStatusUpdate', {'money'=520, 'currentObjs' = 1, 'totalObjs'= 4})
      else
        log('E', logTag, 'could not find mission info for '..tostring(state.locationKey or nil))
      end
    else
      guihooks.trigger('MissionInfoUpdate', nil)
      state.locationInfoDisplayed = false

      if state.triggerCallback and type(state.triggerCallback) == 'function' then
        state.triggerCallback()
        state.triggerCallback = nil
      else
        log('W', logTag, 'No callback set to handle trigger case for Location: '..tostring(state.locationKey))
      end
    end
  end
end

local function decline()
  local state = M.state
  if campaign_campaigns.getCampaignActive() and state.locationInfoDisplayed then
    log('I', logTag, 'Mission declined....')
    local locationInfo = campaign_campaigns.getActiveSubsectionLocationData(state.locationKey).info
    local buttonsTable = {}
    table.insert(buttonsTable, {action = 'accept', text = 'More Info', cmd = 'campaign_exploration.accept()'})
    guihooks.trigger('MissionInfoUpdate',{title = locationInfo.title, type=locationInfo.type, buttons = buttonsTable})
    state.locationInfoDisplayed = false
  end
end

local function getMinimapInfo()
  local subsection = campaign_campaigns.getActiveSubsection()  
  local minimap = subsection and subsection.minimap
  if not minimap then return end

  local locationStatusTable = campaign_campaigns.getLocationStatusTable()

  local info = {}
  for k,v in pairs(subsection.locations) do
    local validPoi = campaign_campaigns.canStartScenario(k) and campaign_campaigns.canImproveResult(k)
    if validPoi and v.entryMarker and scenetree[v.entryMarker..'_marker'] then
      local trigger = scenetree[v.entryMarker]
      local poi = {}
      poi.id = k
      poi.title = v.info.title
      poi.type = v.info.type
      poi.subtype = v.info.subtype
      poi.description = v.info.description
      poi.position = {0, 0}
      local locationStatus = locationStatusTable[subsection.key..'.'..k]
      poi.state = (locationStatus.state == 'completed' and locationStatus.medal) or locationStatus.state
      poi.position.x = (trigger:getPosition().x - minimap.worldCoord.x) / minimap.worldCoord.w
      poi.position.y = 1 - ((trigger:getPosition().y - minimap.worldCoord.y) / minimap.worldCoord.h)
      table.insert(info, poi)
    end
  end

  return info
end

local function onFocusPOI(poi)
  -- log('I', logTag, 'onFocusPOI: '..dumps(poi))
  setFocusPOI(nil)
  guihooks.trigger('MenuHide')
  guihooks.trigger('ChangeState', 'menu')
  bullettime.pause(false)

  setFocusPOI(poi)
  campaign_exploration.buildRoadIndicator()
end

local function updateMapUI()
  local state = M.state
  local info = getMinimapInfo()
  local subsection = campaign_campaigns.getActiveSubsection()
  local minimap = subsection and subsection.minimap
  local uiParams = {}
  uiParams.level = subsection.level or "<missing level>"
  uiParams.money = '$'..tostring(core_inventory.getItem('$$$_MONEY',  0))
  uiParams.baseImg = minimap.image
  uiParams.points = {}
  uiParams.selectedMission = -1
  for i, poi in ipairs(info) do
    -- TODO(AK): State needs to come from result of scenario, if it has been played.
    local p = {x=poi.position.x, y=poi.position.y, type=poi.type, subtype=poi.subtype,
               title=poi.title, desc=poi.description, state=poi.state,
               onClick='campaign_exploration.onFocusPOI("'..poi.id..'")'}
    table.insert(uiParams.points, p)
    if poi.id == state.focusExplorationScenario then
      uiParams.selectedMission = i - 1
    end
  end

  local player = be:getPlayerVehicle(0)
  if player and minimap then
    uiParams.player = {}
    uiParams.player.x = (player:getPosition().x - minimap.worldCoord.x) / minimap.worldCoord.w
    uiParams.player.y = 1 - ((player:getPosition().y - minimap.worldCoord.y) / minimap.worldCoord.h)
    local matrix = player:getRefNodeMatrix()
    local forVec = matrix:getColumn(1)
    local heading = math.atan2(-forVec.x, -forVec.y)*180/math.pi
    uiParams.player.heading = (heading > 0 and heading) or (heading + 360)
  end
  ui_message('', 0, 'MINIMAP_HELP', nil) -- remove hint on how to open the map
  guihooks.trigger('ChangeState', {state ='mapview', params = {data=uiParams}})
end

local function onVehicleSpawned(vehicleId)
  if not getExplorationActive() then
    return
  end

  local campaign = campaign_campaigns.getCampaign()
  local playerId = be:getPlayerVehicleID(0)
  log('I', logTag, 'onVehicleSpawned PlayerID: '..playerId..' Spawned: '..vehicleId)

  if spawningPlayer and vehicleId == playerId then
    local veh = be:getObjectByID(playerId)

    if scenetree.ExplorationGroup then
      scenetree.ExplorationGroup:addObject(veh)
    end

    local endTrigger = (nextSpawnTrigger and scenetree[nextSpawnTrigger]) or (spawningPlayer.locationMarker and scenetree[spawningPlayer.locationMarker])
    nextSpawnTrigger = nil
    spawningPlayer = nil
    if endTrigger then
      local transform = endTrigger:getTransform()
      veh:setTransform(transform)
      veh:queueLuaCommand('obj:queueGameEngineLua("if be:getObjectByID('..playerId..') then be:getObjectByID('..playerId..'):autoplace() end")')
      bullettime.set(1)
      veh:queueLuaCommand('recovery.clear()')
    else
      log('E', logTag, 'cannot find end trigger' )
    end
    buildRoadIndicator()
  end
end

local function stop()
  log('I', logTag, 'stop called....')

  -- make sure exploration specific ui is cleaned up
  guihooks.trigger('MissionInfoUpdate', nil)
  if scenetree.ScenarioTriggersGroup then
    scenetree.ScenarioTriggersGroup:delete()
  end

  M.state.loadNextScenario = nil
  M.state.locationKey = nil
end

local function toggleMinimap()
  log('I', logTag, 'toggleMinimap called....')
  M.state.minimapOpen = not M.state.minimapOpen
  if M.state.minimapOpen then
    bullettime.pause(true)
    updateMapUI()

  else
    bullettime.pause(false)
    guihooks.trigger('ChangeState', {state ='menu'})
  end
end

local function onSerialize()
  -- log('D', logTag, 'onSerialize called...')
  local data = {}
  
  data = deepcopy(M.state)
  -- dump(data)
  -- writeFile("campaign_exploration.txt", dumps(data))
  return data
end

local function onDeserialized(data)
  -- log('D', logTag, 'onDeserialized called...')
  -- dump(data)
  M.state = deepcopy(data)
  if getExplorationActive() then
    --exploreSubsection(state.currentSubsection)
    onFocusPOI(state.focusExplorationScenario)
  end
end

local function onUiChangedState (curUIState, prevUIState)
  local state = M.state
  -- log('I', logTag, 'Ui state changed - cur State: '..curUIState..'  prev State: '..prevUIState..'  state.locationKey: '..tostring(state.locationKey))
  if getExplorationActive() and state.locationKey and state.inSideMissionTrigger and state.missionExtraUiOpened then
    if curUIState == 'menu' then
      local vehicle = be:getPlayerVehicle(0)
      vehicle:queueLuaCommand('controller.setFreeze(0)')
      state.missionExtraUiOpened = false
      local subsectionKey = campaign_campaigns.getActiveSubsection().key
      local vid = be:getPlayerVehicleID(0)
      if campaign_campaigns.isSiteLocation(subsectionKey, state.locationKey) then
        handleSiteTrigger(vid, subsectionKey, state.locationKey)
      else
        handleScenarioTrigger(vid, subsectionKey, state.locationKey)
      end
    end
  end

  if curUIState == 'menu' and prevUIState == 'mapview' then
    if M.state.minimapOpen then
      toggleMinimap()
    end
  end  
end

local function startTimeTrail(scenarioFile, trackFile, vehicleFile)
  log('I', logTag, 'startTimeTrail called...')
  local processedScenario = scenario_quickRaceLoader.loadQuickrace(M.state.locationKey, scenarioFile, trackFile, vehicleFile)
  --dump(processedScenario)
  bindings.menuActive(false)
  startSelectedScenario(processedScenario)
end

local function uiEventSelectVehicle(vehicleData)
  local state = M.state
  log('I', logTag, 'uiEventSelectVehicle called... Location: '..state.locationKey)
  -- dump(vehicleData)

  local locationData = campaign_campaigns.getActiveSubsectionLocationData(state.locationKey)
  local locationInfo = locationData and locationData.info
  if locationInfo.type == 'site' and locationInfo.subtype == 'playerHQ' then
    local vehicle = be:getPlayerVehicle(0)
    vehicleData.licenseText = vehicle:getDynDataFieldbyName("licenseText", 0)
    campaign_campaigns.getCampaign().state.userVehicle = vehicleData
    spawningPlayer = createPlayerSpawningData(vehicleData.model, vehicleData.config, vehicleData.color, vehicleData.licenseText)
    core_vehicles.replaceVehicle(spawningPlayer.model, spawningPlayer.options)

    bindings.menuActive(false)
    core_gamestate.setGameState('scenario', 'scenario', 'freeroam')
    guihooks.trigger('ChangeState', {state = 'menu'})
  elseif locationInfo.type == 'site' and locationInfo.subtype == 'vendor' then
    -- log('I', logTag, 'Buying vehicle.... ')
    local modelData = core_vehicles.getModel(vehicleData.model)
    core_inventory.addItem("$$$_VEHICLES", vehicleData)
    core_inventory.removeItem("$$$_MONEY", modelData.configs[vehicleData.config].Value)
    campaign_dealer.removeFromStock("$$$_VEHICLES", vehicleData)
    -- guihooks.trigger('RefreshVehicles', {vehicles = campaign_dealer.getStock('$$$_VEHICLES'), money = core_inventory.getItemList('$$$_MONEY')})
  end
end

local function uiEventGarageExit()
  log('I', logTag, 'uiEventGarageExit called...')
  local vehicle = be:getPlayerVehicle(0)
  vehicle:queueLuaCommand('controller.setFreeze(0)')

  bindings.menuActive(false)
  core_gamestate.setGameState('scenario', 'scenario', 'freeroam')
  guihooks.trigger('ChangeState', {state = 'menu'})
end

local function onCameraToggled(data)
  -- log('I', logTag, 'onCameraToggled called...')
  -- dump(data)
  local state = M.state
  if data.cameraType == "FreeCam" then 
    state.missionExtraUiOpened = false
    guihooks.trigger('MissionInfoUpdate', nil)
    guihooks.trigger('ChangeState', {state = 'menu'})
  elseif data.cameraType == "GameCam" then
    if getExplorationActive() and state.locationKey and state.inSideMissionTrigger then
      local vehicle = be:getPlayerVehicle(0)
      vehicle:queueLuaCommand('controller.setFreeze(0)')
      state.missionExtraUiOpened = false
      local subsectionKey = campaign_campaigns.getActiveSubsection().key
      local vid = be:getPlayerVehicleID(0)
      if campaign_campaigns.isSiteLocation(subsectionKey, state.locationKey) then
        handleSiteTrigger(vid, subsectionKey, state.locationKey)
      else
        handleScenarioTrigger(vid, subsectionKey, state.locationKey)
      end
    end
  end
end

local function onSaveCampaign(saveCallback)
  local data = {}  
  data = deepcopy(M.state)
  saveCallback(M.__globalAlias__, data)
end

local function onResumeCampaign(campaignInProgress, data)
  log('I', logTag, 'resume campaign called.....')
  M.state = data
end

M.onUiChangedState            = onUiChangedState
M.startTimeTrail              = startTimeTrail
M.uiEventSelectVehicle        = uiEventSelectVehicle
M.uiEventGarageExit           = uiEventGarageExit
M.updateMapUI                 = updateMapUI
M.setFocusPOI                 = setFocusPOI
M.onFocusPOI                  = onFocusPOI
M.buildRoadIndicator          = buildRoadIndicator
M.queryRoadNodeToPosition     = queryRoadNodeToPosition
M.onBeamNGTrigger             = onBeamNGTrigger
M.onUpdate                    = onUpdate
M.onPreRender                 = onPreRender
M.onVehicleSpawned            = onVehicleSpawned
M.accept                      = accept
M.decline                     = decline
M.startSubsectionExploration  = startSubsectionExploration
M.endSubsectionExploration    = endSubsectionExploration
M.stop                        = stop
M.toggleMinimap               = toggleMinimap
M.getExplorationActive        = getExplorationActive
M.isValidLocation             = isValidLocation
M.isValidSubsection           = isValidSubsection
M.onSerialize                 = onSerialize
M.onDeserialized              = onDeserialized
M.onClientStartMission        = onClientStartMission
M.onClientEndMission          = onClientEndMission
M.onCameraToggled             = onCameraToggled
M.onSaveCampaign              = onSaveCampaign
M.onResumeCampaign            = onResumeCampaign
return M
