local M = {}

local defaultLayoutsFile = 'settings/uiapps-layouts-default.json'
local userLayoutsFile = 'settings/uiapps-layouts.json'
local currentVersion = 0.40
local appsDir = 'ui/modules/apps'


local function getList()
  local jsonFiles = FS:findFilesByRootPattern('game:/ui/modules/apps/', 'app.json', 1, false, false)
  local data = {}
  local appDirRegex = 'ui/modules/apps/([%w|_|%-|%s]+)/app.json'

  for _, path in ipairs(jsonFiles) do
    local appDir = string.match(path, appDirRegex)

    if appDir then
      local appData = readJsonFile(path)
      appData.official = isOfficialContent(FS:getFileRealPath(path))
      appData.previews = {
        imageExistsDefault('/ui/modules/apps/'..appDir..'/app.png'),
        fileExistsOrNil('/ui/modules/apps/'..appDir..'/app2.png'),
        fileExistsOrNil('/ui/modules/apps/'..appDir..'/app3.png'),
      }

      if not appData.types then
        appData.types = {'ui.apps.categories.unknown'}
      end

      if appData["domElement"] and appData["directive"] then
        appData["jsSource"] = '../../ui/modules/apps/'..appDir..'/app.js'
        table.insert(data, appData)
      else
        log('E', 'apps', 'invalid app data:' .. tostring(path) .. ': missing "domElement" or "directive" in app.json - IGNORING APP: ' .. dumps(appData))
      end
    else
      log('E', 'apps', 'unable to read app from dir:' .. tostring(path))
    end
  end
  return data
end

local function resetLayout (gamestate)
  if FS:fileExists(userLayoutsFile) and gamestate ~= nil then
    local default = readJsonFile(defaultLayoutsFile)
    local user = readJsonFile(userLayoutsFile)

    user[gamestate] = default[gamestate]
    local worked = serializeJsonToFile(userLayoutsFile, user, true)
    guihooks.trigger('appJsonDump', {write = worked})
    -- guihooks.trigger('appJsonDump', {user = user[gamestate], default = default[gamestate], gamestate = gamestate})
    return user[gamestate]
  end
  return nil
end

local function resetLayouts()
  if FS:fileExists(userLayoutsFile) then
    FS:removeFile(userLayoutsFile)
  end
  return readJsonFile(defaultLayoutsFile)
end

local function getSettings(appDir)
  return readJsonFile('game:/ui/modules/apps/'..appDir..'/settings.json') or nil
end

local function saveSettings(appDir, settings)
  local settingsFile = 'game:/ui/modules/apps/'..appDir..'/settings.json'
  print('saving to '..settingsFile)
  serializeJsonToFile(settingsFile, settings, true)
end

local function getLayouts()
  local userLayouts    = readJsonFile(userLayoutsFile)
  local defaultLayouts = readJsonFile(defaultLayoutsFile)

  if not userLayouts then
    return defaultLayouts
  else
    local userVersion = userLayouts.version or 0
    if currentVersion > userVersion then
      return defaultLayouts
    else
      return userLayouts
    end
  end
end

local function saveLayouts(layouts_data)
  layouts_data['version'] = currentVersion
  serializeJsonToFile(userLayoutsFile, layouts_data, true)
end

local function sendData()
  guihooks.trigger('InstalledContentUpdate', {context="apps", list=getList()})
end

-- Update apps list whenever there is a filesystem change in the apps directory.
-- This way, UI will stay informed about the apps' list without having to
-- explicitly request for it every time it is needed (an initial request is still needed).
local function onFileChanged(filename, type)
  if string.sub(filename, 1, string.len(appsDir)) == appsDir or string.find(filename, 'mods/') == 1 then
    sendData()
  end
end


-- === ui2 =============================================================================
local function getList2 ()
  local basePath = 'ui2/Apps/'
  local jsonFiles = FS:findFilesByRootPattern(basePath, 'info.json', 1, false, false)
  local appDirRegex = basePath .. '([%w|_|%-|%s]+)/info.json'
  local data = {}

  for _, path in ipairs(jsonFiles) do
    local folderName = string.match(path, appDirRegex) or ''
    local folderPath = basePath .. folderName
    data[folderName] = {}
    data[folderName].official = isOfficialContent(path)
    data[folderName].pngFiles = FS:findFilesByRootPattern(folderPath, 'app*.png', 1, false, false)
    data[folderName].cssFiles = FS:findFilesByRootPattern(folderPath, 'app*.css', 1, false, false)
    if FS:fileExists(folderPath .. '/data.json') then
      data[folderName].jsonFile = folderPath .. '/data.json'
    end
    if FS:fileExists(folderPath .. '/app.js') then
      data[folderName].jsFile = folderPath .. '/app.js'
    end
  end

  return data
end

local function sendList2 ()
  guihooks.trigger('AppList', getList2())
end

local AppAvailability = {}
local function getState2 ()
  AppAvailability.gamestate = core_gamestate.state
  AppAvailability.devMode = settings.getValue('devMode')
  -- TODO: figure out how to initialize cameraconfig
  -- TODO: add active player / vehicle?
  return AppAvailability
end

local function sendState2 ()
  guihooks.trigger('AppAvailability', getState2())
end

local function onCameraConfigChanged2 (mode)
  if AppAvailability.camera ~= mode.cameraConfig[mode.focusedCamId].name then
    AppAvailability.camera = mode.cameraConfig[mode.focusedCamId].name
    sendState2()
  end
end

local function onSettingsChanged2 ()
  if AppAvailability.devMode ~= settings.getValue('devMode') then
    sendState2()
  end
end

local function onGameStateUpdate (state)
  AppAvailability.gamestate = state
  sendState2()
end

-- 1 if nr1 > nr2
-- 0 if nr == nr2
-- -1 if nr1 < nr2
-- nil if both are nil
-- if one is nil, the other is considered higher
local function compareVersionNr (str1, str2)
  if str1 == nil or str2 == nil then
    if str1 ~= nil then
      return -1
    elseif str2 ~= nil then
      return 1
    end

    return nil
  end

  local ver1 = split(str1, '%.')
  local ver2 = split(str2, '%.')

  for k, v in pairs(ver1) do
    if tonumber(v) > tonumber(ver2[k]) then
      return 1
    elseif tonumber(v) < tonumber(ver2[k]) then
      return -1
    end
  end

  return 0
end

local function mergePresets (list1, list2)
  local res = list1
  for k, v in pairs(list2) do
    if res[k] == nil or (v.source == 'custom' and res[k].source == 'mod') or compareVersionNr(v.gameVersion, res[k].gameVersion) == 1 then
      res[k] = v
    end
  end

  return res
end

-- Idea: start with default
-- if mods merge them into if their version nr is higher than from default
-- if custom merge them in if they overwrite mods in any case and if they opverwrite default only if the version nr is higher than from game
-- TODO: listen to mounted mods and automatically update ui with new data
local function getPresets2 ()
  local presets = {mods = {}, custom = {}}
  local res = {}
  local files = FS:findFilesByRootPattern( 'settings/', 'app-layout*.json', 1, false, false)
  for _, v in pairs(files) do
    if v == 'settings/app-layout.json' then
      presets.custom = readJsonFile(v)
      for k in pairs(presets.custom) do
        presets.custom[k].source = 'custom'
      end
    elseif v == 'settings/app-layout-default.json' then
      res = readJsonFile(v)
      for k in pairs(res) do
        res[k].source = 'default'
      end
    else
      presets.mods[v] = readJsonFile(v)
      for k in pairs(presets.mods[v]) do
        presets.mods[v][k].source = 'mod'
      end
    end
  end

  for k, v in pairs(presets.mods) do
    res = mergePresets(res, v)
  end

  res = mergePresets(res, presets.custom)

  return res
end

local function sendPresets2 ()
  guihooks.trigger('appLayouts', getPresets2())
end

local function savePresets2 (presets)
  local current = getPresets2()
  -- TODO: think about initializing res with the current json files content
  -- pro: nothing gets removed if it was not changes
  -- con: the file might get more and more cluttered
  local res = {}

  for k, v in pairs(presets) do
    if v.source == 'custom' and compareVersionNr(v.gameVersion, current[k].gameVersion) ~= -1 then
      v.source = nil
      res[k] = v
    end
  end
  serializeJsonToFile('settings/app-layout.json', res, true)
  return res
end

M.getList2 = getList2
M.requestList2 = sendList2
M.getState2 = getState2
M.requestState2 = sendState2
M.onCameraConfigChanged = onCameraConfigChanged2
M.onSettingsChanged = onSettingsChanged2
M.onGameStateUpdate = onGameStateUpdate2
M.getPresets2 = getPresets2
M.requestPresets2 = sendPresets2
M.savePresets2 = savePresets2
-- === end ui2 ==========================================================================


M.requestData = sendData
M.onFileChanged = onFileChanged
M.getList = getList
M.getLayouts = getLayouts
M.saveLayouts = saveLayouts
M.getSettings = getSettings
M.saveSettings = saveSettings
M.resetLayouts = resetLayouts
M.resetLayout = resetLayout
return M
