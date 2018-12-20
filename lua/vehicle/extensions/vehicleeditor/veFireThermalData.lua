local M ={}

local imguiUtils = require('ui/imguiUtils')
local thermal = require('powertrain/combustionEngineThermals')
local veNodeUtils = extensions.vehicleEditor_veNodeUtils
local im = extensions.ui_imgui
local ffi = require('ffi')
M.menuEntry = 'Fire/Thermal'

local setWindowSize = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(100, 100)
local windowOpen = im.BoolPtr(false)
function M.displayThermal()
  if im.TreeNodeEx1('Thermal') then
    --imguiUtils.addRecursiveTreeTable(thermal.debug.engineThermalData,'',false)
  end
end
local function onDebugDraw()
  if setWindowSize[0] then
    im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
    im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
    setWindowSize[0] = false
  end
  if windowOpen[0] then
    if im.Begin('Fire/Thermal Data', windowOpen , 0) then
      veNodeUtils.displayFiredata()
      M.displayThermal()
    end
    im.End()
  end
end

local function onSerialize()
  return {
  }
end

local function onDeserialized(data)

end

local function open(index)
  windowOpen[0] = true
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
