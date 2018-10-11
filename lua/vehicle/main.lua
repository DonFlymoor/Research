-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
vmType = "vehicle"

package.path = "lua/vehicle/?.lua;lua/vehicle/jbeam/?.lua;lua/common/?.lua;lua/common/socket/?.lua;lua/?.lua;?.lua"
package.cpath = ""
require("compatibility")

log = function(...)
  Lua:log(...)
end
print = function(...)
  Lua:log("A", "print", tostring(...))
end

require("utils")
require("mathlib")

math.randomseed(os.time())

-- improve stacktraces
local STP = require "StackTracePlus"
debug.traceback = STP.stacktrace
debug.tracesimple = STP.stacktraceSimple

perf = require("perf")
settings = require("simplesettings")
backwardsCompatibility = require("backwardsCompatibility")
objectId = obj:getID()

playerInfo = {
  seatedPlayers = {}, -- list of players seated in this vehicle; players are indexed from 0 to N (e.g. { [1]=true, [4]=true } for 2nd and 5th players)
  firstPlayerSeated = false,
  anyPlayerSeated = false
}
lastDt = 1 / 20

loadingTimes = {} -- global intentionally, used all over the place

local initCalled = false
log_jbeam = nop -- intentionally global

--- if you want to debug vehicle loading, feel free to uncomment this line:
--startDebugger()

-- step functions
function physicsStep(dtSim)
  wheels.updateWheelVelocities(dtSim)
  powertrain.update(dtSim)
  wheels.updateWheelTorques(dtSim)
  controller.update(dtSim)
  thrusters.update()
  hydros.update(dtSim)
  beamstate.update(dtSim)
  motionSim.update(dtSim)
  --commands.onPhysicsStep(dtSim)
end

-- This is called in the local scope, so it is NOT safe to do things that contact things outside the vehicle
function graphicsStep(dtSim)
  debugPoll()

  lastDt = dtSim
  sensors.updateGFX(dtSim) -- must be before input and ai
  mapmgr.sendTracking() -- must be before ai.updateGFX
  ai.updateGFX(dtSim) -- must be before input
  input.update(dtSim) -- must be as early as possible
  electrics.update(dtSim)
  material.updateGFX()
  controller.updateGFX(dtSim)
  extensions.hook("updateGFX", dtSim) -- must be before drivetrain and after electrics -- why? which extension requires this?
  powertrain.updateGFX(dtSim)
  energyStorage.updateGFX(dtSim)
  drivetrain.updateGFX(dtSim)
  beamstate.updateGFX(dtSim) -- must be after drivetrain
  sounds.updateGFX(dtSim)
  hydros.updateGFX(dtSim) -- must be after (input, electrics) and before props
  thrusters.updateGFX() -- should be after extensions.hook
  if playerInfo.anyPlayerSeated then
    perf.update()
    if playerInfo.firstPlayerSeated then
      gui.frameUpdated(obj:getRealdt())
      damageTracker.updateGFX(dtSim)
    end
  end

  wheels.updateGFX(dtSim)
  props.update()
  fire.updateGFX(dtSim)
  recovery.updateGFX(dtSim)
  motionSim.updateGFX(dtSim)
end

-- debug rendering
function debugDraw(x, y, z)
  local focusPos = float3(x, y, z)
  bdebug.debugDraw(focusPos)
  ai.debugDraw(focusPos)
  beamstate.debugDraw(focusPos)
  controller.debugDraw(focusPos)
  motionSim.debugDraw(focusPos)
  extensions.hook("onDebugDraw", focusPos)
end

function initSystems()
  backwardsCompatibility.init()

  material.init()
  damageTracker.init()
  wheels.init()
  powertrain.init()
  energyStorage.init()
  controller.init()

  wheels.initSecondStage()
  controller.initSecondStage()
  drivetrain.init()

  sensors.reset()
  beamstate.init()
  thrusters.init()
  hydros.init()
  sounds.init()
  props.init()
  electrics.init()
  input.init() -- needs to go after sounds & electrics
  recovery.init()
  bdebug.init()
  sensors.init()
  fire.init()
  powertrain.initSounds()
  controller.initSounds()
  gui.message("", 0, "^vehicle\\.") -- clear damage messages on vehicle restart
  extensions.hook("onInit")
  mapmgr.init()
  motionSim.init()

  controller.initLastStage() --meant to be last in init

  -- be sensitive about global writes from now on
  detectGlobalWrites()
  initCalled = true
end

function init(path, partConfigData)
  local hp1 = HighPerfTimer()
  local hp2 = HighPerfTimer()

  --perf.enable(1)

  if not obj then
    log("W", "default.init", "Error getting main object: unable to spawn")
    return
  end
  log("D", "default.init", "spawning vehicle " .. tostring(path))

  -- we change the lookup path here, so it prefers the vehicle lua
  package.path = path .. "/lua/?.lua;" .. package.path
  extensions = require("extensions")
  extensions.loadModulesInDirectory(path .. "/lua", true, {"controller"})
  extensions.addModulePath("lua/vehicle/extensions/")
  extensions.addModulePath("lua/common/extensions/")

  extensions.load("core_quickAccess")
  --extensions.load("motionSim")

  damageTracker = require("damageTracker")
  drivetrain = require("drivetrain")
  powertrain = require("powertrain")
  powertrain.setVehiclePath(path)
  energyStorage = require("energyStorage")
  controller = require("controller")

  wheels = require("wheels")
  sounds = require("sounds")

  bdebug = require("bdebug")
  input = require("input")
  props = require("props")

  particlefilter = require("particlefilter")
  particles = require("particles")
  material = require("material")
  v = require("jbeam_main")
  electrics = require("electrics")
  beamstate = require("beamstate")
  sensors = require("sensors")
  bullettime = require("bullettime") -- to be deprecated
  thrusters = require("thrusters")
  hydros = require("hydros")
  gui = require("guihooks") -- do not change its name, the GUI callback will break otherwise
  partmgmt = require("partmgmt") -- do not change its name, the GUI callback will break otherwise
  streams = require("guistreams")
  guihooks = gui -- legacy
  ai = require("ai")
  recovery = require("recovery")
  mapmgr = require("mapmgr")
  fire = require("fire")
  commands = require("commands")
  motionSim = require("motionSim")

  table.insert(loadingTimes, {"0 startup", hp1:stopAndReset()})

  -- care about the config before pushing to the physics
  if type(partConfigData) == "string" and string.len(partConfigData) > 0 then
    local firstChar = string.sub(partConfigData, 1, 1)
    if firstChar == "{" or firstChar == "[" then
      log("D", "default.init", "  using partconfig data " .. tostring(partConfigData) .. " - path:" .. tostring(path))
      partmgmt.setConfig(unserialize(partConfigData), false)
    else
      log("D", "default.init", "  using partconfig filename " .. tostring(partConfigData) .. " - path:" .. tostring(path))
      partmgmt.load(partConfigData, false)
    end
  end

  -- experimental: vehicle file caching
  --[[
  local mp = require 'MessagePack'
  local vCacheFilename = 'vehicleCache.bin'
  if FS:fileExists(vCacheFilename) then
    local f = io.open(vCacheFilename, 'r')
    if f then
      v.vehicles = mp.unpack(f:read('*a'))
      f:close()
    end
  end
  --]]
  -- this filters the Debug messages out
  log_jbeam = function(level, source, msg)
    if level == "D" then
      return
    end
    log(level, source, msg)
  end
  if settings.getValue("creatorMode") == true then
    extensions.load("creatorMode")
  end

  if settings.getValue("externalUi") == true then
    extensions.load("extUI")
  end

  --extensions.load("api")

  --if v.vehicles == nil then
  -- load jbeam files
  if not v.loadVehicle(path) then -- important: the real vehicle dir is always last, all additional paths come first
    log("E", "main", "unable to load vehicle: aborted loading")
    return
  end
  table.insert(loadingTimes, {"1.X.X.X loadDirectories (sum)", hp1:stopAndReset()})

  -- experimental: vehicle file caching
  --[[
    local mp = require 'MessagePack'
    local f = io.open(vCacheFilename, 'w')
    if f then
      f:write(mp.pack(v.vehicles))
      f:close()
    end
    table.insert(loadingTimes, {'2. messagepack serialize', hp1:stopAndReset()})
    --]]
  --end

  -- you can change the data in here before it gets submitted to the physics

  -- submit to physics
  hp1:reset()
  v.pushToPhysics(obj)
  table.insert(loadingTimes, {"2.XX pushToPhysics (sum)", hp1:stopAndReset()})

  if v.data == nil then
    v.data = {}
  end

  -- disable lua for simple vehicles
  if v.data and v.data.information and v.data.information.simpleObject == true then
    log("I", "", "lua disabled!")
    return false
  end

  initSystems()
  table.insert(loadingTimes, {"3 initSystems", hp1:stopAndReset()})

  -- temporary tire mark setting
  obj.slipTireMarkThreshold = 10

  -- update gravity and other things
  obj:queueGameEngineLua("vehicleSpawned(" .. tostring(obj:getID()) .. ")")

  if settings.getValue("outgaugeEnabled") == true then
    extensions.load("outgauge")
  end

  -- load the extensions at this point in time, so the whole jbeam is parsed already
  extensions.loadModulesInDirectory("lua/vehicle/extensions/auto", true)

  -- extensions that always load
  extensions.load("skeleton")

  local totalTime = hp2:stopAndReset()
  table.insert(loadingTimes, {"4.X.X.X total (sum)", totalTime})

  --log('D', "default.init", "init done - vehicle loading took "..totalTime..' ms')

  --perf.disable()
  --perf.saveDataToCSV('vehicle_boottime_perf.csv')

  -- dump boot time stats
  --log('D', 'default.init', 'Vehicle boot time stats:')
  --for _, t in pairs(loadingTimes) do
  --  log('D', 'default.init', '  * ' .. rpad(t[1], 34, ' ') .. ' = ' .. lpad(string.format('%5.3f', t[2]), 8, ' ') .. ' ms')
  --end

  -- dump them into a file as well
  --[[
  local f = io.open('vehicle_boottime.csv', "w")
  if f then
    table.sort(loadingTimes, function(a, b) return a[2] > b[2] end)
    f:write(";name, time in ms\n")
    for _,vv in ipairs(loadingTimes) do
      f:write(vv[1] .. ', ' .. tostring(vv[2]) .. "\n")
    end
    f:close()
  end
  --]]
  extensions.hook("onVehicleLoaded", retainDebug)

  return true -- false = unload Lua
end

-- various callbacks
function beamBroken(id, energy)
  beamstate.beamBroken(id, energy)
  wheels.beamBroke(id)
  powertrain.beamBroke(id)
  energyStorage.beamBroke(id)
  controller.beamBroke(id, energy)
  bdebug.beamBroke(id, energy)
end

-- only being called if the beam has deform triggers
function beamDeformed(id, ratio)
  beamstate.beamDeformed(id, ratio)
  controller.beamDeformed(id, ratio)
  bdebug.beamDeformed(id, ratio)
end

function couplerFound(nodeId, obj2id, obj2nodeId)
  -- print('couplerFound'..','..nodeId..','..obj2nodeId..','..obj2id)
  beamstate.couplerFound(nodeId, obj2id, obj2nodeId)
  controller.onCouplerFound(nodeId, obj2id, obj2nodeId)
  extensions.hook("onCouplerFound", nodeId, obj2id, obj2nodeId)
end

function couplerAttached(nodeId, obj2id, obj2nodeId)
  -- print('couplerAttached'..','..nodeId..','..obj2nodeId..','..obj2id)
  beamstate.couplerAttached(nodeId, obj2id, obj2nodeId)
  controller.onCouplerAttached(nodeId, obj2id, obj2nodeId)
  extensions.hook("onCouplerAttached", nodeId, obj2id, obj2nodeId)
end

function couplerDetached(nodeId, obj2id, obj2nodeId)
  -- print('couplerDetached'..','..nodeId..','..obj2nodeId..','..obj2id)
  beamstate.couplerDetached(nodeId, obj2id, obj2nodeId)
  controller.onCouplerDetached(nodeId, obj2id, obj2nodeId)
  extensions.hook("onCouplerDetached", nodeId, obj2id, obj2nodeId)
end

-- called when vehicle is removed
function vehicleDestroy()
  --log('D', "default.vehicleDestroy", "vehicleDestroy()")
  -- when the vehicle gets unloaded, remove all sounds
end

-- called when the user pressed I
function vehicleResetted(retainDebug)
  local hp1 = HighPerfTimer()

  guihooks.reset()
  extensions.hook("onReset", retainDebug)
  ai.reset()
  partmgmt.reset()
  mapmgr.reset()

  if not initCalled then
    --log('D', "default.vehicleResetted", "vehicleResetted()")
    damageTracker.reset()
    wheels.reset()
    electrics.reset()
    powertrain.reset()
    energyStorage.reset()
    controller.reset()
    wheels.resetSecondStage()
    controller.resetSecondStage()
    drivetrain.reset()
    props.reset()
    sensors.reset()
    if not retainDebug then
      bdebug.reset()
    end
    beamstate.reset()
    thrusters.reset()
    input.reset()
    hydros.reset()
    material.reset()
    fire.reset()
    motionSim.reset()
    powertrain.resetSounds()
    controller.resetSounds()

    controller.resetLastStage() --meant to be last in reset
  end
  initCalled = false

  gui.message("", 0, "^vehicle\\.") -- clear damage messages on vehicle restart
  loadingTimes["4_vehicleResetted"] = hp1:stopAndReset()
end

function nodeCollision(p)
  wheels.updateWheelSlip(p)
  fire.nodeCollision(p)
  particlefilter.nodeCollision(p)
  bdebug.nodeCollision(p)
end

function setControllingPlayers(players)
  playerInfo.seatedPlayers = players
  playerInfo.anyPlayerSeated = tableSize(players) > 0
  playerInfo.firstPlayerSeated = players[0] ~= nil

  if playerInfo.anyPlayerSeated then
    if controller and controller.mainController then
      if controller.mainController.vehicleActivated then --TBD, only vehicleActivated should be there
        controller.mainController.vehicleActivated()
      else
        controller.mainController.sendTorqueData()
      end
    end

    damageTracker.setDirty(true) --send over damage data of (now) active vehicle
  end

  bdebug.activated(playerInfo.anyPlayerSeated)
  ai.stateChanged()
  extensions.hook("activated", playerInfo.anyPlayerSeated) -- backward compatibility
  guihooks.trigger("VehicleFocusChanged", {id = obj:getID(), mode = playerInfo.anyPlayerSeated})
  -- TODO: clean below up ...
  obj:queueGameEngineLua("extensions.hook('onVehicleFocusChanged'," .. serialize({id = obj:getID(), mode = playerInfo.anyPlayerSeated}) .. ")")
end

function exportPersistentData()
  local s = serializePackages("reload")
  --log('D', "default.exportPersistentData", s)
  obj:setPersistentData(s)
end

function importPersistentData(s)
  --log('D', "default.importPersistentData", s)
  -- deserialize extensions first, so the extensions are loaded before they are trying to get deserialized
  deserializePackages(unserialize(s))
end

-- used by the GE camera code
local cameraData = {}
function requestCameraConfig()
  obj:queueGameEngineLua("extensions.hook('onVehicleCameraConfigChanged'," .. obj:getID() .. "," .. serialize(cameraData) .. ")")
end

function setCameraConfig(v)
  cameraData = v
  requestCameraConfig()
end

function onSettingsChanged()
  extensions.hook("onSettingsChanged")
  controller.settingsChanged()
  input.settingsChanged()
  motionSim.settingsChanged()
end
