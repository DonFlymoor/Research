-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local ffi = require('ffi')
local im = extensions.ui_imgui
local items = {} 
local subModules ={}
local utils = {'veTriUtils','veBeamUtils','veNodeUtils','veUtils'}

local function onDebugDraw(dt)
  if im.BeginMainMenuBar() then
    if im.BeginMenu("Apps") then
      for _, item in ipairs(items) do
        if item[3] then
          if im.BeginMenu(item[1]) then
            for k,v in pairs(item[3]) do
              if im.MenuItem1(v) then
                item[2](k)
              end
            end
            im.EndMenu()
          end
        elseif im.MenuItem1(item[1]) then
          item[2]()
        end
      end
      im.EndMenu()
    end
    im.EndMainMenuBar()
  end
end

-- loads all extensions in the vehicleeditor subfolder
local function onExtensionLoaded()
  local luaFiles = FS:findFiles('/lua/vehicle/extensions/vehicleeditor/', 've*.lua', -1, true, false)
  items = {}
  for _, fn in ipairs(luaFiles) do
    local path, fn, ext = path.split(fn)
    local name = string.sub(fn, 1, -5)
    if name ~= 'veMain' and not tableFindKey(utils,name) then
      local ext = extensions.use('vehicleeditor_' .. name)
      table.insert(subModules,'vehicleeditor_' .. name)
      if type(ext.open) == 'function' and type(ext.menuEntry) == 'string' then
        if type(ext.subItems) == 'table' then
          table.insert(items, {ext.menuEntry, ext.open, ext.subItems})
        else
          table.insert(items, {ext.menuEntry, ext.open})
        end
      end
    end
  end
end
local function onExtensionUnloaded()
  for _,k in pairs(subModules) do
    extensions.unload(k)
  end
  subModules = {}
end

-- public interface
M.onDebugDraw = onDebugDraw
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onSerialize = onSerialize
return M
