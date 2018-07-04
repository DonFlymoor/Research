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

local handlers = {}

local frame = 0

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
  local line, err = c:receive()
  if err then
    log("E", "Error whilst reading from socket: " .. tostring(error))
  end
  
  if line ~= nil then
    log("D", "Got data from socket: '" .. line .. "'")
  end
  return line
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
  be:getPlayerVehicle(0):queueLuaCommand(command)
  
  vehicleSetup = true
end

local function requestVehicleInput(key)
  local command = "obj:queueGameEngineLua('lastVehicleState." .. key .. " = ' .. input.state." .. key .. ".val)"
  local v = be:getPlayerVehicle(0)
  if v then
    be:getPlayerVehicle(0):queueLuaCommand(command)
  end
end

local function requestVehicleDrivetrain(key)
  local command = "obj:queueGameEngineLua('lastVehicleState." .. key .. " = ' .. drivetrain." .. key .. ")"
  local v = be:getPlayerVehicle(0)
  if v then
    be:getPlayerVehicle(0):queueLuaCommand(command)
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
  be:getPlayerVehicle(0):queueLuaCommand(command)
end

local function issueVehicleInput(key, val)
  if key == 'gear' then
    issueShiftToGear(val)
  else
    local command = "input.event('" .. key .. "', " .. val .. ", 1)"
    be:getPlayerVehicle(0):queueLuaCommand(command)
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
  table.insert(clientsRead, connection)
  table.insert(clientsWrite, connection)
  log("I", "Connected!")
end

local function send(data)
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
  
  local vdata = map.objects[be:getPlayerVehicle(0):getID()]
  state.pos = vdata.pos:toTable()
  state.vel = vdata.vel:toTable()
  state.dir = vdata.dirVec:toTable()
  local dir = vdata.dirVec:normalized()
  state.rot = math.deg(math.atan2(dir:dot(vec3(1, 0, 0)), dir:dot(vec3(0, -1, 0))))
  
  state.view = Engine.getColorBufferBase64(width, height)
  return state
end

local function onInit()
  if connection == nil then
    log("I", "Starting Research adapter...")
    connect()
  end
end

local function handleVControl(msg)
  log("D", "Got a VeControl message from the server. Issuing vehicle inputs.")
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

local function handleSocketInput()
  local message = readSocketMessage()
  if message ~= nil then
    log("I", "Got server message: " .. message)
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
  requestVehicleData()
  handleSocketInput()
end

local function onClientPostStartMission()
  local state = {type = "MapLoaded"}
  send(state)
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
handlers.handleStartScenario = handleStartScenario
handlers.handleRelativeCamera = handleRelativeCamera

M.onInit = onInit
M.onUpdate = onUpdate
M.onClientPostStartMission = onClientPostStartMission
M.onCountdownEnded = onCountdownEnded

return M
