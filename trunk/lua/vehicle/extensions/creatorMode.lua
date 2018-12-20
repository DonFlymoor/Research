-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local copas = require("copas")
local json = require("json")
local jsonEncodeFull = require('libs/lunajson/lunajson').encode() -- slow but conform encoder

local cachedLogs = {}

local wsServer = nil -- websocket
local wsClient = nil

local port
local host


local function sendLogEntries(logs)
  local co = coroutine.create(function()
    local d = {
      api = 'log',
      ok = true,
      id = -1,
      data = logs
    }
    wsClient:send(jsonEncodeFull(d))
  end)
  coroutine.resume(co)
end

local function logSink(...)
  if wsClient then
    sendLogEntries({{...}})
  else
    table.insert(cachedLogs, {...})
  end
end

local function bngApi_websocket_handler(ws)
  wsClient = ws
  while true do
  ::retry::
    local req = ws:receive()
    if not req then
      break
    end
    print('>> bngApi_handler got: ' .. dumps(req))
    req = json.decode(req)
    if not req or not req.api then
      ws:send(jsonEncode({ok=false}))
      goto retry
    end

    if req.api == 'vehicleLua' then
      print(obj:getID() .. ' - executing code: ' .. tostring(req.cmd))
      local res, stdOut = executeLuaSandboxed(req.cmd, 'VehicleCreatorMode')
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
  wsClient = nil
  ws:close()
end


local function setup(_host, _port)
  local settingsChanged = host ~=_host or port ~= _port
  host = _host
  port = _port
  if wsServer and settingsChanged then
    close()
  end
  if not wsServer then
      log('D', 'creatormode', 'object ' .. tostring(obj:getID()) .. ' starting WS server: ' .. tostring(host) .. ":" .. tostring(port))
      wsServer = require('libs/lua-websockets/websocket').server.copas.listen({
        interface = host,
        port = port,
        protocols = {
          bngApi = bngApi_websocket_handler,
        },
        default = bngApi_websocket_handler,
      })
  end
end

local function close ()
  if not wsServer then return end

  wsServer.close()
  wsServer = nil
end

local function updateGFX(dt)
  if wsClient and #cachedLogs > 0 then
    -- send log cache now and empty it as well
    sendLogEntries(cachedLogs)
    cachedLogs = {}
  end
  copas.step(0)
end

-- starts caching log messages
local function onExtensionLoaded()
  log_jbeam = logSink
end

M.updateGFX = updateGFX
M.setup = setup
M.onExtensionLoaded = onExtensionLoaded
M.close = close
return M
