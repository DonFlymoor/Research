-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local currentVehicle = {}

local listeners = {}

local cache = {}
local timer = 0
local updatedt = 1/20
M.updateStreams = false

local informListeners = nop

local playerInfo = playerInfo
local objectId = objectId
local vehicleLuaSpecific = nop

-- executed in physics
local cppIntermediate = obj

-- we are actually in game engine and not vehicle lua, so things need to be handled differently
if not cppIntermediate then
    cppIntermediate = be
    playerInfo = {firstPlayerSeated = true}
    objectId = "gameEngine"
end

local function callListeners(type, data)
  for _,v in pairs(listeners) do
    v(type, data)
  end
end

local function hook(...)
  local msg = encodeJson({...})
  local cmd = "if(HookManager){HookManager.trigger.apply(undefined," .. msg .. ");}"
  cppIntermediate:queueJS(cmd)

  informListeners("hook", msg)
end

local test = true
local function hookStream(name, ...)
    local params = unpack({...})
    local cmd = "if(HookManager){HookManager.trigger('"..name.."',"..encodeJson(params)..");}"
    cppIntermediate:queueStreamJS(name, cmd)

    local sending = arrayConcat({name}, {params})
    informListeners("hook", encodeJson(sending))
end

local function checkStreamsAndVehicle()
    streams.updateStreams()

    --vehicleChange
    if currentVehicle ~= v.data then
        currentVehicle = v.data
        hook("VehicleChange", v.vehicleDirectory)
        hook("VehicleReset", 0)
    end
end

if obj then
    vehicleLuaSpecific = checkStreamsAndVehicle
end

-- in ge this should be onPreRender
-- in vehicle this should be updateGFX
-- WARNING: this can currently only be called from vehicle lua side. from ge this will break
local function frameUpdated(dt)
  timer = timer + dt
  local updateLimit = math.max(dt * 2, updatedt)
  M.updateStreams = timer > updateLimit and playerInfo.firstPlayerSeated

  if M.updateStreams then
    timer = timer % updateLimit
    vehicleLuaSpecific()
    cppIntermediate:queueStreamJS("vStream."..objectId, "if (typeof oUpdate == 'function') oUpdate(".. encodeJson(cache)..");")
    informListeners("stream", encodeJson({cache}))
    table.clear(cache)
  end
end

local function reset()
  M.updateStreams = false
  table.clear(cache)
  hook("VehicleReset", 0) -- Triggering VehicleReset when vehicle is actually reset and not only reloaded.
end

-- WARNING: this can currently only be called from vehicle lua side. from ge this will break
function sendUITextureData(textureName, key, value, objID)
  if not objID or objID == objectId then
    -- message to self
    obj:queueWebViewJS(textureName, string.format('HookManager.trigger(%q,%q);', key, encodeJson(value)))
  else
    -- message to someone else
    local js = encodeJson(value):gsub('%"', '%\\\'') -- replace " with \'
    local l = "be:getObjectByID("..objID.."):queueJSUITexture('"..textureName.."', 'HookManager.trigger(\"" .. key .. "\", " .. js .. ");')"
    obj:queueGameEngineLua(l)
  end
end

-- cache data to be send later
local function send(key, value)
  if M.updateStreams then
    cache[key] = value
  end
end

-- todo replace ui_message
-- instead message should directly call the hook
-- in light of different message types emerging it might be interesting to have a seperate message module
local function message(msg, ttl, category, icon)
  if not playerInfo.firstPlayerSeated then return end
  ui_message(msg, ttl, category, icon)
end

-- used to monitor or stream all communication to somewhere else ie extUI
local function updateListener (module, func)
  listeners[module] = func

  if tableSize(listeners) == 0 then
    informListeners = nop
  else
    informListeners = callListeners
  end
end

-- public interface
M.reset = reset
-- WARNING: this can currently only be called from vehicle lua side. from ge this will break
M.frameUpdated = frameUpdated
M.trigger = hook
M.triggerStream = hookStream
M.send = send
M.message = message

M.updateListener = updateListener

-- WARNING: this can currently only be called from vehicle lua side. from ge this will break
M.sendUITextureData = sendUITextureData

return M