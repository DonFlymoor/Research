-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local dequeue = require('dequeue')

local M = {}
M.recoveryPoints = dequeue.new()   -- historic log of (different enough) vehicle positions
M.safePoints = {}

-------------------------------------------------------------------------------
-- settings
-------------------------------------------------------------------------------
local recoveryPointTimedelta   = 0.2    -- in physics simulation seconds
local recoveredPointSeparation = 2
local recoveredPointSeparationSq = recoveredPointSeparation * recoveredPointSeparation
local logSize                  = 700

-------------------------------------------------------------------------------
-- local vars
-------------------------------------------------------------------------------
local countDown = 0                   -- physics simulation clock
local blendTime = 0
local snapshotTimeSmoother = newTemporalSmoothing(0.5)

-------------------------------------------------------------------------------
-- public functions and some more helpers
-------------------------------------------------------------------------------
M.updateGFX = nop

local function clear()
  M.recoveryPoints = dequeue.new()
  M.safePoints = {}
end

local function onDeserialized(v)
  tableMerge(M, v)
  M.recoveryPoints = dequeue.new(v.recoveryPoints)
end

local function newRecoveryPoint()
  return {
    pos = vec3(obj:getPosition()),
    dirFront = obj:getDirectionVector(),
    dirUp = obj:getDirectionVectorUp()
  }
end

local function blendPoints(a, b, t)
  return {
    pos = vec3(a.pos) + (vec3(b.pos) - vec3(a.pos)) * t,
    dirFront = (vec3(a.dirFront) + (vec3(b.dirFront) - vec3(a.dirFront)) * t):normalized(),
    dirUp = (vec3(a.dirUp) + (vec3(b.dirUp) - vec3(a.dirUp)) * t):normalized()
  }
end

local function getRollPitch(dirFront, dirUp)
  -- find vehicle roll and pitch, in degrees, 0deg being normal upright rotation, +/-180deg being on its roof
  local dirLeft = dirUp:cross(dirFront)
  local roll  = math.deg(math.asin(dirLeft.z))
  local pitch = math.deg(math.asin(dirFront.z))
  if dirUp.z < 0 then -- if we are closer to upside down than to downside up
    -- detect the "on its roof" situation, where angles are zero, and make sure they go all the way to 180deg instead, like this:
    -- original rotation angles:  0deg (ok), 90deg (halfway),      0deg (on its roof), -90deg (halfway), 0deg (ok)
    -- corrected rotation angles: 0deg (ok), 90deg (halfway), +/-180deg (on its roof), -90deg (halfway), 0deg (ok)
    roll  = sign( roll)*(180 - math.abs( roll))
    pitch = sign(pitch)*(180 - math.abs(pitch))
  end
  --log("D", "recovery", "Roll: "..r(roll,2,2)..", Pitch: "..r(pitch,2,2)..", dirUp: "..s(recPoint.dirUp, 2,2))
  return roll, pitch
end

local function setRecoveryPoint(recPoint, rollLimit, pitchLimit)
  -- if the angle limits (in degrees) are surpassed, car is reset to upright position, maintaining the recpoint heading
  local rot
  local dirFront = vec3(recPoint.dirFront)
  local dirUp = vec3(recPoint.dirUp)
  local roll, pitch = getRollPitch(dirFront, dirUp)
  if pitchLimit ~= nil and (math.abs(pitch) > pitchLimit or math.abs(roll) > rollLimit) then
    rot = quatFromDir(-dirFront, vec3(0,0,1))
  else
    rot = quatFromDir(-dirFront, dirUp)
  end
  obj:queueGameEngineLua("vehicleSetPositionRotation("..obj:getID()..","..recPoint.pos.x..","..recPoint.pos.y..","..recPoint.pos.z..","..rot.x..","..rot.y..","..rot.z..","..rot.w..")")
end

local function savePoint(pointName)
  M.safePoints[pointName] = newRecoveryPoint()
end

local function loadPoint(pointName)
  if M.safePoints[pointName] == nil then return end
  obj:requestReset(RESET_PHYSICS)     -- fix vehicle + reset velocity
  obj:queueGameEngineLua('be:getObjectByID('..tostring(obj:getID())..'):resetBrokenFlexMesh()')
  setRecoveryPoint(M.safePoints[pointName], 45, 80)
end

local function saveHome(point)
  M.safePoints['home'] = point or newRecoveryPoint()
  if point == nil then
    gui.message("vehicle.recovery.saveHome", 5, "recovery")
  end
end

local function loadHome()
  loadPoint('home')
  gui.message("vehicle.recovery.loadHome", 5, "recovery")
end

local function updateGFXRecord(dt)
  countDown = countDown - dt
  if countDown <= 0 then
    countDown = countDown + recoveryPointTimedelta
    if M.recoveryPoints:is_empty() then
      local startPoint = newRecoveryPoint()
      if M.home == nil then
        saveHome(startPoint)
      end
      M.recoveryPoints:push_right(startPoint)
      return
    end

    if M.recoveryPoints:peek_right().pos:squaredDistance(obj:getPosition()) < recoveredPointSeparationSq then
      return -- too close to last recovered point
    end

    while M.recoveryPoints:length() >= logSize do  -- remove old positions
      M.recoveryPoints:pop_left()
    end
    M.recoveryPoints:push_right(newRecoveryPoint())
  end
end

local function stopRecovering()
  if M.updateGFX == updateGFXRecord then return end
  M.updateGFX = updateGFXRecord
  obj:setMeshNameAlpha(1, "", true) -- show everything again
  obj:requestReset(RESET_PHYSICS)     -- fix vehicle + reset velocity
  obj:queueGameEngineLua('be:getObjectByID('..tostring(obj:getID())..'):resetBrokenFlexMesh()')
  setRecoveryPoint(newRecoveryPoint(), 45, 80) -- vehicles are usually longer than wider, so they can withstand greater pitch angles (last arg), but smaller roll angles (previous arg)
  if M.recoveryPoints:is_empty() then
    gui.message("vehicle.recovery.end", 5, "recovery")
  else
    if snapshotTimeSmoother:value() > 0.9 then
      gui.message("vehicle.recovery.quick", 7, "recovery")
    else
      gui.message("vehicle.recovery.recovered", 3, "recovery")
    end
  end
end

local function updateGFXRecovery(dt)
  local realDt = obj:getRealdt()
  blendTime = blendTime + realDt
  local snapshotTime = snapshotTimeSmoother:getUncapped(0.03, realDt)
  if blendTime > snapshotTime then
    while blendTime > snapshotTime do
      if M.recoveryPoints:is_empty() then break end
      local lastRecoveredPoint = M.recoveryPoints:pop_right()  -- pop

      if M.recoveryPoints:is_empty() then
        setRecoveryPoint(lastRecoveredPoint)
      end
      blendTime = math.max(blendTime - snapshotTime, 0)
    end
  end
  if M.recoveryPoints:is_empty() then
    stopRecovering()
    return
  end
  local lastRecoveredPoint = M.recoveryPoints:pop_right()
  local nextRecoveryPoint = M.recoveryPoints:peek_right()
  M.recoveryPoints:push_right(lastRecoveredPoint)

  if lastRecoveredPoint and nextRecoveryPoint then
    if lastRecoveredPoint.pos:distance(nextRecoveryPoint.pos) < 20 then
      local p = blendTime / snapshotTime
      local bp = blendPoints(lastRecoveredPoint, nextRecoveryPoint, p)
      setRecoveryPoint(bp)
    else
      setRecoveryPoint(nextRecoveryPoint)
    end
  end

  obj:setMeshNameAlpha(0.6, "", true) -- fade it away... need to be set here becouse sync issues with reset broken props
end

local function startRecovering()
  if M.updateGFX == updateGFXRecovery then return end
  snapshotTimeSmoother:set(1)
  M.updateGFX = updateGFXRecovery
  blendTime = 0

  M.recoveryPoints:push_right(newRecoveryPoint())

  gui.message("vehicle.recovery.recovering", 5, "recovery")
  obj:queueGameEngineLua('be:getObjectByID('..tostring(obj:getID())..'):resetBrokenFlexMesh()')
  obj:queueGameEngineLua('be.nodeGrabber:clearVehicleFixedNodes('..tostring(obj:getID())..')')
end

local function recoverInPlace()
  setRecoveryPoint(newRecoveryPoint(), 45, 80)
end

local function init(path)
  M.updateGFX = updateGFXRecord
end

-- public interface
M.init = init
M.startRecovering = startRecovering
M.stopRecovering = stopRecovering
M.saveHome = saveHome
M.loadHome = loadHome
M.onDeserialized = onDeserialized
M.clear = clear
M.savePoint = savePoint
M.loadPoint = loadPoint
M.recoverInPlace = recoverInPlace

return M
