-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'testMods'

local builtinVehicleConfigs = {}
local builtinVehicles = {}
local builtinLevels = {}
local builtinScenarios = {}
local downloadCoroutine = nil

local vehiclesToTest = {}
local levelsToTest = {}
local configsToTest = {}
local scenariosToTest = {}
local frames = 0
local jobCreated = false

local testData = {}

local levelLoaded = false
local modDownloaded = false

local testJob = false
local testLevel = "levels/showroom_v2_white/main.level.json"

--launched using
--BeamNG.drive.x64.exe -batch -console -level showroom_v2_white/main.level.json -onLevelLoad_ext 'test_testMods'

local function refreshBuiltin()
  --log('I', logTag, 'refreshBuiltin')
  builtinVehicleConfigs = core_vehicles.getConfigList(true).configs
  builtinVehicles = core_vehicles.getModelList().models
  builtinLevels = core_levels.getList()
  builtinScenarios = scenario_scenariosLoader.getList()
end

local function workMain(job)
  while true do
    job.yield()
  end
end

local function work(tagid, resource_version_id)
  testData.tagid = tagid
  testData.resource_version_id = resource_version_id
  log('I', 'testMods', ' ### Test data: ' .. dumps(testData))
  testJob = extensions.core_jobsystem.create(workMain)

  -- figure out the level
  local missionFile = getMissionFilename()
  if not missionFile or missionFile ~= testLevel then
    core_levels.startLevel(testLevel)
  else
    levelLoaded = true
  end
end

local function onExtensionLoaded()
  TorqueScript.setVar('$preventPlayerSpawning', '1')

  if core_camera == nil then
    loadGameModeModules()
  end
  --log('I', logTag, 'loaded')
  refreshBuiltin()
end

local function onModDeactivated(mod)
  refreshBuiltin()
end

--[[local function onUpdate()
  log('I', logTag, "Update")
  frames = frames + 1
  if workerCoroutine ~= nil then
    -- check if its dead
    if coroutine.status(workerCoroutine) == 'dead' then
      log('E', logTag, "workerCoroutine dead. Shutdown.")
      -- its dead jim
      shutdown(0)
      return
    end
    local errorfree, value = coroutine.resume(workerCoroutine)
    log('I', logTag, "Exit coroutine")
    if not errorfree then
      log('E', logTag, "workerCoroutine: ".. tostring(value) .. ' / state: ' .. tostring(coroutine.status(workerCoroutine)))
      log('E', logTag, debug.traceback(workerCoroutine, value))
    end
  end
end]]

local function yieldForSeconds(seconds, job)
  local startTime = Engine.Platform.getRealMilliseconds()
  while Engine.Platform.getRealMilliseconds() - startTime < seconds * 1000 do
    job.yield()
  end
end

local function getNewEntries(newList, oldList, compareFunction)
  local newEntries = {}
  for _, newEntry in pairs(newList or {}) do
    local isBuiltin = false
    -- Iterate over the old list to see if this entry is new
    for _, oldEntry in pairs(oldList or {}) do
      if compareFunction(newEntry, oldEntry) then
        isBuiltin = true
        break
      end
    end
    if not isBuiltin then
      table.insert(newEntries, newEntry)
    end
  end
  return newEntries
end


local function _prepareVehicle(vehicle)
  -- fixing some data up
  local _vehicleName = vehicle.model_key
  local _configName = vehicle.key
  if not vehicle.model_key then
    _vehicleName = vehicle.key
    _configName = nil
  end
  vehicle.vehicleName = _vehicleName
  vehicle.configName = _configName
end

local function _spawnVehicle(vehicle, job)
  log('I', logTag, ' **** spawning vehicle "'.. tostring(vehicle.vehicleName) .. '" with config "' .. tostring(vehicle.configName or 'default')..'"')

  if not FS:fileExists(vehicle.preview) then
    log('E', logTag, 'Missing thumbnail: ' .. tostring(vehicle.preview))
  else
    -- check the correct size of the preview image
    local bitmap = GBitmap()
    if bitmap:loadFile(vehicle.preview) then
      local width = bitmap:getWidth()
      local height = bitmap:getHeight()
      if width > 500 or height > 281 then
        log('E', logTag, "Preview image ("..vehicle.preview..") size ".. width.."x"..height.." larger then 500x281.")
      end
    end
  end

  local oldVehicle = be:getPlayerVehicle(0)
  if oldVehicle == nil then
    core_vehicles.spawnNewVehicle(vehicle.vehicleName, { config=vehicle.configName })
    job.yield()
  else
    core_vehicles.replaceVehicle(vehicle.vehicleName, { config=vehicle.configName })
    local newVehicle = oldVehicle
    while newVehicle == oldVehicle do
      job.yield()
      newVehicle = be:getPlayerVehicle(0)
      --log('I', logTag, 'waiting for vehicle to respawn...') --' | old = ' .. tostring(oldVehicle) .. ', new = ' .. tostring(newVehicle))
    end
  end

  -- Set camera
  guihooks.trigger('hide_ui', true)
  -- no throttle
  local testVehicle = be:getPlayerVehicle(0)
  if testVehicle then
    testVehicle:queueLuaCommand("input.event('throttle', 0, 2)")
    testVehicle:queueLuaCommand("input.event('parkingbrake', 1, 1)")
  end
end

local function _functionTest(vehicleData, job)
  local vehicle = be:getPlayerVehicle(0)
  if not vehicle then return end
  local startPos = vec3(vehicle:getPosition())
  vehicle:queueLuaCommand("input.event('parkingbrake', 0, 1)")
  vehicle:queueLuaCommand("input.event('throttle', 1, 2)")
  log('D', logTag, "Driving for 10 seconds ...")
  yieldForSeconds(10, job)
  local distance = startPos:distance(vehicle:getPosition())
  if distance < 0.1 then
    log('E', logTag, "Vehicle did not move at all. (Model: "..tostring(vehicleData.model_key) .. " Config: " .. tostring(vehicleData.key) .. ")")
  elseif distance < 10 then
    log('E', logTag, "Vehicle only moved " .. math.floor(distance) .. " m. (Model: "..tostring(vehicleData.model_key) .. " Config: " .. tostring(vehicleData.key) .. ")")
  else
    log('I', logTag, "Vehicle moved " .. math.floor(distance) .. " m.")
  end

  -- scenetree.hemisphere:setPosition(Point3F(pos.x, pos.y, 0))
  -- scenetree.light:setPosition(Point3F(pos.x, pos.y, 15))
  -- newVehicle:resetCam()
  -- -- newVehicle:setCamModeByType("orbit")
  -- newVehicle:setCamRotation(Point3F(-135, 1.3, 0))
  -- newVehicle:setCamFOV(20)
  -- newVehicle:setCamDist(newVehicle:camGetMinDist() * 4.25)
  --
  -- -- Wait a few frames for everything to settle down
  -- coroutine.yield()
  --
  -- -- Take screenshot
  -- screenShotName = vehicle.vehicleName .. "/" .. v.key
  -- log('E', logTag, "Saving screenshot "..screenShotName)
  -- TorqueScript.eval('screenShot("testshot.png", "PNG");')
  job.yield()
end

local function _resetVehicle(job)
  be:resetVehicle(0);
  yieldForSeconds(.5, job)
end

local function _screenshot(screenShotName, job)
  job.yield()
  log('I', logTag, "   saved screenshot: "..screenShotName..'.png')
  TorqueScript.eval('screenShot("'..screenShotName..'", "PNG", 1);')
  yieldForSeconds(1, job)
end

local function _360_screenshot(newVehicle, vehicleId, screenShotName, job)
  local step = 45 / 10
  local i = 0
  log('I', logTag, "   creating 360 deg screenshots: "..screenShotName..'_*.png ...')
  for r=-180, (180 - step), step do
    core_camera.setRotation(vehicleId, vec3(r, -10, 0))
    yieldForSeconds(1, job)
    TorqueScript.eval('screenShot("'..(screenShotName .. '_' .. string.format('%03d', i))..'", "PNG", 1);')
    i = i + 1
  end
end

local function _createScreenshots(currentPath, vehicle, job)
  --log('I', logTag, 'creating media for vehicle '..vehicle.vehicleName)
  local oldVehicle = be:getPlayerVehicle(0)
  core_vehicles.replaceVehicle(vehicle.vehicleName, { config = vehicle.configName })
  job.yield()
  local newVehicle = oldVehicle
  while newVehicle == oldVehicle do
    job.yield()
    newVehicle = be:getPlayerVehicle(0)
  end

  -- Set camera
  guihooks.trigger('hide_ui', true)
  settings.setValue('cameraOrbitSmoothing', false)

  _resetVehicle(job)

  -- scenetree.hemisphere:setPosition(Point3F(pos.x, pos.y, 0))
  -- scenetree.light:setPosition(Point3F(pos.x, pos.y, 15))

  local vehicleId = newVehicle:getID()
  core_camera.resetCameraByID(vehicleId)

  core_camera.setFOV(vehicleId, 20)

  -- wait one second for the vehicle to settle
  yieldForSeconds(1, job)

  -- reset the camera after the vehicle rests
  core_camera.resetCameraByID(vehicleId)
  core_camera.setFOV(vehicleId, 20)
  yieldForSeconds(1, job)

  -- newVehicle:setCamModeByType("orbit")
  --newVehicle:setCamRotation(Point3F(-135, 1.3, 0))
  --newVehicle:setCamFOV(20)
  -- newVehicle:setCamModeByType("onboard.driver")

  --core_camera.setRotation(vehicleId, vec3(-135, 0, 0))
  core_camera.setRotation(vehicleId, vec3(-90, 0, 0))

  local idealDistance = newVehicle:getViewportFillingCameraDistance() * 1.05
  core_camera.setDistance(vehicleId, idealDistance)
  core_camera.setFOV(vehicleId, 12)
  core_camera.setOffset(vehicleId, vec3(0, 0, 2 / idealDistance))
  --MoveManager.zoomInSpeed = idealDistance
  --print("* new distance: " .. tostring(idealDistance))

  --newVehicle:queueLuaCommand("input.event('steering', 0.0, 1); input.event('parkingbrake', 1, 1); electrics.toggle_lights() ; electrics.toggle_lightbar_signal() ; electrics.toggle_fog_lights()")
  newVehicle:queueLuaCommand("input.event('parkingbrake', 1, 1)")
  newVehicle:queueLuaCommand('bdebug.state.debugEnabled=false;bdebug.meshVisChange(1, true);')
  yieldForSeconds(1, job)

  bullettime.togglePause()

  -- do various screenshots ...
  local function doScreenWithRot(name, vec)
    core_camera.setRotation(vehicleId, vec)
    job.yield()
    _screenshot(currentPath .. '/' .. name, job)
  end

  local commonType = '/normal'
  doScreenWithRot('right' .. commonType, vec3(90, 0, 0))
  doScreenWithRot('left' .. commonType, vec3(-90, 0, 0))
  doScreenWithRot('top' .. commonType, vec3(90, -89, 0))
  doScreenWithRot('bottom' .. commonType, vec3(90, 89, 0))
  doScreenWithRot('front' .. commonType, vec3(179, 0, 0))
  doScreenWithRot('back' .. commonType, vec3(0, 0, 0))
  doScreenWithRot('persp' .. commonType, vec3(135, -17, 0))

  _360_screenshot(newVehicle, vehicleId, currentPath .. '/rotation/normal', job)

  -- now skeleton
  newVehicle:queueLuaCommand('bdebug.state.debugEnabled=true;bdebug.state.vehicle.beamVis="type";bdebug.state.vehicle.nodeVis="simple";bdebug.meshVisChange(0, true);bdebug.setState(bdebug.state)')
  bullettime.togglePause()
  yieldForSeconds(1, job)
  bullettime.togglePause()

  commonType = '/skeleton'
  doScreenWithRot('right' .. commonType, vec3(90, 0, 0))
  doScreenWithRot('left' .. commonType, vec3(-90, 0, 0))
  doScreenWithRot('top' .. commonType, vec3(90, -89, 0))
  doScreenWithRot('bottom' .. commonType, vec3(90, 89, 0))
  doScreenWithRot('front' .. commonType, vec3(179, 0, 0))
  doScreenWithRot('back' .. commonType, vec3(0, 0, 0))
  doScreenWithRot('persp' .. commonType, vec3(135, -17, 0))

  _360_screenshot(newVehicle, vehicleId, currentPath .. '/rotation/skeleton', job)

  newVehicle:queueLuaCommand('bdebug.state.debugEnabled=false;bdebug.state.vehicle.beamVis="off";bdebug.state.vehicle.nodeVis="simpoffle";bdebug.meshVisChange(1, true);bdebug.setState(bdebug.state)')
  bullettime.togglePause()
  ::continue::
end

local function onModActivated(mod)
  log('D', logTag, ' onModActivated: ' .. dumps(mod))

  if jobCreated then
    log('D', logTag, 'Job was already created.')
    return
  end


  -- make sure the cache is cleared
  core_vehicles.clearCache()

  -- todo: use tableKeys to minimize the data
  local somethingTestWorthy = false
  configsToTest = getNewEntries(
    core_vehicles.getConfigList(true).configs, builtinVehicleConfigs,
    function(newConfig, oldConfig)
      return oldConfig.model_key == newConfig.model_key and oldConfig.key == newConfig.key
    end
  )
  if tableSize(configsToTest) > 0 then
    somethingTestWorthy = true
    log('I', logTag, ' *** configs to test: ' .. tostring(tableSize(configsToTest)))
  end

  vehiclesToTest = getNewEntries(
    core_vehicles.getModelList().models, builtinVehicles,
    function(a, b)
      return a.key == b.key
    end
  )
  if tableSize(vehiclesToTest) > 0 then
    somethingTestWorthy = true
    log('I', logTag, ' *** vehicles to test: ' .. tostring(tableSize(vehiclesToTest)))
  end

  levelsToTest = getNewEntries(
    core_levels.getList(), builtinLevels,
    function(newLevel, oldLevel)
      return oldLevel.misFilePath == newLevel.misFilePath
    end
  )
  if tableSize(levelsToTest) > 0 then
    somethingTestWorthy = true
    log('I', logTag, ' *** levels to test: ' .. tostring(tableSize(levelsToTest)))
  end

  scenariosToTest = getNewEntries(
    scenario_scenariosLoader.getList(), builtinScenarios,
    function(newScenario, oldScenario)
      return newScenario.sourceFile == oldScenario.sourceFile
    end
  )
  if tableSize(scenariosToTest) > 0 then
    somethingTestWorthy = true
    log('I', logTag, ' *** scenarios to test: ' .. tostring(tableSize(scenariosToTest)))
  end

  if not somethingTestWorthy then
    log('E', logTag, ' *** nothing found to be tested. exiting.')
    shutdown(0)
  end



  --log('I', logTag, 'starting testing ...')
  local function workItem(job)
    if mod.modType == 'vehicle' and #configsToTest == 0 then
      log('E', logTag, 'Mod type is "vehicle" but no vehicle config found to test.')
    elseif mod.modType == "terrain" and #levelsToTest == 0 then
      log('E', logTag, 'Mod type is "terrain" but no levels found to test.')
    elseif #configsToTest + #levelsToTest + #scenariosToTest == 0 then
      log('E', logTag, 'Testing of ' .. mod.modType .. ' mods not implemented yet.')
    end

    -- setup artifact logging
    local logSink = LogSink()

    log('D', logTag, 'Checking for game object.')

    while not scenetree.Game do
        job.yield()
    end
    log('D', logTag, 'Game object found.')

    -- test plain vehicles only
    for _, vehicle in pairs(vehiclesToTest) do
      _prepareVehicle(vehicle)
      local currentPath = 'generated/vehicles/' .. vehicle.vehicleName..'/'..(vehicle.configName or 'default')
      logSink:open(currentPath .. '/log.json')
      _spawnVehicle(vehicle, job)
      --_createScreenshots(currentPath, vehicle)
      _functionTest(vehicle, job)
      _resetVehicle(job)
      logSink:close()
    end

    -- then test any configs
    for _, vehicle in pairs(configsToTest) do
      _prepareVehicle(vehicle)
      local currentPath = 'generated/vehicles/' .. vehicle.vehicleName..'/'..(vehicle.configName or 'default')
      logSink:open(currentPath .. '/log.json')
      _spawnVehicle(vehicle, job)
      _createScreenshots(currentPath, vehicle, job)
      _functionTest(vehicle, job)
      _resetVehicle(job)
      logSink:close()
    end

    for _, level in pairs(levelsToTest) do
      levelLoaded = false
      local currentPath = 'generated/levels/' .. level.levelName..'/'
      --_startLogging(currentPath .. '/log.json')

      core_levels.startLevel(level.misFilePath)--don't know how to test it
      -- wait for the level to load
      while not levelLoaded do
        job.yield()
      end
      --_endLogging()
    end

    for _, scenario in pairs(scenariosToTest) do
      levelLoaded = false
      local currentPath = 'generated/scenarios/' .. scenario.scenarioName .. '/'
      log('D', logTag, 'Loading scenario ' .. scenario.scenarioName)
      --_startLogging(currentPath .. '/log.json')

      scenario_scenariosLoader.start(scenario)

      -- wait for the scenario to load
      log('D', logTag, 'Waiting for scenario to load')
      while not levelLoaded do
        job.yield()
      end
      log('D', logTag, 'Scenario loaded')

      --_endLogging()
    end
    -- all done, quit
    shutdown(0)
  end

  extensions.core_jobsystem.create(workItem)
  jobCreated = true
end

local function onClientStartMission(mission)
  log('D', logTag, 'onClientStartMission called.')
  levelLoaded = true
end

local function onScenarioLoaded(scenario)
  log('D', logTag, 'onScenarioLoaded  called.')
  levelLoaded = true
end

local function onFreeroamLoaded(mission)
  log('D', logTag, 'onFreeroamLoaded called.')
  levelLoaded = true
end

local function onDownloadError()
  log('E', logTag, 'Download error, exiting.')
  shutdown(0)
end

local function onBeforeMountEntry(filename, mountPoint)
  local zip = ZipArchive()
  zip:openArchiveName(filename, "R")
  local filesInZIP = zip:getFileList()
  for _, filename in pairs(filesInZIP) do
    if FS:fileExists(filename) then
      log('E', logTag, 'Overwriting original game file ' .. filename)
    end
  end
end

local function onInit()
  log('D', logTag, "initialized")
  registerCoreModule("test_testMods")
end

local function onModManagerReady()
  log('D', logTag, "onModManagerReady")

  extensions.core_modmanager.deactivateModId(testData.tagid)
  extensions.core_modmanager.deactivateMod(tostring(testData.resource_version_id))
  refreshBuiltin()
  extensions.core_modmanager.activateModId(testData.tagid)
  extensions.core_modmanager.activateMod(tostring(testData.resource_version_id))
end

M.onInit = onInit
--M.onUpdate = onUpdate
M.onDownloadError = onDownloadError
M.onExtensionLoaded = onExtensionLoaded
M.onModDeactivated = onModDeactivated
M.onBeforeMountEntry = onBeforeMountEntry
M.onModActivated = onModActivated
M.onClientStartMission = onClientStartMission
M.onScenarioLoaded = onScenarioLoaded
M.onFreeroamLoaded = onFreeroamLoaded
M.onModManagerReady = onModManagerReady

M.work = work

return M
