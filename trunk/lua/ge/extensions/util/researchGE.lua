local M = {}
local logTag = 'ResearchGE'
local version = 'v1.0'

local socket = require('socket/socket')
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

local loadNotified = false

local sensors = {}

local _log = log
local function log(level, message)
  _log(level, logTag, message)
end

local function checkMessage()
  local message = rcom.readMessage(clients)
  if message ~= nil then
    local msgType = message['type']
    if msgType ~= nil then
      msgType = 'handle' .. msgType
      local handler = M[msgType]
      if handler ~= nil then
        handler(message)
      end
    end
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
    if stepsLeft == 0 then
      rcom.sendACK(skt, 'Stepped')
    end
  end

  if stepsLeft == 0 then
    checkMessage()
  end
end

M.onClientPostStartMission = function()
  if loadNotified == false then
    rcom.sendACK(skt, 'MapLoaded')
    loadNotified = true
  end
end

M.onCountdownEnded = function()
  rcom.sendACK(skt, 'ScenarioStarted')
  loadNotified = false
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
end

-- Handlers

M.handleLoadScenario = function(msg)
  local scenarioPath = msg["path"]
  scenariosLoader.startByPath(scenarioPath)
end

M.handleStartScenario = function(msg)
  scenario_scenarios.changeState("running")
  -- scenario_scenarios.getScenario().showCountdown = false
  -- scenario_scenarios.getScenario().countDownTime = 0
  guihooks.trigger("ChangeState", "menu")
end

M.handleRestartScenario = function(msg)
  scenario_scenarios.restartScenario()
  rcom.sendACK(skt, 'ScenarioRestarted')
end

M.handleHideHUD = function(msg)
  be:executeJS('document.body.style.opacity = "0.0";')
end

M.handleShowHUD = function(msg)
  be:executeJS('document.body.style.opacity = "1.0";')
end

M.handleSetPhysicsDeterministic = function(msg)
  be:setPhysicsDeterministic(true)
  rcom.sendACK(skt, 'SetPhysicsDeterministic')
end

M.handleSetPhysicsNonDeterministic = function(msg)
  be:setPhysicsDeterministic(false)
  rcom.sendACK(skt, 'SetPhysicsNonDeterministic')
end

M.handleFPSLimit = function(msg)
  settings.setValue('FPSLimiter', msg['fps'], true)
  settings.setState({FPSLimiterEnabled = true}, true)
  rcom.sendACK(skt, 'SetFPSLimit')
end

M.handleRemoveFPSLimit = function(msg)
  settings.setState({FPSLimiterEnabled = false}, true)
  rcom.sendACK(skt, 'RemovedFPSLimit')
end

M.handlePause = function(msg)
  be:setPhysicsRunning(false)
  rcom.sendACK(skt, 'Paused')
end

M.handleResume = function(msg)
  be:setPhysicsRunning(true)
  rcom.sendACK(skt, 'Resumed')
end

M.handleStep = function(msg)
  local count = msg["count"] - 2
  be:physicsStep(count)
  stepsLeft = count
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
end

M.handleSetPositionRotation = function(msg)
  local pos = msg['pos']
  local rot = msg['rot']

  rot = quatFromDir(vec3(rot[1], rot[2], rot[3]))
  be:getPlayerVehicle(vehicleCursor):setPositionRotation(pos[1], pos[2], pos[3], rot.x, rot.y, rot.z, rot.w)

  rcom.sendACK(skt, 'VehicleMoved')
end

M.handleOpenShmem = function(msg)
  local name = msg['name']
  local size = msg['size']
  
  Engine.openShmem(name, size)
  
  rcom.sendACK(skt, 'OpenedShmem')
end

M.handleCloseShmem = function(msg)
  local name = msg['name']
  
  Engine.closeShmem(name)
  
  rcom.sendACK(skt, 'ClosedShmem')
end

sensors.Camera = function(req, callback)
  local pos, direction, rot, fov, resolution, nearFar, vehicle, vehicleObj, up, data
  local color, depth, annotation

  color = req['color']
  depth = req['depth']
  annotation = req['annotation']

  vehicle = scenarioHelper.getVehicleByName(req['vehicle'])
  vehicleObj = map.objects[vehicle:getID()]

  direction = req['direction']
  direction = vec3(direction[1], direction[2], direction[3])

  fov = math.rad(req['fov'])

  resolution = req['resolution']
  nearFar = req['near_far']

  up = vec3(vehicle:getDirectionVectorUp())
  rot = quatFromDir(direction, up) * quatFromDir(vec3(vehicle:getDirectionVector()))

  pos = req['pos']
  pos = vec3(pos[1], pos[2], pos[3])
  pos = vec3(vehicle:getPosition()) + rot * pos
  pos = Point3F(pos.x, pos.y, pos.z)

  rot = QuatF(rot.x, rot.y, rot.z, rot.w)
  resolution = Point2F(resolution[1], resolution[2])
  nearFar = Point2F(nearFar[1], nearFar[2])

  local data = Engine.renderCameraShmem(color, depth, annotation, pos, rot, resolution, fov, nearFar)

  callback(data)
end

sensors.Lidar = function(req, callback)
  local handle = req['shmem']
  local size = req['size']

  research.lidar.requestDataShmem(handle, size, function(realSize)
    callback({size = realSize})
  end)
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
end

M.handleGetDecalRoadVertices = function(msg)
  local response = Sim.getDecalRoadVertices()
  response = {type = "DecalRoadVertices", vertices = response}
  rcom.sendMessage(skt, response)
end

M.handleEngineFlags = function(msg)
  local flags = msg['flags']
  if flags['annotations'] then
    Engine.Annotation.enable(true)
  end

  if flags['lidar'] then
    research.lidar.enabled(true)
  end

  rcom.sendACK(skt, 'SetEngineFlags')
end

return M
