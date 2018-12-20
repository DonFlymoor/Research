-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
--- raceMarker position
local markerPosition = nil
--- raceMarkerNext position
local markerNextPosition = nil

local markerFinalPosition = nil

--[[doxygen
It hides all raceMarkers.
@param b    a boolean type
void hide(bool b);
--]]
local function hide(b)
  if scenetree.raceMarker then
    scenetree.raceMarker.hidden = b
  end
  if scenetree.raceMarkerBase then
    scenetree.raceMarkerBase.hidden = b
  end
  if scenetree.raceMarkerNext then
    scenetree.raceMarkerNext.hidden = b
  end
  if scenetree.raceMarkerFinal then
    scenetree.raceMarkerFinal.hidden = b
  end
  if scenetree.raceMarkerFinalBase then
    scenetree.raceMarkerFinalBase.hidden = b
  end
end

--[[doxygen
It initializes raceMarker,raceMarkerBase and raceMarkerNext.
Meanwhile, it also clear the states of raceMarkers.

void init();
--]]
local function createRaceMarker(markerName)
  local marker =  createObject('TSStatic')
  marker:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker.dae")
  marker:setPosition(Point3F(0, 0, 0))
  marker.scale = Point3F(1, 1, 1)
  marker:setField('rotation', 0, '1 0 0 0')
  marker.useInstanceRenderData = true
  marker:setField('instanceColor', 0, '1 1 1 1')
  marker:setField('collisionType', 0, "Collision Mesh")
  marker:setField('decalType', 0, "Collision Mesh")
  marker:setField('playAmbient', 0, "1")
  marker:setField('allowPlayerStep', 0, "1")
  marker:setField('canSaveDynamicFields', 0, "1")
  marker:setField('renderNormals', 0, "0")
  marker:setField('meshCulling', 0, "0")
  marker:setField('originSort', 0, "0")
  marker:setField('forceDetail', 0, "-1")
  marker.canSave = true
  marker:registerObject(markerName)  
  return marker
end

local function createRaceMarkerBase(baseName)
 local base =  createObject('TSStatic')
  base:setField('shapeName', 0, "art/shapes/interface/checkpoint_marker_base.dae")
  base:setPosition(Point3F(0, 0, 0))
  base.scale = Point3F(1, 1, 1)
  base:setField('rotation', 0, '1 0 0 0')
  base.useInstanceRenderData = true
  base:setField('instanceColor', 0, '1 1 1 1')
  base:setField('collisionType', 0, "Collision Mesh")
  base:setField('decalType', 0, "Collision Mesh")
  base:setField('playAmbient', 0, "1")
  base:setField('allowPlayerStep', 0, "1")
  base:setField('canSaveDynamicFields', 0, "1")
  base:setField('renderNormals', 0, "0")
  base:setField('meshCulling', 0, "0")
  base:setField('originSort', 0, "0")
  base:setField('forceDetail', 0, "-1")
  base.canSave = true
  base:registerObject(baseName)  
  return base
end

local function init()
  if scenetree.raceMarker then
    scenetree.raceMarker:delete()
  end

  if scenetree.raceMarkerBase then
    scenetree.raceMarkerBase:delete()
  end

  if scenetree.raceMarkerNext then
    scenetree.raceMarkerNext:delete()
  end

  if scenetree.raceMarkerFinal then
    scenetree.raceMarkerFinal:delete()
  end

   if scenetree.raceMarkerFinalBase then
    scenetree.raceMarkerFinalBase:delete()
  end

  if scenetree.ScenarioObjectsGroup then
    local ScenarioObjectsGroup = scenetree.ScenarioObjectsGroup
    local raceMarker = createRaceMarker("raceMarker")
    local raceMarkerBase = createRaceMarkerBase("raceMarkerBase")
    local raceMarkerNext = createRaceMarker("raceMarkerNext")

    local raceMarkerFinal = createRaceMarker("raceMarkerFinal")
    local raceMarkerFinalBase = createRaceMarkerBase("raceMarkerFinalBase")
    ScenarioObjectsGroup:addObject(raceMarker.obj)
    ScenarioObjectsGroup:addObject(raceMarkerBase.obj)
    ScenarioObjectsGroup:addObject(raceMarkerNext.obj)
    ScenarioObjectsGroup:addObject(raceMarkerFinal.obj)
    ScenarioObjectsGroup:addObject(raceMarkerFinalBase.obj)
  end

  hide(true)
  markerPosition = nil
  markerNextPosition = nil
  markerFinalPosition = nil
end

--[[doxygen
It is to render marker color during the scenario.
void render();
--]]
local function render()
   -- blend the marker
  local camPos = vec3(getCameraPosition())
  if scenetree.raceMarker and scenetree.raceMarkerBase and markerPosition then
    local camdistSqt = markerPosition:squaredDistance(camPos)
    local markerAlpha = camdistSqt / 2000
    if markerAlpha > 1 then markerAlpha = 1 end
    local oldColor = scenetree.raceMarker.instanceColor
    oldColor.w = markerAlpha
    scenetree.raceMarker.instanceColor = oldColor
    scenetree.raceMarkerBase.instanceColor = ColorF( 1, 1, 1, markerAlpha * 0.8):asLinear4F()
  end

  if scenetree.raceMarkerNext and markerNextPosition then
    local camdistSqt = markerNextPosition:squaredDistance(camPos)
    local markerAlpha = camdistSqt / 2000
    if markerAlpha > 1 then markerAlpha = 1 end
    local oldColor = scenetree.raceMarkerNext.instanceColor
    oldColor.w = markerAlpha * 0.5
    scenetree.raceMarkerNext.instanceColor = oldColor
  end

  if scenetree.raceMarkerFinal and scenetree.raceMarkerFinalBase and markerFinalPosition then
    local camdistSqt = markerFinalPosition:squaredDistance(camPos)
    local markerAlpha = camdistSqt / 2000
    if markerAlpha > 1 then markerAlpha = 1 end
    local oldColor = scenetree.raceMarkerFinal.instanceColor
    oldColor.w = markerAlpha
    scenetree.raceMarkerFinal.instanceColor = oldColor
    scenetree.raceMarkerFinalBase.instanceColor = ColorF( 1, 1, 1, markerAlpha * 0.8):asLinear4F()
  end

end


--[[doxygen
It sets new positions to raceMarker and raceMarkerBase in order the change their location.
@param pos    a table type for new position
@param nextRadius    a double type for new radius of marker
void setPosition(table pos, double nextRadius);
--]]
local function setPosition(pos, nextRadius, color)
  color = color or ColorF( 1, 0.07, 0, 1)
  markerPosition = vec3(pos)
  if scenetree.raceMarker and scenetree.raceMarkerBase then
    scenetree.raceMarker.hidden = false
    scenetree.raceMarker:setPosition(markerPosition:toPoint3F())
    scenetree.raceMarker:setScale(Point3F(nextRadius, nextRadius, 50))
    scenetree.raceMarker.instanceColor = color:asLinear4F()
    scenetree.raceMarkerBase.hidden = false
    scenetree.raceMarkerBase:setPosition(markerPosition:toPoint3F())
    scenetree.raceMarkerBase:setScale(Point3F(nextRadius*2, nextRadius*2, nextRadius*2))
  end
end

--[[doxygen
It sets new positions to raceMarkerNext in order the change their location.
@param posNext    a table type for new position
@param next2Radius    a double type for new radius of marker
void setNextPosition(table posNext, double next2Radius);
--]]
local function setNextPosition(posNext, next2Radius, color)
  color = color or ColorF( 0.3, 0.3, 0.3, 1)
  markerNextPosition = vec3(posNext)
  if scenetree.raceMarkerNext then
    scenetree.raceMarkerNext.hidden = false
    scenetree.raceMarkerNext:setPosition(markerNextPosition:toPoint3F())
    scenetree.raceMarkerNext:setScale(Point3F(next2Radius, next2Radius, 50))
    scenetree.raceMarkerNext.instanceColor = color:asLinear4F()
  end
end


--[[doxygen
It sets new positions to raceMarkerNext in order the change their location.
@param posNext    a table type for new position
@param next2Radius    a double type for new radius of marker
void setNextPosition(table posNext, double next2Radius);
--]]
local function setFinalMarkerPosition(pos, radius, color)
  color = color or ColorF( 0.3, 0.3, 0.3, 1)
  markerFinalPosition = vec3(pos)
  if scenetree.raceMarkerFinal and scenetree.raceMarkerFinalBase then
    scenetree.raceMarkerFinal.hidden = false
    scenetree.raceMarkerFinal:setPosition(markerFinalPosition:toPoint3F())
    scenetree.raceMarkerFinal:setScale(Point3F(radius, radius, 50))
    scenetree.raceMarkerFinal.instanceColor = color:asLinear4F()
    scenetree.raceMarkerFinalBase.hidden = false
    scenetree.raceMarkerFinalBase:setPosition(markerFinalPosition:toPoint3F())
    scenetree.raceMarkerFinalBase:setScale(Point3F(radius*2, radius*2, radius*2))  
  end
end

--[[doxygen
It sets raceMarker position, raceMarker and raceMarkerBase to initial states.
void clearStat();
--]]
local function clearStat()
  markerPosition = nil
  if scenetree.raceMarker then
    scenetree.raceMarker.hidden = true
  end

  if scenetree.raceMarkerBase then
    scenetree.raceMarkerBase.hidden = true
  end
end
--[[doxygen
It sets raceMarkerNext position, raceMarkerNext to initial states.
void clearNextStat();
--]]
local function clearNextStat()
  markerNextPosition = nil
  if scenetree.raceMarkerNext then
    scenetree.raceMarkerNext.hidden = true
  end
end

local function clearFinalStat()
  markerFinalPosition = nil
  if scenetree.raceMarkerFinal then
    scenetree.raceMarkerFinal.hidden = true
  end
  if scenetree.raceMarkerFinalBase then
    scenetree.raceMarkerFinalBase.hidden = true
  end
end

local function removeFinalMarker()
  if scenetree.raceMarkerFinal then
    scenetree.raceMarkerFinal:deleteObject()
  end
  if scenetree.raceMarkerFinalBase then
    scenetree.raceMarkerFinalBase:deleteObject()
  end  
end

--[[doxygen
It initializes raceMarker,raceMarkerBase and raceMarkerNext.
Meanwhile, it also clear the states of raceMarkers.
void init();
--]]
M.init = init

--[[doxygen
It is to render marker color during the scenario.
void render();
--]]
M.render = render

--[[doxygen
It hides all raceMarkers.
@param b    a boolean type
void hide(bool b);
--]]
M.hide = hide

--[[doxygen
It sets new positions to raceMarker and raceMarkerBase in order the change their location.
@param pos    a table type for new position
@param nextRadius    a double type for new radius of marker
void setPosition(table pos, double nextRadius);
--]]
M.setPosition = setPosition

--[[doxygen
It sets new positions to raceMarkerNext in order the change their location.
@param posNext    a table type for new position
@param next2Radius    a double type for new radius of marker
void setNextPosition(table posNext, double next2Radius);
--]]
M.setNextPosition = setNextPosition

M.setFinalMarkerPosition = setFinalMarkerPosition

--[[doxygen
It sets raceMarker position, raceMarker and raceMarkerBase to initial states.
void clearStat();
--]]
M.clearStat = clearStat

--[[doxygen
It sets raceMarkerNext position, raceMarkerNext to initial states.
void clearNextStat();
--]]
M.clearNextStat = clearNextStat

M.clearFinalStat = clearFinalStat

M.removeFinalMarker = removeFinalMarker
M.createRaceMarker = createRaceMarker
return M
