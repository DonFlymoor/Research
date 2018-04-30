-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local streamControl = {}
local lsensors = {position = {}}

local function willSend(name)
  return gui.updateStreams and streamControl[name]
end

local function reset()
  streamControl = {}
end

local function updateStreams()
  -- Wheelinfo --
  if streamControl.wheelInfo then
    local wheelinfo = {}
    for i,wd in pairs(wheels.wheels) do
      wheelinfo[i] = {
        wd.name
        , wd.radius
        , wd.wheelDir
        , wd.angularVelocity
        , wd.propulsionTorque
        , wd.lastSlip
        , 0 --deprecated, used to be lastTorqueMode
        , wd.downForce
        , wd.brakingTorque
        , wd.brakeTorque
      }
    end
    gui.send('wheelInfo', wheelinfo)
  end

  -- Engineinfo --
  if streamControl.engineInfo then
    gui.send('engineInfo', controller.mainController.engineInfo)
  end

  -- Electrics --
  if streamControl.electrics then
    gui.send('electrics', electrics.values)
  end

  -- Stats --
  if streamControl.stats then
    local statsObj = obj:calcBeamStats()
    local stats = {
      beam_count = statsObj.beam_count,
      node_count = statsObj.node_count,
      beams_broken = statsObj.beams_broken,
      beams_deformed = statsObj.beams_deformed,
      wheel_count = statsObj.wheel_count,
      total_weight = statsObj.total_weight,
      wheel_weight = statsObj.wheel_weight,
      tri_count = obj:getTriangleCount(),
      collidable_tri_count = obj:getCollidableTriangleCount()
    }
    gui.send('stats' , stats )
  end

  if streamControl.sensors then
    local dirVector = obj:getDirectionVector()
    local dirVectorUp = obj:getDirectionVectorUp()
    local objpos = obj:getPosition()
    lsensors.gx = sensors.gx
    lsensors.gy = sensors.gy
    lsensors.gz = sensors.gz
    lsensors.gx2 = sensors.gx2
    lsensors.gy2 = sensors.gy2
    lsensors.gz2 = sensors.gz2
    lsensors.gxMax = sensors.gxMax
    lsensors.gxMin = sensors.gxMin
    lsensors.gyMax = sensors.gyMax
    lsensors.gyMin = sensors.gyMin
    lsensors.gzMax = sensors.gzMax
    lsensors.gzMin = sensors.gzMin
    lsensors.ffbAtWheel = tonumber(hydros.forceAtWheel)
    lsensors.ffbAtDriver = tonumber(hydros.forceAtDriver)
    lsensors.maxffb = tonumber(hydros.curForceLimit)
    lsensors.maxffbRate = tonumber(hydros.maxFFBrate)
    lsensors.position.x = objpos.x
    lsensors.position.y = objpos.y
    lsensors.position.z = objpos.z
    lsensors.roll = dirVectorUp.x * -dirVector.y + dirVectorUp.y * dirVector.x
    lsensors.pitch = dirVector.z
    lsensors.yaw = math.atan2(dirVector.x, -dirVector.y)
    lsensors.gravity = obj:getGravity()
    gui.send('sensors', lsensors)
  end
end

local function updateReferenceCounts(state)
  for k,v in pairs(state) do
    streamControl[k] = v > 0
  end
end

-- public interface
M.reset = reset
M.updateStreams = updateStreams
M.setRequiredStreams = updateReferenceCounts
M.willSend = willSend

return M
