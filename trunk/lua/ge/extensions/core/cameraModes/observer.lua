-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

function C:init()
  self.hidden = true
  self.camID = nil
  self.camLastBulletSpeed = nil
  self.camT = 0.0
  self.targetOverride = nil
end

function C:update(data)
  if not self.camID then return end

  local cam = scenetree.findObjectById(self.camID)
  if not cam then return end

  local camPos = vec3(cam:getPosition())

  if cam.Speed and tonumber(cam.Speed) then
    if self.camLastBulletSpeed ~= cam.Speed then
      bullettime.set(1/cam.Speed)
      self.camLastBulletSpeed = cam.Speed
      if cam.showApps ~= '1' and cam.Speed ~= '1' then
        guihooks.trigger('ShowApps', false)
      end
    end
  elseif self.camLastBulletSpeed then
      bullettime.set(1)
      self.camLastBulletSpeed = nil
      guihooks.trigger('ShowApps', true)      
  end

  local blendSpeed = cam.blendSpeed or 50
  local targetFOV = cam.targetFOV or nil

  if self.camT < 1.0 then
    self.camT = math.min(1, math.max(0, self.camT + (blendSpeed * data.dt)))

    if cam.PositionMove then
      local targetPos = stringToVec3(cam.PositionMove)
      local length = (targetPos - camPos):length()
      camPos = camPos + (targetPos - camPos) * self.camT
    end

    if  targetFOV and tonumber(targetFOV) then
      targetFOV = data.veh.camFOV + (tonumber(targetFOV) - data.veh.camFOV) * self.camT
    end
  end
  
  
  if self.targetOverride then
    local targetObject = scenetree.findObject(self.targetOverride)
    if targetObject then
      --log('A','observer','self.targetOverride: ' ..dumps(self.targetOverride))
      data.pos = vec3(targetObject:getPosition())
    end
  end

  local camPosDelta = (data.pos - camPos):length()
  local dir = (data.pos - camPos):normalized()
  local qdir = quatFromDir(dir)

   if not targetFOV then
     targetFOV =  90 - camPosDelta * 3
   end

  -- application
  data.res.pos = camPos
  data.res.rot = qdir
  data.res.fov = math.max(10, targetFOV)

  return true
end

function C:setCamera(cam, subject, targetOverride)
  if cam then
    self.camID = cam:getID()
  else
    self.camID = nil
  end
  
  if subject and self.camLastBulletSpeed then
    bullettime.set(1)
    self.camLastBulletSpeed = nil
    guihooks.trigger('ShowApps', true)      
  end

  self.camT = 0.0
  
  self.targetOverride = targetOverride
end

function C:onSerialize()
  local data = {}

  if self.camID then
    local cam = scenetree.findObjectById(self.camID)
    if cam then
      data.cameraName = cam:getField('name', '')
    end
  end

  data.camLastBulletSpeed = self.camLastBulletSpeed
  data.camT = self.camT
  data.targetOverride = self.targetOverride
  data.hidden = self.hidden
  return data
end

function C:onDeserialized(data)
  if not data then return end
  if data.cameraName then
    local cam = scenetree.findObject(data.cameraName)
    if cam then
      self.camID = cam:getID()
    end
  end  
  self.camLastBulletSpeed = data.camLastBulletSpeed
  self.camT = data.camT
  self.targetOverride = data.targetOverride
  self.hidden = data.hidden
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
