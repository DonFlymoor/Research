local M = {}
local logTag = "beamng_cef"

--[[getVehicleColor
@param vehicleID int, optional
@return vehicle color in form of a string or table
]]
local function getVehicleColor(vehicleID)
  local game = scenetree.findObject("Game")
  if not game then return "" end
  local vehicle
  if vehicleID then
    vehicle = scenetree.findObjectById(vehicleID)
  else
    vehicle = scenetree.findObjectById(be:getPlayerVehicle(0):getID()) -- TODO: add a check whether the game is running?
  end

  if not vehicle then
    log('E', logTag, 'vehicle not found')
    return
  end

  local w = round(vehicle.color.w*100)/100 -- this is because the TS version was only up to the second decimal
  local x = round(vehicle.color.x*100)/100
  local y = round(vehicle.color.y*100)/100
  local z = round(vehicle.color.z*100)/100

  local color =  tostring(x).." "..tostring(y).." "..tostring(z).." "..tostring(w) -- the TS sequence was like this
  return color
end

local function expandMissionFileName(missionFileName)
  if FS:directoryExists(missionFileName) then
    return missionFileName
  end
  local mfn = String(missionFileName):c_str()
  local missionFile = FS:expandFilename(missionFileName)

  if  FS:fileExists(missionFile) then
    return missionFile
  end
  --If the mission file doesn't exist... try to fix up the string.
  local newMission = missionFile
  --Support for old .mis files
  if string.find(missionFile, ".mis$") then
    newMission = string.gsub(missionFile, ".mis$", ".level.json")

    if FS:fileExists(newMission) then
      return newMission
    end
  end

  --try the new filename
  if not string.find(missionFile, ".level.json$") then
    newMission = missionFile..".level.json"

    if FS:fileExists(newMission) then
      return newMission
    end
  end

  if FS:fileExists(missionFile..'.mis') then
    return missionFile..'.mis'
  end
end

local function startLevelActual(missionFileName)
  if scenetree.serverGroup then
    return
  end

  -- check if new format
  if missionFileName:find('.level.json') and not FS:fileExists(missionFileName) then
    local newName = missionFileName:sub(0, missionFileName:find('.level.json') - 1)
    if FS:directoryExists(newName) then
      log('D', 'startLevel', 'converting level argument to new format: ' .. tostring(missionFileName) .. ' > ' .. tostring(newName))
      missionFileName = newName
    end
  end

  local missionFile = expandMissionFileName(missionFileName)
  if not missionFile or missionFile == "" then
    log('E', logTag, 'expanded mission file is invalid - '..dumps(missionFile))
    return false
  end


  server.createGame(missionFile)
  core_gamestate.requestExitLoadingScreen()
end

local function startLevelWrapper (missionFile)
  core_gamestate.requestEnterLoadingScreen()
  local function help ()
    return startLevelActual(missionFile)
  end
  if scenetree.serverGroup then
    return serverConnection.disconnect(help)
  else
    return help()
  end
end

M.startLevel = startLevelWrapper
M.expandMissionFileName = expandMissionFileName
M.getVehicleColor = getVehicleColor

return M