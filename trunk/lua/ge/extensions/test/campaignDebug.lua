-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'campaignDebug'
local ffi = require('ffi')
local im = ui_imgui

local inputTextBuf = im.ArrayChar(8)
local appLayoutWindowOpen = im.BoolPtr(true)
local models = ""
local modelTable = {}
local selectedModel = im.IntPtr(0)

local configs = ""
local configTable = {}
local selectedConfig = im.IntPtr(0)

local locations = {}
local missions = ""
local missionsTable = {}
local selectedMission = im.IntPtr(0)

local money = im.FloatPtr(0.0)

local function resetMission(location)
  log('I', logTag,'resetMission called')

  local subsection = campaign_campaigns.getOwningSubsection(location.key)
  local currentCampaign = campaign_campaigns.getCampaign()
  -- Resetting mission state
  local locationStatus = currentCampaign.state.locationStatus[subsection.key..'.'..location.key]
  locationStatus.state = "ready"
  locationStatus.medal = ""

  for k,v in pairs(subsection.locations) do
    if v.requires then
      for _,reqData in ipairs(v.requires) do
        for _,name in ipairs(reqData.data or {}) do
          if name == location.key then
            locationStatus = currentCampaign.state.locationStatus[subsection.key..'.'..k]
            locationStatus.state = "ready"
            locationStatus.medal = ""
            goto continue
          end
        end
      end
    end
    ::continue::
  end

  -- Refreshing mission marker
  campaign_exploration.refreshLocationMarkers(subsection)
end

-- Alphabetically sort table
-- https://www.lua.org/pil/19.3.html
local function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

local function init()
  -- Models
  local modelList = core_vehicles.getModelList().models
  local modelString = ""
  for k,v in pairsByKeys(modelList) do
    -- We need to create a string of all the elements so that Combo2 works correctly
    modelString = modelString .. k .. "\0"
    table.insert(modelTable, k)
  end
  models = modelString

  if campaign_campaigns then
    local currentCampaign = campaign_campaigns.getCampaign()
    local currentSubsection = currentCampaign.state.activeSubsection
    locations = currentCampaign.meta.subsections[currentSubsection].locations
    local missionString = ""
    for k,v in pairsByKeys(locations) do
      missionString = missionString .. k .."\0"
      v.key = k
      table.insert(missionsTable, k)
    end
    missions = missionString
  end
end

local function onExtensionLoaded()
  init()
end

 local function completeScenario(state, medal)
  -- log('I', logTag,'completeScenario caled....state = '..tostring(state)..'  medal = '..tostring(medal))

  local scenario = scenario_scenarios.getScenario()
  if state == 'success' then

    statistics_statistics.stopStatsGathering_orginal = statistics_statistics.stopStatsGathering

    local scenario = scenario_scenarios and scenario_scenarios.getScenario()
    if scenario then
      extensions.unload(scenario.directory.."/"..scenario.scenarioName)
    end

    extensions.unload('scenario_raceGoals')

    statistics_statistics.stopStatsGathering = function(scenario)
      statistics_statistics.DEBUG_generateScoreForMedal(medal)

      statistics_statistics.stopStatsGathering = statistics_statistics.stopStatsGathering_orginal
      statistics_statistics.stopStatsGathering_orginal = nil
      extensions.load('scenario_raceGoals')
    end

    scenario_scenarios.finish({msg = scenario.passedMessage})
  else
    scenario_scenarios.finish({failed = scenario.failedMessage})
  end
end

local function onUpdate(dt, dtSim)
  im.Begin("Campaign Debug", appLayoutWindowOpen, im.WindowFlags_MenuBar)

    im.BeginColumns("GroundModelColumnsBegin", 2, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 120)

    -- Money
    im.Text("Money")
    im.NextColumn()
    im.PushItemWidth(100)
    im.InputFloat("", money)
    im.SameLine()
    if im.Button("Add") then
      core_inventory.addItem("$$$_MONEY", money[0])
    end
    im.SameLine()
    if im.Button("Subtract") then
      core_inventory.removeItem("$$$_MONEY", money[0])
    end

    -- Teleportation
    im.NextColumn()
    im.Text("Teleportation")
    im.NextColumn()
    if im.Button('Enable') then
      require('input_action_filter').clear(0)
    end

    -- End Mission
    im.NextColumn()
    im.Text("End Mission")
    im.NextColumn()
    if im.Button('Fail') then
      completeScenario('fail')
    end
    im.SameLine()
    if im.Button('Bronze') then
      completeScenario('success', 'bronze')
    end
    im.SameLine()
    if im.Button('Silver') then
      completeScenario('success', 'silver')
    end
    im.SameLine()
    if im.Button('Gold') then
      completeScenario('success', 'gold')
    end

    -- Vehicle
    im.NextColumn()
    im.Text("Vehicle")
    im.NextColumn()
    im.PushItemWidth(100)
    -- Combo2 uses a string seperated with 0's for the list ("AAA\0BBB\0CCC")
    if im.Combo2("Model", selectedModel, models) then
      local configList = core_vehicles.getConfigList().configs
      local configString = ""
      configTable = {}
      for k,v in pairsByKeys(configList) do
        if v.model_key == modelTable[selectedModel[0]+1] then
          dump(v)
          configString = configString .. v.key .. "\0"
          table.insert(configTable, v.key)
        end
      end
      configs = configString
    end
    im.Combo2("Config", selectedConfig, configs)
    if im.Button('Spawn') then
      core_vehicles.replaceVehicle(modelTable[selectedModel[0]+1], {config = configTable[selectedConfig[0]+1]})
    end
    im.SameLine()
    if im.Button('Add to Garage') then
      -- core_vehicles.replaceVehicle(modelTable[selectedModel[0]+1], {config = configTable[selectedConfig[0]+1]})
      core_inventory.addItem("$$$_VEHICLES", {model=modelTable[selectedModel[0]+1], config = configTable[selectedConfig[0]+1], color='1 1 1 1'})
    end
    im.SameLine()
    if im.Button('Add to Dealer') then
      campaign_dealer.addToStock("$$$_VEHICLES", {model=modelTable[selectedModel[0]+1], config = configTable[selectedConfig[0]+1], color='1 1 1 1'})
    end

    -- Reset Mission
    im.NextColumn()
    im.Text("Reset Mission")
    im.NextColumn()
    im.PushItemWidth(200)
    im.Combo2("Mission", selectedMission, missions)
    if im.Button('Reset') then
      resetMission(locations[missionsTable[selectedMission[0]+1]])
    end

    im.EndColumns()
  im.End()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

return M