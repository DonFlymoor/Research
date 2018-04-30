--  Supplies code-created scenario info for the quickrace selection screen.
--  The created scenarios contain the available tracks.
--  This code also loads the scenario, creating the vehicle, needed prefabs
--  and race checkpoints, and also sets the scenario data so that the scenario_race.lua
--  can be used to handle the race logic.

local M = {}

local times = {}

-- load the prefabs defined in the quickrace track, and also the vehicle.
-- it is loaded here, so that the scenario code can work with the vehicle.
local function onLoadCustomPrefabs(sc)
  log( 'I', 'quickRaceLoad', 'onLoadCustomPrefabs' )
  M.loadVehicle(sc)
end


local function onScenarioLoaded(sc)
  if not sc.track then return end
  --dump(sc.track.tod .. " = TOD")
  if sc.track.tod == 0 or sc.track.tod == 1 or sc.track.tod == 8 then
    
    be:getPlayerVehicle(0):queueLuaCommand("electrics.set_fog_lights(1) ; electrics.setLightsState(2)")
  end
  if sc.track.reverse then
    for _, node in pairs(sc.nodes) do
      if node.rot ~= nil then
        node.rot = node.rot * -1
      end
    end
  end
end

--loads the vehicle by creating a TS-snipped which has the position and vehicle information embedded.
local function loadVehicle(scenario) 
  local vehicle = scenario.vehicle
  if not vehicle then return end

--vehicle.color = vehicle.color or "1 1 1 .5"
  vehicle = core_vehicles.fillDefaults(vehicle.model, vehicle)

  -- figure out which spawnSphere we should use for this scenario_race.
  local spawnSphere = ''
  if scenario.track.rollingStart then
    if scenario.track.reverse then
      spawnSphere = scenario.track.spawnSpheres.rollingReverse
    else
      spawnSphere = scenario.track.spawnSpheres.rolling
    end
  else
    if scenario.track.reverse then
      spawnSphere = scenario.track.spawnSpheres.standingReverse
    else
      spawnSphere = scenario.track.spawnSpheres.standing
    end
  end
  local spawn = scenetree.findObject(spawnSphere)

  local position = { x=0, y=0, z=0}

  if spawn ~= nil then
    position = spawn:getPosition()
  else
    log('E', "QuickRace", "Could not find spawnSphere " .. spawnSphere .. "! Using 0/0/0 instead.")
  end

  local createVehicle = [[
    if(isObject(scenario_player0)) {
      scenario_player0.delete();
    }
    new BeamNGVehicle(scenario_player0) {
      JBeam = "]]..vehicle.model..[[";
      partConfig = "]]..vehicle.config..[[";
      color = "]]..vehicle.color..[[";
      colorPalette0 = "]]..vehicle.color2..[[";
      colorPalette1 = "]]..vehicle.color3..[[";
      renderDistance = "500";
      renderFade = "0.1";
      isAIControlled = "0";
      dataBlock = "default_vehicle";
      position = "]]..position.x..' '..position.y..' '..position.z..[[";
      rotation = "1 0 0 0";
      scale = "1 1 1";
      canSave = "1";
      canSaveDynamicFields = "1";
    };]]
    
  TorqueScript.eval(createVehicle)
  local r = {x=0, y=0, z=1, w=0}
  if spawn ~= nil then
    r = spawn:getRotation()
  end
  be:getPlayerVehicle(0):setPositionRotation(position.x,position.y,position.z,r.x,r.y,r.z,r.w)

  scenetree.ScenarioObjectsGroup:addObject(be:getPlayerVehicle(0))
end

-- callback for the UI: called when it finishes counting down
local function onCountdownEnded()
  local veh = be:getPlayerVehicle(0)
  if veh then
    veh:queueLuaCommand('controller.setFreeze(0)')
  else
    log('E','quickRaceLoad','No player vehicle found!')
  end

  times = {}
end



local function getConfigKey(rolling, reverse, laps)

  local scenario = scenario_scenarios.getScenario()

  if rolling == nil then rolling = scenario.rollingStart end
  if reverse == nil then reverse = scenario.isReverse end
  if laps == nil then laps = scenario.lapCount end

  local mode = "standing"

  if rolling then mode = "rolling" end
  if reverse then mode = mode.."Reverse" end
  if laps then mode = mode .. laps end

  return mode
end


local function onRaceStart( )

  times = {}
end

local function onRaceWaypointReached( wpInfo )
  if not scenario_scenarios.getScenario().isQuickRace then return end

  if not wpInfo.next or wpInfo.next == 1 then
    times[#times+1] = wpInfo.time
    for i = 1, (#times)-1 do
      times[#times] = times[#times] - times[i]
    end
    --dump(wpInfo)
    --dump(times)
    local scenario = scenario_scenarios.getScenario()
    local vehicle = be:getPlayerVehicle(0)

    local record = {
      playerName = getVehicleLicenseName(vehicle),
      vehicleBrand = scenario.vehicle.file.Brand,
      vehicleName = scenario.vehicle.file.Name,
      vehicleConfig = string.gsub(scenario.vehicle.config,"(.*/)(.*)/(.*).pc", "%3"),
      vehicleModel = scenario.vehicle.model
    }

    local place = core_highscores.setScenarioHighscoresCustom(times[#times]*1000,record,scenario.levelName,scenario.scenarioName,M.getConfigKey(false,nil,0))

    if scenario.highscores == nil then
      scenario.highscores = {}
    end
    if scenario.highscores.singleRound == nil then
      scenario.highscores.singleRound = {}
    end

    if place == -1 then
      return
    end

    --dump("place is "..place)
    local incIndexes = {}
    for k,v in ipairs(scenario.highscores.singleRound) do
      if place <= v then 
        incIndexes[#incIndexes+1] = k
      end
    end
    --dump(incIndexes)
    for k,v in ipairs(incIndexes) do
      scenario.highscores.singleRound[k] = scenario.highscores.singleRound[k]+1
    end
    scenario.highscores.singleRound[#scenario.highscores.singleRound+1] = place
    --dump(scenario.highscores.singleRound)

  end
end

local function getVehicleBrand(scenario) 
  return scenario.vehicle.file.Brand
end

local function getVehicleName(scenario)
return scenario.vehicle.file.Name
end

local function onRaceResult(final)
  if not scenario_scenarios.getScenario().isQuickRace then return end
  local scenario = scenario_scenarios.getScenario()
  local vehicle = be:getPlayerVehicle(0)
   
  --highscores.setScenarioHighscores(,M.getVehicleName(),getVehicleLicenseName(),scenario.map,scenario.scenarioName,M.getConfigKey(),0)

  local record = {
    playerName = getVehicleLicenseName(vehicle),
    vehicleBrand = scenario.vehicle.file.Brand,
    vehicleName = scenario.vehicle.file.Name,
    vehicleConfig = string.gsub(scenario.vehicle.config,"(.*/)(.*)/(.*).pc", "%3"),
    vehicleModel = scenario.vehicle.model
  }

  local place = core_highscores.setScenarioHighscoresCustom(final.finalTime*1000, record ,scenario.levelName,scenario.scenarioName,M.getConfigKey())
  local scores = core_highscores.getScenarioHighscores(scenario.levelName, scenario.scenarioName, M.getConfigKey())
  if scenario.highscores == nil then
    scenario.highscores = {}
  end
  scenario.highscores.scores = scores
  if place ~= -1 then
    scenario.highscores.scores[place].current = true
  end
  scenario.highscores.place = place
  scenario.highscores.singleScores = core_highscores.getScenarioHighscores(scenario.levelName, scenario.scenarioName, M.getConfigKey(false,nil,0))
  for _,v in ipairs(scenario.highscores.singleRound) do
    if v <= #(scenario.highscores.singleScores) then
      scenario.highscores.singleScores[v].current = true
    end
  end
  scenario.viewDetailed = 0
  if place == -1 then
    scenario.detailedRecord = {
      playerName = getVehicleLicenseName(vehicle),
      vehicleBrand = scenario.vehicle.file.Brand,
      vehicleName = scenario.vehicle.file.Name,
      place = " / ",
      formattedTimestamp = os.date("!%c",os.time())
    }
  else
    scenario.detailedRecord = scores[place]
  end
end


M.onScenarioLoaded = onScenarioLoaded
M.onLoadCustomPrefabs = onLoadCustomPrefabs

M.addCheckPoint = addCheckPoint
M.onCountdownEnded = onCountdownEnded
M.loadVehicle = loadVehicle
M.loadCheckpoints = loadCheckpoints
M.getConfigKey = getConfigKey

M.onRaceWaypointReached = onRaceWaypointReached
M.onRaceResult = onRaceResult

M.getVehicleBrand = getVehicleBrand
M.getVehicleName = getVehicleName

return M

