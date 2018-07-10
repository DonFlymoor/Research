local M = {}
local logTag = "Research"

local mp = require "MessagePack"
local socket = require("socket.socket")

local scenariosLoader = require("scenario/scenariosLoader")

local host = "127.0.0.1" -- Should be synchronised with server settings somehow
local port = 64256

local connection = nil
local clientsRead = {}
local clientsWrite = {}

local gameState = "menu"

local vehicleSetup = false
local vehicleCursor = 0

local handlers = {}

local frame = 0

local conSleep = 1

lastVehicleState = {
  steering = 0,
  throttle = 0,
  brake = 0,
  parkingbrake = 0,
  clutch = 0,
  gear = 0
}

local _log = log
local function log(level, message)
  _log(level, logTag, message)
end

local function receive(c)
  local length, err = c:receive()
  local data, err = c:receive(tonumber(length))
  
  if err then
    log("E", "Error whilst reading from socket: " .. tostring(error))
    return nil
  end
  
  return data
end

local function readSocketMessage()
  local read = nil
  local write = nil
  local _ = nil
  read, write, _ = socket.select(clientsRead, clientsWrite, 0)
  
  local message = nil
  
  for _, c in ipairs(read) do
    if write[c] == nil then
      goto continue
    end
    
    c:settimeout(0.1, "t")
    
    message = receive(c)
    
    ::continue::
  end
  
  return message
end

local function setupVehicle()
  local command = "controller.mainController.setGearboxMode('realistic')"
  be:getPlayerVehicle(vehicleCursor):queueLuaCommand(command)
  
  vehicleSetup = true
end

local function requestVehicleInput(key)
  local command = "obj:queueGameEngineLua('lastVehicleState." .. key .. " = ' .. input.state." .. key .. ".val)"
  local v = be:getPlayerVehicle(vehicleCursor)
  if v then
    be:getPlayerVehicle(vehicleCursor):queueLuaCommand(command)
  end
end

local function requestVehicleDrivetrain(key)
  local command = "obj:queueGameEngineLua('lastVehicleState." .. key .. " = ' .. drivetrain." .. key .. ")"
  local v = be:getPlayerVehicle(vehicleCursor)
  if v then
    be:getPlayerVehicle(vehicleCursor):queueLuaCommand(command)
  end
end

local function requestVehicleData()
  requestVehicleInput("steering")
  requestVehicleInput("throttle")
  requestVehicleInput("brake")
  requestVehicleInput("parkingbrake")
  requestVehicleInput("clutch")
  
  requestVehicleDrivetrain("gear")
end

local function issueShiftToGear(val)
  local command = "drivetrain.shiftToGear(" .. val .. ")"
  be:getPlayerVehicle(vehicleCursor):queueLuaCommand(command)
end

local function issueVehicleInput(key, val)
  if key == 'gear' then
    issueShiftToGear(val)
  else
    local command = "input.event('" .. key .. "', " .. val .. ", 1)"
    be:getPlayerVehicle(vehicleCursor):queueLuaCommand(command)
  end
end

local function issueVehicleInputs(inputs)
  for k, v in pairs(inputs) do
    issueVehicleInput(k, v)
  end
end

local function connect()
  log("I", "Connecting to research server (" .. host .. ", " .. tostring(port) .. ")")
  connection = socket.connect(host, port)
  if connection ~= nil then
    table.insert(clientsRead, connection)
    table.insert(clientsWrite, connection)
    log("I", "Connected!")
    return true
  end
  
  return false
end

local function send(data)
  if connection == nil then
    return
  end
  
  local mpac = mp.pack(data)
  connection:send(mpac)
end

local function sendVehicleState(vstate)
  vstate["type"] = "VehicleState"
  send(vstate)
end

local function sendGameStateChange(gstate)
  gstate = {gameState = gstate}
  gstate["type"] = "GameStateChange"
  send(gstate)
end

local function getVehicleState(width, height)
  local state = {}
  state.type = "VehicleState"
  
  state.steering = lastVehicleState.steering
  state.throttle = lastVehicleState.throttle
  state.brake = lastVehicleState.brake
  state.clutch = lastVehicleState.clutch
  state.parkingbrake = lastVehicleState.parkingbrake
  state.gear = lastVehicleState.gear
  
  local vdata = map.objects[be:getPlayerVehicle(vehicleCursor):getID()]
  state.pos = vdata.pos:toTable()
  state.vel = vdata.vel:toTable()
  state.dir = vdata.dirVec:toTable()
  local dir = vdata.dirVec:normalized()
  state.rot = math.deg(math.atan2(dir:dot(vec3(1, 0, 0)), dir:dot(vec3(0, -1, 0))))
  
  state.view = Engine.getColorBufferBase64(width, height)
  return state
end

local function handleVControl(msg)
  log("D", "Got a VControl message from the server. Issuing vehicle inputs.")
  issueVehicleInputs(msg["inputs"])
end

local function getScreenResolution()
  local resolution = settings.getValue('GraphicResolutions')
  local ret = {}
  for val in string.gmatch(resolution, "%S+") do
    table.insert(ret, tonumber(val))
  end
  return ret
end

local function getWidthFor(height)
  local resolution = getScreenResolution()
  local ratio = resolution[1] / resolution[2]
  return math.floor(height * ratio)
end

local function getHeightFor(width)
  local resolution = getScreenResolution()
  local ratio = resolution[2] / resolution[1]
  return math.floor(width * ratio)
end

local function handleReqVState(msg)
  local width = msg["width"]
  local height = msg["height"]
  if width == nil then
    width = getWidthFor(height)
  end
  if height == nil then
    height = getHeightFor(width)
  end
  
  local state = getVehicleState(width, height)
  sendVehicleState(state)
end

local function handleLoadScenario(msg)
  local scenarioPath = msg["path"]
  scenariosLoader.startByPath(scenarioPath)
end

local function handleStartScenario(msg)
  scenario_scenarios.changeState("running")
  guihooks.trigger("ChangeState", "menu")
end

local function handleRestartScenario(msg)
  scenario_scenarios.restartScenario()
  
  local state = {type = "ScenarioRestarted"}
  send(state)
end

local function handleRelativeCamera(msg)
  local pos = vec3(msg['pos'][1], msg['pos'][2], msg['pos'][3])
  local rot = vec3(msg['rot'][1], msg['rot'][2], msg['rot'][3])
  local fov = msg['fov']
  
  core_camera.setByName(0, 'relative')
  core_camera.proxy_Player('setupRelative', pos, rot, fov)
end

local function handleHideHUD(msg)
  be:executeJS('document.body.style.opacity = "0.0";')
end

local function handleShowHUD(msg)
  be:executeJS('document.body.style.opacity = "1.0";')
end

local function handlePause(msg)
  bullettime.pause(true)
  
  local state = {type = "Paused"}
  send(state)
end

local function handleResume(msg)
  bullettime.pause(false)
  
  local state = {type = "Resumed"}
  send(state)
end

local function handleVehicleCursor(msg)
  local newCursor = msg["cursor"]
  log("I", "Switching vehicle cursor to: " .. tostring(newCursor))
  vehicleCursor = newCursor
  local state = {type = "VehicleCursor", cursor = vehicleCursor}
  send(state)
end

local function handleSocketInput()
  local message = readSocketMessage()
  if message ~= nil then
    message = mp.unpack(message)
    local msgType = message["type"]
    if msgType ~= nil then
      msgType = "handle" .. msgType
      local handler = handlers[msgType]
      if handler ~= nil then
        handler(message)
      end
    end
  end
end

local function onUpdate(dt)
  if connection == nil then
    if conSleep <= 0 then
      log("I", "Trying to connect...")
      if not connect() then
        conSleep = 5
      end
    else
      conSleep = conSleep - dt
    end
    
    return
  end
  
  requestVehicleData()
  handleSocketInput()
end

local function onClientPostStartMission()
  local state = {type = "MapLoaded"}
  send(state)
end

local function onScenarioRestarted()
end

local function onCountdownEnded()
  local state = {type = "ScenarioStarted"}
  setupVehicle()
  send(state)
end

handlers.handleHello = handleHello
handlers.handlePause = handlePause
handlers.handleResume = handleResume
handlers.handleHideHUD = handleHideHUD
handlers.handleShowHUD = handleShowHUD
handlers.handleVControl = handleVControl
handlers.handleReqVState = handleReqVState
handlers.handleLoadScenario = handleLoadScenario
handlers.handleVehicleCursor = handleVehicleCursor
handlers.handleStartScenario = handleStartScenario
handlers.handleRestartScenario = handleRestartScenario
handlers.handleRelativeCamera = handleRelativeCamera

M.onTick = onTick
M.onUpdate = onUpdate
M.onClientPostStartMission = onClientPostStartMission
M.onCountdownEnded = onCountdownEnded
M.onScenarioRestarted = onScenarioRestarted

return M
