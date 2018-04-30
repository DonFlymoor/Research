-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

--- This is an example of a custom camera mode :D

local C = {}
C.__index = C

function C:init()
  self.disabledByDefault = true
  self.veloSmoother = newExponentialSmoothing(20, 1)
  self.lastDataPos = vec3()
  self.fov = self.fov or 20
end

function C:update(data)
  -- get the data
  local ref  = vec3(data.veh:getNodePosition(self.refNodes.ref))
  local back = vec3(data.veh:getNodePosition(self.refNodes.back))

  -- we need to manually smooth the velocity as its too spiky otherwise which results in bad camera movement
  local velo = self.veloSmoother:get((self.lastDataPos - data.pos):length())
  self.lastDataPos = data.pos

  -- figure out the way the vehicle is oriented
  local dir = (ref - back):normalized()
  -- find out the target that we should look on
  local targetPos = data.pos + vec3(dir.x, dir.y, 0) * math.min(50, 70 * velo)
  -- and place the camera above it
  local camPos = targetPos + vec3(0, 0, (velo * 80)  + 50)
  -- then look from camera position to target :)
  local qdir = quatFromDir((targetPos - camPos):normalized())

  -- set the data, this needs to happen
  data.res.pos = camPos -- required, vec3()
  data.res.rot = qdir -- required, quat()
  data.res.fov = self.fov -- required
  data.res.targetPos = targetPos -- this is optional
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
