-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local name = nil
local electricsName = nil
local isWarning = false
local beepLoopName = nil
local beepLoop = nil
local beepVolume = 1
local tick = 0
local soundNode = 0


local function updateGFX(dt)
  tick = tick + dt
  if tick >= 0.5 then
    tick = 0
    if (electrics.values[electricsName] or 0) > 0 then
      if not isWarning then
        obj:setVolume(beepLoop, beepVolume)
        obj:playSFX(beepLoop)
        isWarning = true
      end
    elseif isWarning then
      obj:stopSFX(beepLoop)
      isWarning = false
    end
  end
end

local function reset()
  isWarning = false
  tick = 0
end

local function init(jbeamData)
  name = jbeamData.name
  electricsName = jbeamData.electricsName or "reverse"
  beepLoopName = jbeamData.beepLoopName or "event:>Vehicle>Electrics>Reverse>Beep_01"
  beepVolume = jbeamData.beepVolume or 1

  isWarning = false

  if jbeamData.soundNode_nodes and type(jbeamData.soundNode_nodes) == "table" and type(jbeamData.soundNode_nodes[1]) == "number" then
    soundNode = jbeamData.soundNode_nodes[1]
  else
    soundNode = 0
  end
  --print(soundNode)
end

local function initSounds()
  beepLoop = obj:createSFXSource(beepLoopName, "AudioDefaultLoop3D", "reverseBeep", soundNode)
end

M.init = init
M.initSounds = initSounds
M.reset = reset
M.updateGFX = updateGFX

return M