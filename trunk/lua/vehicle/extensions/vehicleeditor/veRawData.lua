-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.menuEntry = 'Raw Data'

local imguiUtils = require('ui/imguiUtils')

local im = extensions.ui_imgui
local ffi = require('ffi')

local windowOpen = im.BoolPtr(false)
local nameFilter = im.ArrayChar(128)

local function datahighlightcb(fullpath, k, val)
  if string.find(fullpath, '/beams/') == 1 then
    obj.debugDrawProxy:drawBeam3d(val.cid, 0.1, color(255,0,0,255))
  elseif string.find(fullpath, '/nodes/') == 1 then
    obj.debugDrawProxy:drawNodeSphere(val.cid, 0.1, color(255,0,0,255))
  else
    --print('hovered item: ' .. tostring(k) .. ' , path: ' .. tostring(fullpath) .. ' = ' ..tostring(val))
  end
end

--local function itemCallback(begin, fullpath, k, val)
--  return string.find(fullpath, ffi.string(nameFilter))
--end

local function onDebugDraw(dt)
  if windowOpen[0] ~= true then return end

  if im.Begin("Raw Vehicle Data", windowOpen, 0) then
    --im.InputText("", nameFilter)
    --im.Text(nameFilter)

    imguiUtils.addRecursiveTreeTable(v.data, '', false, datahighlightcb)
  end
  im.End()
end

local function onSerialize()
  return {
    windowOpen = windowOpen[0],
  }
end

local function onDeserialized(data)
  windowOpen[0] = data.windowOpen
end

local function open()
  windowOpen[0] = true
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