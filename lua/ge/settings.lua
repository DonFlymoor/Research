-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local persistencyfile = 'settings/game-settings.ini'
local persistencyfileCloud = 'settings/cloud/game-settings-cloud.ini'

local M = {}
local options = {
  uiUnitLength = {modes={keys={'metric','imperial'}, values={'ui.unit.metric', 'ui.unit.imperial'}}},
  uiUnitTemperature = {modes={keys={'c', 'f', 'k'}, values={'ui.unit.c', 'ui.unit.f', 'ui.unit.k'}}},
  uiUnitWeight = {modes={keys={'lb', 'kg'}, values={'ui.unit.lb', 'ui.unit.kg'}}},
  uiUnitConsumptionRate = {modes={keys={'metric', 'imperial'}, values={'ui.unit.ltr100', 'ui.unit.mpg'}}},
  uiUnitTorque = {modes={keys={'metric', 'imperial'}, values={'ui.unit.nm', 'ui.unit.lbft'}}},
  uiUnitEnergy = {modes={keys={'metric', 'imperial'}, values={'ui.unit.j', 'ui.unit.ftlb'}}},
  uiUnitDate = {modes={keys={'ger', 'uk', 'us'}, values={'DD.MM.YYYY', 'DD/MM/YYYY', 'MM/DD/YYYY'}}},
  uiUnitPower = {modes={keys={'hp', 'bhp', 'kw'}, values={'ui.unit.hp', 'ui.unit.bhp', 'ui.unit.kw'}}},
  uiUnitVolume = {modes={keys={'l', 'gal'}, values={'ui.unit.l', 'ui.unit.gal'}}},
  uiUnitPressure = {modes={keys={'inHg', 'bar', 'psi', 'kPa'}, values={'ui.unit.inHg', 'ui.unit.bar', 'ui.unit.psi', 'ui.unit.kPa'}}},

  uiUpscaling = {modes={keys={'disabled', '720', '1080'}, values={'Disabled', '1280 x 720', '1920 x 1080'}}},
  onlineFeatures = {modes={keys={'enable', 'disable'}, values={'ui.common.enable', 'ui.common.disable'}}},
  defaultGearboxBehavior = {modes={keys={'arcade', 'realistic'}, values={'ui.common.arcade', 'ui.common.realistic'}}},
  absBehavior = {modes={keys={'arcade', 'realistic', 'off'}, values={'ui.common.arcade', 'ui.common.realistic', 'ui.common.off'}}},
  escBehavior = {modes={keys={'arcade', 'realistic', 'off'}, values={'ui.common.arcade', 'ui.common.realistic', 'ui.common.off'}}},
  communityTranslations = {modes={keys={'enable', 'disable'}, values={'ui.common.enable', 'ui.common.disable'}}},
}
local disk = 1
local cloud = 2
local discard = 3
local deprecated = discard
local settingsList = {       -- { storage, default_value }
  languageOS                  = { discard, nil },
  languageOSLong              = { discard, nil },
  languageProvider            = { discard, nil },
  languageProviderLong        = { discard, nil },
  communityLanguages          = { deprecated, nil },
  userLanguageSelected        = { discard, nil },
  userLanguageSelectedLong    = { discard, nil },
  userLanguagesAvailable      = { discard, nil },
  userColorPresets            = { cloud, nil },
  uiLanguage                  = { discard, nil },
  uiUnits                     = { cloud  , nil },
  uiUnitLength                = { cloud  , 'imperial' },
  uiUnitDistance              = { deprecated, nil },
  uiUnitTemperature           = { cloud  , 'f' },
  uiUnitWeight                = { cloud  , 'lb' },
  uiUnitConsumptionRate       = { cloud  , 'imperial' },
  uiUnitTorque                = { cloud  , 'imperial' },
  uiUnitEnergy                = { cloud  , 'imperial' },
  uiUnitDate                  = { cloud  , 'us' },
  uiUnitPower                 = { cloud  , 'bhp' },
  uiUnitVolume                = { cloud  , 'gal' },
  uiUnitPressure              = { cloud  , 'psi' },
  onlineFeatures              = { cloud  , 'enable' },
  modAutoUpdates              = { disk   , false },
  communityTranslations       = { cloud  , 'disable' },
  disableDynamicCollision     = { disk   , false },
  GraphicFullscreen           = { disk   , true },
  devMode                     = { cloud  , false },
  creatorMode                 = { cloud  , false },
  externalUi                  = { cloud  , false },
  showPcs                     = { cloud  , false },
  multiseat                   = { discard, false }, -- intentionally use multiseat only until game is closed
  multiseatTags               = { cloud  ,  true },
  traffic                     = { discard, false }, -- intentionally use traffic only until game is closed
  rpmLedsEnabled              = { disk   , false },
  unfocusedInput              = { cloud  , false },
  -- key (grip)
  filter0_limitEnabled        = { disk   , false },
  filter0_limitStartSpeed     = { disk   ,    14 },
  filter0_limitEndSpeed       = { disk   ,    70 },
  filter0_limitMultiplier     = { disk   ,   0.3 },
  -- pad
  filter1_limitEnabled        = { disk   , false },
  filter1_limitStartSpeed     = { disk   ,    14 },
  filter1_limitEndSpeed       = { disk   ,    70 },
  filter1_limitMultiplier     = { disk   ,   0.5 },
  -- direct
  filter2_limitEnabled        = { disk   , false },
  filter2_limitStartSpeed     = { disk   ,     0 },
  filter2_limitEndSpeed       = { disk   ,   100 },
  filter2_limitMultiplier     = { disk   ,   0.8 },
  -- key (drift)
  filter3_limitEnabled        = { disk   , false },
  filter3_limitStartSpeed     = { disk   ,    20 },
  filter3_limitEndSpeed       = { disk   ,    80 },
  filter3_limitMultiplier     = { disk   ,   0.8 },
  userLanguage                = { cloud  , '' }, -- empty = no user language set, using steam or OS language then
  cameraOrbitRelaxation       = { cloud  , 3 },
  cameraOrbitMaxDynamicFov    = { cloud  , 35 },
  cameraOrbitSmoothing        = { cloud  , true },
  cameraFOVTune               = { cloud  , 0 },
  cameraPosTuneX              = { cloud  , 0 },
  cameraPosTuneY              = { cloud  , 0 },
  cameraPosTuneZ              = { cloud  , 0 },
  cameraFanVsTV               = { cloud  , 0.1 },
  cameraTVSpeed               = { cloud  , 1 },
  cameraTransitionTime        = { cloud  , 300 },
  disableSteeringwheel        = { cloud  , false },
  interpolatePosition         = { cloud  , true },
  interpolateAlternative      = { cloud  , false },
  interpolateFull             = { cloud  , false },
  interpolateLua              = { cloud  , false },
  replayLevel                 = { cloud  , -1 },
  replayAlpha                 = { disk   , true },
  interpolateCenter           = { deprecated, nil },
  interpolateCircles          = { deprecated, nil },
  interpolateNodes            = { deprecated, nil },
  restrictScenarios           = { cloud  , true },
  autoSaveInGarage            = { cloud  , false },
  cameraChaseRollSmoothing    = { cloud  , 1 },
  uiUpscaling                 = { disk   , '1080' },
  WindowPlacement             = { disk   , '' },
  outgaugeEnabled             = { cloud  , false },
  outgaugeIP                  = { cloud  , '127.0.0.1' },
  outgaugePort                = { cloud  , 4444 },
  startThermalsPreHeated      = { cloud  , true },
  startBrakeThermalsPreHeated = { cloud  , true },
  defaultGearboxBehavior      = { cloud  , 'arcade' },
  absBehavior                 = { cloud  , 'realistic' },
  escBehavior                 = { cloud  , 'realistic' },
  autoClutch                  = { cloud  , true },
  autoThrottle                = { cloud  , true },
  gearboxSafety               = { cloud  , true },
  useFmodLiveUpdate           = { cloud  , false },
  defaultShifterMode          = { deprecated, nil },
  gameplayDefaultShifterMode  = { deprecated, nil },
  autoShiftPrevention         = { deprecated, nil },
  cameraConfig                = { cloud  , nil },
  cameraOrder                 = { deprecated, nil },
  defaultCameraMode           = { deprecated, nil },
  cameraLoadCustomModes       = { deprecated, nil },
  PostFXHDRGeneralEnabled     = { disk   , nil },
  GraphicGPU                  = { disk   , nil },
  GraphicSyncFullscreen       = { deprecated, nil },
  vsync                       = { disk   , 0 },
  GraphicResolutions          = { disk   , nil },
  GraphicGrassDensity         = { disk   , nil },
  AudioMasterVol              = { disk   , nil },
  AudioMusicVol               = { deprecated, nil },
  AudioMaxChannels            = { disk   , nil },
  AudioEffectsVol             = { disk   , nil },
  GraphicAntialias            = { disk   , nil },
  GraphicDynReflectionTexsize = { disk   , nil },
  FPSLimiter                  = { disk   , 60 },
  FPSLimiterEnabled           = { disk   , false },
  PostFXLightRaysEnabled      = { disk   , nil },
  GraphicDynReflectionDetail  = { disk   , nil },
  GraphicBorderless           = { disk   , nil },
  GraphicRefreshRate          = { disk   , nil },
  GraphicShaderQuality        = { disk   , nil },
  GraphicDisplayDriver        = { disk   , nil },
  GraphicAnisotropic          = { disk   , nil },
  MainMenuBackgroundMode      = { disk   , nil },
  GraphicDynReflectionFacesPerupdate={disk,nil },
  GraphicAntialiasType        = { disk   , nil },
  AudioInterfaceVol           = { disk   , nil },
  GraphicGamma                = { disk   , nil },
  GraphicDynReflectionEnabled = { disk   , nil },
  GraphicOverallQuality       = { disk   , nil },
  PostFXDOFGeneralEnabled     = { disk   , nil },
  GraphicMeshQuality          = { disk   , nil },
  AudioDevice                 = { disk   , nil },
  GraphicLightingQuality      = { disk   , nil },
  GraphicTextureQuality       = { disk   , nil },
  GraphicDynReflectionDistance= { disk   , nil },
  GraphicPostfxQuality        = { disk   , nil },
  GraphicDisableShadows       = { disk   , nil },
  AudioAmbienceVol            = { disk   , nil },
  PostFXSSAOGeneralEnabled    = { disk   , nil },
  AudioProvider               = { disk   , nil },
  OnlineHiddenMessageIDs      = { disk   , nil },
  PerformanceWarningsmissing64binary       = { disk, nil },
  PerformanceWarningstoolessmemoryfor64bit = { disk, nil },
  PerformanceWarningsthirdpartysoftware    = { disk, nil },
  PerformanceWarningslowmem                = { disk, nil },
  PerformanceWarningsminmem                = { disk, nil },
  PerformanceWarningsmemused               = { disk, nil },
  PerformanceWarningsfreememlow            = { disk, nil },
  PerformanceWarningsminmem                = { disk, nil },
  PerformanceWarningscpuonecore            = { disk, nil },
  PerformanceWarningscpuquadcore           = { disk, nil },
  PerformanceWarningscpulowclock           = { disk, nil },
  PerformanceWarningscpu64bits             = { disk, nil },
  PerformanceWarningsremotedesktop         = { disk, nil },
  PerformanceWarningsintelgpu              = { disk, nil },
  PerformanceWarningsgeforcemin            = { disk, nil },
  PerformanceWarningsamdhd                 = { disk, nil },
  PerformanceWarningsamdradeon             = { disk, nil },
  PerformanceWarningsgpulowmem             = { disk, nil },
  PerformanceWarningsgpurecmem             = { disk, nil },
  PerformanceWarningsos32bits              = { disk, nil },
  PerformanceWarningsoldwin7               = { disk, nil },
  PerformanceWarningsxinput                = { disk, nil },
  PerformanceWarningsdinput                = { disk, nil },
  PerformanceWarningsoswin8                = { disk, nil },
  PerformanceWarningsapp32                 = { disk, nil },
  PerformanceWarningspowerdisconnected     = { disk, nil },
  PerformanceWarningsbatterylow            = { disk, nil },
  PerformanceWarningsbatterycritical       = { disk, nil },
  PerformanceWarningswin8rec               = { disk, nil },
}

local defaultValues = { }
for k,v in pairs(settingsList) do
  defaultValues[k] = v[2]
end

local values = deepcopy(defaultValues)
local lastSavedTime = 0

local function sendUIState()
  --log("D", "settings.sendUIState", dumps(values))
  guihooks.trigger('SettingsChanged', {values = values, options = options})
end

local function save()
  --log("D", "settings", "Saving options to disk")
  lastSavedTime = os.clock()

  -- save options
  -- log("D", "settings.save", dumps(values))
  local localValues = {}
  local cloudValues = {}
  for k, v in pairs(values) do
    if     (settingsList[k] or {})[1] == disk    then
      localValues[k] = values[k]
    elseif (settingsList[k] or {})[1] == cloud   then
      cloudValues[k] = values[k]
    elseif (settingsList[k] or {})[1] == discard then
      -- nop - don't save anywhere
    else
      if not shipping_build then
        log("W", "", "Setting "..dumps(k).." = "..dumps(values[k]).." with unknown type "..dumps((settingsList[k] or {})[1])..", defaulting to cloud storage")
      end
      cloudValues[k] = values[k]
    end
  end
  -- log("D", "settings.save_local", dumps(localValues))
  -- log("D", "settings.save_cloud", dumps(cloudValues))
  saveIni(persistencyfile, localValues)
  saveIni(persistencyfileCloud, cloudValues)

  TorqueScript.eval( 'saveGlobalOptions();' );
  -- let UI and Lua know
  sendUIState()
  extensions.hook('onSettingsChanged')
  be:queueAllObjectLua('onSettingsChanged()')
end

local function refreshTSState(withValue)
  --log("D", "settings", "RefreshTSState get()s withValue "..dumps(withValue)..", where vol = "..dumps(values.AudioMasterVol))
  for k,o in pairs(options) do
    if withValue and type(o.get) == 'function' then
      values[k] = o.get()
    end
    if type(o.getModes) == 'function' then
      o.modes = o.getModes()
    end
  end
end

local function refreshLanguages()
  -- 0) ask c++ what language is active right now, so we can see if it changed later
  local oldLanguage = Lua:getSelectedLanguage()

  -- no community translations > en-US only
  if values.communityTranslations ~= 'enable' then
    -- en-US only
    values.userLanguage = ''
  end

  local languageMap = require('languageMap') -- load locally, so we don't have it hanging around in memory all the time

  -- 1) set new language
  Lua.userLanguage = values.userLanguage
  -- 2) ask C++ for the correct language
  Lua:reloadLanguages()
  -- 3) get the language that c++ chose
  values.userLanguageSelected = Lua:getSelectedLanguage()
  values.userLanguageSelectedLong = languageMap.resolve(values.userLanguageSelected)
  -- ui language is the same
  values.uiLanguage = values.userLanguageSelected
  --print(' * userLanguageSelected: ' .. tostring(values.userLanguageSelected) .. ' [' .. tostring(values.userLanguageSelectedLong) .. ']')

  -- info things for the UI, not used in the decision process
  -- list available languages
  options.userLanguagesAvailable = {}
  table.insert(options.userLanguagesAvailable, {key="", name="Automatic"}) -- the empty ('') language will be auto - it'll use the OS/steam lang
  local locales = FS:findFilesByRootPattern('game:/locales/', '*.json', -1, true, false)
  for _, l in pairs(locales) do
    local key = string.match(l, 'locales/([^\\.]+).json')

    table.insert(options.userLanguagesAvailable, {key=key, name = languageMap.resolve(key)})
  end
  --print(' * languagesAvailable: ' .. dumps(options.userLanguagesAvailable))

  -- detailed info, only for the user
  values.languageOS = Lua:getOSLanguage()
  values.languageOSLong = languageMap.resolve(values.languageOS)
  --print(' * languageOS: ' .. tostring(values.languageOS) .. ' [' .. tostring(values.languageOSLong) .. ']')
  values.languageProvider = Lua:getSteamLanguage()
  values.languageProviderLong = Steam and Steam.language or ""
  --print(' * languageProvider: ' .. tostring(values.languageProvider) .. ' [' .. tostring(values.languageProviderLong) .. ']')

  -- was the language changed?
  local languageChanged = Lua:getSelectedLanguage() ~= oldLanguage
  if values.userLanguage ~= Lua:getSelectedLanguage() then
    -- the system chose another one, set back to automatic
    languageChanged = true
    values.userLanguage = ''
  end
  --print(' - languageChanged >> ' .. tostring(languageChanged) .. ' | "' .. tostring(Lua:getSelectedLanguage()) .. '" ~= ' .. tostring(oldLanguage))

  -- send the new state to the UI
  if languageChanged or M.newTranslationsAvailable then
    sendUIState()
  end
end

local function setState(newState, ignoreCache)
  if newState == nil then return end
  local isChanged = false
  for k, s in pairs(newState) do
    if values[k] == nil or (tostring(s) ~= tostring(values[k]))  then
      isChanged = true
      values[k] = s
      if options[k] and type(options[k].set) == 'function' then
        options[k].set(s)
      end
    end
  end

  if not isChanged and not ignoreCache then return end

  -- get valid state from TS
  refreshTSState(true)
  save()

  -- we can update the dynamic collision state on the fly
  if values.disableDynamicCollision ~= nil then
    be:setDynamicCollisionEnabled(not values.disableDynamicCollision)
  end

  if values.unfocusedInput         ~= nil then WinInput.setUnfocusedInput (values.unfocusedInput)        end
  if values.multiseatTags          ~= nil then be.multiseatTags          = values.multiseat and values.multiseatTags end

  if values.replayLevel            ~= nil then be.replayLevel            = values.replayLevel            end
  if values.replayAlpha            ~= nil then be.replayAlpha            = values.replayAlpha            end

  if values.interpolatePosition    ~= nil then be.interpolatePosition    = values.interpolatePosition    end
  if values.interpolateAlternative ~= nil then be.interpolateAlternative = values.interpolateAlternative end
  if values.interpolateFull        ~= nil then be.interpolateFull        = values.interpolateFull        end
  if values.interpolateLua         ~= nil then be.interpolateLua         = values.interpolateLua         end

  refreshLanguages()
end

local function setValue(key, value, ignoreCache, cloud)
  local newValues = deepcopy(values)
  if type(cloud) == 'boolean' then
    if settingsList[k] then
      settingsList[k][1] = cloud
    else
      settingsList[k] = { cloud }
    end
  end
  newValues[key] = value
  setState(newValues, ignoreCache)
end

local function getValue(key, defaultValue)
  if values[key] == nil then
    return defaultValue
  end
  return values[key]
end

local function loadSettingValues()
  local data = loadIni(persistencyfile) or {}
  local cloudData = loadIni(persistencyfileCloud) or {}
  -- log("D", "settings.loadSettingValues_local", dumps(data))
  -- log("D", "settings.loadSettingValues_cloud", dumps(cloudData))
  tableMerge(data, cloudData)

  return data
end

local function load(ignoreCache)
  -- fix the options up and compbine the keys and values into the dict
  for k,v in pairs(options) do
    if v.keys and v.values and not v.dict then
      v.dict = {}
      for i = 0, #v.keys, 1 do
        v.dict[v.keys[i]] = v.values[i]
      end
    end
  end

  local settings_graphic = require('settings_graphic')
  local settings_audio = require('settings_audio')
  local settings_gameplay = require('settings_gameplay')
  tableMerge(options, settings_graphic.buildOptionHelpers())
  tableMerge(options, settings_audio.buildOptionHelpers())
  tableMerge(options, settings_gameplay.buildOptionHelpers())

  -- ensure translation.zip is mounted before reloading the languages
  local translationsFilename = 'mods/translations.zip'
  if FS:fileExists(translationsFilename) and not FS:isMounted(translationsFilename) then
    FS:mount(translationsFilename)
  end

  refreshTSState(true)
  local newState = deepcopy(values)
  local data = loadSettingValues()
  if data then
    tableMerge(newState, defaultValues)
    tableMerge(newState, data)
  end

  --refreshTSState(true)
  -- log("D", "settings.load", dumps(newState))
  setState(newState, ignoreCache)
  --dump(data)
end

local function reload()
  refreshTSState(true)
  save()
end

local function init()
  -- load the persistency file at least
  local data = loadSettingValues()
  if data then
    tableMerge(values, data)
  end

  require('settings_graphic').onInit(data)
end

local function onFirstUpdate()
  -- force application of all settings the first time, since init() has not correctly applied all of them
  -- we could make init() call load(), but that would fail because it's still too early, and some stuff is not initialized yet
  load(true)
  require('settings_graphic').onFirstUpdate(data)
  require('settings_audio').onFirstUpdate()
end

local function onFileChanged(filename, type)
  if filename == persistencyfile and (os.clock()-lastSavedTime) > 5 then
    load(false)
  end
end

local function getValues()
  return deepcopy(values)
end

M.onFirstUpdate = onFirstUpdate
M.onFileChanged = onFileChanged
M.requestState = sendUIState
M.setState = setState
M.setValue = setValue
M.getValue = getValue
M.getValues = getValues
M.reload = reload
M.save = save
M.load = load
M.init = init

return M
