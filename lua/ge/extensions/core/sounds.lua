
local M = {}
local lastCamPos = nil
local SFXSnapshotTriggerId = nil

local function setGlobalParameter(name, value)
  globalParams:setParameterValue(name, value)
end

local function onPreRender(dt)
  local tod = scenetree.tod
  if Engine.Audio.getGlobalParams then
    local globalParams = Engine.Audio.getGlobalParams()
    if globalParams then
      if tod and tod.time then
        globalParams:setParameterValue("g_Tod", tod.time)
      end
      lastCamPos = lastCamPos or getCameraPosition()
      globalParams:setParameterValue("g_CamSpeedMS", (getCameraPosition() - lastCamPos):len() / dt)
      lastCamPos = getCameraPosition()

      globalParams:setParameterValue("g_CamOnboard", core_camera and core_camera.isCameraInside(0) and 1 or 0)

      local camObj = getCamera()
      globalParams:setParameterValue("g_CamFree", (camObj and camObj:isSubClassOf('BeamNGVehicle') and 0) or 1)
    end
  end
end

local function initEngineSound(vehicleId, engineId, jsonPath, nodeId, noloadVol, loadVol)
  local vehicle = scenetree.findObjectById(vehicleId)
  if vehicle then
    vehicle:engineSoundInit(engineId, jsonPath, nodeId or -1, noloadVol or 1, loadVol or 1)
    vehicle:engineSoundParameterList(engineId, {wet_level = 0, dry_level = 1})
  end
end

local function updateEngineSound(vehicleId, engineId, rpm, onLoad, engineVolume)
  local vehicle = scenetree.findObjectById(vehicleId)
  if not vehicle then return end
  vehicle:engineSoundUpdate(engineId, rpm, onLoad, engineVolume)
end

local function setEngineSoundParameter(vehicleId, engineId, paramName, paramValue)
  local vehicle = scenetree.findObjectById(vehicleId)
  if not vehicle then return end
  vehicle:engineSoundParameter(engineId, paramName, paramValue)
end

local function setEngineSoundParameterList(vehicleId, engineId, parameters)
  local vehicle = scenetree.findObjectById(vehicleId)
  if not vehicle then return end
  vehicle:engineSoundParameterList(engineId, parameters)
end

M.setGlobalParameter = setGlobalParameter
M.onPreRender = onPreRender
M.initEngineSound = initEngineSound
M.updateEngineSound = updateEngineSound
M.setEngineSoundParameter = setEngineSoundParameter
M.setEngineSoundParameterList = setEngineSoundParameterList

return M
