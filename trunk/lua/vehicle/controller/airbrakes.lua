-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local max = math.max

local lastBrake = 0
local sampleWindow = 0.25
local doSample = false
local sampleTimer = 0
local sampleStart = 0
local coolDownTimer = 0
local soundNode = 0

local function updateGFX(dt)
  local brake = electrics.values.brake or 0
  coolDownTimer = max(coolDownTimer - dt, 0)
  if lastBrake - brake > 0.01 and not doSample and coolDownTimer <= 0 then
    doSample = true
    sampleTimer = 0
    sampleStart = lastBrake
  end

  if doSample then
    sampleTimer = sampleTimer + dt
    if sampleTimer >= sampleWindow then
      local dBrake = (brake - sampleStart) / sampleTimer
      doSample = false
      if dBrake < -0.2 then
        local intensity = -dBrake * sampleWindow
        --print(intensity)
        obj:playSFXOnce("event:>Vehicle>Pneumatics>Air_Brakes", soundNode, intensity, 1.0)
        coolDownTimer = 0.5
      end
    end
  end

  lastBrake = brake
end

local function reset()
  lastBrake = 0
  coolDownTimer = 0
  doSample = false
  sampleStart = 0
end

local function init(jbeamData)
  lastBrake = 0
  coolDownTimer = 0
  doSample = false
  sampleStart = 0

  if jbeamData.soundNode_nodes and type(jbeamData.soundNode_nodes) == "table" and type(jbeamData.soundNode_nodes[1]) == "number" then
    soundNode = jbeamData.soundNode_nodes[1]
  else
    soundNode = 0
  end
end

M.init = init
M.reset = reset
M.updateGFX = updateGFX

return M