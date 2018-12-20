-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.menuEntry = 'Node Inspector'
M.subItems  = {'Node name','Key/value', 'Node Id'}
local veNodeKeyValue = extensions.vehicleEditor_veNodeKeyValue
local veNodeName = extensions.vehicleEditor_veNodeName
local veNodeId = extensions.vehicleEditor_veNodeId
local im = extensions.ui_imgui
local ffi = require('ffi')

local byNameWindowOpen = im.BoolPtr(false)
local byKeyWindowOpen = im.BoolPtr(false)
local byNodeIdWindowOpen = im.BoolPtr(false)

local setWindowSize = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(100, 100)

local function onDebugDraw()
  if setWindowSize[0] then
    im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
    im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
    setWindowSize[0] = false
  end
  if byNameWindowOpen[0] then
    if im.Begin('Find Node By Name', byNameWindowOpen, 0) then
      veNodeName.findNodeName()
    end
    im.End()
  end
  if byKeyWindowOpen[0] then
    if im.Begin('Find Node By key',byKeyWindowOpen,0) then
      veNodeKeyValue.findNodeByKey()
    end
    im.End()
  end
  if byNodeIdWindowOpen[0] then
    if im.Begin("Find Node By Id",byNodeIdWindowOpen,0) then
      veNodeId.findNodeById()
    end
    im.End()
  end
end

local function onSerialize()
  return {
    byNameWindowOpen = byNameWindowOpen[0],
    byKeyWindowOpen = byKeyWindowOpen[0],
    byNodeIdWindowOpen = byNodeIdWindowOpen[0],
  }
end

local function onDeserialized(data)
  byNameWindowOpen[0] = data.byNameWindowOpen
  byKeyWindowOpen[0] = data.byKeyWindowOpen
  byNodeIdWindowOpen[0] = data.byNodeIdWindowOpen
end

local function open(index)
  if index == 1 then
    byKeyWindowOpen[0] = false
    byNameWindowOpen[0] = true
    byNodeIdWindowOpen[0] = false
  elseif index == 2 then
    byNameWindowOpen[0] = false
    byKeyWindowOpen[0] = true
    byNodeIdWindowOpen[0] = false
  elseif index == 3 then
    byNodeIdWindowOpen[0] = true
    byNameWindowOpen[0] = false
    byKeyWindowOpen[0] = false
  end
  setWindowSize[0] = true
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

return M
