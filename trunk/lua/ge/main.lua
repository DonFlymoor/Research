-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--- you can use this to turn of Just In Time compilation for debugging purposes:
--jit.off()
vmType = 'game'

package.path = 'lua/ge/?.lua;lua/gui/?.lua;lua/common/?.lua;lua/common/socket/?.lua;lua/?.lua;?.lua'
package.cpath = ''

require('compatibility')
if FS:fileExists('lua/ge/replayInterpolation.lua') then require('replayInterpolation') end

log = function(...) Lua:log(...) end
print = function(...)
  local args = { n = select("#", ...), ... }
  local s_args = {}
  for i = 1, args.n do
    table.insert(s_args, tostring(args[i]))
  end
  Lua:log('A', "print", table.concat(s_args, ', '))
  -- if you want to find out, where the print was used:
  -- Lua:log('A', "print", debug.traceback())
end

require("utils")

require("ge_utils")
json = require("json")
map = require("map")
actions = require("input_actions")
bindings = require("input_bindings")
guihooks = require("guihooks")
screenshot = require("screenshot")
virtualinput = require("virtualinput")
bullettime = require("bullettime")
local deprecatedExtensions = require("deprecatedExtensions")
extensions = require("extensions")
extensions.setDeprecatedExtensions(deprecatedExtensions)
extensions.addModulePath("lua/ge/extensions/")
extensions.addModulePath("lua/common/extensions/")
settings = require("settings")
perf = require("perf")
spawn = require("spawn")
setSpawnpoint= require ("setSpawnpoint")
serverConnection = require("serverConnection")
server = require("server/server")
commands = require("server/commands")
missionLoad = require("server/missionLoad")
gameManager = require("server/game")
beamng_cef = require("beamng_cef")
audio_client = require("client/audio")

worldReadyState = -1 -- tracks if the level loading is done yet: 0 = no, 1 = yes, load play ui, 2 = all done

gdcdemo = nil -- demo mode disabled

defaultVehicleModel = 'etk800'

--[[
-- function to trace the memory usage
local maxMemUsage = 0
local function trace_mem(event, line)
  local s = debug.getinfo(2)
  local m, _ = gcinfo()
  if m > maxMemUsage then
    maxMemUsage = m
  end
  Lua:log('D', 'luaperf', tostring(event) .. ' = ' .. tostring(s.what) .. '_' .. tostring(s.source) .. ':' .. tostring(s.linedefined) .. ' / memory usage: ' .. tostring(m) .. ' (max: ' .. tostring(maxMemUsage) .. ')')
end
debug.sethook(trace_mem, "c")
--]]

--[[
gdcdemo = {
  start = function()
      campaign_campaigns.startByFolder('campaigns/gdc_2017', gdcdemo.startCampaign)
  end
}
]]

math.randomseed(os.time())
local SteamLicensePlateVehicleId
local cmdArgs = Engine.getStartingArgs()

--Lua:enableStackTraceFile("lua.ge.stack.txt", true)

logAlways=print

-- improve stacktraces
local STP = require "StackTracePlus"
debug.traceback = STP.stacktrace
debug.tracesimple = STP.stacktraceSimple

if tableFindKey(cmdArgs, '-luadebug') then
  startDebugger()
end
local _isSafeMode = tableFindKey(cmdArgs, '-safemode')
function isSafeMode()
  return _isSafeMode
end

-- immediate command line arguments
-- worked off before anything else
-- called when the world is init'ed
local function handleCommandLineFirstFrame()
  if tableFindKey(cmdArgs, '-resaveMaterials') then

    -- first: find levels
    TorqueScript.exec("core/art/datablocks/datablockExec.cs")

    local function resaveTSFiles(pattern, fnSuffix)
      local filenames = FS:findFilesByRootPattern('/', pattern, -1, true, false)
      dump(filenames)
      for _, fn in pairs(filenames) do
        local dir, filename, ext = string.match(fn, "(.-)([^/]-([^%.]+))$")
        --local outName = dir .. 'folder.material.json'
        log('I', 'resaveMaterials', 'converting ts script: ' .. tostring(fn) )
        -- record known things
        local knownObjects = scenetree.getAllObjects()
        -- convert to map
        local newKnownObjects = {}
        for k, v in pairs(knownObjects) do
          newKnownObjects[v] = 1
        end
        knownObjects = newKnownObjects

        -- load the file
        TorqueScript.exec(fn)

        -- figure out what objects were loaded from that file by diffing with the known objects above
        local knownObjects2 = scenetree.getAllObjects()
        local newObjects = {}
        for _, o in pairs(knownObjects2) do
          if not knownObjects[o] then
            table.insert(newObjects, o)
          end
        end
        dump(newObjects)

        -- get all objects in it
        for _, oName in pairs(newObjects) do
          local obj = scenetree.findObject(oName)
          if obj then
            local s = obj:serialize(true, -1)
            s = string.gsub(s,'%s+$','') -- trim right

            -- save every object on its own
            local outName = dir .. obj.name ..  fnSuffix
            print(outName)
            writeFile(outName, s)
            --obj:delete()
          end
        end
      end
    end

    resaveTSFiles('material.cs', '.material.json')
    resaveTSFiles('*Data.cs', '.datablock.json')
    log('I', 'resaveMaterials', 'all done, exiting gracefully')
    shutdown(0)

  elseif tableFindKey(cmdArgs, '-deps') then
    extensions.util_dependencyTree.test()
    print('done')
    shutdown(0)
  end
end

--[[
check if there is default vehicle or not
if not then use the deafult defaultVehicleModel
]]
function loadDefaultVehicle()
  local myveh = TorqueScript.getVar('$beamngVehicleArgs')
  if myveh ~=""  then
    TorqueScript.setVar( '$beamngVehicle', myveh )

    local mycolor = beamng_cef.getVehicleColor()
    TorqueScript.setVar( '$beamngVehicleColor', mycolor )
    return
  end

  local invalidDefaultVehicle = false
  local data = readJsonFile('settings/default.pc')

  if data then
    if data.model and data.licenseName and data.colors then
      local dir = FS:directoryExists('vehicles')
      if dir then
        if #FS:findFilesByPattern('/vehicles/'..data.model..'/', '*.jbeam', 0, false, false) > 0 then
          TorqueScript.setVar( '$beamngVehicle', data.model )
          TorqueScript.setVar( '$beamngVehicleConfig', 'settings/default.pc' )
          TorqueScript.setVar( '$beamngVehicleLicenseName', data.licenseName )
        else
          data.model = defaultVehicleModel
          TorqueScript.setVar( '$beamngVehicle', data.model )

          data.color = beamng_cef.getVehicleColor()
          os.remove('settings/default.pc')
        end
      end
      TorqueScript.setVar( '$beamngVehicleLicenseName', data.licenseName )
      TorqueScript.setVar( '$beamngVehicleColor', data.color )
    else
      log('E', 'main', "The default vehicle in 'settings/default.pc' is broken. You can either delete 'settings/default.pc' or set a new default vehile.")
      invalidDefaultVehicle = true
    end
  end

  if invalidDefaultVehicle then
    TorqueScript.setVar( '$beamngVehicle', defaultVehicleModel)
    TorqueScript.setVar( '$beamngVehicleColor', "White")
  end
end

local coreModules =  {'core_apps', 'scenario_scenariosLoader', 'campaign_campaignsLoader', 'core_levels',
                      'scenario_quickRaceLoader', 'core_highscores', 'core_replay','core_vehicles', 
                      'core_jobsystem', 'core_modmanager','core_hardwareinfo',
                      'core_commandhandler', 'core_remoteController', 'core_gamestate', 'core_online',
                      'core_paths', 'util_creatorMode', 'core_sounds','core_audio', 'core_imgui'
                      }
                      --,'util_extUI'
                      --'core_schemeCommandServer' -- unused for now - replaced by startCommandListener()

local sharedModules = { 'core_quickAccess', 'core_camera', 'core_groundMarkers', 'core_environment',
                        'core_weather', 'core_trailerRespawn'}

-- careerModules = {'scenario_levelConnector'} -- TODO(AK): unused for now. move this to the correct file later

local extraUserRequestedExtensions = {}

function loadCoreExtensions()
  extensions.load(coreModules)
end

function loadGameModeModules(...)
  extensions.unloadExcept(coreModules)
  extensions.load(sharedModules, extraUserRequestedExtensions, ...)
  extraUserRequestedExtensions = {}
  extensions.hookExcept(coreModules, 'onInit')
end

function unloadGameModules()
  extensions.unloadExcept(coreModules)
end

function registerCoreModule(module)
  for _, mod in ipairs(coreModules) do
    if mod == module then return end
  end
  table.insert(coreModules, module)
end

function endActiveGameMode(callback)
  local endCallback = function ()
    unloadGameModules()

    if type(callback) == 'function' then
      callback()
    end
  end
  -- NOTE: We have to use a callback to serverConnection.disconnect because is it updated in a
  --       State machine
  serverConnection.disconnect(endCallback)
end

function queueExtensionToLoad(modulePath)
  -- log('I', 'main', "queueExtensionToLoad called...."..modulePath)
  table.insert(extraUserRequestedExtensions, modulePath)
end

-- called before the Mission Resources are loaded
function clientPreStartMission(mission)
  worldReadyState = 0
  extensions.hook('onClientPreStartMission', mission)
  guihooks.trigger('PreStartMission')  
  loadDefaultVehicle()
end

-- called when level, car etc. are completely loaded (after clientPreStartMission)
function clientPostStartMission(mission)
  --default game state, will get overriden by each mode
  core_gamestate.setGameState('freeroam', 'freeroam', 'freeroam')
  extensions.hook('onClientPostStartMission', mission)
end

-- called when the level items are already loaded (after clientPostStartMission)
function clientStartMission(mission)
  log("D", "clientStartMission", "starting mission: " .. tostring(mission))
  extensions.hook('onClientStartMission', mission)
  be:physicsStartSimulation()
  map.assureLoad() --> needs to be after extensions.hook('onClientStartMission', mission)
  guihooks.trigger('MenuHide')
 -- SteamLicensePlateVehicleId = nil
end

function clientEndMission(mission)
  -- core_gamestate.requestGameState()
  -- log("D", "clientEndMission", "ending mission: " .. tostring(mission))
  be:physicsStopSimulation()
  bullettime.pause(false)
  extensions.hookNotify('onClientEndMission', mission)
end

function returnToMainMenu()
  endActiveGameMode()
end

function onEditorEnabled(enabled)
  --print('onEditorEnabled', enabled)
  extensions.hook('onEditorEnabled', enabled)
  map.setEditorState(enabled)

end

local luaPreRenderMaterialCheckDuration = 0

function luaPreRender(dtReal, dtSim, dtRaw)
  map.updateGFX(dtReal)
  map.drawDebug(dtReal, Lua.lastDebugFocusPos)
  extensions.hook('onPreRender', dtReal, dtSim, dtRaw)
  extensions.hook('onDrawDebug', Lua.lastDebugFocusPos, dtReal, dtSim, dtRaw)

  -- will be used for ge streams later
  -- guihooks.frameUpdated(dtReal)

  -- detect if we need to switch the UI around
  if worldReadyState == 1 then
    -- log('I', 'gamestate', 'Checking if vehicle is done rendering material') -- this is far too verbose and seriously slows down the debugging
    luaPreRenderMaterialCheckDuration = luaPreRenderMaterialCheckDuration + dtRaw
    local pv = be:getPlayerVehicle(0)
    local allReady = (not pv) or (pv and pv:isRenderMaterialsReady())
    if allReady or luaPreRenderMaterialCheckDuration > 30 then
      log('D', 'gamestate', 'Checking material finished loading')
      core_gamestate.requestExitLoadingScreen('worldReadyState')
      -- switch the UI to play mode
      -- be:executeJS("HookManager.trigger('ChangeState', 'menu', ['loading', 'backgroundImage.mainmenu']);")
      worldReadyState = 2
      luaPreRenderMaterialCheckDuration = 0
      extensions.hook('onWorldReadyState', worldReadyState)
    end
  end
end

gAutoHideDashboard = false -- when enabled, it is not working correctly for some reason...
local lastTimeSinceLastMouseMoved = 0
local lastTimeSinceLastRadialMoved = 0 -- for radial menu app (moved by gamepad usually)

function updateFirstFrame()
  bindings.init()
  virtualinput.init()
  bullettime.init()

  extensions.hook('onFirstUpdate')
  settings.onFirstUpdate()

  -- make sure the editing tools are in the correct state
  onEditorEnabled(Engine.getEditorEnabled())

  if gdcdemo then
    gdcdemo.start()
  end
  handleCommandLineFirstFrame()
end

function update(dtReal, dtSim, dtRaw)
  --local used_memory_bytes, _ = gcinfo()
  --log('D', "update", "Lua memory usage: " .. tostring(used_memory_bytes/1024) .. "kB")

  debugPoll()

  virtualinput.update()
  bindings.updateGFX(dtRaw)
  bullettime.update(dtSim)
  screenshot.updateGFX()

  extensions.hook('onUpdate', dtReal, dtSim, dtRaw)
  perf.update()

  local timeSinceLastMouse = Engine.Platform.getRealMilliseconds() - getMovedMouseLastTimeMs()
  if timeSinceLastMouse - lastTimeSinceLastMouseMoved < 0 then
    guihooks.trigger('MenuFocusShow', false)
  end
  lastTimeSinceLastMouseMoved = timeSinceLastMouse

  if core_quickAccess then
    local timeSinceLastRadial = Engine.Platform.getRealMilliseconds() - core_quickAccess.getMovedRadialLastTimeMs()
    if timeSinceLastRadial - lastTimeSinceLastRadialMoved < 0 then
      guihooks.trigger('MenuFocusShow', false)
    end
    lastTimeSinceLastRadialMoved = timeSinceLastRadial
  end

  if gAutoHideDashboard and bindings.isMenuActive and ((Engine.Platform.getRealMilliseconds() - getCEFFocusMouseLastTimeMs()) > 30000) then
    guihooks.trigger('MenuHide')
  end

  -- if be.physicsMaxSpeed then
  --   ui_message('Physics Speed up: ' .. string.format("%0.3f %%", be.physicsSimSpeedUp*100), 10, 'physicsSimSpeedUp')
  -- end
end

-- called when the UI is up and running
function uiReady()
  extensions.hook('onUiReady')

  -- TODO: figure out what level to load on startup here and load it once
end

-- Called on reload (Control-L)
function init()
  actions.init()
  settings.init()
  guihooks.trigger("EngineLuaReloaded")
  --log('D', "init", 'GameEngine Lua (re)loaded')

  extensions.load(coreModules)
  extraUserRequestedExtensions = {}

  core_online.openSession() -- try to connect to online services

  -- import state last
  importPersistentData()

  -- request the UI ready state
  be:executeJS('HookManager.trigger("isUIReady")')

  -- be sensitive about global writes from now on
  detectGlobalWrites()
  map.assureLoad()

  -- world ready to do sth
  worldReadyState = 0

  -- put the mods folder in clear view, so users don't put stuff in the wrong place
  if not FS:directoryExists("mods") then FS:directoryCreate("mods") end
end

function onBeamNGWaypoint(args)
  map.onWaypoint(args)
  extensions.hook('onBeamNGWaypoint', args)
end

-- do not delete - this is the default function name for the BeamNGTrigger from the c++ side
function onBeamNGTrigger(data)
  extensions.hook('onBeamNGTrigger', data)
end

function onFileChanged(t)
  --print("onFileChanged: " .. tostring(filename) .. ' : ' .. tostring(type))
  for k,v in pairs(t) do
    --print("onFileChanged: " .. tostring(v.filename) .. ' : ' .. tostring(v.type))
    settings.onFileChanged(v.filename, v.type)
    map.onFileChanged(v.filename, v.type)
    extensions.hook('onFileChanged', v.filename, v.type)
    bindings.onFileChanged(v.filename)

    if string.startswith(v.filename, 'html/') then
      guihooks.trigger('FileChanged', {filename = v.filename, type = v.type})
    end
  end
end

function getLevelList()
  if not FS:directoryExists('/levels/') then
    return {}
  end
  local files = FS:findFilesByPattern('/levels/', '*.level.json', 1, true, false)
  local oldMisfiles = FS:findFilesByPattern('/levels/', '*.mis', 1, true, false)
  arrayConcat(files, oldMisfiles)
  arrayConcat(files, FS:findFilesByPattern('/levels/', 'info.json', 1, true, false))
  local dupLookUp = {}
  local filesList = {}
  local filename
  -- filter paths to only return filename without extension
  for k,v in pairs(files) do
    filename = string.gsub(files[k], "(.*/)(.*)/(.*)", "%2")
    if not dupLookUp[filename] then
      table.insert(filesList, filename)
      dupLookUp[filename] = true
    end
  end
  return filesList
end

function physicsEngineEvent(...)
  local args = unpack({...})
  extensions.hook('onPhysicsEngineEvent', args)
end

-- nil values are equal last values
function setPlateText(txt, vehId, designPath)
  local veh = nil
  if vehId then
    veh = be:getObjectByID(vehId)
  else
    veh = be:getPlayerVehicle(0)
  end
  if not veh then return end
  if txt then
    veh:setDynDataFieldbyName("licenseText", 0, txt)
  else
    txt = getVehicleLicenseName(vehId)
  end

  if not designPath then
    designPath = veh:getDynDataFieldbyName("licenseDesign", 0) or ''
  else
    veh:setDynDataFieldbyName("licenseDesign", 0, designPath)
  end

  local design = readJsonFile(designPath)
 -- dump(design)
  if not design or not design.data then
    if designPath:len() > 0 then
      log('E', 'main', "License plate "..designPath.." not existing")
    end
    local levelPath, levelName, _ = path.split( getMissionFilename() )
    if levelPath then
      local levelName = string.match(levelPath,'levels/(%a+)')
      --log('E', 'main.setPlateText', "levelPath= "..tostring(levelPath).." levelName="..tostring(levelName))
      designPath =  'vehicles/common/licenseplates/'..levelPath:gsub('levels/', '')..'/licensePlate-default.json'
      design = readJsonFile(designPath)
    end
  end

  if not design or not design.data then
    designPath = 'vehicles/common/licenseplates/default/licensePlate-default.json'
    design = readJsonFile(designPath)
  end

----adding licenseplate html generator and characterlayout to Json file

  if design then
    if design.data.characterLayout then
      if FS:fileExists(design.data.characterLayout) then
        design.data.characterLayout = readJsonFile(design.data.characterLayout)
      else
        log('E',tostring(design.data.characterLayout) , ' File not existing')
      end
    else
      design.data.characterLayout= "vehicles/common/licenseplates/default/platefont.json"
      design.data.characterLayout= readJsonFile(design.data.characterLayout)
    end

    if design.data.generator then
      if FS:fileExists(design.data.generator) then
        design.data.generator = "local://local/" .. design.data.generator
      else
        log('E',tostring(design.data.generator) , ' File not existing')
      end
    else
      design.data.generator = "local://local/vehicles/common/licenseplates/default/licenseplate-default.html"
    end
    veh:createUITexture("@licenseplate-default", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default", 'init("diffuse","' .. txt .. '", '.. encodeJson(design) .. ');')
    veh:createUITexture("@licenseplate-default-normal", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default-normal", 'init("bump","' .. txt .. '", '.. encodeJson(design) .. ');')
    veh:createUITexture("@licenseplate-default-specular", design.data.generator, 1024, 512, UI_TEXTURE_USAGE_MANUAL, 1)
    veh:queueJSUITexture("@licenseplate-default-specular", 'init("specular","' .. txt .. '", '.. encodeJson(design) .. ');')
  end
end

function getVehicleLicenseName(veh)
  if gdcdemo then
    return 'GDC2017'
  end

  if not veh then veh = be:getPlayerVehicle(0) end
  if not veh then return '' end
  if type(veh) == 'number' then
    veh = be:getObjectByID(veh)
  end
  if not veh then return '' end

  local txt = veh:getDynDataFieldbyName("licenseText", 0)
  if txt and txt:len() > 0 then return txt end

  if Steam and Steam.isWorking and Steam.accountLoggedIn and not SteamLicensePlateVehicleId and veh:getID() == be:getPlayerVehicle(0):getID() then
    SteamLicensePlateVehicleId = veh:getID()
    txt = Steam.playerName
    --print("steam username: " .. Steam.playerName)
    txt = txt:gsub('%"', '%\'') -- replace " with '
    -- more cleaning up required?
  else
    local T = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
    txt = T[math.random(1, #T)] .. T[math.random(1, #T)] .. T[math.random(1, #T)] ..'-'..math.random(0, 9)..math.random(0, 9)..math.random(0, 9)..math.random(0, 9)
  end

  veh:setDynDataFieldbyName("licenseText", 0, txt)
  return txt
end

function getVehicleName(veh)
  if veh and veh.configs then
    return veh.configs.Name
  else
    return "Unknown"
  end
end

function getVehicleBrand(veh)
  if veh and veh.model then
    return veh.model.Brand
  else
    return "Unknown"
  end
end

--[[
save default vehicle configurations
@param objTable table contains vehicle config
]]
function saveDefaultVehicle(objTable)
  objTable.licenseName = getVehicleLicenseName()
  core_vehicles.saveVehicleConfig(0, 'settings/default.pc', objTable)

  TorqueScript.setVar( '$beamngVehicle', objTable.model )
  TorqueScript.setVar( '$beamngVehicleConfig', 'settings/default.pc' )
  TorqueScript.setVar( '$beamngVehicleLicenseName', objTable.licenseName )
  TorqueScript.setVar( '$beamngVehicleColor', objTable.color )
end

function vehicleSpawned(vid)
  local v = be:getObjectByID(vid)
  if not v then return end

  -- update the gravity of the vehicle
  if core_environment then
    v:queueLuaCommand("obj:setGravity(\""..core_environment.getGravity().."\")")
  end

  -- tell the vehicle to start its debugger as well
  if debugPoll ~= nop then
    v:queueLuaCommand("startDebugger()")
  end

  extensions.hook('onVehicleSpawned', vid)
end

function vehicleSwitched(oldVehicle, newVehicle, player)
  local oid = oldVehicle and oldVehicle:getID() or -1
  local nid = newVehicle and newVehicle:getID() or -1
  local oldinfo = oldVehicle and ("id "..dumps(oid).." ("..oldVehicle:getPath()..")") or dumps(oldVehicle)
  local newinfo = newVehicle and ("id "..dumps(nid).." ("..newVehicle:getPath()..")") or dumps(newVehicle)
  log('I', 'main', "Player #"..dumps(player).." vehicle switched from: "..oldinfo.." to: "..newinfo)

  bindings.onVehicleChanged(oldVehicle, newVehicle, player)
  extensions.hook('onVehicleSwitched', oid, nid, player)

  if player == 0 then -- update main camera
    if not commands.isFreeCamera(player) then
      local game = scenetree.findObject("Game")
      if game then
        game:setCameraHandler(newVehicle)
      end
    end
  end

  --Steam.setStat('meters_driven', 1)
end

function onVehicleDestroyed(vid)
  if SteamLicensePlateVehicleId == vid then
    SteamLicensePlateVehicleId = nil
  end
  extensions.hook('onVehicleDestroyed', vid)
end

function onCouplerAttached(objId1, objId2, nodeId, obj2nodeId)
  extensions.load('core_trailerCamera')
  if core_trailerCamera.checkForTrailer(objId1, objId2) == false then
    extensions.unload('core_trailerCamera')
  end
  extensions.hook('onCouplerAttached', objId1, objId2, nodeId, obj2nodeId)
end

function onCouplerDetached(objId1, objId2)
  extensions.hook('onCouplerDetached', objId1, objId2)
  if core_trailerCamera ~= nil then
    if core_trailerCamera.checkForTrailer(objId1, objId2) == true then
      extensions.unload('core_trailerCamera')
    end
  end
end

--Trigered when trailer coupler is detached by the user
function onCouplerDetach(objId, nodeId)
  extensions.hook('onCouplerDetach', objId, nodeId)
end

function onAiModeChange(vehicleID, newAiMode)
  extensions.hook('onAiModeChange', vehicleID, newAiMode)
end

function replayStateChanged(...)
  core_replay.stateChanged(...)
end

function networkDataReady(data)
  nodeStream.send(data)
end

function exportPersistentData()
  local s = serializePackages()
  -- log('D', 'main', 'persistent data exported: ' .. tostring(s))
  be.persistenceLuaData = s
end

function importPersistentData()
  local s = be.persistenceLuaData
  -- log('D', 'main', 'persistent data imported: ' .. tostring(s))
  -- deserialize extensions first, so the extensions are loaded before they are trying to get deserialized
  local data = unserialize(s)
  -- TODO(AK): Remove this stuff post completing serialization work
  -- writeFile("ge_exportPersistentData.txt", dumps(data))
  deserializePackages(data)
end

function updatePhysicsState(val)
  be:executeJS('updatePhysicsState('..tostring(val)..')')
  if val then
    extensions.hook('onPhysicsUnpaused')
  else
    extensions.hook('onPhysicsPaused')
  end
end

function updateTranslations()
  -- unmount if in use, so we can update the file
  if FS:isMounted('mods/translations.zip') then
    FS:unmount('mods/translations.zip')
  end

  extensions.core_repository.installMod('locales.zip', 'translations.zip', 'mods/', function(data)
    log('D', 'updateTranslations', 'translations download done: mods/translations.zip')
    -- reload the settings to activate the new files
    settings.newTranslationsAvailable = true -- this enforces the UI refresh, fixes some state problems
    settings.load(true)
  end)
end

function enableCommunityTranslations()
  settings.setState( { communityTranslations = 'enable' } )
  updateTranslations()
end

-- little shortcut
function annotate()
  extensions.util_annotation.extractData()
end

-- called when the game is not running realtime anymore
function nonRealtime()
  extensions.hook('onNonRealtime')
  --ui_message("Cannot run simulation at full speed. Vehicles are moving in slow motion and scenarios may be impossible to finish.", 0.3, "fpsWarn")
end

function onExit()
    log('D', 'onExit', 'Exiting')
    extensions.hook('onExit')
    settings.save()
end

function onInstabilityDetected(jbeamFilename)
  bullettime.pause(true)
  log('E', "", "Instability detected for vehicle " .. tostring(jbeamFilename))
  ui_message({txt="vehicle.main.instability", context={vehicle=tostring(jbeamFilename)}}, 10, 'instability', "warning")
end

function onVehicleResetted(vehicleID)
    extensions.hook('onVehicleResetted', vehicleID)
end

function resetGameplay(playerID)
  extensions.hook('onResetGameplay', playerID)
end
