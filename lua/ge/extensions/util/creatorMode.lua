-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local creatorModeHttpServer = nil
local wsServer = nil -- websocket
local wsClientConnection = nil -- websocket client Conn

local jsonEncodeFull = require('libs/lunajson/lunajson').encode() -- slow but conform encoder
local copas = require('libs/copas/copas')

local requestVehicleState = 0

local httpListenPort = 16719 -- this is the initial port
local nextVehiclePort = httpListenPort + 2
local listenHost = '127.0.0.1' -- DO NOT set this to anything other than localhost. the webserver is not meant to do this.

local vehiclePorts = {}

local function messageBrowser(d)
  coroutine.resume(coroutine.create(function ()
    if not wsClientConnection then return end
    d.ok = true;
    d.id = -1;
    local res = jsonEncodeFull(d)
    wsClientConnection:send(res)
  end))
end

local function bngApi_websocket_handler(ws)
  --print('>> bngApi_handler got: ' .. dumps(req))
  wsClientConnection = ws
  while 1 do
    local req = ws:receive()
    if not req then
      coroutine.yield()
      return
    end
    req = json.decode(req)
    if not req or not req.api then
      ws:send(jsonEncode({ok=false}))
      return
    end

    if req.api == 'engineLua' then
      --print('executing code: ' .. tostring(req.cmd))
      local res, stdOut = executeLuaSandboxed(req.cmd, 'GECreatorMode')
      if req.id ~= -1 then
        -- -1 == global request, no return requested
        --print('result = ' .. dumps(res))
        local res = jsonEncodeFull({ok = true, id=req.id, api=req.api, result=res, stdOut=stdOut, cmd=req.cmd})
        ws:send(res)
      end
    else
      print("unknown API: "..tostring(req.api))
      ws:send(jsonEncode({ok=false, error='unknown_api'}))
    end
  end
  print(">>> DONE")
  --ws:close()
end


local function creatorModeEnabledChanged()

  if true then return end
  -- IMPORTANT --------------------------------------------------------------
  -- disable creator mode even if it is enabled in the settings
  ---------------------------------------------------------------------------

  if not settings then return end

  if settings.getValue('creatorMode') == true and not creatorModeHttpServer then
    -- start
    creatorModeHttpServer = require('utils/simpleHttpServer')
    creatorModeHttpServer.start(listenHost, httpListenPort, 'ui/entrypoints/creatormode', nil, function(req, path)
      return {
        httpPort = httpListenPort,
        wsPort = httpListenPort + 1,
        host = listenHost,
      }
    end)

    -- the websocket counterpart
    wsServer = require('libs/lua-websockets/websocket').server.copas.listen({
      interface = listenHost,
      port = httpListenPort + 1,
      protocols = {
        bngApi = bngApi_websocket_handler,
      },
      default = bngApi_websocket_handler,
    })

    -- open the URL in the browser
    openWebBrowser('http://' .. listenHost .. ':' .. tostring(httpListenPort) .. '/')

  elseif settings.getValue('creatorMode') == false and creatorModeHttpServer then
    -- stop
    creatorModeHttpServer.stop()
    creatorModeHttpServer = nil

    wsServer.close()
    wsServer = nil
  end
end

local function setupVehicleWs(vid)
  --print("getVehiclePort > " .. tostring(vid) .. ' , vehiclePorts = ' .. dumps(vehiclePorts) .. ' / nextVehiclePort = ' .. tostring(nextVehiclePort))
  -- assign a new port if required
  if not vehiclePorts[vid] then
    vehiclePorts[vid] = nextVehiclePort
    nextVehiclePort = nextVehiclePort + 1
    -- rotate the ports at some point ...
    if nextVehiclePort - httpListenPort > 1000 then
      nextVehiclePort = httpListenPort + 2
    end
    coroutine.resume(coroutine.create(function ()
      if not wsClientConnection then return end
      d.ok = true;
      d.id = -1;
      local res = jsonEncodeFull(d)
      wsClientConnection:send(res)
    end))
  end
  local v = scenetree.findObject(vid)
  if not v then return end
  -- start the websocket server inside the vehicle
  local luacmd = 'extensions.creatorMode.setup("' .. listenHost .. '",'..vehiclePorts[vid]..")"
  --print(">>>> " .. luacmd)
  v:queueLuaCommand(luacmd)

  return vehiclePorts[vid]
end

local function sendVehicles()
  local vehicles = {}
  local vehicleNames = scenetree.findClassObjects('BeamNGVehicle')
  local count = 0
  for _, name in ipairs(vehicleNames) do
    local veh = scenetree.findObject(name)
    if veh then
      local vid = veh:getID()
      vehicles[vid] = {
        jbeam = veh.JBeam,
        partconfig = veh.partConfig,
        licenseText = veh.licenseText,
        name = veh.name,
        port = setupVehicleWs(vid),
      }
      count = count + 1
    end
  end
  local res = { vehicles = vehicles, vehicleCount = count }
  --dump(res)
  messageBrowser({api='vehiclesChanged', data = res})
end

local function onUpdate()
  if not creatorModeHttpServer then return end

  copas.step(0)
  creatorModeHttpServer.update()

  if requestVehicleState > 0 then
    requestVehicleState = requestVehicleState - 1
    if requestVehicleState == 0 then
      sendVehicles()
    end
  end
end

local function sendVehiclesDelayed()
  requestVehicleState = 5
end

local function onVehicleSpawned(vid)
  if not creatorModeHttpServer then return end

  setupVehicleWs(vid)

  -- also send the changes to the UI
  sendVehiclesDelayed()
end

M.onUpdate = onUpdate

-- IMPORTANT: THIS IS COMPLETELY DISABLED
-- check if we need to enable/disable ourself
M.onExtensionLoaded = creatorModeEnabledChanged
M.onSettingsChanged = creatorModeEnabledChanged


M.requestVehicles = sendVehicles
M.onVehicleSpawned = onVehicleSpawned
M.onVehicleDestroyed = sendVehiclesDelayed

M.test = function() print('test') end
return M
