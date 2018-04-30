-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'saveDynamicData'

local workerCoroutine = nil
local moveNext = false

local vehicleBlacklist = {}

local timer = 0
local lastHeartbeat = 0

local function wait(seconds)
  local start = timer
  while timer <= start + seconds do
    coroutine.yield() --wait a bit to let potential boost build up
  end
end

local function onPreRender(dt)
  timer = timer + dt

  if workerCoroutine ~= nil then
    local errorfree, value = coroutine.resume(workerCoroutine)
    if not errorfree then
      log('E', logTag, debug.traceback(workerCoroutine, "workerCoroutine: "..value))
    end
    if coroutine.status(workerCoroutine) == "dead" then
      shutdown(0)
    end
  end
end


-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
  log('I', logTag, "initialized")
end

local function onExtensionLoaded()
  log('I', logTag, "module loaded")
  be.physicsMaxSpeed = true

  -- Load the blacklisted vehicles
  local blackListFile = readJsonFile("blacklist.json")

  if blackListFile then
	log('I', logTag, "Found blacklist.json")
	vehicleBlacklist = blackListFile
  else
	log('I', logTag, "Couldn't find blacklist.json.")
	local defaultBlackListFile = readJsonFile("blacklistDefault.json")

	if defaultBlackListFile then
		log('I', logTag, "Using default blacklist.")
		vehicleBlacklist = defaultBlackListFile
	else
		log('I', logTag, "Default blacklist not found")
	end
  end

  log('I', logTag, "Vehicles that are skipped:")
  for index,value in pairs(vehicleBlacklist) do log('I', logTag, value) end

  workerCoroutine = coroutine.create(function()
      log('I', logTag, 'Waiting for mod manager to be ready...')
      while not core_modmanager.isReady() do
        wait(1)
      end

	  -- Wait 5 seconds for the level to load properly
	  wait(5)

      log('I', logTag, 'Getting config list')
      local configs = core_vehicles.getConfigList(true).configs
      coroutine.yield()

      local vehicleFolder = nil
      local vehicleConfig = nil
      local cmdArgs = Engine.getStartingArgs()
      for i = 1, #cmdArgs do
        local arg = cmdArgs[i]
        arg = arg:stripchars('"')
        if arg == '-testvehicle' and i + 1 <= #cmdArgs then
          vehicleFolder = cmdArgs[i + 1]
          log('I', logTag, "Vehicle filter: "..vehicleFolder)
        elseif arg == '-testconfig' and i + 1 <= #cmdArgs then
          vehicleConfig = cmdArgs[i + 1]
          log('I', logTag, "Config filter: "..vehicleConfig)
        end
      end

      local blacklistLookup = {}
      for k,v in pairs(vehicleBlacklist) do
        blacklistLookup[v] = true
      end

      local filteredConfigs = {}
      for k,v in pairs(configs) do
        if (not vehicleFolder or v.model_key == vehicleFolder) and (not vehicleConfig or v.key == vehicleConfig) and not blacklistLookup[v.model_key] then
          filteredConfigs[k] = v
        end
      end

      local configCount = tableSize(filteredConfigs)
      log('I', logTag, tostring(configCount).." configs")

      wait(5)

      local counter = 0
      for _, v in pairs(filteredConfigs) do
        counter = counter + 1
        log('I', logTag, string.format("Spawning vehicle %05d / %05d", counter, configCount) .. ' : ' .. ' name: ' .. tostring(v.model_key) .. ', config: ' .. tostring(v.key))
        if (not vehicleFolder or v.model_key == vehicleFolder) and (not vehicleConfig or v.key == vehicleConfig) then
          local filepath = "vehicles/"..v.model_key .."/info_"..v.key..".touched"
          local data = readJsonFile(filepath)
          if not data then
            -- Replace the vehicle
            coroutine.yield()
            local oldVehicle = be:getPlayerVehicle(0)
            core_vehicles.replaceVehicle(v.model_key, { config=v.key })
            coroutine.yield()
            local newVehicle = oldVehicle
            while newVehicle == oldVehicle or newVehicle == nil do
              coroutine.yield()
              newVehicle = be:getPlayerVehicle(0)
            end

            newVehicle:setPositionRotation(0,0,0.5,0,0,0,1)

            -- Wait a few frames for everything to settle down
            wait(3)
            timer = 0
            lastHeartbeat = 0

            --Do stuff
            moveNext = false

            newVehicle:queueLuaCommand("extensions.load('dynamicVehicleData')")
            wait(1)

            newVehicle:queueLuaCommand("dynamicVehicleData.performTests(" .. serialize(v.model_key) ..",".. serialize(v.key) .. ")")

            local timeoutStart = timer
            while timer < timeoutStart + 600 and (timer - lastHeartbeat) < 20 and moveNext == false do
              coroutine.yield()
            end
            if not moveNext then
              log('E', logTag, '*** TIMEOUT ***')
            end
            log('I', logTag, ' *** *** *** *** *** *** *** *** *** *** *** *** ')
            moveNext = false
          else
            log('I', logTag, " *** Config info does already exist, skipping... ***")
          end
        end
        ::continue::
      end
    end)
end

local function vehicleDone()
  moveNext = true
end

local function heartbeat()
  lastHeartbeat = timer
end

local function onExtensionUnloaded()
  log('I', logTag, "module unloaded")
end

M.onPreRender = onPreRender
M.onInit = onInit
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.vehicleDone = vehicleDone
M.heartbeat = heartbeat

return M
