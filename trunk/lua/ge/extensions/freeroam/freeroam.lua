local M = {state={}}

local logTag = 'freerom'

local inputActionFilter = require('input_action_filter')

local function startFreeroamHelper (level, startPointName)
  core_gamestate.requestEnterLoadingScreen(logTag .. '.startFreeroamHelper')
  loadGameModeModules()
  M.state = {}
  M.state.freeromActive = true

  local levelPath = level
  if type(level) == 'table' then
    setSpawnpoint.setDefaultSP(startPointName, level.levelName)
    levelPath = level.misFilePath
  end

  inputActionFilter.clear(0)

  core_levels.startLevel(levelPath, startPointName)
  core_gamestate.requestExitLoadingScreen(logTag .. '.startFreeroamHelper')
end

local function startFreeroam(level, startPointName)
  log('D', logTag, 'startFreeroam called...')
  core_gamestate.requestEnterLoadingScreen(logTag)

  -- this is to prevent bug where freerom is started while a different level is still loaded.
  -- Loading the new freerom causes the current loaded freerom to unload which breaks the new freerom
  if scenetree.MissionGroup then
    log('D', logTag, 'Delaying start of freerom until current level is unloaded...')
    M.triggerDelayedStart = function()
      log('D', logTag, 'Triggering a delayed start of freerom...')
      M.triggerDelayedStart = nil
      startFreeroam(level, startPointName)
    end

    endActiveGameMode(M.triggerDelayedStart)
  elseif not core_gamestate.getLoadingStatus(logTag .. '.startFreeroamHelper') then -- remove again at some point
    startFreeroamHelper(level, startPointName)
    core_gamestate.requestExitLoadingScreen(logTag)
  end
end

local function onClientPreStartMission(mission)
  local path, file, ext = path.split2(mission)
  file = path .. 'mainLevel'
  if not FS:fileExists(file..'.lua') then return end
  extensions.load({{extName = file, globalAlias = 'mainLevel'}})
  if mainLevel and mainLevel.onClientPreStartMission then
    mainLevel.onClientPreStartMission(mission)
  end
end

local function onClientStartMission(mission)
  local path, file, ext = path.split2(mission)
  file = path .. 'mainLevel'

  if M.state.freeromActive then
    extensions.hook('onFreeroamLoaded', mission)

    local ExplorationCheckpoints = scenetree.findObject("ExplorationCheckpointsActionMap")
    if ExplorationCheckpoints then
      ExplorationCheckpoints:push()
    end
  end
end

local function onClientEndMission(mission)
  if M.state.freeromActive then
    M.state.freeromActive = false
    local ExplorationCheckpoints = scenetree.findObject("ExplorationCheckpointsActionMap")
    if ExplorationCheckpoints then
      ExplorationCheckpoints:pop()
    end
  end

  if not mainLevel then return end
  local path, file, ext = path.split2(mission)
  extensions.unload(path .. 'mainLevel')
end



-- Resets previous vehicle alpha when switching between different vehicles
-- Used to fix multipart highlighting when switching vehicles
local function onVehicleSwitched(oldId, newId, player)
  if oldId then
    local veh = be:getObjectByID(oldId)
    if veh then
      veh:queueLuaCommand('partmgmt.selectReset()')
    end
  end
end

local function onResetGameplay(playerID)
  local scenario = scenario_scenarios and scenario_scenarios.getScenario()
  local campaign = campaign_campaigns and campaign_campaigns.getCampaign()
  if not scenario and not campaign then
    be:resetVehicle(playerID)
  end
end

local function startTrackBuilder(level)
  local callback = function () 
    log('I', logTag, 'startTrackBuilder callback triggered...')
    editor.showTrackBuilder() 
  end

  extensions.setCompletedCallback("onClientStartMission", callback);
  startFreeroam(level)
end

-- public interface
M.startFreeroam           = startFreeroam
M.onClientPreStartMission = onClientPreStartMission
M.onClientStartMission    = onClientStartMission
M.onClientEndMission      = onClientEndMission
M.onVehicleSwitched       = onVehicleSwitched
M.onResetGameplay         = onResetGameplay
M.startTrackBuilder       = startTrackBuilder

return M
