-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local originalDistance = 5

local playerId

local isTrailer = false

local function getDistance (pos1, pos2)
  local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-pos2.y)+(pos1.z-pos2.z)*(pos1.z-pos2.z))
  if distance ~= distance then
    distance = 0
  end
  return distance
end

local function checkForTrailer(objId1, objId2)
  if playerId ~= objId1 and playerId ~= objId2 then return false end

  if objId1 == objId2 then return false end

  local obj1 = scenetree.findObjectById(objId1)
  local obj2 = scenetree.findObjectById(objId2)

  local pos1
  local pos2

  pos1 = vec3(obj1:getPosition())
  pos2 = vec3(obj2:getPosition())

  if obj1 ~= nil and obj2 ~= nil then
    local dist = getDistance(pos1, pos2)
    if dist < 1 or dist > 15 then return false end
  end
end

local function onCouplerAttached(objId1, objId2)
  playerId = be:getPlayerVehicleID(0)
  isTrailer = checkForTrailer(objId1, objId2)
  if isTrailer == false then return end
  local dist1 = 5
  local dist2 = 5

  if core_camera then
    originalDistance = core_camera.getCameraDataById(playerId).orbit.distance

    dist1 = core_camera.getCameraDataById(objId1).orbit.distance
    dist2 = core_camera.getCameraDataById(objId2).orbit.distance

    -- set camera to orbit if not already
    local activeCam = core_camera.getActiveCamName(0)

    if activeCam ~= 'orbit' then
      core_camera.setByName(0, 'orbit')
    end
    core_camera.setDefaultDistance(playerId, dist1+dist2+1)
    core_camera.setDistance(playerId, dist1+dist2+1)
    -- change camera back to what it used to be
    if activeCam ~= 'orbit' then
      core_camera.setByName(0, activeCam)
    end
  end
end

local function onCouplerDetached(objId1, objId2)
  if isTrailer == false then return false end
  if core_camera then
    local activeCam = core_camera.getActiveCamName(0)
    if activeCam ~= 'orbit' then
      core_camera.setByName(0, 'orbit')
    end
    core_camera.setDefaultDistance(playerId, originalDistance)
    core_camera.setDistance(playerId, originalDistance)
    if activeCam ~= 'orbit' then
      core_camera.setByName(0, activeCam)
    end
  end
end

M.onCouplerAttached = onCouplerAttached
M.onCouplerDetached = onCouplerDetached

return M