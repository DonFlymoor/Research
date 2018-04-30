-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local abs = math.abs

M.gx = 0
M.gy = 0
M.gz = 0
M.gx2 = 0
M.gy2 = 0
M.gz2 = 0

M.gxMax = 0
M.gxMin = 0

M.gyMax = 0
M.gyMin = 0

M.gzMax = 0
M.gzMin = 0

M.gxSmoothMax = 0

local gx_smooth2 = nil
local gy_smooth2 = nil
local gz_smooth2 = nil
local gx_Smoother = nil
local gx_smooth3 = nil

local resetTimer = 0
local resetTime  = 10 -- time when the min/max values are getting reset

local function resetMinMax()
  M.gxMax = 0
  M.gxMin = 0
  M.gyMax = 0
  M.gyMin = 0
  M.gzMax = 0
  M.gzMin = 0
end

local function reset()
  gx_smooth2 = newTemporalSmoothingNonLinear(7)
  gy_smooth2 = newTemporalSmoothingNonLinear(7)
  gz_smooth2 = newTemporalSmoothingNonLinear(7)
  gx_Smoother = newTemporalSmoothing(4) -- it acts like a timer

  resetMinMax()
end

local function updateGFX(dt)
  if not gx_smooth2 then return end
  resetTimer = resetTimer + dt
  if resetTimer > resetTime then
    resetMinMax()
    resetTimer = 0
  end
  M.gx = obj:getSensorX()
  M.gy = obj:getSensorY()
  M.gz = obj:getSensorZnonInertial()

  M.gx2 = gx_smooth2:get(M.gx, dt)
  M.gy2 = gy_smooth2:get(M.gy, dt)
  M.gz2 = gz_smooth2:get(M.gz, dt)

  M.gxSmoothMax = gx_Smoother:getUncapped(0, dt)
  local absgx = abs(M.gx)
  if absgx > M.gxSmoothMax then
    gx_Smoother:set(absgx)
    M.gxSmoothMax = absgx
  end

  M.gxMax = math.max(M.gxMax, M.gx2)
  M.gxMin = math.min(M.gxMin, M.gx2)
  M.gyMax = math.max(M.gyMax, M.gy2)
  M.gyMin = math.min(M.gyMin, M.gy2)
  M.gzMax = math.max(M.gzMax, M.gz2)
  M.gzMin = math.min(M.gzMin, M.gz2)
end

local function init()
  resetMinMax()
  if not v.data.refNodes then
    return
  end

  if v.data.engine == nil and (v.data.hydros == nil or tableSize(v.data.hydros) == 0) then
    return
  end

  M.reset()
end
-- public interface
M.updateGFX = updateGFX
M.reset = reset
M.init = init

return M
