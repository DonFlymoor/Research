-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- filters
local autozoom = require('core/cameraModes/autozoom')
local autopoint = require('core/cameraModes/autopoint')
local handheld = require('core/cameraModes/handheld')
local noise = require('core/cameraModes/noise')
local smooth = require('core/cameraModes/smooth')
local predictor = require('core/cameraModes/predictor')

local C = {}
C.__index = C

local p = hptimer()

local function dumpsi(...)
  return dumps({...}):gsub("\n", " ")
end

function C:init()
  self.now = 0 -- timekeeping (cannot use a countdown since the countdown will randomly change over time)
  self.tvModeOdds = settings.getValue('cameraFanVsTV') or 0.1
  self.isFanMode = true
  self.offsetPeriod = 1
  self.lastOffset = self.now

  -- vehicle position
  self.lastCarPos = vec3()

  -- last camera position in world coords
  self.camPos = vec3(0,0,2)
  self.lastCamPos = vec3(0,0,2)

  -- camera panning effect
  self.camVel = vec3(0,0,0)
  self.panningSpeedFactor = settings.getValue('cameraTVSpeed') or 1

  -- camera switch triggers:
  -- * teleporting
  self.teleportingSpeed = 1000/3.6 -- in m/s, threshold to detect teleport with F7 / recovery / reset / replay seeking
  -- * time
  self.camChangeTimeMin = 1.5 -- never switch cam faster than this, no matter what
  self.camChangeTimeBase = 6 -- randomization base for timeMax:
  self.camChangeTimeMax = self.camChangeTimeBase -- never keep the same camera for longer than this. will be a bit randomized after each cam change
  self.lastCamChangeTime = -self.camChangeTimeMax -- used to decide when it's been too long in the same camera. will be a bit randomized after each cam change
  -- car is going away from the camera (compared to initial distance from cam)
  self.initialDistance = 100000
  -- * vehicle not visible by camera
  self.camVisibilityCheckPeriod = 0.5 -- in seconds, how often to check if car is occluded by an object
  self.lastVisibilityCheckTime = self.now

  -- filters
  self.autozoom = autozoom()
  self.autopoint = autopoint()
  self.autopoint.refNodes = self.refNodes
  self.noise = noise()
  self.noise:init(0.14)
  self.smooth = smooth()
  self.smooth:init(20, 2.0)
  self.handheld = handheld()
  self.predictor = predictor()
end

function C:setRefNodes(centerNodeID, leftNodeID, backNodeID)
  self.refNodes.ref = centerNodeID
  self.refNodes.left = leftNodeID
  self.refNodes.back = backNodeID
  self.autopoint:setRefNodes(centerNodeID, leftNodeID, backNodeID)
end

-- generate a random value between deadzone and max. if centered is true, values may have negative sign
local function dzRandom(deadzone, max, centered)
  local result = math.random() -- o .. 1
  if centered then
    -- [-max..-deadzone][+deadzone..+max]
    result = (max-deadzone) * (2*result-1)
    if result < 0 then result = result - deadzone
    else               result = result + deadzone end
  else
    -- [+deadzone..+max]
    result = (max-deadzone) * result + deadzone
  end
  return result
end
function C:onVehicleResetted(...)
  return true
end
-- switch to a new camera
function C:reset()
  self.lastCamChangeTime = -self.camChangeTimeMax*2
  self.lastVisibilityCheckTime = self.now
end
local function findNewOffset(veh)
  -- locate a good vehicle node position for the camera to track
  local spawnAABBRadius = veh:getSpawnAABBRadius()
  for tries=1,10 do
    local node = math.random(0, veh:getNodeCount()-1)
    local offset = vec3(veh:getNodePosition(node))
    local worldSpeed = vec3(veh:getNodeVelocity(node))
    if worldSpeed:length() > 5/3.6 or offset:length() < spawnAABBRadius then -- avoid fallen nodes
      return vec3(offset)
    end
  end
  return nil -- give up after some tries
end
function C:switchCamera(carPos, futureCarPos, velLength, chancesMultiplier, carStopped)
  -- chancesMultiplier starts at 1, decreasing towards 0
  -- choose a new camera position near this future car position
  local forwardVector = (futureCarPos - carPos):normalized()
  local    sideVector = forwardVector:cross(vec3(0,0,1)):normalized()
  local      upVector = (carPos - futureCarPos):cross(sideVector):normalized()
  local minSideDist = 1.2 * chancesMultiplier*chancesMultiplier
  local    sideDist = dzRandom(minSideDist, minSideDist+math.min(20, velLength*chancesMultiplier), true) -- further away the faster you go, but never too far
  local   minUpDist = 0.2 * chancesMultiplier
  local      upDist = dzRandom(minUpDist, minUpDist+math.max(3,math.min(10,velLength*chancesMultiplier)), false) * math.random() -- random height distance, closer to the ground when going slow, never too far
  self.camPos = futureCarPos + sideVector*sideDist + upVector*upDist

  -- randomize camera panning effect. bias it towards X axis, so camera rolls together with vehicle (or opposed to it)
  if self.isFanMode then
    self.camVel = vec3(0,0,0)
  else
    local lonSpeed = (velLength/2) * (2*math.random() - (carStopped and 1 or 0.1))
    local minSideVel = minSideDist / 20
    local minUpVel = minUpDist / 8
    local panningLocal = vec3(
        dzRandom(minSideVel, minSideVel + math.min(2,velLength*chancesMultiplier/20), true), --side
        -math.min(5, lonSpeed),   -- longitudinal
        dzRandom(minUpVel, minUpVel + math.min(1,velLength*chancesMultiplier/40), true))  -- up
    panningLocal.z = math.max(panningLocal.z, (upDist - 0.1) / self.camChangeTimeMax) -- make sure camera won't trespass the road surface parallel to vehicle speed
    panningLocal = self.panningSpeedFactor * panningLocal -- slow down or speed up according to user preferences
    self.camVel = axisSystemApply({sideVector, -forwardVector, upVector}, panningLocal) -- speed coords to world coords
  end
end
function C:update(data)
  data.dt = data.dtSim -- switch to physics dt, to respect time scaling
  if data.dt < 0.00001 then
    -- safe assign for avoid nils if external camera never finished an update before
    data.res.pos = self.pos or data.res.pos
    data.res.rot = self.rot or data.res.rot
    data.res.fov = self.fov or data.res.fov
    return
  end

  -- if car moved way too fast, reset smoothers and trigger a switch of camera
  local vehicleTeleported = (data.pos - self.lastCarPos):length()/data.dt > self.teleportingSpeed
  local cameraTeleported = (self.lastCamPos - self.camPos):length()/data.dt > self.teleportingSpeed
  self.lastCamPos = self.camPos

  -- right after a reset, we initialize the stuff that requires vehicle data
  if vehicleTeleported or self.now == 0 then
    self:init()
    self.lastCarPos = data.pos
  end
  if cameraTeleported or self.now == 0 then
    self.autozoom.mustReset = true
    self.handheld.mustReset = true
  end

  -- position
  local carPos = data.pos
  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))
  local nx = (left-ref):normalized()
  local ny = (back-ref):normalized()
  local nz = nx:cross(ny):normalized()
  -- smooth speed
  local vel = (carPos - self.lastCarPos)/data.dt
  self.lastCarPos = carPos
  local carStopped = vel:length() < 0.5
  local mustOffset = (self.now - self.lastOffset) > self.offsetPeriod
  if mustOffset then
    self.lastOffset = self.now
    if self.isFanMode then
      if carStopped then
        self.offsetPeriod = dzRandom(1, 5)
        self.autopoint:setSpring(1, 0.7)
      else
        self.offsetPeriod = dzRandom(0.2, 1.5)
        self.autopoint:setSpring(100, 5)
      end
    else
      if carStopped then
        self.offsetPeriod = dzRandom(2, 3)
        self.autopoint:setSpring(0.1, 0.5)
      else
        self.offsetPeriod = dzRandom(0.5, 1.5)
        self.autopoint:setSpring(2, 1.3)
      end
    end
    local offset = findNewOffset(data.veh) -- distance to current vehicle center
    if offset then offset = vec3(offset:dot(nx), offset:dot(ny), offset:dot(nz)) end -- from world axis system to vehicle axis system
    self.autopoint.localOffset = offset or self.autopoint.localOffset -- in local vehicle coordinates
  end

  -- check if we should switch to a new camera
  local minTimeElapsed = (self.now - self.lastCamChangeTime) >= self.camChangeTimeMin -- prevent confusing fast cam switches
  local tooLong = (self.now - self.lastCamChangeTime) >= self.camChangeTimeMax -- don't keep any one camera for boringly long
  local minDistance = math.max(30, self.initialDistance)
  local goingAway = (carPos - self.camPos):length() > minDistance -- if car is going far away from camera
  local justStarted = self.now == 0
  local mustCheckVisibility = (self.now - self.lastVisibilityCheckTime) > self.camVisibilityCheckPeriod
  local visibleNow = true
  if mustCheckVisibility then
    self.lastVisibilityCheckTime = self.now
    visibleNow = 0 == be:castRay(self.camPos:toPoint3F(), carPos:toPoint3F())
  end
  local shouldSwitchCamera = minTimeElapsed and (justStarted or tooLong or not visibleNow or goingAway)
  if shouldSwitchCamera then
    -- update camera reference data
    self.lastCamChangeTime = self.now

    -- try to find a new camera position that shows the car along its predicted future path (without occlusions)
    local maxAttempts = 40
    local attemptsLeft = maxAttempts
    local acc = 0
    while true do
      self.isFanMode = math.random() > self.tvModeOdds
      local z = dzRandom(0.4, 1.4)
      if self.isFanMode then
        self.autozoom:init(newTemporalSmoothing(15, 15))
        self.autozoom.steps = { {  0, z*120}, {1.5, z*80}, {  3, z*30}, {  6, z*30}, { 10, z*20}, { 40, z*10}, { 90, z*10}, {150, z*10} }
      else
        self.autozoom:init(newTemporalSpring(15, 10))
        self.autozoom.steps = { {  0, z*120}, {1.5, z*90}, {  3, z*70}, {  8, z*50}, { 20, z*20}, { 50, z*10}, {125, z* 4}, {200, z* 2} }
      end
      -- the more attempts, the less we restrict our search
      local chancesMultiplier = attemptsLeft/maxAttempts
      chancesMultiplier = chancesMultiplier * chancesMultiplier -- restrict spawn area faster, so we can find a solution faster
      attemptsLeft = attemptsLeft - 1

      -- randomize next camera spawn times, so the camera-change timing pattern isn't sooo obvious
      self.camChangeTimeMax = self.camChangeTimeBase * dzRandom(0.7, 0.7+0.6*chancesMultiplier) + (carStopped and 2 or 0)

      -- generate a random speed vector when car is parked, to avoid low speed jittering in random weird directions (including under ground)
      if carStopped then
        vel.x = dzRandom(0.5   , 2, true)
        vel.y = dzRandom(0.5   , 2, true)
        vel.z = 0
        vel = axisSystemApply({nx, ny, nz}, vel) -- speed coords to world coords
        self.autozoom.steps = { {  0, 120}, {1.5, 100}, {  3,  70}, {  6,  50}, { 10,  20}, { 40,  12}, { 90,   4}, {150,   2} }
      end

      -- predict the vehicle position by the time the cam changes again
      local carPosMidway = carPos + vel*chancesMultiplier * self.camChangeTimeMax*0.5
      -- check if the driving path is clear
      local obstaclesInPath = 0 ~= be:castRay(carPos:toPoint3F(), carPosMidway:toPoint3F())
      if obstaclesInPath then
        -- car will go through the map. assume it's just an upcoming slope
        local distTravel = (carPosMidway - carPos):length()
        local slopeOffset = vec3(0,0,distTravel*0.35)
        local newCarPosLast = carPosMidway + slopeOffset
        -- see if our assumption is right and we can rise our head above the ground
        local distToGround = be:castRay(carPosMidway:toPoint3F(), newCarPosLast:toPoint3F())
        if distToGround ~= 0 then
          -- yep, it's probably a slope, let's move the vehicle prediction right above the ground
          newCarPosLast = carPosMidway + vec3(0,0,distToGround + 0.1)
          -- check if the path is clear (to prevent spawning on roofs after an uphill)
          local obstaclesInPath = 0 ~= be:castRay(carPos:toPoint3F(), (newCarPosLast + vec3(0, 0, 1)):toPoint3F()) -- we add a meter in this check because right at the ground we'll probably not see the car immediately, it may take a second to appear if there's a crest
          if not obstaclesInPath then
            -- the slope prediction looks good, let's run with it
            carPosMidway = newCarPosLast
          end
        end
      end
      local carPosEnd = carPosMidway + (carPosMidway - carPos)

      -- attempt to place the camera halfway to the predicted car destination
      self:switchCamera(carPos, carPosMidway, vel:length(), chancesMultiplier, carStopped)
      -- handheld camera should be at human height above ground, try to correct that
      if self.isFanMode then
        local heightTest = 50
        local humanCameraHeight = dzRandom(1.3, 2.0)
        local distDown = be:castRay(self.camPos:toPoint3F(), (self.camPos-vec3(0,0,heightTest)):toPoint3F())
        if distDown == 0 or distDown == heightTest then -- we may be underground
          local distUp = heightTest-be:castRay((self.camPos+vec3(0,0,heightTest)):toPoint3F(), self.camPos:toPoint3F())
          if distUp == 0 or distUp == heightTest then -- we are too far over the ground, default to current vehicle height
            self.camPos.z = self.camPos.z +          humanCameraHeight
          else
            self.camPos.z = self.camPos.z + distUp + humanCameraHeight
          end
        else
          self.camPos.z = self.camPos.z - distDown + humanCameraHeight
         end
      end

      -- guesstimate future cam positions several points along changeTime, 3 positions in total, according to panning speed
      local camPosEnd  = self.camPos + self.camVel * self.camChangeTimeMax*1.0

      -- verify if we can & will see, and if the camera path is clean
      p:stopAndReset()
      if carStopped then
        carPosMidway = carPos
        carPosEnd = carPos
      end
      self.initialDistance = (carPosEnd - carPos):length() / 2
      if  0 == be:castRay(self.camPos:toPoint3F(), carPos:toPoint3F())   -- is car visible now
      and 0 == be:castRay(carPos:toPoint3F(), self.camPos:toPoint3F())   -- is cam visible now
      and 0 == be:castRay(camPosEnd:toPoint3F(),carPosEnd:toPoint3F())  -- is car visible at the end
      and 0 == be:castRay(carPosEnd:toPoint3F(),camPosEnd:toPoint3F())  -- is cam visible at the end
      and 0 == be:castRay(self.camPos:toPoint3F(), camPosEnd:toPoint3F())  -- can camera travel
      then
        acc = acc + p:stopAndReset()
        break -- yay, found a good camera
      end
      acc = acc + p:stopAndReset()
      if attemptsLeft == 0 then break end -- tough luck, we'll just use whatever we have by now
    end
    --log("I", "", "Chose new camera in attempts: "..dumps(maxAttempts-attemptsLeft).." ("..dumps(round(acc*10)/10).." ms), "..dumpsi(fails)..", time: "..dumps(self.camChangeTimeMax))
    if self.isFanMode then
      self.predictor.future = dzRandom(0.05,0.25)
      if carStopped then
        self.handheld:init(20, 5, 2)
        self.noise:init(0.02)
      else
        self.handheld:init(dzRandom(30,50), dzRandom(7,9), dzRandom(0.25, 0.7))
        self.noise:init(0.08)
      end
    else
      self.handheld:init(80, 15, 0.05)
      self.predictor.future = dzRandom(0.05,0.35)
    end
    self.smooth:init(nil, nil, self.camPos)
    local offset = findNewOffset(data.veh) -- distance to current vehicle center
    if offset then offset = vec3(offset:dot(nx), offset:dot(ny), offset:dot(nz)) end -- from world axis system to vehicle axis system
    self.autopoint.localOffset = offset or self.autopoint.localOffset -- in local vehicle coordinates
  end
  -- apply panning effect
  self.camPos = self.camPos + self.camVel * data.dt

  -- car debug
  --debugDrawer:drawSphere((carPos+vec3(0,0,2)):toPoint3F(), 0.5, ColorF(1,0,0,0.5)) -- car position
  --debugDrawer:drawSphere(carPos:toPoint3F(), 0.3, ColorF(1,0,0,1.0))
  --debugDrawer:drawCylinder(carPos:toPoint3F(), carPosEnd:toPoint3F(), 0.1, ColorF(1,0,0,0.1)) -- predicted car path
  --debugDrawer:drawSphere(carPosEnd:toPoint3F(), 0.3, ColorF(1,0,0,0.3))
  --debugDrawer:drawSphere((carPos+vel):toPoint3F(), 0.5, ColorF(0,1,0,0.5)) -- speed
  -- camera debug
  --debugDrawer:drawCylinder(self.camPos:toPoint3F(), self.camPos:toPoint3F(), 0.05, ColorF(1,1,1,0.8)) -- cam position
  --debugDrawer:drawSphere(self.camPos:toPoint3F(), 0.1, ColorF(0,0,1,0.2))
  --debugDrawer:drawCylinder(self.camPos:toPoint3F(), camPosEnd:toPoint3F(), 0.02, ColorF(0,0,1,0.3))
  --debugDrawer:drawSphere(camPosEnd:toPoint3F(), 0.1, ColorF(0,0,1,0.2))

  -- update clock
  self.now = self.now + data.dt

  -- fill the function return values (position, direction, etc)
  data.res.pos = self.camPos
  self.predictor:update(data)
  self.autozoom:update(data)
  self.autopoint:update(data)
  if self.isFanMode then
    self.noise:update(data)
    self.smooth:update(data)
  end
  self.handheld:update(data)

  -- save in case we are paused with dt==0 and cannot compute this stuff anymore
  self.pos = data.res.pos
  self.rot = data.res.rot
  self.fov = data.res.fov
  return true
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
