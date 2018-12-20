-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this tiny module helps setting the steam rich presence

local M = {}

-- How to use: print(extensions.util_richPresence.set('yolo'))
M.state = { levelName = "", vehicleName = "" }

local function msgFormat()
  local msg = "Playing "

  if extensions.core_gamestate.state.state then
    msg = msg.. tostring((core_gamestate.state.state:gsub("^%l", string.upper)) )
  end

  if M.state.levelName ~= "" then
    msg = msg .. " on " .. M.state.levelName .. " "
  end

  if M.state.vehicleName ~= "" then
    msg = msg .. " with " .. M.state.vehicleName
  end

  M.set(msg)
end

local function onVehicleSwitched(oldId, newId, player)
  local currentVehicle = core_vehicles.getCurrentVehicleDetails()
  if currentVehicle.model.Name then
    if currentVehicle.model.Brand then
      M.state.vehicleName = currentVehicle.model.Brand .. " " .. currentVehicle.model.Name
    else
      M.state.vehicleName = currentVehicle.model.Name
    end
  end
  msgFormat()
end

local function onClientPostStartMission(mission)
  local currentLevel = string.match(mission, "/?levels/(.-)/") or ''
  if currentLevel ~= "" then
    M.state.levelName = currentLevel:gsub("^%l", string.upper)
    M.state.levelName = M.state.levelName:gsub("_", " ")
    M.state.levelName = string.gsub(" "..M.state.levelName, "%W%l", string.upper):sub(2)
    msgFormat()
  end
end

local function onEditorEnabled(enabled)
  if enabled then
    M.set('Level editing')
  else
    msgFormat()
  end
end

local function onGameStateUpdate(state)
  msgFormat()
end


local function onExtensionLoaded()
  Steam.setRichPresence('steam_display', '#BNGGSW') -- BNGGSW = BeamNG Generic Status Wrapper
  Steam.setRichPresence('status', beamng_windowtitle) -- will show up in the 'view game info' dialog in the Steam friends list.

  if not shipping_build or not string.match(beamng_windowtitle, "RELEASE") then
    M.set = nop
  end
end

local function onExtensionUnloaded()
  Steam.clearRichPresence()
end

-- returns true on success
local function set(v)
  return Steam.setRichPresence('b', tostring(v))
end


M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onDeserialized    = nop -- do not remove
M.set = set

M.onVehicleSwitched = onVehicleSwitched
M.onClientPostStartMission = onClientPostStartMission
M.onEditorEnabled = onEditorEnabled
M.onGameStateUpdate = onGameStateUpdate

return M
