-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxiliary"
M.relevantDevice = nil

local beaconSpeed = 0
local electricsName = nil

local function updateGFX(dt)
  electrics.values[electricsName] = electrics.values.lightbar > 0 and ((electrics.values.beaconSpin + (dt * beaconSpeed)) % 360) or 0
end

local function init(jbeamData)
  beaconSpeed = jbeamData.spinSpeed or 320
  electricsName = jbeamData.electricsName or "beaconSpin"
  electrics.values[electricsName] = 1
end

M.init = init
M.updateGFX = updateGFX

return M
