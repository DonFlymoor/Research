-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local settings = require("simplesettings")

local ffi = require("ffi")

local acos = math.acos
local max = math.max
local min = math.min
local abs = math.abs

local ip = nil
local port = nil

local updateTime = 0
local updateTimer = 0

local lastFrameData = nil
local udpSocket = nil

local hasDefinedV1Struct = false
local accX
local accY
local accZ
local accelerationSmoothingX
local accelerationSmoothingY
local accelerationSmoothingZ
local accXSmoother
local accYSmoother
local accZSmoother

local function sendDataPaketV1(dt)
  --log('D', 'motionSim', 'sendDataPaketV1: '..tostring(ip) .. ':' .. tostring(port))

  local o = ffi.new("motionSim_t")
  o.magic = "BNG1"

  local position = vec3(obj:getPosition())
  o.posX = position.x
  o.posY = position.y
  o.posZ = position.z

  local velocity = obj:getVelocity()
  o.velX = velocity.x
  o.velY = velocity.y
  o.velZ = velocity.z

  o.accX = accX
  o.accY = accY
  o.accZ = accZ

  local upVector = vec3(obj:getDirectionVectorUp())
  local vectorForward = vec3(obj:getDirectionVector())

  local quat = quatFromDir(vectorForward, upVector)
  local euler = quat:toEulerYXZ()

  o.upVecX = upVector.x
  o.upVecY = upVector.y
  o.upVecZ = upVector.z

  local rollRate = obj:getRollAngularVelocity()
  local pitchRate = obj:getPitchAngularVelocity()
  local yawRate = obj:getYawAngularVelocity()

  o.rollPos = -euler.z --negated angle here, seems like that is the "standard" for motion sims here
  o.pitchPos = -euler.y --negated angle here, seems like that is the "standard" for motion sims here
  o.yawPos = euler.x

  o.rollRate = rollRate
  o.pitchRate = pitchRate
  o.yawRate = yawRate

  o.rollAcc = (rollRate - lastFrameData.rollRate) / dt
  o.pitchAcc = (pitchRate - lastFrameData.pitchRate) / dt
  o.yawAcc = (yawRate - lastFrameData.yawRate) / dt

  lastFrameData.rollRate = rollRate
  lastFrameData.pitchRate = pitchRate
  lastFrameData.yawRate = yawRate

  -- if streams.willSend("profilingData") then
  --   gui.send(
  --     "profilingData",
  --     {
  --       --
  --       accX = {title = "Acc X", color = getContrastColorStringRGB(1), unit = "", value = o.accX},
  --       accY = {title = "Acc Y", color = getContrastColorStringRGB(2), unit = "", value = o.accY},
  --       accZ = {title = "Acc Z", color = getContrastColorStringRGB(3), unit = "", value = o.accZ}
  --     }
  --   )
  -- end

  --convert the struct into a string
  local packet = ffi.string(o, ffi.sizeof(o))

  --log("I", "motionSim.sendDataPaketV1", "Sending To: " .. ip .. "port: " .. port)
  udpSocket:sendto(packet, ip, port)
end

local function updateGFXV1(dt)
end

local function updateV1(dt)
  updateTimer = updateTimer + dt
  local accXRaw = -obj:getSensorX()
  local accYRaw = -obj:getSensorY()
  local accZRaw = -obj:getSensorZ()
  accX = accelerationSmoothingX > 0 and accXSmoother:get(accXRaw) or accXRaw
  accY = accelerationSmoothingY > 0 and accYSmoother:get(accYRaw) or accYRaw
  accZ = accelerationSmoothingZ > 0 and accZSmoother:get(accZRaw) or accZRaw

  if updateTimer >= updateTime then
    sendDataPaketV1(dt)
    updateTimer = 0
  end
end

local function resetV1()
  lastFrameData = {
    rollRate = 0,
    pitchRate = 0,
    yawRate = 0
  }

  accXSmoother:reset()
  accYSmoother:reset()
  accZSmoother:reset()
end

local function settingsChanged()
  M.init()
end

local function initV1()
  if not hasDefinedV1Struct then
    ffi.cdef [[
    typedef struct motionSim_t  {
      //Magic to check if packet is actually useful, fixed value of "BNG1"
      char           magic[4];

      //World position of the car
      float          posX;
      float          posY;
      float          posZ;

      //Velocity of the car
      float          velX;
      float          velY;
      float          velZ;

      //Acceleration of the car, gravity not included
      float          accX;
      float          accY;
      float          accZ;

      //Vector components of a vector pointing "up" relative to the car
      float          upVecX;
      float          upVecY;
      float          upVecZ;

      //Roll, pitch and yaw positions of the car
      float          rollPos;
      float          pitchPos;
      float          yawPos;

      //Roll, pitch and yaw "velocities" of the car
      float          rollRate;
      float          pitchRate;
      float          yawRate;

      //Roll, pitch and yaw "accelerations" of the car
      float          rollAcc;
      float          pitchAcc;
      float          yawAcc;
    } motionSim_t;
    ]]
    hasDefinedV1Struct = true
  end

  lastFrameData = {
    rollRate = 0,
    pitchRate = 0,
    yawRate = 0
  }

  ip = settings.getValue("motionSimIP") or "127.0.0.1"
  port = settings.getValue("motionSimPort") or 4444
  local updateRate = settings.getValue("motionSimHz") or 100
  updateTime = 1 / updateRate

  accelerationSmoothingX = settings.getValue("motionSimAccelerationSmoothingX") or 30
  accelerationSmoothingY = settings.getValue("motionSimAccelerationSmoothingY") or 30
  accelerationSmoothingZ = settings.getValue("motionSimAccelerationSmoothingZ") or 30
  accXSmoother = newExponentialSmoothing(accelerationSmoothingX)
  accYSmoother = newExponentialSmoothing(accelerationSmoothingY)
  accZSmoother = newExponentialSmoothing(accelerationSmoothingZ)

  log("I", "motionSim.initV1", string.format("MotionSim V1 active! IP config: %s:%d, update rate: %dhz", ip, port, updateRate))

  udpSocket = socket.udp()

  M.update = updateV1
  M.updateGFX = updateGFXV1
  M.reset = resetV1
end

local function init()
  M.reset = nop
  M.updateGFX = nop
  M.update = nop
  M.debugDraw = nop

  local isMotionSimEnabled = settings.getValue("motionSimEnabled") or false
  if isMotionSimEnabled then
    local motionSimVersion = settings.getValue("motionSimVersion") or 1
    log("I", "motionSim.init", "Trying to load motionSim with version: " .. motionSimVersion)
    if motionSimVersion == 1 then
      log("D", "motionSim.init", "MotionSim V1 active!")
      initV1()
    else
      log("E", "motionSim.init", "Unknown motionSim version: " .. motionSimVersion)
    end
  end
end

M.init = init
M.reset = nop
M.settingsChanged = settingsChanged

M.updateGFX = nop
M.update = nop
M.debugDraw = nop

return M
