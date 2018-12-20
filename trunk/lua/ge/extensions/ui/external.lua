local M = {}

local logTag = 'externalUI'

local jsonEncodeFull = require('libs/lunajson/lunajson').encode() -- slow but conform encoder
local copas = require('libs/copas/copas')
local guihooks = require('guihooks')

-- ref to the different servers
local servers = {http = nil, ws = nil, vehicles = {}}
local activeVehicle = nil

-- ws = information about the state of the sockets (ie updates on vehicles sockets / sockets will be closed and do not reopen etc)
-- tunnel = socket to tunnel all execution / data requests through (will be used by gameApi)
-- beamng = information usually contained in the beamng variable (version of the game, build etc)
local clients = {wsStatus = {}, cmdTunnel = {}}
local ctrs = {wsStatus = 0, cmdTunnel = 0}

local httpListenPort = 16719 -- this is the initial port
local nextVehiclePort = httpListenPort + 2
local maxVehicles = 1000 -- number of vehicles that can be spawned at the same time wihout having a websocket conflict
local listenHost = '127.0.0.1' -- DO NOT set this to anything other than localhost. the webserver is not meant to do this.


local function isServerRunning ()
  -- assume that if the http server is running the websockets are as well or at least in the process of spinning up
  return servers.http ~= nil
end

local function getVehicles ()
  local vehicles = {}
  local vehicleNames = scenetree.findClassObjects('BeamNGVehicle')
  for _, name in ipairs(vehicleNames) do
    local veh = scenetree.findObject(name)
    if veh then
      local vid = veh:getID()
      table.insert(vehicles, vid)
    end
  end
  local current = nil
  if be and be:getPlayerVehicle(0) then
    current = be:getPlayerVehicle(0):getID()
  end
  return vehicles, current
end


local function send (protocol, msg)
  coroutine.resume(coroutine.create(function ()
    if tableSize(clients[protocol]) == 0 then return end
    local d = tableMerge({ok = true, id = -1}, msg)
    local res = jsonEncodeFull(d)
    -- print('sending')
    -- dump(d)
    for key in pairs(clients[protocol]) do
      clients[protocol][key]:send(res)
    end
  end))
end


local function loop (ws, actionTable, pref)
  local ctr = ctrs[pref]
  clients[pref][ctr] = ws
  ctrs[pref] = ctrs[pref] + 1

  while 1 do
    local req = ws:receive()
    if not req then
      coroutine.yield()
      return
    end

    if req and req == 'close' then
      clients[ctr] = nil
      break
    end

    req = json.decode(req)
    if req and req.action then
      -- print('=====')
      -- print('Req:')
      -- dump(req)
      if actionTable[req.action] ~=nil then
        if req.id == nil then
          req.id = -1
        end
        local res = {ok = true, id=req.id, action=req.action}
        res = tableMerge(res, actionTable[req.action](req))
        -- print('res: ')
        -- print(jsonEncodeFull(res))
        -- TODO: send this only to the current websocket or broadcast it to every socket anyway?
        -- pros of the latter: less overlaping requests, con: how to deal with the id?
        ws:send(jsonEncodeFull(res))
      else
        ws:send(jsonEncodeFull({ok=false, error='unknown_request', request = req}))
      end
    else
      ws:send(jsonEncodeFull({ok=false, error='no_action', request = req}))
    end
  end
end

local function vehicleWs ()
  return {ports = servers.vehicles, active = activeVehicle}
end

local function wsStatus_handler(ws)
  log('D', logTag, 'new wsStatus connection')
  local actions = {
    vehicleWsInfo = function (req)
      return {payload = vehicleWs()}
    end,
    buildInfo = function (req)
      return {payload = {}} -- TODO: implement this
    end
  }
  loop(ws, actions, 'wsStatus')
end

local function cmdTunnel_handler(ws)
  log('D', logTag, 'new cmdTunnel connection')
  local actions = {
    engineScript = function (req)
      return {payload = TorqueScript.eval(req.cmd)}
    end,
    engineLua = function (req)
      local res, stdOut = executeLuaSandboxed(req.cmd, 'GECreatorMode')
      return {payload = res, stdOut = stdOut}
    end,
    rawEngineLua = function (req)
      local res, stdOut = executeLuaSandboxed(req.cmd, 'GECreatorMode')
      return {payload = {res = res, stdOut = stdOut, cmd = req.cmd}}
    end,
    activeObject = function (req)
      print('activeObject', req)
      return {payload = {}} -- TODO: implement this
    end,
    allObjects = function (req)
      print('allObjects', req)
      return {payload = {}} -- TODO: implement this
    end,
  }
  loop(ws, actions, 'cmdTunnel')
end


local function closeHttpServer ()
  log('D', logTag, 'closing http server')
  if not servers.http then return end
  servers.http.stop()
  servers.http = nil
end

local function startHttpServer ()
  log('D', logTag, 'starting http server')
  servers.http = require('utils/simpleHttpServer')
  servers.http.start(listenHost, httpListenPort, '', nil, function(req, path)
    return {
      httpPort = httpListenPort,
      wsPort = httpListenPort + 1,
      host = listenHost,
    }
  end)
end

local function sendToVehicle (id, cmd)
  v = scenetree.findObject(id)
  if not v then return end
  v:queueLuaCommand(cmd)
end

local function closeWebsockets ()
  log('D', logTag, 'closing websockets')
  if servers.ws then
    servers.ws.close()
    servers.ws = nil
  end

  local veh, _ = getVehicles()
  for _, id in ipairs(veh) do
    if servers.vehicles[id] then
      sendToVehicle(id, 'extensions.externalUI.close()')
    end
  end
end

local function guihookToExternal (type, msg)
  if not isServerRunning() then return end
  send('cmdTunnel', {action = type, id=-1, payload = msg})
end

local function startWebsockets ()
  if not servers.ws then
    log('D', logTag, 'starting primary websocket')
    servers.ws = require('libs/lua-websockets/websocket').server.copas.listen({
      interface = listenHost,
      port = httpListenPort + 1,
      protocols = {
        wsStatus = wsStatus_handler,
        cmdTunnel = cmdTunnel_handler
      },
      default = wsStatus_handler,
    })
  end

  local veh
  veh, activeVehicle = getVehicles()
  log('D', logTag, 'telling vehicles to also start their websockets')
  for _, id in ipairs(veh) do
    if not servers.vehicles[id] then
      local v = scenetree.findObject(id)
      if not v then return end

      servers.vehicles[id] = nextVehiclePort
      nextVehiclePort = nextVehiclePort + 1
      -- start from the beginning if we ancountered a threshold
      if nextVehiclePort - httpListenPort > maxVehicles then
        nextVehiclePort = httpListenPort + 2
      end


      local luacmd = 'extensions.externalUI.setup("' .. listenHost .. '",' ..servers.vehicles[id].. ')'
      v:queueLuaCommand(luacmd)
    end
  end

  guihooks.updateListener(logTag, guihookToExternal)

  log('D', logTag, tableSize(servers.vehicles) .. ' of max ' .. maxVehicles .. ' vehicles connected')
end

local function closeEverything ()
  guihooks.updateListener(logTag, nil)
  log('D', logTag, 'telling all conencted externals to close and not expect the game to come up again')
  -- send to clients, that the connections will not come up again / that most of them can be closed except maybe status on, which might want to try reconnecting
  send('wsStatus', {action = 'closeAll'})
  -- then close everything
  closeHttpServer()
  closeWebsockets()
end


local function checkExternalUIEnabled ()
  if not settings then return end

  local shouldBeRunning = settings.getValue('externalUi')
  local isRunning = isServerRunning()
  log('D', logTag, 'check externalUI enabled, (should be:' .. tostring(shouldBeRunning) .. ', is:' ..  tostring(isRunning) .. ')')
  if shouldBeRunning and not isRunning then
    startHttpServer()
    startWebsockets()
  elseif not shouldBeRunning and isRunning then
    closeEverything()
  end
end

local function openCreatorMode ()
  openWebBrowser('http://' .. listenHost .. ':' .. tostring(httpListenPort) .. '/ui/entrypoints/creatormode/')
end

local function onUpdate ()
  if not isServerRunning() then return end

  copas.step(0)
  servers.http.update()
end

local function vehicleStateChanged ()
  if isServerRunning() then
    -- close old vehicles' ws
    local vh
    vh, activeVehicle = getVehicles()
    for id, port in ipairs(servers.vehicles) do
      if not tableContains(vh, id) then
        sendToVehicle(id, 'extensions.externalUI.close()')
        servers.vehicles[id] = nil
      end
    end

    -- create new ws
    startWebsockets()

    -- tell external ui about it
    send('wsStatus', {action = 'vehicleWsInfo', payload = vehicleWs()})
  end
end


M.onUpdate = onUpdate
M.onSettingsChanged = checkExternalUIEnabled
M.onExtensionLoaded = checkExternalUIEnabled
M.onExtensionUnloaded = closeEverything

M.openCreatorMode = openCreatorMode

M.onVehicleSpawned = vehicleStateChanged
M.onVehicleDestroyed = vehicleStateChanged
return M