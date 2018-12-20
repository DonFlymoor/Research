local M = {}

local im = extensions.ui_imgui
local imguiUtils = require('ui/imguiUtils')
local ffi = require('ffi')
local veBeamUtils = extensions.vehicleEditor_veBeamUtils
local deformBeamPtr = im.IntPtr(0)

function M.displayDeforemdBeam(lens)
  local beamsString = ''
  local deformedBeams = {}
  for i=0,#v.data.beams do
    local deformation = obj:getBeamDebugDeformation(v.data.beams[i].cid)
    if deformation ~=1 then  
      beamsString = beamsString .. tostring(v.data.beams[i].cid).. "\0"
      table.insert(deformedBeams,v.data.beams[i].cid)
    end
  end
  if beamsString ~= '' then
    im.Combo2("Deformed Beams", deformBeamPtr, beamsString)
    im.Separator()
    veBeamUtils.displayLiveData(deformedBeams[deformBeamPtr[0]+1],lens)
  else
    im.Text('No beam deformed')
  end
end

local function onSerialize()
  return {
  }
end 
local function onDeserialized(data)
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

return M