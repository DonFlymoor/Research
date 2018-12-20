-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'spawnVehicles'

local workerCoroutine = nil
local moveNext = false
local timer = 0
local frameCounter = 1
local helper = require('scenario/scenariohelper')

local vehicles = {
  'barstow',
  'burnside',
  'cannon',
  'citybus',
  'coupe',
  'etk800',
  'etkc',
  'etki',
  'fullsize',
  'hatch',
  'hopper',
  'idealcar',
  -- 'idealcar2',
  'legran',
  'midsize',
  'miramar',
  'moonhawk',
  'pessima',
  'pickup',
  'pigeon',
  'roamer',
  'sbr',
  'semi',
  'sunburst',
  'super',
  'van'
}

local excludedConfigs = {
  "guineapig_hatch"
}

local trailers = {
  'boxutility',
  'boxutility_large',
  'caravan',
  'cargotrailer',
  'dryvan',
  'flatbed',
  'tanker',
  'tsfb'
}

local props = {
  'ball',
  'barrels',
  'barrier',
  'blockwall',
  'bollard',
  'christmas_tree',
  'cones',
  'flail',
  'flipramp',
  'haybale',
  'inflated_mat',
  'kickplate',
  'large_angletester',
  'large_bridge',
  'large_cannon',
  'large_crusher',
  'large_hamster_wheel',
  'large_metal_ramp',
  'large_roller',
  'large_spinner',
  'large_tilt',
  'metal_box',
  'metal_ramp',
  'piano',
  'roadsigns',
  'rocks',
  'rollover',
  'sawhorse',
  'streetlight',
  'suspensionbridge',
  'tirestacks',
  'tirewall',
  'trafficbarrel',
  'tube',
  'wall',
  'weightpad',
  'woodcrate',
  'woodplanks'
}

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
    for _,vehicle in pairs(vehicles) do
      for k,v in pairs(configs) do
        if v.model_key == vehicle then
          if tableContains(excludedConfigs, v.key) then
            log('I', logTag, v.key .. " is excluded!")
          else
            filteredConfigs[k] = v
          end
        end
      end
    end

    local counter = 0
    local faulty_automobile ={}
    local faultyvehicleFilename = '/settings/cloud/faultyvehicles.json'
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

      local startPosition = vec3(newVehicle:getPosition())
      newVehicle:queueLuaCommand("controller.mainController.setGearboxMode('arcade')")
      newVehicle:queueLuaCommand("input.event('throttle', 0.3, 1)")


      -- Wait a few frames for everything to settle down
      wait(10.0)

      local endPosition = vec3(newVehicle:getPosition())
      local distance = endPosition:distance(startPosition)
      if distance <= 10 then
        log('E', logTag, 'vehicle: ' .. tostring(v.model_key) .. ' config: ' .. tostring(v.key) .. ' did not move')
        table.insert(faulty_automobile, v.model_key..' '..v.key)
        jsonWriteFile(faultyvehicleFilename, faulty_automobile)
      end
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

local function getDistance (pos1, pos2)
  local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-endPosition.y)+(pos1.z-endPosition.z)*(pos1.z-endPosition.z))
  if distance ~= distance then
    distance = 0
  end
  return distance
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