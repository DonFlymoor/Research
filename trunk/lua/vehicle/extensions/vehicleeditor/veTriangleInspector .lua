local M = {}

M.menuEntry = 'Triangle Inspector'
M.subItems  = {'by connected node','by tri name '}
local veTriangleNodes = extensions.vehicleEditor_veTriangleNodes
local veTriangleNames = extensions.vehicleEditor_veTriangleNames
local im = extensions.ui_imgui
local ffi = require('ffi')
local triNodeWindow = im.BoolPtr(false)
local triNameWindow = im.BoolPtr(false)
local setWindowSize = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(100, 100)


local function onDebugDraw()
  if triNodeWindow[0] then
    if im.Begin('Find Tri by node', triNodeWindow, im.WindowFlags_AlwaysHorizontalScrollbar) then
      veTriangleNodes.findTriByNode()
    end
    im.End()
  end
  if triNameWindow[0] then
    if im.Begin('Find Tri By Name', triNameWindow,im.WindowFlags_AlwaysHorizontalScrollbar) then
      veTriangleNames.findTriByName()
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
    triNodeWindow = triNodeWindow[0],
    triNameWindow = triNameWindow[0],
  }
end

local function onDeserialized(data)
  triNodeWindow[0] = data.triNodeWindow
  triNameWindow[0] = data.triNameWindow
end

local function open(index)
  if index ==1 then
    triNodeWindow[0] = true
    triNameWindow[0] = false
  elseif index == 2 then
    triNodeWindow[0] = false
    triNameWindow[0] = true
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