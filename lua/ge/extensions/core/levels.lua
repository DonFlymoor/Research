local M = {state={}}
local levels = nil

local logTag = 'levels'

local levelsDir = 'levels'

local cacheInvalid = true

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

local function getList(allLevels)
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
    local info = jsonReadFile(l.infoPath) or {}
    
    -- hidden?
    if not allLevels and info.hidden then goto continue end

    info.misFilePath = l.dir ..'/'..l.entryPoint
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
  guihooks.trigger('InstalledContentUpdate', {context='allLevels', list=getList(true)})
end

local function isFileRelatedToLevel(filepath)
  if string.find(filepath, 'levels/') == nil then return false end
  return string.find(filepath, '.json') or string.find(filepath, '.mis') and true or false
end

local function onFileChanged(filename, type)
  if string.sub(filename, 1, string.len(levelsDir)) == levelsDir or (string.find(filename, 'mods/') == 1 and isFileRelatedToLevel(filename) )then
    cacheInvalid = true
  end
end

local function onFileChangedEnd()
  if cacheInvalid then
    sendData()
    cacheInvalid = false
  end
end

local function expandMissionFileName(missionFileName)
  if FS:directoryExists(missionFileName) then
    return missionFileName
  end
  local mfn = String(missionFileName):c_str()
  local missionFile = FS:expandFilename(missionFileName)

  if  FS:fileExists(missionFile) then
    return missionFile
  end
  --If the mission file doesn't exist... try to fix up the string.
  local newMission = missionFile
  --Support for old .mis files
  if string.find(missionFile, ".mis$") then
    newMission = string.gsub(missionFile, ".mis$", ".level.json")

    if FS:fileExists(newMission) then
      return newMission
    end
  end

  --try the new filename
  if not string.find(missionFile, ".level.json$") then
    newMission = missionFile..".level.json"

    if FS:fileExists(newMission) then
      return newMission
    end
  end

  if FS:fileExists(missionFile..'.mis') then
    return missionFile..'.mis'
  end
end

local function startLevelActual(missionFileName)
  if scenetree.serverGroup then
    return
  end

  -- check if new format
  if missionFileName:find('.level.json') and not FS:fileExists(missionFileName) then
    local newName = missionFileName:sub(0, missionFileName:find('.level.json') - 1)
    if FS:directoryExists(newName) then
      log('D', 'startLevel', 'converting level argument to new format: ' .. tostring(missionFileName) .. ' > ' .. tostring(newName))
      missionFileName = newName
    end
  end

  local missionFile = expandMissionFileName(missionFileName)
  if not missionFile or missionFile == "" then
    log('E', logTag, 'expanded mission file is invalid - '..dumps(missionFile))
    return false
  end

  server.createGame(missionFile)
  core_gamestate.requestExitLoadingScreen(logTag)
end

local function startLevelWrapper (missionFile)
  -- restirct from calling again until done
  if core_gamestate.getLoadingStatus(logTag) then return end

  core_gamestate.requestEnterLoadingScreen(logTag)
  local function help ()
    return startLevelActual(missionFile)
  end
  if scenetree.serverGroup then
    return serverConnection.disconnect(help)
  else
    return help()
  end
end

-- public interface
M.onFileChanged         = onFileChanged
M.onFileChangedEnd      = onFileChangedEnd
M.requestData           = sendData
M.getList               = getList
M.startLevel            = startLevelWrapper
M.expandMissionFileName = expandMissionFileName
return M
