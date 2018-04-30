-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C


local function rotateEuler(x, y, z, q)
  q = q or quat()
  q = quatFromEuler(0, z, 0) * q
  q = quatFromEuler(0, 0, x) * q
  q = quatFromEuler(y, 0, 0) * q
  return q
end

function C:reloaded()
  -- global fov tuning
  self.fov = self.fov + settings.getValue('cameraFOVTune') or 0
  self.fov = math.min(150, math.max(1, self.fov))

  self.globalOffset = vec3(
    settings.getValue('cameraPosTuneX') or 0,
    settings.getValue('cameraPosTuneY') or 0,
    settings.getValue('cameraPosTuneZ') or 0
  )

  -- if right hand drive, invert X axis
  if self.rightHandCamera then
    self.globalOffset.x = - self.globalOffset.x
  end

end

function C:init()
  self.camRot = vec3(0, 0, 0)
  self.fov = self.fov or 55
  self.fovInit = self.fovInit or self.fov
  self:reloaded()
end


function C:reset()
  self.camRot = vec3(0, 0, 0)
  self.fov = self.fovInit + settings.getValue('cameraFOVTune') or 0
end

function C:lookback()
  if self.camRot.x > 0 then
    self.camRot.x = 0
  else
    self.camRot.x = 180
  end
end

function C:update(data)
  -- update input
  self.camRot.y = self.camRot.y - BeamEngine.camY * 10 + (MoveManager.pitchUpSpeed - MoveManager.pitchDownSpeed) * (-1000 * data.dt)
  self.camRot.x = self.camRot.x + BeamEngine.camX * 10 + (MoveManager.yawLeftSpeed - MoveManager.yawRightSpeed) * (1000 * data.dt)
  --self.camRot.z = self.camRot.z +  MoveManager.roll  * 10.0f + (MoveManager.rollLeftSpeed - MoveManager.rollRightSpeed) * (dt)

  local rdz = (BeamEngine.zoomInSpeed - BeamEngine.zoomOutSpeed) * data.dt * 4000
  self.fov = math.min(math.max(self.fov + rdz, 10), 150)

  if self.camRot.y > 85 then self.camRot.y = 85 end
  if self.camRot.y < -85 then self.camRot.y = -85 end

  BeamEngine.camX = 0
  BeamEngine.camY = 0

  --
  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))

  local onboardCamPos = vec3(data.veh:getNodePosition(self.camNodeID))


  local dir = (ref - back):normalized()
  local camPos = data.pos + onboardCamPos
  local camLeft = (ref - left):normalized()
  if dir:squaredLength() == 0 or camLeft:squaredLength() == 0 then
    data.res.pos = camPos
    data.res.rot = quatFromDir(vec3(0,1,0), vec3(0, 0, 1))
    return false
  end

  local camUp = -(dir:cross(camLeft):normalized())
  local qdir = quatFromDir(dir)

  local rotatedUp = vec3(0, 0, 1)
  rotatedUp = qdir * rotatedUp

  -- TODO: add camera roll input support: camRot.z
  local lookRot = 0 -- removed for now. readd: TODO: // bo->avgCamSteering.get(steering) * steerLookMax * (1.0f - min(camRefVelo.lenSquared(), 150.0f) / 200.0f)
  qdir = rotateEuler(-math.rad(-self.camRot.x), -math.rad(self.camRot.y), math.atan2(rotatedUp:dot(camLeft), rotatedUp:dot(camUp)), qdir)

  local camOffset = (qdir * self.globalOffset)

  -- application
  data.res.pos = camPos + camOffset
  data.res.rot = qdir
  data.res.fov = self.fov
  return true
end

function C:onSerialize()
  local data = {}
  for k,v in pairs(self) do
    if type(v) ~= 'function' then
      data[k] = v
    end
  end
  --log('I', 'onboard', 'onSerialize called...')
  --dump(data)
  return data
end

function C:onDeserialized(data)
 if not data then return end
 for k,v in pairs(data) do
    self[k] = v
  end
end

function C:setRefNodes(centerNodeID, leftNodeID, backNodeID)
  self.refNodes.ref = centerNodeID
  self.refNodes.left = leftNodeID
  self.refNodes.back = backNodeID
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
