-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local blurRects = {}

local function addToGroup (group, rects)
  -- TODO
end

local function replaceGroup (group, rects)
  blurRects[group] = rects
end

local function removeGroup (group)
  blurRects[group] = nil
end 

local function removeAllGroups ()
  blurRects = {}
end


-- Blur api:
-- (0, 0) is top left corner; (1, 1) bottom right
-- maskedBlurFX.obj:addFrameBlurRect(0, 0.15, 1, 0.8)

local function onPreRender () 
  local maskedBlurFX = scenetree.ScreenBlurFX
  if maskedBlurFX then

    for _, list in pairs(blurRects) do
      for _, rect in pairs(list) do
        maskedBlurFX.obj:addFrameBlurRect(rect[1], rect[2], rect[3], rect[4])
      end
    end

  end
end

local function onExtensionLoaded () 
  -- TODO
end

local function onExtensionUnloaded () 
  -- TODO
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onPreRender = onPreRender

M.replaceGroup = replaceGroup
M.removeGroup = removeGroup
M.removeAllGroups = removeAllGroups
M.setColor = setColor

M.rects = blurRects

return M