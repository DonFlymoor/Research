-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

-- this file should contain all the lua things for the garage mode

local garageLevel = 'levels/garage/info.json' 

local inputActionFilter = require('input_action_filter')
--local ambientSoundPlayOnce= require('lua/ge/extensions/ui/ambientSound')
inputActionFilter.setGroup('garage_camera_blacklist', {"toggleCamera", "toggleFirstPerson", "dropCameraAtPlayer", "dropPlayerAtCamera"} )
inputActionFilter.setGroup('garage_nodegrabber_blacklist', {"nodegrabberRender"} )
inputActionFilter.setGroup('garage_uiActions_blacklist', {"switch_next_vehicle", "switch_previous_vehicle", "vehicle_selector", "parts_selector", "toggle_help", "options", "photomode"} )

local soundParams = nil

-- sounds
local ambientSoundIdGeneral = nil
local ambStream1ID,ambStream2ID
local vehicleID = nil
local maxCameraDistance = 6
local ambSoundDay = nil

local function _start()
  guihooks.trigger('ChangeState', 'garage.menu.select')
  core_gamestate.setGameState('garage', 'garage', 'none')

  inputActionFilter.clear(0)
  inputActionFilter.addAction(0, 'garage_camera_blacklist', true)
  inputActionFilter.addAction(0, 'garage_nodegrabber_blacklist', true)
  inputActionFilter.addAction(0, 'garage_uiActions_blacklist', true)

  if core_environment then
    local tod = core_environment.getTimeOfDay()
    if tod and tod.dayLength then
        local dayLengthMs = tod.dayLength * 1000
        tod.time = (Engine.Platform.getRealMilliseconds() % dayLengthMs) / dayLengthMs
        core_environment.setTimeOfDay(tod)
    end
  end

  vehicleID = be:getPlayerVehicleID(0)
  core_camera.setMaxDistance(vehicleID, maxCameraDistance)
end

local function _end()
  core_camera.setMaxDistance(vehicleID, nil)
  inputActionFilter.clear(0)

  -- delete sounds
  if ambientSoundIdGeneral then
    Engine.Audio.deleteSource(ambientSoundIdGeneral)
    ambientSoundIdGeneral = nil
  end

  serverConnection.disconnect()  
end

local function activate()
  log('D', 'garage.activate', "activated")
  local missionFile = getMissionFilename()
  if missionFile ~= garageLevel then
    core_levels.startLevel(garageLevel)--Tested&&Works
  else
    _start()
  end
end

local function onExtensionLoaded()
  log('D', 'garage.onExtensionLoaded', "ui/garage module loaded")
  activate()

end

local function onExtensionUnloaded()
  local missionFile = getMissionFilename()
  inputActionFilter.clear(0)
  if missionFile == garageLevel then
    _end()
  end
end

local function onVehicleSwitched(oldVehicle, newVehicle, player)  
  if player ~= 0 then return end
  local newvehicle =  be:getObjectByID(newVehicle)
  newvehicle:queueLuaCommand('controller.setFreeze(1)')
  newvehicle:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
  vehicleID = newVehicle
  core_camera.setMaxDistance(vehicleID, maxCameraDistance)
end

local function onCameraModeChanged(modeName)
  if modeName then    
    core_camera.setMaxDistance(vehicleID, maxCameraDistance)
  end
end

local function onClientStartMission(missionFile)
  if missionFile == garageLevel then
    _start()

    soundParams = SFXParameterGroup("GarageSoundParams")

    -- start playing ambient levels
    ambientSoundIdGeneral = Engine.Audio.createSource('AudioGui', 'event:>Ambient>Maps>Garage>Generic')
    local ambSoundGeneral = scenetree.findObjectById(ambientSoundIdGeneral)
    if(ambSoundGeneral) then
      ambSoundGeneral:play(-1)
      soundParams:addSource(ambSoundGeneral.obj)
    end
  end
end

local function onClientEndMission(missionFile)
  
end

local dayValue = newTemporalSmoothing(0.5, 0.5)

local function onPreRender(dt)
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onClientStartMission = onClientStartMission
M.onClientEndMission = onClientEndMission
M.onVehicleSwitched = onVehicleSwitched
M.onCameraModeChanged = onCameraModeChanged
M.onPreRender = onPreRender

M.activate = activate

return M
