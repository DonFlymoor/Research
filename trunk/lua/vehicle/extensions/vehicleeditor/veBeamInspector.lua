
-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.menuEntry = 'Find Beam By'
M.subItems = {'Connected node', 'Beam Name','Deformed Beams'}

local vedeformedBeam =extensions.vehicleEditor_veDeformation
local vebeamNodes = extensions.vehicleEditor_veBeamNodes
local vebeamName = extensions.vehicleEditor_veBeamName
local im = extensions.ui_imgui
local ffi = require('ffi')
local nodeWindow = im.BoolPtr(false)
local beamNameWindow = im.BoolPtr(false)
local deformBeamWindow = im.BoolPtr(false)
local setWindowSize = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(100, 100)
local beamLegths = {}
local initialize = false

local function initialize()
  if M.initialize then return end
  for i=0,#v.data.beams-1 do
    beamLegths[v.data.beams[i].cid] = obj:getBeamLength(v.data.beams[i].cid)
  end
  M.initialize = true
end
local function onDebugDraw()
  if nodeWindow[0] then
    if im.Begin('Find Beam By connected node', nodeWindow, im.WindowFlags_AlwaysHorizontalScrollbar) then
      vebeamNodes.findBeamByConnectedNode(beamLegths)
    end
    im.End()
  end
  if beamNameWindow[0] then
    if im.Begin('Find Beam By Name', beamNameWindow,im.WindowFlags_AlwaysHorizontalScrollbar) then
      vebeamName.findBeamByName(beamLegths)
    end
    im.End()
  end
  if deformBeamWindow[0] then
    if im.Begin('Deformed beams', deformBeamWindow,im.WindowFlags_AlwaysHorizontalScrollbar) then
      vedeformedBeam.displayDeforemdBeam(beamLegths)
    end
    im.End()
  end
  if setWindowSize[0] then
    im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
    im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
    setWindowSize[0] = false
  end
end

local function onSerialize()
  return {
    nodeWindow = nodeWindow[0],
    beamNameWindow = beamNameWindow[0],
    deformBeamWindow = deformBeamWindow[0],
    beamLegths = beamLegths,
  }
end

local function onDeserialized(data)
  nodeWindow[0] = data.nodeWindow
  beamNameWindow[0] = data.beamNameWindow
  deformBeamWindow[0] = data.deformBeamWindow
  beamLegths = data.beamLegths
end

local function open(index)
  if index ==1 then
    nodeWindow[0] = true
    beamNameWindow[0] = false
  elseif index == 2 then
    nodeWindow[0] = false
    beamNameWindow[0] = true
  elseif index==3 then
    deformBeamWindow[0] =true
  end
  setWindowSize[0] = true
  initialize()
end

local function onExtensionLoaded()

end

local function onExtensionUnloaded()
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized
M.onDebugDraw = onDebugDraw
M.open = open
M.beamDeformed = beamDeformed

return M
