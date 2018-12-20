-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt


local M = {}
local terrain = nil

local function onClientStartMission()
  terrain = nil
end

local function getTerrainHeight(point)
  if not terrain then
    local terrains = scenetree.findClassObjects("TerrainBlock")
    terrain = scenetree.findObject(terrains[1])
  end

  if terrain then
    return terrain:getHeight(point)
  end
  return nil
end


-- public interface
M.onClientStartMission = onClientStartMission
M.getTerrainHeight = getTerrainHeight

return M
