-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'bngSandboxTest'

local function sandboxTest(results)
  if results.imageLoaded == false and results.locationChanged == false and results.whitelistTest == true then
    log('E', logTag, "External source was not loaded! Window location did not change! Whitelist is working! Succeeded Test.")
  else
    log('E', logTag, "Failed Test.")
  end
  shutdown(0)
end

M.sandboxTest = sandboxTest

return M