local M = {state={}}
local levels = nil

local logTag = 'levels'

local levelsDir = 'levels'

local inputActionFilter = require('input_action_filter')


-- finds all levels: this has a lot of backward compatibility code in there
function findAvailableLevels()
  local level_dirs = FS:findFilesByPattern('/levels/', '*', 0, false, true)
  table.sort(level_dirs, function(a,b) return string.lower(a) < string.lower(b) end )

  local res = {}

  for _, d in pairs(level_dirs) do
    -- check if its a valid folder really
    if FS:fileExists(d) or not FS:directoryExists(d) or d == "/levels/mod_info" then
      goto continue
    end
    local l = {}
    -- valid level?
    l.dir = d
    l.infoPath = d .. '/info.json'
    if not FS:fileExists(l.infoPath) then
      log('E', 'levels', 'info.json missing: ' .. l.infoPath)
    end

    -- figure out name
    l.levelName = d:match('levels/([^/]+)')

    -- figure out entry points (in order of priority)
    local newSceneTreeEntry = d .. '/main/'
    local oldMainFile = d .. '/main.level.json'
    if FS:directoryExists(newSceneTreeEntry) then
      l.fullfilename = newSceneTreeEntry
    elseif FS:fileExists(oldMainFile) then
      l.fullfilename = oldMainFile
    else
      -- look for any mission files in there and use the first
      local files = FS:findFilesByPattern(d, '*.mis', 1, true, false)
      if #files ~= 0 then
        l.fullfilename = files[1]
      else
        log('E', 'levels', 'No entry point for level found: ' .. d .. '. Ignoring level.')
        goto continue
      end
    end

    -- figure out the entry point value. We use that to find some other files (decals, images, etc)
    local dirname, filename, ext = path.split(l.fullfilename)
    filename = string.gsub(filename, "%.mis$", "")
    l.entryPoint = string.gsub(filename, "%.level.json$", "")

    l.dirEntry = l.dir .. '/' .. l.entryPoint

    table.insert(res, l)
    ::continue::
  end
  return res
end

local function getList()
  -- if levels then
  --   return levels
  -- else
  --   levels = {}
  -- end
  local levels = {}
  if not FS:directoryExists('/levels/') then
    log('E', 'levels', 'main levels folder not found: /levels/')
    return {}
  end

  -- find all levels
  local found_levels = findAvailableLevels()
  --dump(found_levels)

  for _, l in pairs(found_levels) do
    -- so, enrich the data of the levels for the user interface below
    local info = readJsonFile(l.infoPath) or {}
    info.misFilePath = l.dir ..'/'..l.entryPoint
    -- hidden?
    if info.hidden then goto continue end
    info.levelName = l.levelName
    info.fullfilename = l.fullfilename

    -- hwardware limitations
    if type(info.x86Compatible) == 'boolean' and info.x86Compatible == false and beamng_arch == 'x86' then
      info.disableReason = 'x86'
    end

    info["official"] = isOfficialContent(FS:getFileRealPath(l.dir))

    if type(info["previews"]) == 'table' and #info["previews"] > 0 then
      -- add prefix
      local newPreviews = {}
      for _, img in pairs(info["previews"]) do
        table.insert(newPreviews, l.dir..'/' .. img)
      end
      info["previews"] = newPreviews
    else
      info["title"] = l.levelName
      info["previews"] = {
        imageExistsDefault(l.dirEntry..'.png', imageExistsDefault(l.dirEntry..'_preview.png')),
      }
    end
    info["preview"] = nil

    if type(info.spawnPoints) == 'table' then
      for _, point in pairs(info.spawnPoints) do
        if not point.previews then point.previews = {} end

        -- add path prefix
        local newPreviews = {}
        for _, img in pairs(point.previews) do
          table.insert(newPreviews, l.dir..'/' .. img)
        end
        table.insert(newPreviews, imageExistsDefault(l.dir..'/'.. (point.preview or ''), l.dirEntry..'_preview.png'))
        point.previews = newPreviews
        point.preview = nil
      end
    else
      info.spawnPoints = {}
    end

    -- insert default spawn point
    table.insert(info.spawnPoints, {
      previews = info["previews"],
      name = 'ui.common.default',
      flag = 'default'
    })

    --dump(info)

    table.insert(levels, info)

    ::continue::
  end

  -- now filter out .mis levels if a json version of the same exists
  local jsonLevels = {}
  for _, level in pairs(levels) do
    if string.find(level.fullfilename, ".json") then
      jsonLevels[level.levelName] = true
    end
  end

  local newLevels = {}
  for _, level in pairs(levels) do
    -- check if there is a json version of this, thus hide the old .mis file format
    if string.find(level.fullfilename, ".mis") and jsonLevels[level.levelName] then
      --log('D', logTag, 'not adding .mis level as .json format is existing for the same level: ' .. dumps(level))
    else
      table.insert(newLevels, level)
    end
  end

  return newLevels
end

local function sendData()
  guihooks.trigger('InstalledContentUpdate', {context='levels', list=getList()})
end


local function onFileChanged(filename, type)
  if string.sub(filename, 1, string.len(levelsDir)) == levelsDir or string.find(filename, 'mods/') == 1 then
    sendData()
  end
end

local function startFreeroam(level, startPointName)
  log('D', logTag, 'startFreeroam called...')

  -- this is to prevent bug where freerom is started while a different level is still loaded.
  -- Loading the new freerom causes the current loaded freerom to unload which breaks the new freerom
  if scenetree.MissionGroup then
    log('D', logTag, 'Delaying start of freerom until current level is unloaded...')
    M.triggerDelayedStart = function()
      log('D', logTag, 'Triggering a delayed start of freerom...')
      M.triggerDelayedStart = nil
      M.startFreeroam(level, startPointName)
    end

    endActiveGameMode(M.triggerDelayedStart)
  else
    loadGameModeModules()
    M.state = {}
    M.state.freeromActive = true

    local levelPath = level
    if type(level) == 'table' then
      setSpawnpoint.setDefaultSP(startPointName, level.levelName)
      levelPath = level.misFilePath
    end

    inputActionFilter.clear(0)

    beamng_cef.startLevel(levelPath)
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

-- public interface
M.onFileChanged = onFileChanged
M.requestData = sendData
M.getList = getList
M.startFreeroam = startFreeroam
M.onClientPreStartMission = onClientPreStartMission
M.onClientStartMission = onClientStartMission
M.onClientEndMission = onClientEndMission
M.onVehicleSwitched = onVehicleSwitched

return M
