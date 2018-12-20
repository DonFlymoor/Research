-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = "saveDynamicData"

local moveNext = false

local vehicleBlacklist = {}

local lastHeartbeat = 0

local pcFilesToTest = {}

local testLevel = "levels/autotest/main.level.json"

local testJob = nil
local watchdogTimer = nil
local levelOk = false

-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
  log("I", logTag, "initialized")
end

local function _workMain(job)
  log("E", logTag, "=== WORKING ===")
  log("I", logTag, "Waiting for mod manager to be ready...")
  while not extensions.core_modmanager.isReady() do
    job.sleep(0.5)
  end

  while not levelOk do
    job.sleep(0.5)
  end

  log("E", logTag, "=== WORKING 2 ===")
  for _, v in pairs(pcFilesToTest) do
    local vehName = v:match("vehicles/([^/]+)")
    local config = v:match("vehicles/[^/]+/(.+)%.pc$")
    log("I", logTag, " " .. tostring(v) .. " >  name: " .. tostring(vehName) .. ", config: " .. tostring(config))
    local filepath = "vehicles/" .. vehName .. "/info_" .. config .. ".touched"
    local data = jsonReadFile(filepath)
    if not data then
      -- Replace the vehicle
      job.yield()
      local oldVehicle = be:getPlayerVehicle(0)
      core_vehicles.replaceVehicle(vehName, {config = config})
      job.yield()
      local newVehicle = oldVehicle
      while newVehicle == oldVehicle or newVehicle == nil do
        job.yield()
        newVehicle = be:getPlayerVehicle(0)
      end

      newVehicle:setPositionRotation(0, 0, 0.5, 0, 0, 0, 1)
      watchdogTimer = hptimer()

      -- Wait a few frames for everything to settle down
      job.sleep(3)

      --Do stuff
      moveNext = false

      newVehicle:queueLuaCommand("extensions.load('dynamicVehicleData')")
      job.sleep(1)

      --log('E', 'XXXXXXXXXXXXXXXXXXXX', "dynamicVehicleData.performTests(" .. serialize(vehName) .. "," .. serialize(config) .. ")")
      newVehicle:queueLuaCommand("dynamicVehicleData.performTests(" .. serialize(vehName) .. "," .. serialize(config) .. ")")

      lastHeartbeat = watchdogTimer:stop()
      local hp = hptimer()
      local reason = ""
      while true do
        local runTime = hp:stop()
        local maxRunTimeExceeded = runTime > 600000
        local watchdogTriggered = (watchdogTimer:stop() - lastHeartbeat) > 20000

        if maxRunTimeExceeded then
          reason = "maxRuntime"
          break
        end
        if watchdogTriggered then
          reason = "watchdog"
          break
        end
        if moveNext then
          reason = "moveNext"
          break
        end
        job.yield()
      end
      log("I", logTag, reason)
      log("I", logTag, " *** *** *** *** *** *** *** *** *** *** *** *** ")
      moveNext = false
    else
      log("I", logTag, " *** Config info does already exist, skipping... ***")
    end
  end

  log("I", logTag, " Testing is done")

  shutdown(0)
end

local function _startWorking()
  log("I", logTag, "START WORK")
  testJob = extensions.core_jobsystem.create(_workMain)
end

local function onClientStartMission(missionFile)
  if missionFile == testLevel then
    levelOk = true
  end
end

local function work(pcFiles)
  pcFilesToTest = pcFiles
  local missionFile = getMissionFilename()

  _startWorking()

  if not missionFile or missionFile ~= testLevel then
    core_levels.startLevel(testLevel)
  else
    levelOk = true
  end

  -- TODO: we need to block here until all the work is done!
  --TODO this method is (usually) called twice (first loads the level, then does the tests),
  --so we need some way to signal worker.lua that the job is not done once this method returns for the first time (bool return?)
end

local function onExtensionLoaded()
  log("I", logTag, "module loaded")
  --be.physicsMaxSpeed = true
  be:setPhysicsSpeedFactor(10)

  if core_camera == nil then
    loadGameModeModules()
  end

  -- Load the blacklisted vehicles
  local blackListFile = jsonReadFile("blacklist.json")

  if blackListFile then
    log("I", logTag, "Found blacklist.json")
    vehicleBlacklist = blackListFile
  else
    log("I", logTag, "Couldn't find blacklist.json.")
    local defaultBlackListFile = jsonReadFile("blacklistDefault.json")

    if defaultBlackListFile then
      log("I", logTag, "Using default blacklist.")
      vehicleBlacklist = defaultBlackListFile
    else
      log("I", logTag, "Default blacklist not found")
    end
  end

  log("I", logTag, "Vehicles that are skipped:")
  for index, value in pairs(vehicleBlacklist) do
    log("I", logTag, value)
  end
end

local function vehicleDone()
  moveNext = true
end

local function heartbeat()
  lastHeartbeat = watchdogTimer:stop()
end

local function onExtensionUnloaded()
  log("I", logTag, "module unloaded")
end

M.onInit = onInit
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.vehicleDone = vehicleDone
M.heartbeat = heartbeat
M.onClientStartMission = onClientStartMission
M.work = work

return M
