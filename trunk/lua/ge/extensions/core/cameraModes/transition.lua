-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

function C:init()
  self.hidden = true
  self.camLastPosRel = vec3(5,5,5)
  self.camLastFOV = 90
  self.camLastQDir = quat(1,0,0,1)
  self.transitionTime = 0
  self.transitionDuration = settings.getValue('cameraTransitionTime') or 350 -- in ms
end

function C:update(data)
  data.res.pos = data.res.pos - data.pos -- make it relative

  if self.transitionTime > 0 then
    local oldTransitionTime = self.transitionTime
    self.transitionTime = math.max(0, self.transitionTime - data.dt * 1000)
    local perc = (self.transitionTime / oldTransitionTime)
    perc = perc * perc

    -- smooth
    data.res.pos = data.res.pos + (self.camLastPosRel - data.res.pos) * perc
    data.res.fov = data.res.fov + (self.camLastFOV - data.res.fov) * perc
    data.res.rot = data.res.rot:nlerp(self.camLastQDir, perc)
  end

  self.camLastPosRel = vec3(data.res.pos)

  data.res.pos = data.res.pos + data.pos -- make it absolute again

  self.camLastQDir = quat(data.res.rot)
  self.camLastFOV = data.res.fov
  return true
end

function C:reloaded()
  self.transitionDuration = settings.getValue('cameraTransitionTime') or 350
end

function C:start()
  self.transitionTime = self.transitionDuration
end

function C:onSerialize()
  local data = {}
  for k,v in pairs(self) do
    if type(v) ~= 'function' then
      data[k] = v
    end
  end
  -- log('I', 'transition', 'onSerialize called...')
  -- dump(data)
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
