-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this lets the camera fly on the first path of the map

local defaultSplineSmoothing = 0.5
local pathName = nil
local customData = nil

local C = {}
C.__index = C

function C:init()
  self.hidden = true
  self.ctrlPoint = 0
  self.camT = 0
end

function C:update(data)
  if not pathName and customData then
      pathName = customData:getNextPath() 
  end
  local path = core_paths.getPath(pathName)
  if not path or #path.nodes < 2 then return end
  local nodes = path.nodes

  -- simulate interpolated camera
  local n1, n2, n3, n4 = path.getNodeIds(self.ctrlPoint)

  self.camT = self.camT + data.dt
  local nextTime = nodes[n2].time
  if self.camT > nextTime and self.ctrlPoint <= path.endIdx - 1 then
    self.ctrlPoint = self.ctrlPoint + 1
    n1, n2, n3, n4 = path.getNodeIds(self.ctrlPoint)
    self.camT = self.camT - nextTime
    nextTime = nodes[n2].time
  end

  local t = math.min(self.camT / nextTime, 1)

  local pos = catmullRom(nodes[n1].pos, nodes[n2].pos, nodes[n3].pos, nodes[n4].pos, t, nodes[n2].positionSmooth)
  local rot = catmullRomQuat(nodes[n1].rot, nodes[n2].rot, nodes[n3].rot, nodes[n4].rot, t, nodes[n2].rotationSmooth):normalized()

  -- restarting when reached the end
  if self.ctrlPoint >= path.endIdx - 1 and t >= 1 then
    self.ctrlPoint = 0
    self.camT = 0

    if customData then
      pathName = customData:getNextPath()
    end
  end
  
  -- application
  data.res.pos = pos
  data.res.rot = rot
  data.res.fov = 80

  return true
end

function C:setCustomData(data)
  customData = data
end

function C:reset()
  customData:reset()
  pathName = nil
  self.camT = 0
  self.ctrlPoint = 0
end

function C:onSerialize()
  local data = {}
  for k,v in pairs(self) do
    if type(v) ~= 'function' then
      data[k] = v
    end
  end
  data.customData = customData
  -- log('I', 'path', 'onSerialize called...')
  -- dump(data)
  return data
end

function C:onDeserialized(data)
 if not data then return end
 for k,v in pairs(data) do
    if k ~= 'customData' then
      self[k] = v
    end
  end
  customData = data.customData
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
