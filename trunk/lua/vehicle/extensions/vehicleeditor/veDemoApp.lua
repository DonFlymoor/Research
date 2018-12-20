-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this is a tiny example imgui app to be integrated within the vehicle editor. Please copy and rename it before modifying it.

local M = {}

M.menuEntry = 'Demo app' -- what the menu item will be

local im = extensions.ui_imgui

local windowOpen = im.BoolPtr(false)

-- main drawing function
local function onDebugDraw()
  if windowOpen[0] ~= true then return end -- if window is invisible, do nothing

  -- window
  if im.Begin('My Window Title', windowOpen, 0) then

    -- some example text
    im.Text('Gear: ')
    im.SameLine()
    im.Text(tostring(electrics.values.gear))

    -- TODO: draw whatever you want here

  end
  -- please do not forget to 'close' the window with end
  im.End()
end

-- helper function to open the window
local function open()
  windowOpen[0] = true
end

-- called when the extension is loaded (might be invisible still)
local function onExtensionLoaded()
end

-- called when the extension is unloaded
local function onExtensionUnloaded()
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.onDebugDraw = onDebugDraw

M.open = open

return M
