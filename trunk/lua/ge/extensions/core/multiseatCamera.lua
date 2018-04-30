-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require("utils")
local M = {}

local zBuffer = {}
local smoothing = 1500
local lastLocation = vec3(0, 0, 0);
local dirBuffer = {}

local function getDistance (pos1, pos2)
  local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-pos2.y)+(pos1.z-pos2.z)*(pos1.z-pos2.z))
  if distance ~= distance then
    distance = 0
  end
  return distance
end

local function onExtensionLoaded()
  if core_camera then
    core_camera.resetCameraByID(be:getPlayerVehicleID(0))
  end
end

local function onExtensionUnloaded()
  if core_camera then
    core_camera.resetCameraByID(be:getPlayerVehicleID(0))
  end
end

local function getBufferMean (buffer)
  if #buffer == 0 then
    return vec3(0, 0, 0)
  end
  local x = 0
  local y = 0
  local z = 0
  for _, b in pairs(buffer) do
    x = x + b.x
    y = y + b.y
    z = z + b.z
  end
  return vec3(x/#buffer, y/#buffer, z/#buffer)
end

local function addToBuffer (buffer, value)
  local newBuffer = {}
  table.insert(newBuffer, value)
  local lastValue
  for k, b in pairs(buffer) do
    if (k < smoothing) then
      table.insert(newBuffer,b)
    end
  end
  return newBuffer
end

local function onUpdate()
  local i = 0
  local meanLocation = vec3(0, 0, 0)
  local meanDirection = vec3(0, 0, 0)
  local maxDistance = 0
  local pos = vec3(0, 0, 0)
  local dir = vec3(0, 0, 0)
  for k, v in pairs(map.objects) do
    meanLocation = meanLocation + v.pos
    if be:getPlayerVehicleID(0) == k then
      pos = v.pos
      dir = v.dirVec:normalized()
    end

    for k_, v_ in pairs(map.objects) do
      local dist = getDistance(v.pos, v_.pos)
      if dist > maxDistance then
        maxDistance = dist
      end
    end

    i = i + 1
  end

  maxDistance = maxDistance/1+10

  if i ~= 0 then
    meanLocation = vec3(meanLocation.x/i, meanLocation.y/i, meanLocation.z/i)
  else
    meanLocation = vec3(0, 0, 0)
  end

  meanDirection = meanLocation - lastLocation - pos
  dirBuffer = addToBuffer(dirBuffer, meanDirection)
  local smoothedMeanDirection = getBufferMean(dirBuffer)
  lastLocation = meanLocation

  local targetCenter = meanLocation-pos

  local left = vec3(-meanDirection.y, meanDirection.x, targetCenter.z)
  local back = vec3(meanDirection.x, -meanDirection.y, targetCenter.z)

  if core_camera then
    local vid = be:getPlayerVehicleID(0)
    core_camera.setTargetMode(vid, 'notCenter', vec3(0, 0, 0))
    core_camera.setDistance(vid, maxDistance)
    core_camera.setFOV(vid, 40)
    core_camera.setRef(vid, targetCenter, left, back)
  end
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onUpdate = onUpdate

return M
