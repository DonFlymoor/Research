-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local C = {}
C.__index = C

function C:init()
  self.hidden = true
end

function C:update(data)
  data.veh.camFOV = data.res.fov
  data.veh:setCameraPosRot(data.res.pos.x, data.res.pos.y, data.res.pos.z, data.res.rot.x, data.res.rot.y, data.res.rot.z, data.res.rot.w)
  return true
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
