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

function C:init()
  self:onVehicleCameraConfigChanged()
  self:onSettingsChanged()
  self:reset()
end

function C:onVehicleCameraConfigChanged()
  self.hidden = self.name == "driver" -- 'driver' camera data is kept, for driver.lua and other cams to use it. but the cam is hidden from the end-user
end
function C:onSettingsChanged()
  self.fov = math.max(2, self.fov or 55)
end

function C:reset()
  self.camRot = vec3()
  self.fovOffset = 0
end

function C:update(data)
  -- update input
  self.camRot.x = self.camRot.x + 10*MoveManager.yawRelative   + 100*data.dt*(MoveManager.yawRight - MoveManager.yawLeft)
  self.camRot.y = self.camRot.y - 10*MoveManager.pitchRelative + 100*data.dt*(MoveManager.pitchDown  - MoveManager.pitchUp)
  --self.camRot.z = self.camRot.z - 10*MoveManager.rollRelative  + 100*data.dt*(MoveManager.rollRight- MoveManager.rollLeft)
  self.camRot.y = clamp(self.camRot.y, -85, 85)

  -- fov tweaks
  local extraOffset = 4.5 * data.dt * (MoveManager.zoomIn - MoveManager.zoomOut) * getCameraFov()
  self.fovOffset = clamp(self.fovOffset + extraOffset, 2-self.fov, 120-self.fov)
  local fov = self.fov + self.fovOffset
  local mustNotifyFov = round(fov*10) ~= round((self.lastNotifiedFov or self.fov) * 10)
  if mustNotifyFov then
    self.lastNotifiedFov = fov
    ui_message({txt='ui.camera.fov', context={degrees=fov}}, 2, 'cameramode')
  end

  -- position
  local carPos = data.pos
  local nodePos = vec3(data.veh:getNodePosition(self.camNodeID))

  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local left = vec3(data.veh:getNodePosition(self.refNodes.left))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))
  local dir = (ref - back):normalized()

  local camLeft = (ref - left):normalized()
  if dir:squaredLength() == 0 or camLeft:squaredLength() == 0 then
    data.res.pos = carPos + nodePos
    data.res.rot = quatFromDir(vec3(0,1,0), vec3(0, 0, 1))
    return false
  end

  local camUp = -(dir:cross(camLeft):normalized())
  local qdir = quatFromDir(dir)
  local rotatedUp = qdir * vec3(0, 0, 1)
  qdir = rotateEuler(math.rad(self.camRot.x), math.rad(self.camRot.y), math.atan2(rotatedUp:dot(camLeft), rotatedUp:dot(camUp)), qdir)

  -- application
  data.res.pos = carPos + nodePos
  data.res.rot = qdir
  data.res.fov = fov
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
