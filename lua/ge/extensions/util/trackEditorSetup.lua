-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local simpleSplineTrack

local function onScenarioLoaded(sc) 
	simpleSplineTrack = extensions.util_simpleSplineTrack

  simpleSplineTrack.unloadAll()
  simpleSplineTrack.load(sc.track.customData.name, true, true)
  
  simpleSplineTrack.addCheckPointPositions(sc.track.reverse)
  simpleSplineTrack.positionVehicle(sc.track.reverse)
end

M.onScenarioLoaded = onScenarioLoaded
return M

