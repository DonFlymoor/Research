-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local originalDistance = 5

local playerId

local function checkForTrailer(objId1, objId2)
  local playerId = be:getPlayerVehicleID(0)

  if playerId ~= objId1 and playerId ~= objId2 then return false end

  if objId1 == objId2 then return false end

  local obj1 = scenetree.findObjectById(objId1)
  local obj2 = scenetree.findObjectById(objId2)

  local pos1
  local pos2

  pos1 = obj1:getPosition()
  pos2 = obj2:getPosition()

  if obj1 ~= nil and obj2 ~= nil then
    local dist = (pos1 - pos2):len()
    if dist < 1 or dist > 15 then return false end
  end

  return true
end

local function onCouplerAttached(objId1, objId2)
  playerId = be:getPlayerVehicleID(0)

  local dist1 = 5
  local dist2 = 5

  if core_camera ~= nil then
    originalDistance = core_camera.getCameraDataById(playerId).orbit.distance

    local obj1 = core_camera.getCameraDataById(objId1)
    local obj2 = core_camera.getCameraDataById(objId2)

    if obj1 ~= nil then
      dist1 = obj1.orbit.distance
    end
    if obj2 ~= nil then
      dist2 = obj2.orbit.distance
    end

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

M.checkForTrailer = checkForTrailer
M.onCouplerAttached = onCouplerAttached
M.onCouplerDetached = onCouplerDetached

return M