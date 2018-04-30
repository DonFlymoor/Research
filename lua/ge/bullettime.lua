-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.simulationSpeed = 1
M.simulationSpeedReal = 1
local initialTimeScale = M.simulationSpeed
local simulationSpeed_smooth = newTemporalSmoothing(3)

local bulletTimeSlots = {1/100, 1/16, 1/8, 1/4, 1/2, 1}
local instantSlowmoSlot = 3
M.selectionSlot = #bulletTimeSlots

local function getPause()
  return not be:getEnabled()
end

local function update(dt)
  if getPause() then return end -- do not transition while paused

  local finalcv = M.simulationSpeed
  local cv = simulationSpeed_smooth:get(finalcv, dt)

  physicsEngineEvent('timescale',cv)
  be:setSimulationTimeScale(cv)
  M.simulationSpeedReal = cv

  if cv == finalcv then
    M.update = nop
  end
end

local function reportSpeed(speed, simplified)
  if speed > 1.001 then
      ui_message({txt="vehicle.bullettime.changeFast", context={speed=speed}}, 5, "bullettime")
    elseif speed > 0.999 then
    if not simplified then
      ui_message("vehicle.bullettime.realtime", 5, "bullettime")
    end
  else
    if simplified then
      ui_message("vehicle.bullettime.slowmotion", 5, "bullettime")
    else
      local t = 1/speed
      if t ~= math.floor(t) then
        t = string.format("%.1f", speed)
      end
      ui_message({txt="vehicle.bullettime.changeSlow", context={slowmoTimes=t}}, 5, "bullettime")
    end
  end
end

local function setTargetSpeed(val)
  if type(val) ~= "number" then
    log("E","bullettime","Tried to set non-numeric speed: "..dumps(val))
    return
  end
  M.simulationSpeed = math.max(0.001, math.min(1, val))
  initialTimeScale = M.simulationSpeed
  if getPause() then return end
  M.update = update
end

local function selectPreset(val)
  if core_replay.state.state == "playing" then
    if     val == "^" then core_replay.toggleSpeed("realtime")
    elseif val == "v" then core_replay.toggleSpeed("slowmotion")
    elseif val == "<" then core_replay.toggleSpeed( -1)
    elseif val == ">" then core_replay.toggleSpeed(  1)
    end
  else
    if     val == "^" then M.selectionSlot = #bulletTimeSlots
    elseif val == "v" then M.selectionSlot = instantSlowmoSlot
    elseif val == "<" then M.selectionSlot = M.selectionSlot - 1
    elseif val == ">" then M.selectionSlot = M.selectionSlot + 1
    end

    M.selectionSlot = math.max(1, math.min(M.selectionSlot, #bulletTimeSlots))
    setTargetSpeed(bulletTimeSlots[M.selectionSlot])
    reportSpeed(M.simulationSpeed, false)
  end
end

local function getReal()
  return M.simulationSpeedReal
end
local function get()
  return M.simulationSpeed
end
local function set(val)
  setTargetSpeed(val)
  reportSpeed(M.simulationSpeed, true)
end

local function init()
  simulationSpeed_smooth:set(be:getSimulationTimeScale()) -- start smoother in current value, not in zero
end

local function requestValue()
  guihooks.trigger("BullettimeValueChanged", M.simulationSpeed)
end

local function pause(paused)
  if core_replay.state.state == "playing" then
    core_replay.pause(paused)
  else
    if paused == getPause() then return end
    if paused then
      initialTimeScale = M.simulationSpeed -- backup the original physics scale
      M.simulationSpeed = 0
      M.update = nop
    else
      simulationSpeed_smooth:set(initialTimeScale) -- start smoother in current value, not in zero
      setTargetSpeed(initialTimeScale) -- restore the original physics scale
    end
    be:setSimulationTimeScale(M.simulationSpeed)
    be:setEnabled(not paused)
    updatePhysicsState(not paused)
  end
end
local function togglePause()
  if core_replay.state.state == "playing" then
    core_replay.togglePlay()
  else
    pause(not getPause())
  end
end

-- public interface
M.update = nop
M.init = init
M.get = get -- 1=realtime, 0.5=slowmo, 2=fastmotion
M.getReal = getReal -- 1=realtime, 0.5=slowmo, 2=fastmotion, smoothing included
M.set = set -- 1=realtime, 0.5=slowmo, 2=fastmotion
M.selectPreset = selectPreset
M.pause = pause
M.getPause = getPause
M.togglePause = togglePause
M.requestValue = requestValue
M.reportSpeed = reportSpeed

return M
