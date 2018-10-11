local M  = {}
local logTag = "commands.lua"
local mustSwitchBack = false

local function getGame()
  local game = scenetree.findObject("Game")
  if not game then
    log('E', logTag, 'Game object does not exist')
    return nil
  end
  return game
end

local function getCamera(game)
  if not game then
    log('E', logTag, 'need Game object to find Camera')
  end
  local camera = scenetree.findObjectById(game.camera)
  if not camera then
    log('E', logTag, 'Camera object does not exist')
    return nil
  end
  return camera
end

local function setGameCamera()
  TorqueScript.call("clearCameraRotationalSpeeds")
  local game = getGame()
  if not game then return end
  game:setCameraHandler(be:getPlayerVehicle(0))
end

local function setFreeCamera()
  TorqueScript.call("clearCameraRotationalSpeeds")
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  local veh = be:getPlayerVehicle(0)
  if veh then camera:setTransform(veh:getCameraTransform()) end
  game:setCameraHandler(camera.obj)
end

local function isFreeCamera(player)
  local veh = be:getPlayerVehicle(player)
  if not veh then return false end
  local game = getGame()
  if not game then return false end
  local cam = game:getCameraHandler()
  if not cam then return false end
  return cam:getType() ~= veh:getType()
end

local function changeCameraSpeed(val)
  local speed = tonumber(TorqueScript.getVar("$Camera::movementSpeed") or 1)
  local multiplier = 1 + math.abs(val)*0.2
  if val > 0 then speed = speed * multiplier end
  if val < 0 then speed = speed / multiplier end
  speed = math.max(2, math.min(100,speed))
  TorqueScript.setVar("$Camera::movementSpeed", speed)
  ui_message({txt="ui.camera.speed", context={speed=speed}}, 1, "cameraspeed")
end

local function onNodegrabStart()
  local game = getGame()
  if not game then return end
  mustSwitchBack = not isFreeCamera(0)
  if mustSwitchBack then
    setFreeCamera()
  end
end

local function onNodegrabStop()
  if mustSwitchBack then
    setGameCamera()
  end
  mustSwitchBack = false
end

local function dropCameraAtPlayer()
  setFreeCamera()
end

local function dropPlayerAtCamera()
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  local pos = camera:getPosition()
  local rot =  QuatF(0, 0, 1, 0) * camera:getRotation() -- vehicles forward are inverted
  --be:getPlayerVehicle(0):setPositionRotation(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w) -- this reset the vehicle :()
  be:getPlayerVehicle(0):setPosition(pos)
  setGameCamera()
end

local function toggleFirstPerson()
  --NOOP, do nothing for now, well reimplement properly one day
end

local function toggleCamera(player)
  player = 0 -- forcibly have multiseat users switch main camera instead of their own
  if be:getPlayerVehicle(player) then
    if isFreeCamera(player) then
      setGameCamera()
      extensions.core_camera.updateUIMessage(player)
      extensions.hook("onCameraToggled", {cameraType='GameCam'})      
    else
      setFreeCamera()
      ui_message("ui.camera.freecam",  10, "cameramode")
      extensions.hook("onCameraToggled", {cameraType='FreeCam'})      
    end
  end
end

local function setEditorCameraStandard()
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  camera:setFlyMode()
  camera.newtonMode = "1"
  camera.newtonRotation = "1"
  -- these should be the same as those in gameengine c++ camera.h declaration
  camera.angularForce = 400
  camera.angularDrag = 16
  -- IMPORTANT: if you touch this, modify camera.mass in editorgui.ed.cs too
  camera.mass = 1
  camera.drag = 17
  camera.force = 600
  game:setCameraHandler(camera.obj)
end

local function setEditorCameraNewton()
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  -- Switch to Newton Fly Mode without rotation damping
  camera:setFlyMode()
  camera.newtonMode = "1"
  camera.newtonRotation = "0"
  camera.angularForce = 100
  camera.angularDrag = 2
  camera.mass = 10
  camera.drag = 2
  camera.force = 500
  game:setCameraHandler(camera.obj)
end

local function setEditorCameraNewtonDamped()
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  --Switch to Newton Fly Mode with damped rotation
  camera:setFlyMode()
  camera.newtonMode = "1"
  camera.newtonRotation = "1"
  camera.angularForce = 100
  camera.angularDrag = 2
  camera.mass = 10
  camera.drag = 2
  camera.force = 500
  camera:setAngularVelocity(Point3F(0, 0, 0))
  game:setCameraHandler(camera.obj)
end

local function setEditorOrbitCamera()
  local game = getGame()
  if not game then return end
  local camera = getCamera(game)
  if not camera then return end
  camera:setEditOrbitMode()
  game:setCameraHandler(camera.obj)
end

local function getCameraTransformJson()
  local pos = getCameraPosition()
  local rot = getCameraQuat()
  return string.format('[%0.2f, %0.2f, %0.2f, %g, %g, %g, %g]', pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
end

local function setFreeCameraTransformJson(json)
  setFreeCamera()

  json = readJsonData(json, nil)
  if not json then return end

  setCameraPosRot(json[1], json[2], json[3], json[4], json[5], json[6], json[7])
end

M.dropCameraAtPlayer = dropCameraAtPlayer
M.dropPlayerAtCamera = dropPlayerAtCamera
M.getCamera = getCamera
M.getGame = getGame
M.onNodegrabStart = onNodegrabStart
M.onNodegrabStop = onNodegrabStop
M.setFreeCamera = setFreeCamera
M.setGameCamera = setGameCamera
M.setCameraFree = setFreeCamera -- retrocompat
M.setCameraPlayer = setGameCamera -- retrocompat
M.changeCameraSpeed = changeCameraSpeed
M.setEditorCameraNewton = setEditorCameraNewton
M.setEditorCameraNewtonDamped = setEditorCameraNewtonDamped
M.setEditorCameraStandard = setEditorCameraStandard
M.setEditorOrbitCamera = setEditorOrbitCamera
M.toggleCamera = toggleCamera
M.isFreeCamera = isFreeCamera
M.toggleFirstPerson = toggleFirstPerson
M.getCameraTransformJson = getCameraTransformJson
M.setFreeCameraTransformJson = setFreeCameraTransformJson

return M
