-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.dependencies = {'core_weather'}

local svg = require('svgwriter')

local configfn = 'annotation_config.json'

local config = {}

local recordMode = 0 -- 0 = init, 1 = loading, 2 = ready and recording
local lastPos = nil
local heatmap = require('heatmap')
local colorRed = ColorI(255,0,0,255)
local generatedSets = 0

local saveTime = 10 -- save every X seconds as backup
local saveTimer = 0

local aiSettingsRequested = -1

-- for the UI / stats
local runTime = 0

local writeBuffers = {}
local outputFilenameSuffixes = {
  screen = '_screen',
  annotated = '_annotated',
  depth = '_depth'
}

local function formatString(res)
  local d = os.date('*t')
  res = res:gsub("{YYYY}", string.format('%04d', d.year))
  res = res:gsub("{YY}", string.format('%02d', d.year - 2000))
  res = res:gsub("{Y}", d.year)
  res = res:gsub("{MM}", string.format('%02d', d.month))
  res = res:gsub("{M}", d.month)
  res = res:gsub("{DD}", string.format('%02d', d.day))
  res = res:gsub("{D}", d.day)
  res = res:gsub("{HH}", string.format('%02d', d.hour))
  res = res:gsub("{H}", d.hour)
  res = res:gsub("{mm}", string.format('%02d', d.min))
  res = res:gsub("{m}", d.min)
  res = res:gsub("{ss}", string.format('%02d', d.sec))
  res = res:gsub("{s}", d.sec)
  res = res:gsub("{sessionName}", config.session.name)
  return res
end

local function saveData()
  heatmap.save(formatString(config.session.sessionPrefix) .. '/heatmap.svg')
end

local function quit()
  saveData()
  shutdown(0)
end

local function updateUI()
  local d = {
    runTime = runTime * 1000, -- in ms
    generatedSets = generatedSets,
  }
  if config.session.dataLimit then
    d.left = config.session.dataLimit - generatedSets
    d.progress = (generatedSets / config.session.dataLimit) * 100
    d.eta = ((d.runTime / generatedSets) * d.left)
  end
  guihooks.trigger('AnnotationStateChanged', d)
end

local function writeAnnotationColors()
  if not config.session then return end
  local annotations = AnnotationManager.getAnnotations()
  local annotationSize = tableSize(annotations)
  local svgDoc = svg.Document(300, 20 * annotationSize, svg.gray(0))
  local i = 0
  for k, v in pairs(annotations) do
    local r = svg.Rect(0, 20 * i, 300, 20, 0, 0, {
      fill = svg.rgb(v.r, v.g, v.b)
    })
    svgDoc:add(r)
    local txt = k .. '  [' .. v.r .. ',' .. v.g .. ',' .. v.b .. ']'
    local r = svg.Text(txt , 0, 20 * (i + 1) - 3, {
      fill = 'black'
    })
    svgDoc:add(r)
    i = i + 1
  end
  svgDoc:writeTo(formatString(config.session.sessionPrefix) .. '/colors.svg')
end

local function onClientPostStartMission(mission)
  if config.automatic then
    log('I', 'annotation', "map loaded: " .. tostring(mission))

    -- add some more temp data to the config
    local terr = getObjectByClass("TerrainBlock")
    if terr then
      config.terrainOffset = vec3(terr:getPosition())
    end
  end

  -- set the time things
  if config.map.name and tostring(mission):find(config.map.name) then
    if config.map.dayTime then
      setTimeOfDay(config.map.dayTime)
      -- TODO remove it when we have new binaries, use TimeOfDay::getTimeNormalized
      local tod = getObjectByClass("TimeOfDay")
      if tod and tod.getTimeNormalized then
        log('D', logTag, 'Remove this hack and use TimeOfDay::get/setTimeNormalized')
      elseif tod and tod.azimuthOverride ~=0 then
        tod.time = tod.time + 0.25
      end

    end
    local tod = getObjectByClass("TimeOfDay")
    if tod and type(config.map.timeRunning) == 'boolean' then
      tod.play = config.map.timeRunning
    end
    if tod and type(config.map.dayLengthSeconds) == 'number' then
      tod.dayLength = config.map.dayLengthSeconds
    end

    if config.map.weather then
      extensions.core_weather.activate(config.map.weather)
    end
  end

  if not config.vehicle.visible then
    local veh = be:getPlayerVehicle(0)
    if veh then
      veh:queueLuaCommand('bdebug.meshVisChange(0, true);')
    end
  end

  -- export annotation colors
  writeAnnotationColors()

  Engine.Annotation.enable(true)
  recordMode = 1
end

local function getCmdLineScenario()
  local cmdArgs = Engine.getStartingArgs()
  local idx = tableFindKey(cmdArgs, '-scenario')
  if idx ~= nil and #cmdArgs >= idx + 1 then
    --print("fallback: " .. cmdArgs[idx + 1])
    return cmdArgs[idx + 1]
  end
  return nil
end

-- starts everything off by loading the level or scenario
local function start(automatic)
  if automatic == nil then automatic = true end

  -- guard against multiple start calls
  if config.started then return end
  config.started = true

  -- overwrite automatic mode
  config.automatic = automatic

  -- load level
  if config.automatic then
    if not config.scenario then
      -- actively change the level
      local levelName = tostring(config.map.name)
      local levelFullPath = 'levels/'..levelName..'/main.level.json'
      -- set the spawnpoint to be used
      setSpawnpoint.setDefaultSP(config.map.spawnpoint, levelName)
      -- load the level
      
      loadGameModeModules()
      beamng_cef.startLevel(levelFullPath)
    else
      local scenarioPath = 'levels/'..tostring(config.map.name)..'/'..config.scenario
      if not FS:fileExists(scenarioPath) then
        log('E', 'annotation', 'configuration invalid... scenario file is not existing: '.. scenarioPath)
        quit()
      end
      scenario_scenariosLoader.startByPath(scenarioPath)
    end
  else
    onClientPostStartMission(TorqueScript.getVar("$Server::MissionPath"))
  end
end

local function reloadConfig()
  -- parse the args
  local cmdArgs = Engine.getStartingArgs()
  for i = 1, #cmdArgs do
    local arg = cmdArgs[i]
    arg = arg:stripchars('"')
    if arg == '-annotationconfig' and i + 1 <= #cmdArgs then
      configfn = cmdArgs[i + 1]
    end
  end

  config = readJsonFile(configfn)
  log('I', 'annotation', "Config loaded: " .. tostring(configfn)) --.. ": "..dumps(config))
  if tableSize(config) == 0 then
    log('E', 'annotation', 'configuration invalid, exiting')
    quit()
  end

  -- write session info
  config.beamng_version = beamng_version
  config.beamng_build = beamng_buildinfo

  -- default value for config.session.format
  config.session = config.session or {}
  config.session.format = config.session.format or 'json'

  writeJsonFile(formatString(config.session.sessionPrefix) .. '/session.json', config, true)

  -- command line overrites config setting
  if not config.scenario then
    config.scenario = getCmdLineScenario()
    -- start the automatically if the command line argument is provided
    if config.scenario then
      start(true)
    end
  end

  config.loaded = true
end

local function onExtensionUnloaded()
  log('I', 'annotation', "module unloaded")
  heatmap.destroy()
end


local function _doExport(vdata)
  -- figure out the vehicles
  local data = {
    --screen = 'screen.png',
    --annotation = 'v1/default',
    --level = getTSVar('$Server::MissionFile'),
  }

  data.time = getTimeOfDay(true)

  --dump(vdata)

  -- convert some data
  data.pos = vdata.pos:toTable()
  data.vel = vdata.vel:toTable()
  data.dir = vdata.dirVec:toTable()
  local dir = vdata.dirVec:normalized()
  data.rot = math.deg(math.atan2(dir:dot(vec3(1,0,0)), dir:dot(vec3(0,-1,0))))

  if not config.session then
    reloadConfig()
    start(false)
  end

  data.filenameBase = formatString(config.session.sessionPrefix) .. '/' .. formatString(config.session.dataPrefix, ctx)
  if not config.session.dummy then
    local suffix = '.png'
    local future = requestAnnotatedBuffers(
      data.filenameBase .. outputFilenameSuffixes.screen .. suffix,
      data.filenameBase .. outputFilenameSuffixes.annotated .. suffix,
      data.filenameBase .. outputFilenameSuffixes.depth .. suffix,
      'extensions.util_annotation.buffersWrittenCallback')
    if not future then
      log('E', 'annotation', 'requestAnnotatedBuffers did not return a future')
      return
    end
    writeBuffers[future] = data
    heatmap.update()
  end

  -- TODO: add the annotated image output generation here

  log('I', 'annotation', '- ' .. tostring(data.filenameBase))

  -- check if we have enough data now
  generatedSets = generatedSets + 1
  if config.session.dataLimit and generatedSets >= config.session.dataLimit then
    log('I', 'annotation', ' exiting gracefully as all data is recorded: ' .. tostring(generatedSets) .. ' entries')
    quit()
  end

  updateUI()
end

local function exportData(forced)
  local veh = be:getPlayerVehicle(0)
  if not veh then
    log('E', 'annotation', 'player vehicle missing? Simulation paused?')
    return
  end

  local vdata = map.objects[veh:getID()]
  if not vdata then
    log('E', 'annotation', 'player vehicle missing? Simulation paused?')
    return
  end

  -- reset the vehicle if it collided
  -- OLD RESET CODE:
  --if vdata.damage > 20 or #vdata.objectCollisions > 0 then
  --  print("vdata.damage = " .. tostring(vdata.damage))
  --  print("vdata.objectCollisions = " .. dumps(vdata.objectCollisions))
  --  veh:queueLuaCommand('obj:requestReset(RESET_PHYSICS)')
  --  aiSettingsRequested = 3
  --end

  if not lastPos then lastPos = vdata.pos end -- init the first position so we skip the loading screen ...

  if forced or (lastPos - vdata.pos):length() > config.session.distance then
    _doExport(vdata)
    lastPos = vdata.pos
  end
end

local function updateAI()
  if aiSettingsRequested < 0 then return end

  aiSettingsRequested = aiSettingsRequested - 1
  if aiSettingsRequested > 0 then return end

  local veh = be:getPlayerVehicle(0)

  if not veh then return end
  veh:queueLuaCommand('ai.setCutOffDrivability(' .. config.ai.drivability .. ')')  -- will span part of road network w drivability > config.ai.drivability
  veh:queueLuaCommand('ai.setState({mode = "' .. config.ai.mode .. '"})') -- , debugMode = "route"
  veh:queueLuaCommand('ai.setAggression(' .. config.ai.aggression .. ')')
  veh:queueLuaCommand('ai.driveInLane("' .. config.ai.driveInLane .. '")')
  if type(config.ai.speedLimitKmh) == 'number' then
    local s = config.ai.speedLimitKmh * 0.277778 -- kmh to m/s
    veh:queueLuaCommand('ai.setSpeedMode("limit");ai.setSpeed(' .. s .. ')')
  end
end

local function onPreRender(dt)
  -- ready to load the config at least?
  if recordMode == 0 and worldReadyState >= 0 and not config.loaded then
    reloadConfig()
    return
  end

  if not config.automatic then return end -- in manual mode?

  if recordMode == 1 and worldReadyState == 2 then
    log('I', 'annotation', "all ready, starting AI")
    local veh = be:getPlayerVehicle(0)
    if veh then
      if config.session.fastForward == true then
        be.physicsMaxSpeed = true
      end
      if config.session.dynamicCollision == false then
        settings.setValue('disableDynamicCollision', true)
      end

      aiSettingsRequested = 1 -- send right away

      core_camera.setByName(0, config.camera.mode)
      core_camera.proxy_Player('setupRelative',
        vec3(config.camera.relative.position),
        vec3(config.camera.relative.rotation),
        config.camera.relative.fov
      )
      --guihooks.trigger('hide_ui', true)
      core_gamestate.setGameState('annotation_mode', 'annotation_mode', nil)

      -- enter recording phase
      recordMode = 2
    end
  end

  -- record data?
  if recordMode == 2 then
    updateAI()
    exportData()

    -- do backup saves every X seconds in case the simulation crashes and alike
    saveTimer = saveTimer + dt
    if saveTimer >= saveTime then
      saveData()
      saveTimer = saveTimer - saveTime
    end

    runTime = runTime + dt
  end
end

local function buffersWrittenCallback(future)
  --print('buffersWrittenCallback', future)
  if not future or not writeBuffers[future] then
    log('E', 'annotation', 'unknown future on buffer written callback: ' .. tostring(future))
    return
  end

  local data = writeBuffers[future]
  local filenameBase = data.filenameBase
  data.filenameBase = nil -- remove from the data

  if config.session.format == 'json' then
    -- json output: do not touch the images
    writeJsonFile(filenameBase .. '.json', data, true)
  end

  writeBuffers[future] = nil
end

local function onExtensionLoaded()
  loadGameModeModules()
end

local function onScenarioChange(scenario)
  print('onScenarioChange', scenario and scenario.state)
  if not config.automatic then return end

  if scenario and scenario.state == 'pre-start' then
    if not config.vehicle.visible then
      local veh = be:getPlayerVehicle(0)
      if veh then
        veh:queueLuaCommand('bdebug.meshVisChange(0, true);')
      end
    end
  elseif scenario and scenario.state == 'post' then
    quit()
  end
end

local function onScenarioUIReady(state)
  if not config.automatic then return end
  print('onScenarioUIReady', state)
  if state == 'start' then    
    scenario_scenarios.onScenarioUIReady('play')
  elseif state == 'play' then
    print(nil)
  end
end

local function isAutomatic()
  return (config and config.automatic) or false
end

local function changeToAutomatic()
  config.automatic = true
end

-- interface
M.start = start
M.cancel = quit
M.extractData = function() exportData(true) end
M.onPreRender = onPreRender
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onClientPostStartMission = onClientPostStartMission
M.onScenarioChange = onScenarioChange
M.onScenarioUIReady = onScenarioUIReady
M.isAutomatic = isAutomatic
M.changeToAutomatic = changeToAutomatic
M.buffersWrittenCallback = buffersWrittenCallback
return M
