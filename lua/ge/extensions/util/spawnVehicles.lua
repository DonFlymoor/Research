-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'spawnVehicles'

local workerCoroutine = nil
local moveNext = false
local timer = 0
local frameCounter = 1

local function wait(seconds)
  local start = timer
  while timer <= start + seconds do
    coroutine.yield() --wait a bit to let potential boost build up
  end
end

local function onPreRender(dt)
  --Wait a few frames to let the game load properly
  if frameCounter > 400 then
	  if workerCoroutine ~= nil then
		local errorfree, value = coroutine.resume(workerCoroutine)
		if not errorfree then
		  log('E', logTag, "workerCoroutine: "..value)
		end
		if coroutine.status(workerCoroutine) == "dead" then
		  shutdown(0)
		end
		timer = timer + dt
	  end
  end
  frameCounter = frameCounter + 1
end


-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
  log('I', logTag, "initialized")
end

local function onExtensionLoaded()
  log('I', logTag, "module loaded")
  workerCoroutine = coroutine.create(function()
    log('I', logTag, 'Waiting for mod manager to be ready...')
    while not core_modmanager.isReady() do
      wait(1)
    end

    log('I', logTag, 'Getting config list')
    local configs = core_vehicles.getConfigList(true).configs
    local configCount = tableSize(configs)
    log('I', logTag, tostring(configCount).." configs")

    wait(5)

    local filteredConfigs = {}
    for k,v in pairs(configs) do
      -- if v.model_key ~= "box" or v.model_key == "bigramp" then
      if v.model_key ~= "box" then
        filteredConfigs[k] = v
      end           
    end

    local counter = 0
    for _, v in pairs(filteredConfigs) do
      -- Replace the vehicle
      counter = counter + 1
      moveNext = false
      log('I', logTag, string.format("Spawning vehicle %05d / %05d", counter, configCount) .. ' : ' .. ' name: ' .. tostring(v.model_key) .. ', config: ' .. tostring(v.key))
      local oldVehicle = be:getPlayerVehicle(0)
      core_vehicles.replaceVehicle(v.model_key, { config=v.key })
      coroutine.yield()
      local newVehicle = oldVehicle
      while newVehicle == oldVehicle or newVehicle == nil do
        coroutine.yield()
        newVehicle = be:getPlayerVehicle(0)
      end
      -- Wait a few frames for everything to settle down
      wait(1.5)

      local timeoutStart = timer
      while (timer - timeoutStart) < 20 and moveNext == false do
        coroutine.yield()
      end
      if not moveNext then
        log('E', logTag, '*** TIMEOUT ***')
      end
      ::continue::
    end
  end)
end

local function onExtensionUnloaded()
  log('I', logTag, "module unloaded")
end

local function onVehicleSpawned()
  moveNext = true
end

M.onPreRender = onPreRender
M.onInit = onInit
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onVehicleSpawned = onVehicleSpawned
return M
