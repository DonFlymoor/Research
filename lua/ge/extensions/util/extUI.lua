-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local copas = require('copas')

local uiWebServer = nil
local wsServer = nil -- websocket
local wsClientConnection = nil -- websocket client Conn
local wsAvailable = false -- bool if socket is available. this is needed, because messages might be send when wsServer var is set, but not runnign yet

local encodeJsonFull = require('jsonEncoderFull')() -- slow but conform encoder

local requestVehicleState = 0

local httpListenPort = 16409 -- this is the initial port
local nextVehiclePort = httpListenPort + 2
local listenHost = '0.0.0.0' -- DO NOT set this to anything other than localhost. the webserver is not meant to do this.

local vehiclePorts = {}

local jsBeamng = {}

local function messageBrowser(d)
  coroutine.resume(coroutine.create(function ()
    if not wsAvailable then return end
    d.ok = true;
    d.id = -1;
    local res = encodeJsonFull(d)
    wsClientConnection:send(res)
  end))
end

local function bngApi_websocket_handler(ws)
  wsClientConnection = ws
  while 1 do
    local req = ws:receive()
    if not req then
      coroutine.yield()
      return
    end
    print('>> bngApi_handler got: ' .. dumps(req))
    req = json.decode(req)
    if not req or not req.api then
      ws:send(encodeJson({ok=false}))
      return
    end

    if req.api == 'engineLua' then
      --print('executing code: ' .. tostring(req.cmd))
      local res, stdOut = executeLuaSandboxed(req.cmd, 'GECreatorMode')
      if req.id ~= -1 then
        -- -1 == global request, no return requested
        --print('result = ' .. dumps(res))
        local res = encodeJsonFull({ok = true, id=req.id, api=req.api, result=res, stdOut=stdOut, cmd=req.cmd})
        ws:send(res)
      end
    elseif req.api == 'engineScript' then
      TorqueScript.eval(req.cmd)
    elseif req.api == 'beamngVar' then
      -- todo think about doing this without js, so we could potentially show no ui in the game when the external ui is loaded
      local res = encodeJsonFull({ok = true, id=req.id, api=req.api, data=jsBeamng, stdOut=stdOut, cmd=req.cmd})
      dump(res)
      ws:send(res)
    else
      print("unknown API: "..tostring(req.api))
      ws:send(encodeJson({ok=false, error='unknown_api'}))
    end
  end
  print(">>> DONE")
  --ws:close()
end


local function creatorModeEnabledChanged()
  if not settings then return end

  if settings.getValue('externalUi') == true and not uiWebServer then
    -- start
    uiWebServer = require('simpleHttpServer')
    uiWebServer.start(listenHost, httpListenPort, '/', nil, function(req, path)
      return {
        httpPort = httpListenPort,
        wsPort = httpListenPort + 1,
        host = listenHost,
      }
    end)
    print('created http server')

    -- the websocket counterpart
    wsServer = require('websocket').server.copas.listen({
      interface = listenHost,
      port = httpListenPort + 1,
      protocols = {
        bngApi = bngApi_websocket_handler,
      },
      default = bngApi_websocket_handler,
    })

    print('created websocket')

    wsAvailable = true;
  elseif settings.getValue('externalUi') == false and uiWebServer then
    -- stop
    uiWebServer.stop()
    uiWebServer = nil

    wsServer.close()
    wsServer = nil
    wsAvailable = false;
  end
end


local function onUpdate()
  if not uiWebServer then return end

  copas.step(0)
  uiWebServer.update()

  -- if requestVehicleState > 0 then
  --   requestVehicleState = requestVehicleState - 1
  --   if requestVehicleState == 0 then
  --     sendVehicles()
  --   end
  -- end
end

local function triggerHookInWs (data)
  messageBrowser({api = 'jsHook', data = data})
end

local function updateStreamInWs (data)
  messageBrowser({api = 'streamData', data = data})
end

local function onVehicleSpawned(vid)
  if not uiWebServer then return end

  setupVehicleWs(vid)

  -- also send the changes to the UI
  sendVehiclesDelayed()
end

local function storeBeamng (b)
  jsBeamng = b
  messageBrowser({api = 'beamngVar', data = b})
end

M.onUpdate = onUpdate

-- check if we need to enable/disable ourself
M.onExtensionLoaded = creatorModeEnabledChanged
M.onSettingsChanged = creatorModeEnabledChanged

M.hookTriggered = triggerHookInWs
M.streamUpdate = updateStreamInWs

M.setUiInfo = storeBeamng

return M
