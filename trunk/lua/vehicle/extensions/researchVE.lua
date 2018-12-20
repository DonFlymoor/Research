local M = {}
local logTag = 'ResearchVE'

local socket = require('libs/luasocket/socket.socket')
local rcom = require('utils/researchCommunication')

local sensorHandlers = {}

local skt = nil
local clients = {}

local host = nil
local port = nil

local conSleep = 60

local _log = log
local function log(level, message)
  _log(level, logTag, message)
end

local function checkMessage()
  local message, err = rcom.readMessage(clients)
  if err ~= nil then
    skt = nil
    clients = {}
    conSleep = 60
    return
  end

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
  else
    log('I', 'Could not connect...')
  end
end

M.startConnecting = function(targetHost, targetPort)
  host = targetHost
  port = targetPort
end

M.onDebugDraw = function()
  if port ~= nil then
    if skt == nil then
      if conSleep <= 0 then
        conSleep = 60
        connect()
      else
        conSleep = conSleep - 1
      end
    end
  end

  if skt == nil then
    return
  end

  checkMessage()
end

-- Handlers

local function submitInput(inputs, key)
  local val = inputs[key]
  if val ~= nil then
    input.event(key, val, 1)
  end
end

M.handleControl = function(msg)
  submitInput(msg, 'throttle')
  submitInput(msg, 'steering')
  submitInput(msg, 'brake')
  submitInput(msg, 'parkingbrake')
  submitInput(msg, 'clutch')

  local gear = msg['gear']
  if gear ~= nil then
    drivetrain.shiftToGear(gear)
  end

  rcom.sendACK(skt, 'Controlled')
end

M.handleSetShiftMode = function(msg)
  drivetrain.setShifterMode(msg['mode'])
  rcom.sendACK(skt, 'ShiftModeSet')
end

sensorHandlers.GForces = function(msg)
  local resp = {type='GForces'}

  resp['gx'] = sensors.gx
  resp['gx2'] = sensors.gx2
  resp['gxSmoothMax'] = sensors.gxSmoothMax
  resp['gy'] = sensors.gy
  resp['gy2'] = sensors.gy2
  resp['gz'] = sensors.gz
  resp['gz2'] = sensors.gz2

  return resp
end

sensorHandlers.Electrics = function(msg)
  local resp = {type = 'Electrics'}
  resp['values'] = electrics.values
  return resp
end

sensorHandlers.Damage = function(msg)
  local resp = {type = 'Damage'}
  resp['damageExt'] = beamstate.damageExt
  resp['deformGroupDamage'] = beamstate.deformGroupDamage
  resp['lowpressure'] = beamstate.lowpressure
  resp['damage'] = beamstate.damage
  return resp
end

local function getVehicleState()
  local vehicleState = {
    pos = obj:getPosition(),
    dir = obj:getDirectionVector(),
    up = obj:getDirectionVectorUp(),
    vel = obj:getVelocity()
  }
  vehicleState['pos'] = {
    vehicleState['pos'].x,
    vehicleState['pos'].y,
    vehicleState['pos'].z
  }

  vehicleState['dir'] = {
    vehicleState['dir'].x,
    vehicleState['dir'].y,
    vehicleState['dir'].z
  }

  vehicleState['up'] = {
    vehicleState['up'].x,
    vehicleState['up'].y,
    vehicleState['up'].z
  }

  vehicleState['vel'] = {
    vehicleState['vel'].x,
    vehicleState['vel'].y,
    vehicleState['vel'].z
  }
  return vehicleState
end

local function getSensorData(request)
  local response, sensor_type, handler

  sensor_type = request['type']
  handler = sensorHandlers[sensor_type]
  if handler ~= nil then
    response = handler(request)
    return response
  end

  return nil
end

M.handleSensorRequest = function(msg)
  local request, response, data
  response = {}
  request = msg['sensors']
  for k, v in pairs(request) do
    data = getSensorData(v)
    if data == nil then
      log('E', 'Could not get data for sensor: ' .. k)
    end
    response[k] = data
  end

  response = {type = 'SensorData', data = response}
  response['state'] = getVehicleState()
  rcom.sendMessage(skt, response)
end

M.handleSetAiMode = function(msg)
  ai.setMode(msg['mode'])
  rcom.sendACK(skt, 'AiModeSet')
end

M.handleSetAiLine = function(msg)
  local nodes = msg['line']
  local fauxPath = {}
  local cling = msg['cling']
  local z = 0
  local speedList = {}
  for idx, n in ipairs(nodes) do
    local pos = vec3(n['pos'][1], n['pos'][2], 10000)
    if cling then
      z = obj:getSurfaceHeightBelow(pos:toFloat3())
    else
      z = n['pos'][3]
    end
    pos.z = z
    local fauxNode = {
      pos = pos,
      radius = 0,
      radiusOrig = 0,
    }
    table.insert(speedList, n['speed'])
    table.insert(fauxPath, fauxNode)
  end

  local arg = {
    script = fauxPath,
    wpSpeeds = speedList
  }

  ai.driveUsingPath(arg)
  rcom.sendACK(skt, 'AiLineSet')
end

M.handleSetAiSpeed = function(msg)
  ai.setSpeedMode(msg['mode'])
  ai.setSpeed(msg['speed'])
  rcom.sendACK(skt, 'AiSpeedSet')
end

M.handleSetAiTarget = function(msg)
  local targetName = msg['target']
  obj:queueGameEngineLua('scenetree.findObjectById(' .. obj:getID() .. '):queueLuaCommand("ai.setTargetObjectID(" .. scenetree.findObject(\'' .. targetName .. '\'):getID() .. ")")')
  rcom.sendACK(skt, 'AiTargetSet')
end

M.handleSetAiWaypoint = function(msg)
  local targetName = msg['target']
  ai.setTarget(targetName)
  rcom.sendACK(skt, 'AiWaypointSet')
end

M.handleSetAiSpan = function(msg)
  if msg['span'] then
    ai.spanMap(0)
  else
    ai.setMode('disabled')
  end
  rcom.sendACK(skt, 'AiSpanSet')
end

M.handleSetDriveInLane = function(msg)
  if msg['lane'] then
    ai.driveInLane('on')
  else
    ai.driveInLane('off')
  end
  rcom.sendACK(skt, 'AiDriveInLaneSet')
end

M.handleUpdateVehicle = function(msg)
  local response = {type = 'VehicleUpdate'}
  response['state'] = getVehicleState()
  rcom.sendMessage(skt, response)
  return true
end

return M
