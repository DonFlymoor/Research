local M = {}
local logTag = 'ResearchVE'

local socket = require('socket/socket')
local rcom = require('utils/researchCommunication')

local skt = nil
local clients = {}

local host = nil
local port = nil

local conSleep = 60

local sensorHandlers = {}

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

  rcom.sendACK(skt, 'Controlled')
end

sensorHandlers.GForces = function(msg)
  local resp = {type='GForces'}

  resp['gx'] = sensors.gx
  resp['gx2'] = sensors.gx2
  resp['gxMax'] = sensors.gxMax
  resp['gxMin'] = sensors.gxMin
  resp['gxSmoothMax'] = sensors.gxSmoothMax
  resp['gy'] = sensors.gy
  resp['gy2'] = sensors.gy2
  resp['gyMax'] = sensors.gyMax
  resp['gyMin'] = sensors.gyMin
  resp['gz'] = sensors.gz
  resp['gz2'] = sensors.gz2
  resp['gzMax'] = sensors.gzMax
  resp['gzMin'] = sensors.gzMin
  
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
  rcom.sendMessage(skt, response)
end

return M
