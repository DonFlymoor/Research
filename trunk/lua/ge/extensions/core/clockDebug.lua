-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = { }

local realClock = 0
local simClock = 0
local gfxClock = 0
local lastSent = 0
local counters = { wall=false, graphics=false, cef=false, physics=false, gfxpsx=false, min=false, max=false}

local function reset()
  for k,v in pairs(counters) do
    counters[k] = { clock=0, updates=0, value=0 }
  end
end

local function onExtensionLoaded()
  reset()
  realClock = 0
  simClock = 0
  gfxClock = 0
  guihooks.trigger("clockDebugInit")
end

local function onUpdate(dtReal, dtSim, dtRaw)
  local clockType = be:getClockType()
  local prevDelay = gfxClock - simClock

  local simScale = bullettime.getReal()
  realClock = realClock + dtRaw
  simClock = simClock + (dtSim / simScale)
  gfxClock = gfxClock + dtReal

  local newDelay = gfxClock - simClock
  if math.abs(newDelay-prevDelay) > (1/2000/simScale) then
    if clockType ~= 1 then
      local percent = (newDelay-prevDelay) / dtReal
      log("W", "", string.format("Time slip detected: %05.2f%% or %05.1fms (total: %07.3fs)", percent*100, (newDelay-prevDelay)*1000, newDelay))
    end
  end

  counters.wall.clock = counters.wall.clock + dtRaw
  counters.wall.updates = counters.wall.updates + 1

  counters.graphics.clock = counters.graphics.clock + dtReal
  counters.graphics.updates = counters.graphics.updates + 1

  counters.cef.clock = counters.wall.clock
  counters.cef.updates = counters.cef.updates + 0 --TODO

  counters.physics.clock = counters.physics.clock + (dtSim/simScale)

  local timeSinceLastSent = counters.wall.clock - lastSent
  local fps = 25
  fps = 100000 -- unlimited updates
  if timeSinceLastSent > (1/fps) then

    counters.wall.value = 0
    counters.graphics.value = (counters.graphics.clock - counters.wall.clock)     / counters.wall.clock
    counters.physics.value =  (counters.physics.clock  - counters.wall.clock)     / counters.wall.clock
    counters.gfxpsx.value =      (counters.graphics.clock  - counters.physics.clock) / counters.physics.clock
    counters.max.value = (0.0005 * counters.wall.updates) / counters.wall.clock / simScale
    counters.min.value = -counters.max.value
    counters.cef.value = 0
    for k,v in pairs(counters) do
      v.value = (v.value * 100)
    end

    counters.wall.color = "white"
    counters.wall.lineWidth = 2
    counters.graphics.color = "red"
    counters.graphics.lineWidth = 2
    counters.graphics.unit = "% dev"
    counters.physics.color = "cyan"
    counters.physics.lineWidth = 3
    counters.physics.unit = "% dev"
    counters.gfxpsx.color = "white"
    counters.gfxpsx.lineWidth = 2
    counters.gfxpsx.unit = "% dev"
    counters.cef.color = "white"
    counters.min.color = "salmon"
    counters.max.color = "salmon"

    local fps = counters.wall.updates / counters.wall.clock
    local data = deepcopy(counters)
    data.cef = nil
    data.wall = nil
    --data.fps = {}
    --data.fps.value = fps
    --data.fps.color = "hotpink"
    --data.fps.lineWidth = 8

    --log("I", "", dumps(counters))
    guihooks.trigger("clockDebug", {counters=data, clockType=clockType, fps=fps, now=realClock})
    reset()
    lastSent = counters.wall.clock
  end
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

return M
