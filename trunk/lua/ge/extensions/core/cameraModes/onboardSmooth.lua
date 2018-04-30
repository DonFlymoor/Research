-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

local camNodeID = nil

function C:init()
  self.disabledByDefault = true
  self.defaultRotation = vec3(self.defaultRotation)
  self.camRot = vec3(self.defaultRotation)
  self.camLastRot = vec3()
  self.fov = self.fov or 55
  self:reloaded()
  
  -- calculate driver camera fov once
  for k,v in pairs(self.otherCameras.onboard or {}) do
    if v.name == "driver" then
      self.fov = v.fov
      break
    end
  end
end


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


function C:reset()
  self.camRot = vec3(0, 0, 0)
  
  -- reset fov
  for k,v in pairs(self.otherCameras.onboard or {}) do
    if v.name == "driver" then
      self.fov = v.fov
      break
    end
  end
end

function C:update(data)

  -- calculate camNodeID continously to prevent issue with multple vehicles
  camNodeID = 0
  for k,v in pairs(self.otherCameras.onboard or {}) do
    if v.name == "driver" then
      camNodeID = v.camNodeID
      break
    end
  end

  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))

  local onboardCamPos = vec3(data.veh:getNodePosition(camNodeID))

  -- update input
  local dtfactor = data.dt * 1000

  local Xinput = (MoveManager.yawLeftSpeed - MoveManager.yawRightSpeed)
  -- local dx = input * dtfactor
  local triggerValue = 0.001
  
  if Xinput > triggerValue then
    self.camRot.x = Xinput * 900
  elseif Xinput < -triggerValue then
    self.camRot.x = Xinput * 900
  elseif Xinput > -triggerValue and Xinput < triggerValue then
    self.camRot.x = 0
  end

 
  local Yinput = (MoveManager.pitchUpSpeed - MoveManager.pitchDownSpeed)
  -- local dx = input * dtfactor
  local triggerValue = 0.001
  
  if Yinput > triggerValue then
      self.camRot.y = Yinput * 400
  elseif Yinput < -triggerValue then
      self.camRot.y = Yinput * 200
  elseif Yinput > -triggerValue and Yinput < triggerValue then
    self.camRot.y = 0
  end

  local rdz = (BeamEngine.zoomInSpeed - BeamEngine.zoomOutSpeed) * data.dt * 4000
  self.fov = math.min(math.max(self.fov + rdz, 10), 150)

  local targetRot = self.camRot



  --


  local rot = vec3(math.rad(self.camRot.x), -math.rad(self.camRot.y), math.rad(self.camRot.z))

  local ratio = 1 / (data.dt * 3)
  rot.x = 1 / (ratio + 1) * rot.x + (ratio / (ratio + 1)) * self.camLastRot.x
  rot.y = 1 / (ratio + 1) * rot.y + (ratio / (ratio + 1)) * self.camLastRot.y

  self.camLastRot = vec3(rot)

  self.camRot = vec3(math.deg(rot.x), math.deg(rot.y), math.deg(rot.z))

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

  --look direction based on camRot
  qdir = rotateEuler(-math.rad(-self.camRot.x), -math.rad(self.camRot.y), math.atan2(rotatedUp:dot(camLeft), rotatedUp:dot(camUp)), qdir)

  local camOffset = (qdir * self.globalOffset)



  -- application
  data.res.pos = camPos + camOffset
  data.res.rot = qdir
  data.res.fov = self.fov
  return true
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
