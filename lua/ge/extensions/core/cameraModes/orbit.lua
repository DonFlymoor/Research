-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- ORBIT CAMERA

local C = {}
C.__index = C
local vecUp = vec3(0,0,1)

local function getRot(base, vf, vz)
    local nyn = vf:normalized()
    local nxn = nyn:cross(vz):projectToOriginPlane(vecUp):normalized()
    local nzn = nxn:cross(nyn):normalized()
    local nbase = base:normalized()
    return math.atan2(-nbase:dot(nxn), nbase:dot(nyn)), math.asin(nbase:dot(nzn))
end

function C:init()
  if self.defaultRotation == nil then
    self.defaultRotation = vec3(0, -17, 0)
  end
  self.target = false
  self.defaultRotation = vec3(self.defaultRotation)
  self.offset = vec3(self.offset)
  self.camRot = vec3(self.defaultRotation)
  self.camLastRot = vec3(math.rad(self.camRot.x), math.rad(self.camRot.y), 0)
  self.camMinDist = self.distanceMin or 3
  self.camDist = self.distance or 5
  self.camLastDist = self.distance or 5
  self.defaultDistance = self.distance or 5
  self.camLastTargetPos = vec3()
  self.camLastPos = vec3()
  self.camLastPos2 = vec3()
  self.camLastPosPerp = vec3()
  self.camVel = vec3()
  self.mode = self.mode or 'ref'
  self.fov = self.fov or 65
  self.cameraResetted = 3
  self.lockCamera = false
  self.orbitOffset = vec3()
  self.smoothingEnabled = settings.getValue('cameraOrbitSmoothing', true)
  self.preResetPos = vec3(1e+300, 0, 0)
  self.lastTargetSpeed = 0

  self.targetCenter = vec3(0, 0, 0)
  self.targetLeft = vec3(0, 0, 0)
  self.targetBack = vec3(0, 0, 0)

  self:reloaded()
end

function C:reset()
  self.camBase = nil
  if self.cameraResetted == 0 then
    self.preResetPos = self.camLastTargetPos
    -- if a reload hasn't just happened
    self.camRot = vec3(self.defaultRotation)
    self.cameraResetted = 3
    self.camDist = self.defaultDistance
    -- for some reason this fixes things sometimes :|
    MoveManager.pitchUpSpeed = 0
    MoveManager.pitchDownSpeed = 0
    MoveManager.yawLeftSpeed = 0
    MoveManager.yawRightSpeed = 0
    self.lockCamera = false
  end
end

function C:reloaded()
  -- if a reset countdown is NOT already happening
  -- make sure this gets recalculated by invalidating it
  MoveManager.pitchUpSpeed = 0
  MoveManager.pitchDownSpeed = 0
  MoveManager.yawLeftSpeed = 0
  MoveManager.yawRightSpeed = 0
  -- global fov tuning
  self.fov = self.fov + settings.getValue('cameraFOVTune') or 0
  self.fov = math.min(150, math.max(1, self.fov))
  self.relaxation = settings.getValue('cameraOrbitRelaxation') or 3
  self.maxDynamicFov = settings.getValue('cameraOrbitMaxDynamicFov') or 35
  self.smoothingEnabled = settings.getValue('cameraOrbitSmoothing', true)
end

function C:lookback()
  if self.camRot.x > 0 then
    self.camRot.x = 0
  else
    self.camRot.x = 180
  end
end

function C:setRotation(rot)
  self.camRot = vec3(rot)
end

function C:setFOV(fov)
  self.fov = fov
end

function C:setOffset(v)
  self.orbitOffset = vec3(v)
end

function C:setRefNodes(centerNodeID, leftNodeID, backNodeID, dynamicFovRearNodeID)
  self.refNodes.ref = centerNodeID
  self.refNodes.left = leftNodeID
  self.refNodes.back = backNodeID
  self.rearNodeID = dynamicFovRearNodeID -- specifies which area of the vehicle will have constant screen-size during dolly zoom effect (dynamic FOV effect)
end

-- params in global coords
function C:setRef(center, left, back)
  self.target = true
  self.targetCenter = center
  self.targetLeft = left
  self.targetBack = back
end

function C:setTargetMode(targetMode, camBase)
  self.mode = targetMode
  self.camBase = camBase
end

function C:setDefaultDistance(d)
  self.defaultDistance = d
end

function C:setDistance(d)
  self.camDist = d
end

function C:setMaxDistance(d)
  self.camMaxDist = d
end


function C:update(data)
  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))

  if self.target then
    ref = self.targetCenter
    left = self.targetLeft
    back = self.targetBack
  end

  -- calculate the camera offset: rotate with the vehicle
  local nx = left - ref
  local ny = back - ref
  local nz = nx:cross(ny):normalized()
  ny = nx:cross(-nz):normalized() * ny:length()

  local targetPos
  if not self.camBase then
    -- this needs to happen here as on init the node data is not existing yet
    if self.offset and self.offset.x and nx:length() ~= 0 and ny:length() ~= 0 then
      self.camBase = vec3(self.offset.x / nx:length(), self.offset.y / ny:length(), self.offset.z / nz:length())
      self.camOffset2 = nx * self.camBase.x + ny * self.camBase.y + nz * self.camBase.z
      targetPos = data.pos + ref + self.camOffset2
    elseif self.camOffset2 then
      targetPos = data.pos + ref + self.camOffset2
      self.camOffset2 = nil -- we only use previous offset for only one frame when needed
    else
      targetPos = vec3(data.veh:getBBCenter()) - (data.pos + ref)
    end
  else
    self.camOffset2 = nx * self.camBase.x + ny * self.camBase.y + nz * self.camBase.z
    targetPos = data.pos + ref + self.camOffset2
  end
  -- print((self.camLastTargetPos - targetPos):length() / (data.dtSim+ 1e-30))

  local yawDif = MoveManager.yawLeftSpeed - MoveManager.yawRightSpeed
  local pitchDif = MoveManager.pitchUpSpeed - MoveManager.pitchDownSpeed

  if self.lockCamera == true then
    local camdir = self.camLastTargetPos - self.camLastPos2
    if sign((targetPos - self.camLastTargetPos):dot(camdir)) < 0 then
      self.camRot.x = self.camRot.x + 180
      self.camLastRot.x = self.camLastRot.x + math.pi
      self.camLastPos2 = targetPos + camdir
      self.camLastPosPerp = vecUp:cross(camdir):normalized() * (self.relaxation * -0.8) + targetPos
    end
  end

  local dir = vec3(0,1,0)
  if self.cameraResetted == 1 then
    if self.mode ~= 'center' then
      dir = ref - back
      if (targetPos - self.preResetPos):length() < 14 then
        local rx, ry = getRot((targetPos - self.camLastPos), dir, nz)
        self.camLastRot.x = rx
        self.camLastRot.y = ry
        self.camRot.x = 0
      else
        self.camRot = vec3(self.defaultRotation)
        self.camLastRot = vec3(math.rad(self.camRot.x), math.rad(self.camRot.y) * 1.5, 0)
      end
      self.camLastPos2 = targetPos - dir
      dir = dir:normalized()
    end
  end

  if math.abs(yawDif) > 0.01 and self.cameraResetted == 0 then
    self.lockCamera = true
  end

  local maxRot = 4.5
  if (math.abs(yawDif) + math.abs(pitchDif) + math.abs(BeamEngine.camX) + math.abs(BeamEngine.camY) > 0) then
    maxRot = 1000
  end

  -- debugDrawer:drawSphere(self.camLastPos2:toPoint3F(), 1, ColorF(1,1,0,0.3))
  local dtfactor = data.dt * 1000
  self.camRot.x = self.camRot.x - fsign(BeamEngine.camX) * math.min(math.abs(BeamEngine.camX * 10), maxRot * data.dt) - yawDif * dtfactor
  self.camRot.y = self.camRot.y - fsign(BeamEngine.camY) * math.min(math.abs(BeamEngine.camY * 10), maxRot * data.dt) - pitchDif * dtfactor
  --self.camRot.z = self.camRot.z +  MoveManager.roll  * 10.0f + (MoveManager.rollLeftSpeed - MoveManager.rollRightSpeed) * (data.dt * 300)

  self.camRot.y = math.min(math.max(self.camRot.y, -85), 85)

  -- make sure the rotation is never bigger than 2 PI
  if self.camRot.x > 180 then
    self.camRot.x = self.camRot.x - 360
  elseif self.camRot.x < -180 then
    self.camRot.x = self.camRot.x + 360
  end

  if self.camLastRot.x > math.pi then
    self.camLastRot.x = self.camLastRot.x - math.pi * 2
  elseif self.camLastRot.x < -math.pi then
    self.camLastRot.x = self.camLastRot.x + math.pi * 2
  end

  BeamEngine.camX = 0
  BeamEngine.camY = 0

  self.camDist = self.camDist + (BeamEngine.zoomInSpeed - BeamEngine.zoomOutSpeed) * dtfactor
  if self.camDist < self.camMinDist then
    self.camDist = self.camMinDist
  end
  if self.camMaxDist and self.camDist > self.camMaxDist then
    self.camDist = self.camMaxDist
  end

  if nx:squaredLength() == 0 or ny:squaredLength() == 0 then
    data.res.pos = data.pos
    data.res.rot = quatFromDir(vec3(0,1,0), vec3(0, 0, 1))
    return false
  end

  --debugDrawer:drawSphere(targetPos:toPoint3F(), 0.3, ColorF(1,0,0,0.3))

  if self.cameraResetted ~= 1 then
    local lastCamPointVec = (targetPos - self.camLastPos2)
    local lastCamLastPerp = self.camLastPosPerp - targetPos
    if lastCamPointVec:length() < self.relaxation and lastCamLastPerp:length() > self.relaxation * 0.8 then
      local moveDir = (targetPos - self.camLastTargetPos):normalized()
      if math.abs(lastCamPointVec:normalized():dot(moveDir)) > math.abs(lastCamLastPerp:normalized():dot(moveDir)) then
        local camLastPos2 = lastCamPointVec:cross(lastCamLastPerp):cross(lastCamLastPerp):normalized()
        self.camLastPos2 = camLastPos2 + targetPos
        lastCamPointVec = (targetPos - self.camLastPos2)
      end
    end
    dir = lastCamPointVec:normalized()
    local dirxy = vec3(dir.x, dir.y, 0)
    local coef = math.max(0, 1 - dirxy:length())
    coef = coef * coef
    dir = (dir * math.max(0, 1 - coef) + dirxy:normalized() * coef):normalized()
  end

  --debugDrawer:drawSphere(self.camLastPos2:toPoint3F(), 2, ColorF(1,1,0,0.3))

  local lastCamPointVec = self.camLastPos2 - targetPos
  --print(lastCamPointVec:length()..','..self.relaxation)
  local camPos2 = lastCamPointVec:normalized() * self.relaxation + targetPos

  local rot = vec3(math.rad(self.camRot.x), math.rad(self.camRot.y), math.rad(self.camRot.z))

  -- smoothing
  local dist = self.camDist
  if self.smoothingEnabled then
    local ratio = 1 / (data.dt * 8)
    local srdif = -sign(self.camLastRot.x - rot.x)
    if math.abs(self.camLastRot.x + srdif * 2 * math.pi - rot.x) < math.abs(self.camLastRot.x - rot.x) then
      self.camLastRot.x = self.camLastRot.x + srdif * 2 * math.pi
    end
    local rotxDiff = (1 / (ratio + 1) * rot.x + (ratio / (ratio + 1)) * self.camLastRot.x) - self.camLastRot.x
    rot.x = self.camLastRot.x + fsign(rotxDiff) * math.min(math.abs(rotxDiff), maxRot * data.dt)
    rot.y = 1 / (ratio + 1) * rot.y + (ratio / (ratio + 1)) * self.camLastRot.y
    dist = 1 / (ratio + 1) * self.camDist + (ratio / (ratio + 1)) * self.camLastDist
  end

  local fov = self.fov
  local player = 0
  local lveh = be:getPlayerVehicle(player)
  local fovdistDiff = 0
  if lveh then
    -- Compute dynamic fov effect, for greater sense of speed when the vehicle travels faster.
    -- It's basically a "dolly zoom" effect:
    ---- The faster you go, the wider the FOV we use
    ---- The wider FOV we use, the smaller the vehicle would appear, so we move the camera closer to counter it

    -- deal with paused physics:
    local targetSpeed = self.lastTargetSpeed
    local dt = data.dtSim -- choose dtSim so that FOV is not affected by bullet time or pause
    if dt > 0 then
      targetSpeed = (self.camLastTargetPos - targetPos):length() / dt
      -- deal with teleporting messing up the FOV, leading to weird effects
      local teleportingSpeed = 1000/3.6 -- in m/s, threshold to detect teleport with F7 / recovery / reset / replay seeking
      local vehicleTeleported = targetSpeed > teleportingSpeed
      if vehicleTeleported then targetSpeed = self.lastTargetSpeed end
      self.lastTargetSpeed = targetSpeed
    end

    -- find where the rear of the vehicle is. this is roughly(*) the vehicle area that will occupy the same size in screen space, no matter the speed.
    -- (*) the camera is usually not right behind the car, but behind+higher: this angle is ignored for simplicity. The bounding box is usually a bit too big anyway, so the end result is close enough that we can ignore this asterisk (*) in our calculations. In the same way, if the user rotates the camera left or right, we ignore that horizontal angle too (we always use the same refToRear distance)
    local rear
    if self.rearNodeID then
      rear = vec3(data.veh:getNodePosition(self.rearNodeID)) + data.pos
    else
      local oobb = lveh:getSpawnWorldOOBB()
      rear = oobb:getPoint(4) + oobb:getPoint(9) + oobb:getPoint(5) + oobb:getPoint(6)
      rear = vec3(rear.x, rear.y, rear.z) / 4
    end
    --debugDrawer:drawSphere((rear):toPoint3F(), 0.3, ColorF(1,0,0,1.0))
    --debugDrawer:drawSphere((targetPos):toPoint3F(), 0.3, ColorF(0,1,0,1.0))

    -- compute how wide the rear of the car is (in screen space) when using the jbeam config (self.camDist). This 'originalWidth' will be preserved in screen space, no matter the FOV we end up applying
    local refToRear = (rear - targetPos):length()
    local hdegToRad = math.pi/180 * 0.5

    -- compute how much more FOV we're going to add depending on speed (from zero up to self.maxDynamicFov)
    fov = self.fov + self.maxDynamicFov * (math.min(1, targetSpeed/130))

    -- apply final field of view
    -- compute and apply the camera distance that will preserve the originalWidth
    fovdistDiff = (self.camDist - refToRear) * (math.tan(self.fov * hdegToRad) / math.tan(fov * hdegToRad) - 1)

    --local val1 = self.fov
    --log("I", "", graphs(val1, 150)..string.format("%5.2f", val1))
    --debugDrawer:drawSphere((rear):toPoint3F(), 0.2, ColorF(1.0, 0.0, 0, 0.2))
  end

  local calculatedCamPos = quatFromDir(vec3(dir)) * vec3(
    math.sin(rot.x) * math.cos(rot.y)
    , -math.cos(rot.x) * math.cos(rot.y)
    , -math.sin(rot.y)
  ) * (dist + fovdistDiff)

  local camPos = calculatedCamPos + targetPos + self.orbitOffset
  local camLastPosPerp = vecUp:cross(dir):normalized() * (self.relaxation * -0.8) + targetPos

  self.camLastTargetPos = targetPos
  self.camVel = (camPos - self.camLastPos) / data.dt
  self.camLastPos = camPos
  self.camLastPos2 = camPos2
  self.camLastPosPerp = camLastPosPerp
  self.camLastRot = rot
  self.camLastDist = dist
  self.cameraResetted = math.max(self.cameraResetted - 1, 0)

  -- application
  data.res.pos = camPos
  data.res.rot = quatFromDir((targetPos - camPos):normalized())
  data.res.fov = fov
  data.res.targetPos = targetPos
  return true
end


function C:onSerialize()
  local data = {}
  for k,v in pairs(self) do
    if type(v) ~= 'function' then
      data[k] = v
    end
  end
  return data
end

function C:onDeserialized(data)
 if not data then return end
 for k,v in pairs(data) do
    self[k] = v
  end
end


-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end

