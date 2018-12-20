-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'ResearchGE'
local version = 'v1.5'

local socket = require('libs/luasocket/socket.socket')
local rcom = require('utils/researchCommunication')

local scenariosLoader = require('scenario/scenariosLoader')
local scenarioHelper = require('scenario/scenariohelper')

local host = '127.0.0.1'
local port = 64256

local skt = nil
local clients = {}

local gameState = 'menu'

local conSleep = 1
local stepsLeft = 0
local stepACK = false

local loadNotified = false

local loadRequested = false
local startRequested = false
local restartRequested = false

local sensors = {}

local lidars = {}

local _log = log
local function log(level, message)
  _log(level, logTag, message)
end

local function checkMessage()
  local message, err = rcom.readMessage(clients)

  if err ~= nil then
    skt = nil
    clients = {}
    conSleep = 5
    return false
  end

  if message ~= nil then
    local msgType = message['type']
    if msgType ~= nil then
      msgType = 'handle' .. msgType
      local handler = M[msgType]
      if handler ~= nil then
        return handler(message)
      else
        return true
      end
    else
      return true
    end
  else
    return false
  end
end

local function connect()
  log('I', 'Trying to connect to: ' .. host .. ':' .. tostring(port))
  skt = socket.connect(host, port)
  if skt ~= nil then
    log('I', 'Connected!')
    table.insert(clients, skt)

    local hello = {type = 'Hello', version = version}
    rcom.sendMessage(skt, hello)
  else
    log('I', 'Could not connect...')
  end
end

M.onPreRender = function(dt)
  if skt == nil then
    if conSleep <= 0 then
      conSleep = 5
      connect()
    else
      conSleep = conSleep - dt
    end

    return
  end

  if stepsLeft > 0 then
    stepsLeft = stepsLeft - 1
    if stepsLeft == 0 and stepACK then
      rcom.sendACK(skt, 'Stepped')
    end
  end

  if stepsLeft == 0 then
    while checkMessage() do end
  end
end

M.onClientStartMission = function()
  if loadRequested and loadNotified == false then
    rcom.sendACK(skt, 'MapLoaded')
    loadNotified = true
    loadRequested = false
  end
end

M.onCountdownEnded = function()
  if startRequested then
    rcom.sendACK(skt, 'ScenarioStarted')
    loadNotified = false
    startRequested = false
  end
end

M.onScenarioRestarted = function()
  if restartRequested then
    M.handleStartScenario(nil)
    rcom.sendACK(skt, 'ScenarioRestarted')
    restartRequested = false
  end
end

M.onInit = function()
  local cmdArgs = Engine.getStartingArgs()
  for i, v in ipairs(cmdArgs) do
    if v == "-rport" then
      port = tonumber(cmdArgs[i + 1])
    end

    if v == "-rhost" then
      host = cmdArgs[i + 1]
    end
  end

  settings.setValue('uiUnits', 'metric')
  settings.setValue('uiUnitLength', 'metric')
  settings.setValue('uiUnitTemperature', 'c')
  settings.setValue('uiUnitWeight', 'kg')
  settings.setValue('uiUnitTorque', 'metric')
  settings.setValue('uiUnitConsumptionRate', 'metric')
  settings.setValue('uiUnitEnergy', 'metric')
  settings.setValue('uiUnitDate', 'iso')
  settings.setValue('uiUnitPower', 'hp')
  settings.setValue('uiUnitVolume', 'l')
  settings.setValue('uiUnitPressure', 'bar')
end

-- Handlers

M.handleLoadScenario = function(msg)
  local scenarioPath = msg["path"]
  scenariosLoader.startByPath(scenarioPath)
  loadRequested = true
  return false
end

M.handleStartScenario = function(msg)
  scenario_scenarios.changeState("running")
  scenario_scenarios.getScenario().showCountdown = false
  scenario_scenarios.getScenario().countDownTime = 0
  guihooks.trigger("ChangeState", "menu")
  startRequested = true
  return true
end

M.handleRestartScenario = function(msg)
  scenario_scenarios.restartScenario()
  restartRequested = true
  return false
end

M.handleHideHUD = function(msg)
  be:executeJS('document.body.style.opacity = "0.0";')
  return true
end

M.handleShowHUD = function(msg)
  be:executeJS('document.body.style.opacity = "1.0";')
  return true
end

M.handleSetPhysicsDeterministic = function(msg)
  be:setPhysicsSpeedFactor(1)
  be:setPhysicsDeterministic(true)
  rcom.sendACK(skt, 'SetPhysicsDeterministic')
  return true
end

M.handleSetPhysicsNonDeterministic = function(msg)
  be:setPhysicsSpeedFactor(1)
  be:setPhysicsDeterministic(false)
  rcom.sendACK(skt, 'SetPhysicsNonDeterministic')
  return true
end

M.handleFPSLimit = function(msg)
  settings.setValue('FPSLimiter', msg['fps'], true)
  settings.setState({FPSLimiterEnabled = true}, true)
  rcom.sendACK(skt, 'SetFPSLimit')
  return true
end

M.handleRemoveFPSLimit = function(msg)
  settings.setState({FPSLimiterEnabled = false}, true)
  rcom.sendACK(skt, 'RemovedFPSLimit')
  return true
end

M.handlePause = function(msg)
  be:setPhysicsRunning(false)
  rcom.sendACK(skt, 'Paused')
  return true
end

M.handleResume = function(msg)
  be:setPhysicsRunning(true)
  rcom.sendACK(skt, 'Resumed')
  return true
end

M.handleStep = function(msg)
  local count = msg["count"]
  be:physicsStep(count)
  stepsLeft = count
  stepACK = msg["ack"]
  return true
end

M.handleVehicleConnection = function(msg)
  local vID, vHost, vPort, veh, command

  vID = msg['vid']
  vHost = msg['host']
  vPort = msg['port']

  command = 'extensions.load("researchVE")'
  veh = scenarioHelper.getVehicleByName(vID)
  veh:queueLuaCommand(command)

  command = 'researchVE.startConnecting("' .. vHost .. '", '
  command = command .. tostring(vPort) .. ')'
  veh:queueLuaCommand(command)
  return true
end

M.handleSetPositionRotation = function(msg)
  local pos = msg['pos']
  local rot = msg['rot']

  rot = quatFromDir(vec3(rot[1], rot[2], rot[3]))
  be:getPlayerVehicle(vehicleCursor):setPositionRotation(pos[1], pos[2], pos[3], rot.x, rot.y, rot.z, rot.w)

  rcom.sendACK(skt, 'VehicleMoved')
  return true
end

M.handleOpenShmem = function(msg)
  local name = msg['name']
  local size = msg['size']

  Engine.openShmem(name, size)

  rcom.sendACK(skt, 'OpenedShmem')
  return true
end

M.handleCloseShmem = function(msg)
  local name = msg['name']

  Engine.closeShmem(name)

  rcom.sendACK(skt, 'ClosedShmem')
  return true
end

sensors.Camera = function(req, callback)
  local offset, orientation, up
  local pos, direction, rot, fov, resolution, nearFar, vehicle, vehicleObj, data
  local color, depth, annotation

  color = req['color']
  depth = req['depth']
  annotation = req['annotation']

  if req['vehicle'] then
    vehicle = scenarioHelper.getVehicleByName(req['vehicle'])
    orientation = vec3(vehicle:getDirectionVector())
    up = vec3(vehicle:getDirectionVectorUp())
    orientation = quatFromDir(orientation, up)

    offset = vec3(vehicle:getPosition())
  else
    orientation = quatFromEuler(0, 0, 0)
    offset = vec3(0, 0, 0)
    up = vec3(0, 0, 1)
  end

  direction = req['direction']
  direction = vec3(direction[1], direction[2], direction[3])

  fov = math.rad(req['fov'])

  resolution = req['resolution']
  nearFar = req['near_far']

  rot = quatFromDir(direction, up) * orientation

  pos = req['pos']
  pos = vec3(pos[1], pos[2], pos[3])
  if req['vehicle'] then
    pos = offset + rot * pos
  else
    pos = offset + pos
  end
  pos = Point3F(pos.x, pos.y, pos.z)

  rot = QuatF(rot.x, rot.y, rot.z, rot.w)
  resolution = Point2F(resolution[1], resolution[2])
  nearFar = Point2F(nearFar[1], nearFar[2])

  local data = Engine.renderCameraShmem(color, depth, annotation, pos, rot, resolution, fov, nearFar)

  callback(data)
end

sensors.Lidar = function(req, callback)
  local name = req['name']
  local lidar = lidars[name]
  if lidar ~= nil then
    lidar:requestDataShmem(function(realSize)
      callback({size = realSize})
    end)
  else
    callback(nil)
  end
end

local function getSensorData(request, callback)
  local response, sensor_type, handler
  sensor_type = request['type']
  handler = sensors[sensor_type]
  if handler ~= nil then
    handler(request, callback)
  else
    callback(nil)
  end
end

local function getNextSensorData(requests, response, callback)
  local key = next(requests)
  if key == nil then
    callback(response)
    return
  end

  local request = requests[key]
  requests[key] = nil

  local cb = function(data)
    response[key] = data
    getNextSensorData(requests, response, callback)
  end

  getSensorData(request, cb)
end

M.handleSensorRequest = function(msg)
  local requests

  local cb = function(response)
    response = {type = 'SensorData', data = response}
    rcom.sendMessage(skt, response)
  end

  requests = msg['sensors']

  getNextSensorData(requests, {}, cb)
  return true
end

M.handleGetDecalRoadVertices = function(msg)
  local response = Sim.getDecalRoadVertices()
  response = {type = "DecalRoadVertices", vertices = response}
  rcom.sendMessage(skt, response)
  return true
end

M.handleEngineFlags = function(msg)
  log('I', 'Setting engine flags!')
  local flags = msg['flags']
  if flags['annotations'] then
    Engine.Annotation.enable(true)
  end

  rcom.sendACK(skt, 'SetEngineFlags')
  return true
end

local function getVehicleState(vid)
  local vehicle = scenetree.findObject(vid)
  local state = {
    pos = vehicle:getPosition(),
    dir = vehicle:getDirectionVector(),
    up = vehicle:getDirectionVectorUp(),
    vel = vehicle:getVelocity()
  }
  state['pos'] = {
    state['pos'].x,
    state['pos'].y,
    state['pos'].z
  }

  state['dir'] = {
    state['dir'].x,
    state['dir'].y,
    state['dir'].z
  }

  state['up'] = {
    state['up'].x,
    state['up'].y,
    state['up'].z
  }

  state['vel'] = {
    state['vel'].x,
    state['vel'].y,
    state['vel'].z
  }
  return state
end

M.handleUpdateScenario = function(msg)
  local response = {type = 'ScenarioUpdate'}
  local vehicleStates = {}
  for idx, vid in ipairs(msg['vehicles']) do
    vehicleStates[vid] = getVehicleState(vid)
  end
  response['vehicles'] = vehicleStates

  rcom.sendMessage(skt, response)
  return true
end

M.handleOpenLidar = function(msg)
  log('I', 'Opening lidar!')
  local name = msg['name']
  local shmem = msg['shmem']
  local shmemSize = msg['size']
  local vid = msg['vid']
  local vid = scenetree.findObject(vid):getID()
  local vRes = msg['vRes']
  local vAngle = math.rad(msg['vAngle'])
  local rps = msg['rps']
  local hz = msg['hz']
  local angle = math.rad(msg['angle'])
  local maxDist = msg['maxDist']
  local offset = msg['offset']
  offset = Point3F(offset[1], offset[2], offset[3])
  local direction = msg['direction']
  direction = Point3F(direction[1], direction[2], direction[3])

  local lidar = research.LIDAR(vid, offset, direction, vRes, vAngle, rps, hz, angle, maxDist)
  lidar:open(shmem, shmemSize)
  lidar:enabled(true)
  lidars[name] = lidar

  rcom.sendACK(skt, 'OpenedLidar')
  return true
end

M.handleCloseLidar = function(msg)
  local name = msg['name']
  local lidar = lidars[name]
  if lidar ~= nil then
    lidar.close()
    lidars[name] = nil
  end
  rcom.sendACK(skt, 'ClosedLidar')
  return true
end

M.handleGameStateRequest = function(msg)
  local state = core_gamestate.state.state
  resp = {type = 'GameState'}
  if state == 'scenario' then
    resp['state'] = 'scenario'
    resp['scenario_state'] = scenario_scenarios.getScenario().state
  else
    resp['state'] = 'menu'
  end
  rcom.sendMessage(skt, resp)
  return true
end

return M
