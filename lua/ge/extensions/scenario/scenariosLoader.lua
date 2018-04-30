-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local logTag = 'scenariosLoader'

local M = {}
M.scenarioModules   = {'scenario_scenarios', 'scenario_waypoints', 'statistics_statistics', 'scenario_raceUI', 'scenario_raceGoals'}

local displayedRestrictMessage = nil

local function processScenarioData(scenarioKey, scenarioData, scenarioFilename)
    scenarioData.scenarioKey = scenarioKey

    if scenarioFilename then
      scenarioData.sourceFile = scenarioFilename
      scenarioData.official = isOfficialContent(FS:getFileRealPath(string.sub(scenarioFilename,0)))
      scenarioData.levelName = string.gsub(scenarioFilename, "levels/(.*)/scenarios/(.*)%.json", "%1")
      scenarioData.scenarioName = string.gsub(scenarioFilename, "(.*/)(.*)%.json", "%2")
      scenarioData.directory = string.gsub(scenarioFilename, "(.*)/(.*)%.json", "%1")
    end

    local tmp = 'levels/' .. scenarioData.levelName .. '/info.json'
    if FS:fileExists(tmp) then
      local infoJson = readJsonFile(tmp)
      if infoJson and infoJson.title then 
        scenarioData.map = infoJson.title 
      end
    end

    -- below are the defaults for a scenario including automatic file guessing for some fields
    if not scenarioData.vehicles then
      scenarioData.vehicles = {scenario_player0 = {playerUsable = true, startFocus = true}, ['*'] = {playerUsable = false}}
    end

    if not scenarioData.difficulty then
      scenarioData.difficulty = 'easy'
    end
    scenarioData.extensions = scenarioData.extensions or {}
    table.insert(scenarioData.extensions, {name=scenarioData.scenarioName, optional=true}) -- try to load an extension with the scenarioname by default

    -- figure out if a html start file is existing
    local htmldiscovered = false
    if not scenarioData.startHTML then
      scenarioData.startHTML = scenarioData.scenarioName .. '.html'
      htmldiscovered = true
    end
    if not FS:fileExists(scenarioData.directory.."/"..scenarioData.startHTML) then
      if not htmldiscovered then
        log('W', logTag, 'start html not found, disabled: ' .. scenarioData.startHTML)
      end
      scenarioData.startHTML = nil
    end

      
    if not scenarioData.introType then
        scenarioData.introType = 'htmlOnly'
    end

    -- figure out the prefabs: add default and check them
    if not scenarioData.prefabs then
      scenarioData.prefabs = {}
    end

    -- try to load some defaults
    tmp = scenarioData.directory .. "/" .. scenarioData.scenarioName .. '.prefab'
    if FS:fileExists(tmp) then
      table.insert(scenarioData.prefabs, tmp)
    end

    tmp = scenarioData.directory .. "/" .. scenarioData.scenarioName .. '_intro' .. '.prefab'
    if FS:fileExists(tmp) then
      table.insert(scenarioData.prefabs, tmp)
    end

    local levelPath = 'levels/' .. scenarioData.levelName
    tmp = levelPath .. "/" .. scenarioData.scenarioName .. '.prefab'
    if FS:fileExists(tmp) then
      table.insert(scenarioData.prefabs, tmp)
    end

    local np = {}
    for _,p in pairs(scenarioData.prefabs) do
      if FS:fileExists(p) then
        if not tableContainsCaseInsensitive(np, p) then
          table.insert(np, p)
        end
      else
        tmp = levelPath.."/"..p..'.prefab'
        local dirtmp = scenarioData.directory .. "/"..p..'.prefab'
        if not tableContainsCaseInsensitive(np, tmp) and FS:fileExists(tmp) then
          table.insert(np, tmp)
        elseif not tableContainsCaseInsensitive(np, dirtmp) and FS:fileExists(dirtmp) then
          table.insert(np, dirtmp)
        else
          log('E', logTag, 'Prefab not found: ' .. tostring(p) .. ' - DISABLED')
          log('E', logTag, 'Used in scenario: ' .. tostring(scenarioFilename))
        end
      end
    end
    scenarioData.prefabs = np

    -- figure out the previews automatically and check for errors
    if not scenarioData.previews then
      local tmp = FS:findFilesByRootPattern(scenarioData.directory.."/", scenarioData.scenarioName..'*.jpg', 0, true, false)
      scenarioData.previews = {}
      for _, p in pairs(tmp) do
        if string.startswith(p, scenarioData.directory) then
          table.insert(scenarioData.previews, string.sub(p, string.len(scenarioData.directory) + 2))
        end
      end
    end
    np = {}
    for _,p in pairs(scenarioData.previews) do
        table.insert(np, imageExistsDefault(scenarioData.directory.."/"..p))
    end
    if tableSize(np) == 0 then
       table.insert(np, imageExistsDefault(''))
    end
    scenarioData.previews = np
    if #scenarioData.previews == 0 then
      log('W', logTag, 'scenario has no previews: ' .. tostring(scenarioData.scenarioName))
    end

    if not scenarioData.playersCountRange then scenarioData.playersCountRange = {} end
    if not scenarioData.playersCountRange.min then scenarioData.playersCountRange.min = 1 end
    scenarioData.playersCountRange.min = math.max( 1, scenarioData.playersCountRange.min )
    if not scenarioData.playersCountRange.max then scenarioData.playersCountRange.max = scenarioData.playersCountRange.min end
    scenarioData.playersCountRange.max = math.max( scenarioData.playersCountRange.min, scenarioData.playersCountRange.max )

    scenarioData.extraTime = 0

    -- set defaults if keys are missing
    scenarioData.lapCount = scenarioData.lapCount or 1
    scenarioData.whiteListActions = scenarioData.whiteListActions or {"default_whitelist_scenario"}
    scenarioData.blackListActions = scenarioData.blackListActions or {"default_blacklist_scenario"}
    scenarioData.radiusMultiplierAI = scenarioData.radiusMultiplierAI or 1

    local restrictScenarios = settings.getValue("restrictScenarios")
    if restrictScenarios == nil then restrictScenarios = true end
    if (shipping_build and campaign_campaigns and campaign_campaigns.getCampaignActive()) then restrictScenarios = true end

    if not restrictScenarios then
      if not displayedRestrictMessage then
        displayedRestrictMessage = true
        log('W', logTag, '** no restrictions **')
      end
      scenarioData.whiteListActions = {}
      scenarioData.blackListActions = {"loadHome", "saveHome", "recover_vehicle", "reload_vehicle"}
    end

    -- process lapConfig
    scenarioData.BranchLapConfig = scenarioData.BranchLapConfig or scenarioData.lapConfig or {}
    scenarioData.lapConfig = {}
    for i, v in ipairs(scenarioData.BranchLapConfig) do
      if type(v) == 'string' then
        table.insert(scenarioData.lapConfig, v)
      end
    end
    scenarioData.initialLapConfig = deepcopy(scenarioData.lapConfig)

    return scenarioData
end

local function loadScenario(scenarioPath, key)
  -- log('D', logTag, 'Load scenario - '..scenarioPath)
  local processedScenario = nil
  if scenarioPath then
    local scenarioData = readJsonFile(scenarioPath)
    
    if scenarioData then
      -- readJsonFile for valid scenarios returns a table with 1 entry
      if type(scenarioData) == 'table' and #scenarioData == 1 then
        processedScenario = processScenarioData(key, scenarioData[1], scenarioPath)
      end
    else
      log('E', logTag, 'Could not find scenario '..scenarioPath)
    end
  end
  
  return processedScenario
end

-- this function is used by the UI to display the list of scenarios
local function getList(subdirectory)
  displayedRestrictMessage = false
  local levelList = getLevelList()
  local scenarios = {}
  for _, levelName in ipairs(levelList) do
    local path = ""
    if subdirectory ~= nil then
      path = 'levels/' .. levelName .. '/scenarios/' .. subdirectory .. '/'
    else 
      path = 'levels/' .. levelName .. '/scenarios/'
    end
    local t3dpath = '/' .. path -- the leading slash is a workaround for a bug in FS:findFilesByRootPattern
    local subfiles = FS:findFilesByPattern(t3dpath, '*.json', -1, true, false)
    for _, scenarioFilename in ipairs(subfiles) do
      -- remove leading 'game:' in filename
      scenarioFilename = string.gsub(scenarioFilename, "(.*:/)(.*)", "%2")
      local newScenario = loadScenario(scenarioFilename)
      if newScenario then
        if not shipping_build  or  (shipping_build and not newScenario.restrictToCampaign) then
          table.insert(scenarios, newScenario)
        end        
      end      
    end
  end
  return scenarios
end

-- this function is called when the user selects a scenario to play from the UI
local function start(sc)
  if campaign_campaigns then
    campaign_campaigns.stop()
  end    

  if scenetree.MissionGroup then
    log('D', logTag, 'Delaying start of scenario until current level is unloaded...')

    M.triggerDelayedStart = function()
      log('D', logTag, 'Triggering a delayed start of scenario...')
      M.triggerDelayedStart = nil
      start(sc)
    end
    
   endActiveGameMode(M.triggerDelayedStart)
  else
    loadGameModeModules(M.scenarioModules)
    displayedRestrictMessage = nil
    scenario_scenarios.executeScenario(sc)
  end
end

local function startByPath(path)
  if not string.find(path, ".json") then
    path = path..".json"
  end
  if not FS:fileExists(path) then
    log('E', logTag, path .." does not exist")
    return
  end
  --TODO check whether correct level is loaded <- really necessary?
  local newScenario = loadScenario(path)
  start(newScenario)
end

-- function that reloads the current scenario when its sources have changed
local function reloadScenarioSourcefile()
  local scenario = scenarios and scenario_scenarios.getScenario()
  if not scenario then return end

  print("@@@@@@reloadScenarioSourcefile()")
  -- saves the values to look for
  local levelName = scenario.levelName
  local scenarioName = scenario.scenarioName
  local sourceFile = scenario.sourceFile
  -- refresh the list
  local scenarios = getList()
  -- select the scenario again
  for k,v in pairs(scenarios) do
    if v.levelName == levelName and v.scenarioName == scenarioName and v.sourceFile == sourceFile then
      start(v)
      break
    end
  end
  log('E', logTag, 'Unable to reload scenario: scenario not found anymore. Please check for typos in the JSON')
end

-- called when a file is modified, deleted, etc
local function onFileChanged(filename, type)
  local scenario = scenarios and scenario_scenarios.getScenario()
  if not scenario then return end

  if scenario.sourceFile == 'game:' .. filename then
    reloadScenarioSourcefile()
  end
end

local function load(name)
  local list = getList()
  for _, v in ipairs(list) do
    if v.name == name then
      start(v)
    end
  end
end

  local function  customPreviewLoader( levelName)
    -- figure out the previews automatically and check for errors
  
  
    local directory = '/levels/'..levelName
    local previews = {}
  
    local tmp = FS:findFilesByRootPattern("/levels/"..levelName.."/",levelName..'_preview*.png', 0, true, false)
    for _, p in pairs(tmp) do
      table.insert(previews, p)
    end
    tmp = FS:findFilesByRootPattern("/levels/"..levelName.."/",levelName..'_preview*.jpg', 0, true, false)
    for _, p in pairs(tmp) do
      table.insert(previews, p)
    end
  
    -- if #previews == 0 then
    --   log('W', 'scenarios', 'scenario has no previews: ' .. tostring(scenarioData.scenarioName))
    -- end
    return previews
  end
  
  local function getLevels(subdirectory)
    local levelList = getLevelList()
    local levels = {}
    
    for _, levelName in ipairs(levelList) do
      local path = '/levels/' .. levelName .. '/scenarios/' .. subdirectory
      local busScenarios =  FS:findFilesByPattern(path, '*.json', -1, true, false)
  
      -- TODO: make this more generic. Perhaps think about how it can be applied to different "Job" types
      if (#busScenarios > 0) then
        local newLevel = {}
        newLevel.levelName = levelName
        newLevel.levelInfo = readJsonFile('game:/levels/'..levelName..'/info.json') -- this contains the level info for the UI!
        newLevel.official = isOfficialContent(FS:getFileRealPath('levels/'..levelName..'/info.json'))
        newLevel.previews = customPreviewLoader(levelName)

        newLevel.scenarios = {}

        -- hardcoded for now...
        local busLineFiles = FS:findFilesByPattern('/levels/'.. levelName .. '/buslines/', '*.buslines.json', -1, true, false)
        local routes = {}
        for _, file in pairs(busLineFiles) do
          local busLine = readJsonFile(file)
          for _, route in pairs(busLine.routes) do
            -- For now we assume there is only one bus scenario therefore
            -- we just use this as a 'template' for each route.
            local scenario = loadScenario(busScenarios[1])
            -- assign scenario name to route direction
            scenario.name = route.routeID .. ' ' .. route.direction
            -- check if starting position for the line exists
            if route.spawnLocation then 
              scenario.spawnLocation = route.spawnLocation
            end

            if route.previews then
              scenario.previews ="/levels/".. levelName .."/buslines/" .. route.previews[1]
            end

            if route.vehicle then
              scenario.userSelectedVehicle = route.vehicle
            end

            if route.tasklist then
              scenario.stopCount = 0;
              for _, task in pairs(route.tasklist) do
                scenario.stopCount = scenario.stopCount + 1
              end
            end

            scenario.busdriver.strictStop = true
            -- scenario.busdriver.simulatePassengers = true
            scenario.busdriver.routeID = route.routeID
            scenario.busdriver.variance = route.variance
            table.insert(newLevel.scenarios, scenario)
          end
        end
        table.insert(levels, newLevel)
      end
    end
  
    return levels
  end
  

-- public interface
M.getLevels                       = getLevels
M.getList                         = getList
M.loadScenario                    = loadScenario
M.processScenarioData             = processScenarioData
M.start                           = start
M.startByPath                     = startByPath
M.load                            = load
M.onFileChanged                   = onFileChanged
return M
