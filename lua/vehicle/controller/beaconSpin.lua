-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = nil

local beaconSpeed = 0

local function init(jbeamData)
  beaconSpeed = jbeamData.spinSpeed or 320
  electrics.values.beaconSpin = 1
end

local function updateGFX(dt)
  electrics.values.beaconSpin = electrics.values.lightbar > 0 and ((electrics.values.beaconSpin + (dt * beaconSpeed)) % 360) or 0
end

M.init = init
M.updateGFX = updateGFX

return M