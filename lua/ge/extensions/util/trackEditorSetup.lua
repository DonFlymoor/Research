-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}



local simpleSplineTrack = require('util/simpleSplineTrack')





local function onScenarioLoaded(sc) 
  simpleSplineTrack.unloadAll()
  simpleSplineTrack.load(sc.track.customData.name)
  
  simpleSplineTrack.addCheckPointPositions()
  simpleSplineTrack.positionVehicle()

end


local function onClientEndMission()
    simpleSplineTrack.removeTrack()
    simpleSplineTrack.unloadAll()
end

M.onScenarioLoaded = onScenarioLoaded
M.onClientEndMission = onClientEndMission

return M

