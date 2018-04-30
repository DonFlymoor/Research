-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

function C:init(future)
  self.hidden = true
  self.future = future or self.future or 0.1
end
function C:onVehicleResetted(...)
  return true
end
function C:update(data)
  local curPos = data.res.targetPos
  if self.lastPos == nil then self.lastPos = curPos end
  local vel = (curPos - self.lastPos) / data.dt
  local predictedDiff = self.future * vel
  data.res.targetPos = curPos + predictedDiff

  data.res.rot = quatFromDir((data.res.targetPos - data.res.pos):normalized())
  self.lastPos = curPos
  return true
end

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
