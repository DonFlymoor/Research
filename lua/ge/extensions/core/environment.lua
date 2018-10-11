local M = {}
--[[
envState
  TimeOfDay
    time
    play
    speed
  Weather
    fog
    cloudcover
    rain
      ground model
      material: specular
      ambient color
--]]
M.groundModels = {}
M.loadedGroundModelFiles = {}

local envObjectIdCache = {}

local gm_filename = 'art/groundmodels.json'
local simSpeed = 1
local init_env={}
local function getObject(className)
  if envObjectIdCache[className] then
    return scenetree.findObjectById(envObjectIdCache[className])
  end

  envObjectIdCache[className] = 0
  local objNames = scenetree.findClassObjects(className)
  if objNames and tableSize(objNames) > 0 then
    local obj = scenetree.findObject(objNames[1])
    if obj then
      envObjectIdCache[className] = obj:getID()
      return scenetree.findObject(objNames[1])
    end
  end

  return nil
end

local function transformTime2Colors(filePath, time)
  if type(filePath) == 'string' and bitmap:loadFile(filePath) then
    local width = bitmap:getwidth()
    local index = time*width
    local color
    bitmap:getColor(index, 0, color)
    return color
  end
  return nil
end

local function setColors(time)
  local skyObj = getObject("scattersky")
  if skyObj then
    local colorize = transformTime2Colors(skyObj.colorizeGradientFile, time)
    local sunScale = transformTime2Colors(skyObj.sunScaleGradientFile, time)
    local ambientScale = transformTime2Colors(skyObj.ambientScaleGradientFile, time)
    local fogScale = transformTime2Colors(skyObj.fogScaleGradientFile, time)
    skyObj.colorize = colorize
    skyObj.sunScale = sunScale
    skyObj.ambientScale = ambientScale
    skyObj.fogScale = fogScale
    --skyObj.shadowsoftness = 1
    --skyObj.flarescale = 0
    --skyObj.sunsize = 0
  end
end

-------------------------------------------------------------
local function setTimeOfDay(timeOfDay)
  local timeObj = getObject("TimeOfDay")
  if timeObj and timeOfDay.time then
    timeObj.time = timeOfDay.time
    --setColors(timeOfDay.time)
    timeObj.play = timeOfDay.play
    timeObj.dayScale = timeOfDay.dayScale
    timeObj.nightScale = timeOfDay.nightScale
    timeObj.dayLength = timeOfDay.dayLength
  end
end

local function getTimeOfDay()
  local timeOfDay = {}
  local timeObj = getObject("TimeOfDay")
  if timeObj then
    timeOfDay.time = timeObj.time
    timeOfDay.play = timeObj.play
    timeOfDay.dayScale = timeObj.dayScale
    timeOfDay.nightScale = timeObj.nightScale
    timeOfDay.dayLength = timeObj.dayLength
  end
  return timeOfDay
end

local function setWindSpeed(windSpeed)
  local cloudObj = getObject("CloudLayer")
  if cloudObj and windSpeed then
    cloudObj.windSpeed = windSpeed
    cloudObj:postApply()
  end
end

local function getWindSpeed()
  local cloudObj = getObject("CloudLayer")
  local windSpeed
  if cloudObj then
    windSpeed = cloudObj.windSpeed
  end
  return windSpeed
end


local function setCloudCover(cloud)
  local cloudObj = getObject("CloudLayer")
  if cloudObj and cloud then
    cloudObj.coverage = cloud
    cloudObj:postApply()
  end
end

local function getCloudCover()
  local cloudObj = getObject("CloudLayer")
  local cloud
  if cloudObj then
    cloud = cloudObj.coverage
  end
  return cloud
end

local function setFogDensity(fog)
  local fogObj = getObject("LevelInfo")
  if fogObj and fog then
    fogObj.fogDensity = fog
    fogObj:postApply()
  end
end

local function getFogDensity()
  local fogObj = getObject("LevelInfo")
  local fog
  if fogObj then
    fog = fogObj.fogDensity
  end
  return fog
end

local function setPrecipitation(rainDrops)
  local rainObj = getObject("Precipitation")
  if rainObj and rainDrops then
    rainObj.numOfDrops = rainDrops
  end
end

local function getPrecipitation()
  local rainObj = getObject("Precipitation")
  local rainDrops
  if rainObj then
    rainDrops = rainObj.numOfDrops
  end
  return rainDrops
end

local function setGravity(grav)
  if not grav then return end
  -- important: let the level known about the change
  -- otherwise the spawning of objects will have the wrong gravity
  if scenetree.theLevelInfo then
    scenetree.theLevelInfo.gravity = grav
  end
  be:queueAllObjectLua("obj:setGravity("..grav..")")
end

local function getGravity()
  if scenetree.theLevelInfo then
    return scenetree.theLevelInfo.gravity
  end
  return -9.81; -- fallback
end


-------------------------------------------------------------
local function getState()
  local res = {}
  local timeObj = getTimeOfDay()
  if timeObj then
    res.time = timeObj.time
    res.play = timeObj.play
    res.dayScale = timeObj.dayScale
    res.nightScale = timeObj.nightScale
  end

  local windSpeed = getWindSpeed()
  res.windSpeed = windSpeed

  local cloudCover = getCloudCover()
  res.cloudCover = cloudCover

  local fog = getFogDensity()
  res.fogDensity = fog

  local numOfDrops = getPrecipitation()
  res.numOfDrops = numOfDrops

  res.gravity = getGravity()

  if next(res) == nil then
    return nil
  end
  return res

end

local function setState(state)

  if state then
    local timeObj = {time = state.time, play = state.play, dayScale = state.dayScale, nightScale = state.nightScale}
    setTimeOfDay(timeObj)

    setWindSpeed(state.windSpeed)

    setCloudCover(state.cloudCover)

    setFogDensity(state.fogDensity)

    setPrecipitation(state.numOfDrops)

    setGravity(state.gravity)
  end
end

local function dumpGroundModels()
  local gmCount = be:getGroundModelCount()
  local gms = {}
  for i = 0, gmCount do
    local gm = be:getGroundModelByID(i)
    if gm.data then
      gm = gm.data
      gms[gm.name or i] = {
      id = i,
      roughnessCoefficient = gm.roughnessCoefficient,
      defaultDepth = gm.defaultDepth,
      staticFrictionCoefficient = gm.staticFrictionCoefficient,
      slidingFrictionCoefficient = gm.slidingFrictionCoefficient,
      hydrodynamicFriction = gm.hydrodynamicFriction or gm.hydrodnamicFriction,
      stribeckVelocity = gm.stribeckVelocity,
      strength = gm.strength,
      collisiontype = gm.collisiontype,
      fluidDensity = gm.fluidDensity,
      flowConsistencyIndex = gm.flowConsistencyIndex,
      flowBehaviorIndex = gm.flowBehaviorIndex or gm.flowBehaviourIndex, -- omg ...
      dragAnisotropy = gm.dragAnisotropy,
      skidMarks = gm.skidMarks,
      shearStrength = gm.shearStrength
      }
    end
  end
  writeJsonFile('groundmodels_dump.json', gms, true)
end

local function loadGroundModelFile(filename)
  local gms = readJsonFile(filename)
  if not gms then
    log('E', 'ge.environment.reloadGroundModels', 'unable to load main ground models file: ' .. filename);
    return
  end

  local particles = require("particles")
  local materials = particles.getMaterialsParticlesTable()

  --dump(gms)
  local counter = 0

  local function submitGroundModel(k, v)
    local gm = ground_model()
    local names = v.aliases or {}
    table.insert(names, k)

    local knownAttributes = {aliases=1, roughnessCoefficient=1, staticFrictionCoefficient=1, slidingFrictionCoefficient=1, hydrodynamicFriction=1, stribeckVelocity=1, strength=1, collisiontype=1, fluidDensity=1, flowConsistencyIndex=1, flowBehaviorIndex=1, dragAnisotropy=1, skidMarks=1, defaultDepth=1, shearStrength = 1}
    local knownProblems = {hydrodnamicFriction='hydrodynamicFriction', flowBehaviourIndex='flowBehaviorIndex'}
    for j, _ in pairs(v) do
      if knownProblems[j] then
        log('E', 'groundmodels', 'Please fix your grounmodel up: ' .. tostring(j) .. ' should be instead: ' .. knownProblems[j])
      elseif not knownAttributes[j] then
        log('E', 'groundmodels', 'Unknown ground model attribute: ' .. tostring(j) .. ' - IGNORED')
      end
    end

    gm.roughnessCoefficient = v.roughnessCoefficient or 0
    gm.defaultDepth = v.defaultDepth or 0
    gm.staticFrictionCoefficient = v.staticFrictionCoefficient or 1
    gm.slidingFrictionCoefficient = v.slidingFrictionCoefficient or 0.7
    gm.hydrodynamicFriction = v.hydrodynamicFriction or v.hydrodnamicFriction or 0.01
    gm.stribeckVelocity = v.stribeckVelocity or 6
    gm.strength = v.strength or 1
    gm.collisiontype = 0
    if type(v.collisiontype) == 'string' then
      gm.collisiontype = particles.getMaterialIDByName(materials, v.collisiontype)
      --print(v.collisiontype .. ' -> ' .. tostring(gm.collisiontype))
    end
    gm.fluidDensity = v.fluidDensity or 200
    gm.flowConsistencyIndex = v.flowConsistencyIndex or 10000
    gm.flowBehaviorIndex = v.flowBehaviorIndex or v.flowBehaviourIndex or 0.5 -- omg ...
    gm.dragAnisotropy = v.dragAnisotropy or 0
    gm.skidMarks = v.skidMarks or false
    gm.shearStrength = v.shearStrength or 0

    for _, name in pairs(names) do
      local newName = string.upper(name)

      be:setGroundModel(newName, gm)
      --print("****** setting groundmodel: " .. tostring(newName))
      -- save them in lua so we could work with them later
      M.groundModels[newName] = gm
      counter = counter + 1
    end
  end

  -- convert the keys to uppercase
  local newGms = {}
  for k, v in pairs(gms) do
    if string.len(k) > 31 then
        local newk = string.sub(k, 1, 30)
        log('E', 'ge.environment.reloadGroundModels', 'Ground model name too long: "' .. tostring(k) .. '" is longer than the supported 31 characters. It will be cut to "' .. tostring(newk) .. '")')
        k = newk
    end
    newGms[string.upper(k)] = v
  end
  gms = newGms

  -- this enforces asphalt being the first always
  if gms['ASPHALT'] == nil then
    log('E', 'ge.environment.reloadGroundModels', 'The required ground model "ASPHALT" is missing. The default groundmodel will be random. Good luck :|')
  else
    submitGroundModel('ASPHALT', gms['ASPHALT'])
  end
  -- submit all other ground models randomly afterwards
  for k, v in pairs(gms) do
    if k ~= 'ASPHALT' then
      submitGroundModel(k, v)
    end
  end

  if counter > 0 then
    table.insert(M.loadedGroundModelFiles, filename)
  end
  --log('D', 'ge.environment.reloadGroundModels', 'loaded ' .. tostring(counter) .. ' ground models from file ' .. tostring(filename))
end

local function reloadGroundModels(missionFile)
  --log('D', 'ge.environment.reloadGroundModels', 'reloading all ground models ...')
  be:resetGroundModels()
  M.groundModels = {}
  M.loadedGroundModelFiles = {}

  -- load the common groundmodels first
  loadGroundModelFile(gm_filename)

  -- then load level groundmaps
  missionFile = missionFile or getMissionFilename()
  if missionFile and string.len(missionFile) > 0 then
    local levelDir, filename, ext = string.match(missionFile, "(.-)([^/]-([^%.]*))$")
    local files = FS:findFilesByRootPattern(levelDir..'/groundModels/', '*.json', -1, true, false)

    -- filter paths to only return filename without extension
    for _,fn in pairs(files) do
      loadGroundModelFile(fn)
    end
  end
end

local function reset()
    guihooks.trigger("EnvironmentStateUpdate", getState())
    reloadGroundModels()
end
local function reset_init()
    setState(init_env)
end
local function onClientPreStartMission(mission)
  --print("onClientPreStartMission: " .. tostring(mission))
  reloadGroundModels(mission)
  init_env=getState()
end

-- having this function, enables writing groundmodels that are getting reloaded dynamically in the game
local function onFileChanged(filename, type)
  if filename and filename:find('.json') then
    filename = string.upper(filename)
    for _, f in pairs(M.loadedGroundModelFiles) do
      if string.upper(f) == filename then
        log('D', 'environment', 'ground model changed dynamically, reloading collision')
        reset()
        -- in this case we want to make sure everything uses the new properties
        -- do not put this in reset as it would be called twice
        be:reloadCollision()
        return
      end
    end
  end
end

-- This function is exposed to the module (M.requestState) but was not implemented
-- I guess the intention is to send a guihook - gsiantikos
local function sendState()
  guihooks.trigger("EnvironmentStateUpdate", getState())
end

local function invertLerp(from,to,value)
  value = math.min(math.max(from, value),to)
  return (value - from) / (to-from)
end

--local dbgui_window_open = core_imgui.BoolPtr(true)
--local dbgui_windowFlag_MenuBar = core_imgui.ImGuiWindowFlags("ImGuiWindowFlags_MenuBar")

local function renderdebugUI()
  core_imgui.Begin("Environment-Debug", dbgui_window_open, dbgui_windowFlag_MenuBar)

  local fontHeight = core_imgui.GetTextLineHeight()
  core_imgui.BeginChild("groundmodels", core_imgui.ImVec2(150, 0))
  local ffi = require('ffi')

  for i = 1, 10 do
    local pos = core_imgui.GetCursorScreenPos()
    core_imgui.Text("A: " .. tostring(i))
    core_imgui.ImDrawList_AddRectFilled(
      core_imgui.GetWindowDrawList(),
      pos,
      core_imgui.ImVec2(pos.x + 20, pos.y + fontHeight),
      core_imgui.GetColorU32ByVec4(core_imgui.ImVec4(1,0,0,1))
    )
    core_imgui.SameLine()
    core_imgui.Text("A: " .. tostring(i))
  end
  core_imgui.EndChild()


  core_imgui.BeginChild("groundmodels1",core_imgui.ImVec2(150, 0))
  core_imgui.Text("A")
  core_imgui.Text("B")
  core_imgui.EndChild()

  core_imgui.End()
end

local function onUpdate()
  local levelInfo = getObject("LevelInfo")
  if not levelInfo then return end

  local tempCurve = levelInfo:getTemperatureCurveC()
  if #tempCurve < 2 then return end

  local tod = getTimeOfDay()
  if not tod or not tod.time then
    be:setSeaLevelTemperatureK( tempCurve[1][2] + 273.15 )
    return
  end

  local tempC = 15
  local t = math.max(tempCurve[1][1], math.min(tempCurve[#tempCurve][1], tod.time))
  for i, v in ipairs(tempCurve) do
    if v[1] > t or i == #tempCurve then
      local factor = invertLerp(tempCurve[i-1][1], v[1], t)
      tempC = lerp(tempCurve[i-1][2], v[2], factor)
      break
    end
  end

  be:setSeaLevelTemperatureK( tempC + 273.15 )

  --renderdebugUI()
end

local function onClientStartMission(mission)
  envObjectIdCache = {}
end

local function onEditorEnabled(enabled)
  if not enabled then
    envObjectIdCache = {}
  end
end


------------------------------------------
---for ui interface environment property
M.setState = setState
M.requestState = sendState
M.reset = reset
M.getState = getState
M.reset_init=reset_init
----------------------------------------------
M.setTimeOfDay = setTimeOfDay
M.getTimeOfDay = getTimeOfDay
M.setWindSpeed = setWindSpeed
M.getWindSpeed = getWindSpeed
M.setCloudCover = setCloudCover
M.getCloudCover = getCloudCover
M.setFogDensity = setFogDensity
M.getFogDensity = getFogDensity
M.setPrecipitation = setPrecipitation
M.getPrecipitation = getPrecipitation
M.setGravity = setGravity
M.getGravity = getGravity
M.store_init=store_init
M.onClientPreStartMission = onClientPreStartMission
M.onInit = reset
M.onFileChanged = onFileChanged
M.onUpdate = onUpdate
M.onClientStartMission = onClientStartMission
M.onEditorEnabled = onEditorEnabled

M.dumpGroundModels = dumpGroundModels

return M
