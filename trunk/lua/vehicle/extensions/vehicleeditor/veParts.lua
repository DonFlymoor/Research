-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.menuEntry = 'Parts'
local imguiUtils = require('ui/imguiUtils')

local im = extensions.ui_imgui
local vePartsConfig =extensions.vehicleEditor_vePartsConfig
local veTuning = extensions.vehicleEditor_veTuning
local windowOpen = im.BoolPtr(false)
local tuningWindow = im.BoolPtr(false)
local partsWindow = im.BoolPtr(false)

local function partshighlightcb(fullpath, k, val)
  if type(val) == 'table' and val.partName then
    partmgmt.selectPart(val.partName, true)
  end
  --print('hovered item: ' .. tostring(k) .. ' , path: ' .. tostring(fullpath))
end

local function itemCallback(begin, fullpath, k, val)
  if type(val) ~= 'table' then return end
  if begin then
    if val.active then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
    else
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
    end
  else
    im.PopStyleColor()
  end
  return true
end

local function Menu()
  if im.BeginMenuBar() then
    if im.BeginMenu("Vehicle Config") then
      if im.MenuItem1("Parts") then
        partsWindow[0]  = true
      end
      if im.MenuItem1("Tuning") then  
        tuningWindow[0] = true
      end
      im.EndMenu()
    end
    im.EndMenuBar()
  end
  
  if partsWindow[0] then
   if im.Begin("Parts##",partsWindow) then
     vePartsConfig.displayParts(v.slotMap, 'parts')
    end
    im.End()
  end
  if tuningWindow[0] then
    if im.Begin('Tuning',tuningWindow) then
      veTuning.tuning()
    end
    im.End()
  end
end
local function onDebugDraw(dt)
  if windowOpen[0] ~= true then return end
  
  if im.Begin("Parts", windowOpen,im.WindowFlags_MenuBar) then
    Menu()
    if im.CollapsingHeader1("Slots Raw") then
      imguiUtils.addRecursiveTreeTable(v.slotMap, '', false, partshighlightcb, itemCallback)
    end
    if im.CollapsingHeader1("Descriptions") then
      imguiUtils.addRecursiveTreeTable(v.slotDescriptions, '')
    end
    if im.CollapsingHeader1("Variables") then
      imguiUtils.addRecursiveTreeTable(v.variables, '')
    end
  end
  im.End() 
end

local function onSerialize()
  return {
    windowOpen = windowOpen[0],
    tuningWindow = tuningWindow[0],
    partsWindow = partsWindow[0],
  }
end

local function onDeserialized(data)
  windowOpen[0] = data.windowOpen
  tuningWindow[0] = data.tuningWindow
  partsWindow[0] = data.partsWindow
end

local function open()
  windowOpen[0] = true
  vePartsConfig.initialize = true
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