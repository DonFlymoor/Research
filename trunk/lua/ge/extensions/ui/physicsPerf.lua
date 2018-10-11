-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local timer = 0

local function onPreRender(dtReal, dtSim, dtRaw)
  timer = timer + dtReal
  if timer > 5 then
    guihooks.trigger('physicsperf', be:getPerformanceImpacts())
    timer = timer - 5
  end
end

M.onPreRender = onPreRender

return M


