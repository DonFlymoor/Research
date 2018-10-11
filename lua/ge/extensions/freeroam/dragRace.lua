-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local helper = require('scenario/scenariohelper')

local exitTrigger = false
local time = 0
-- TStatic objects used for left and right number displays
local leftTimeDigits = {}
local rightTimeDigits = {}
local leftSpeedDigits = {}
local rightSpeedDigits = {}
local started = false
local jumpStarted = false
local speedUnit = 0
local vehicles = {}
local spawningOpponentVehicle = false
-- local opponentDistanceFromStart = 0
-- local playerDistanceFromStart = 0 
local opponentPrestageReady = false
local opponentStageReady = false
local opponentVehicleName = ""

local playerPrestageReady = false
local playerStageReady = false

-- local playerReady = false

local playerVehicle = nil
local opponentVehicle = nil

local results = {}

local function updateDisplay(side, finishTime, finishSpeed)
  local timeDisplayValue = {}
  local speedDisplayValue = {}
  local timeDigits = {}
  local speedDigits = {}

  if side == "r" then
    timeDigits = rightTimeDigits
    speedDigits = rightSpeedDigits
  elseif side == "l" then
    timeDigits = leftTimeDigits
    speedDigits = leftSpeedDigits
  end

  if finishTime < 10 then
    table.insert(timeDisplayValue, "empty")
  end

  if finishSpeed < 100 then
    table.insert(speedDisplayValue, "empty")
  end

  -- Three decimal points for time
  for num in string.gmatch(string.format("%.3f", finishTime), "%d") do
    table.insert(timeDisplayValue, num)
  end

  -- Two decimal points for speed
  for num in string.gmatch(string.format("%.2f", finishSpeed), "%d") do
    table.insert(speedDisplayValue, num)
  end

  for i,v in ipairs(timeDisplayValue) do 
    timeDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. v ..".dae")
    timeDigits[i]:postApply()
  end

  for i,v in ipairs(speedDisplayValue) do 
    speedDigits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_".. v ..".dae")
    speedDigits[i]:postApply()
  end
end

local function clearDisplay(digits)
  -- Setting display meshes to empty object
  -- We can assume 5 as we know there are only 5 digits availble for each display
  for i=1, #digits do 
    digits[i]:setField('shapeName', 0, "art/shapes/quarter_mile_display/display_empty.dae")
    digits[i]:postApply()
  end
end

local function resetDisplays()
  clearDisplay(leftTimeDigits)
  clearDisplay(rightTimeDigits)
  clearDisplay(leftSpeedDigits)
  clearDisplay(rightSpeedDigits)
end

local function onUpdate(dt)
  if started then
    time = time + dt
  end
  -- Checking current animation frame. Greenlight becomes visible at frame 79 (0.79)
  local rightGreenAnimFrame = scenetree.findObject("Greenlight_R"):getAnim().sequenceTime 
  if rightGreenAnimFrame > 0.78 and rightGreenAnimFrame < 0.8 and not jumpStarted then
    -- TODO: Reimplement jump start functionality
    started = true
    opponentVehicle:queueLuaCommand('controller.setFreeze(0)')
    guihooks.trigger('Message', {ttl = 5, msg = "Quarter mile started", category = "fill", icon = "flag"})
  end

  local leftGreenAnimFrame = scenetree.findObject("Greenlight_L"):getAnim().sequenceTime 
  if leftGreenAnimFrame > 0.78 and leftGreenAnimFrame < 0.8 and not jumpStarted then
    started = true
    guihooks.trigger('Message', {ttl = 5, msg = "Quarter mile started", category = "fill", icon = "flag"})
  end
end

local function getDistance(pos1, pos2)
  local distance = math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-pos2.y))
  if distance ~= distance then
    distance = 0
  end
  return distance
end

local function getTwoSmallestValues(values)
  local min1 = values[1]
  local min2 = values[2]

  if (min2.distance < min1.distance) then
    min1 = values[2]
    min2 = values[1]
  end

  for i=3, #values do
    if (values[i].distance < min1.distance) then
      min2 = min1
      min1 = values[i]
    elseif values[i].distance < min2.distance then
      min2 = values[i]
    end
  end

  return {min1, min2}
end

local function setupPrestage() 
  local prestageLightL = scenetree.findObject("Prestagelight_l")
  prestageLightL:playAnim('prestage_start', false)
  opponentVehicle:queueLuaCommand('controller.setFreeze(1)')
  -- TODO: Instead of setting path all the time I should just change route speed/aggression
  -- since same waypoint is being used anyways...
  opponentVehicle:queueLuaCommand('ai.setAggression('.. 0 ..')')
  opponentVehicle:queueLuaCommand('ai.setSpeed('.. 5 ..')')
  opponentPrestageReady = true
end

local function setupStage()
  local stageLightL = scenetree.findObject("Stagelight_l")
  stageLightL:playAnim('prestage_start', false)
  opponentVehicle:queueLuaCommand('controller.setFreeze(1)')
  opponentVehicle:queueLuaCommand('ai.setAggression('.. 2 ..')')
  opponentVehicle:queueLuaCommand('ai.setSpeed(nil)')
  opponentStageReady = true
end

local function calculateDistanceFromStart(vehicle, trigger)
  local wheels = {}

  -- We need to identify all vehicle wheels and then calculate the distance from the start line for each wheel
  for i=0, vehicle:getWheelCount()-1 do
    local axisNodes = vehicle:getWheelAxisNodes(i)
    local nodePos = vehicle:getNodePosition(axisNodes[1])
    local wheelNodePos = vehicle:getPosition() + vec3(nodePos.x, nodePos.y, nodePos.z):toPoint3F()
    local distance = getDistance(wheelNodePos, trigger:getPosition())
    -- because lua...
    wheels[i+1] = {wheelNodePos = wheelNodePos, distance = distance}
  end

  -- In order to accurately calculate that AI is in the correct position 
  -- we need to find the wheels that are closest to the start line
  local closestWheels = getTwoSmallestValues(wheels)
  local wheel1 = closestWheels[1].wheelNodePos
  local wheel2 = closestWheels[2].wheelNodePos
  -- Point inbetween both wheels is calculated so that we can get a somewhat accurate distance measurement
  local centerPoint = vec3((wheel1.x + wheel2.x)/2, (wheel1.y + wheel2.y)/2, (wheel1.z + wheel2.z)/2):toPoint3F()
  -- opponentDistanceFromStart = getDistance(centerPoint, trigger:getPosition())
  local distanceFromStart = getDistance(centerPoint, trigger:getPosition())

  -- TODO: Remove the following debug draws
  for k,v in pairs(closestWheels) do
    -- Line from each closest wheel to start line
    debugDrawer:drawLine(v.wheelNodePos, trigger:getPosition(), ColorF(0.5,0.0,0.5,1.0))
  end
  -- Line between two closest wheels
  debugDrawer:drawLine(closestWheels[1].wheelNodePos, closestWheels[2].wheelNodePos, ColorF(0.5,0.0,0.5,1.0))
  -- Sphere indicating center point of the wheels
  debugDrawer:drawSphere(centerPoint, 0.2, ColorF(0.0,0.0,1.0,1.0))
  -- Sphere indicating start line
  debugDrawer:drawSphere(trigger:getPosition(), 0.2, ColorF(0.0,0.0,1.0,1.0))
  -- Line between start line and center point of wheels
  debugDrawer:drawLine(centerPoint, trigger:getPosition(), ColorF(0,1,0,1.0))
  -- Text to indicate current distance from start line
  debugDrawer:drawTextAdvanced(trigger:getPosition(), String('Distance:' .. distanceFromStart), ColorF(0,0,0,1), true, false, ColorI(255, 255, 255, 255))

  return distanceFromStart
end 

-- data = trigger event data, side = left(L) or right(R) start point
local function animateLights(data, side) 
  local lights = {
    amberLight1 = scenetree.findObject("Amberlight1_" .. side),
    amberLight2 = scenetree.findObject("Amberlight2_" .. side),
    amberLight3 = scenetree.findObject("Amberlight3_" .. side),
    greenLight = scenetree.findObject("Greenlight_" .. side),
  }

  for v in pairs(lights) do 
    lights[v]:playAnim('tree_start', false)
  end
end

local function onPreRender(dt, dtSim) 
  if playerVehicle then
    local stageTriggerR = scenetree.findObject("stageTrigger_R")
    local playerDistanceFromStart = calculateDistanceFromStart(playerVehicle, stageTriggerR)

    if playerDistanceFromStart > 0 then
      if playerDistanceFromStart < 2 and playerDistanceFromStart > 1 and playerPrestageReady == false then
        local prestageLightR = scenetree.findObject("Prestagelight_r")
        prestageLightR:playAnim('prestage_start', false)
        playerPrestageReady = true
        opponentVehicle:queueLuaCommand('controller.setFreeze(0)')
      end
      -- AI vehicle is approximately on the start line
      if playerDistanceFromStart < 1 and playerStageReady == false then
        local stageLightR = scenetree.findObject("Stagelight_r")
        stageLightR:playAnim('prestage_start', false)
        playerStageReady = true
        animateLights(data, "L")
        animateLights(data, "R")
      end
    end
  end

  if opponentVehicle then
    local stageTriggerL = scenetree.findObject("stageTrigger_L")
    local opponentDistanceFromStart = calculateDistanceFromStart(opponentVehicle, stageTriggerL)
    -- TODO: fine tune this value as some vehicles don't stop as well as others,
    -- not sure how this could be solved atm though
    if opponentDistanceFromStart > 0 then
      -- AI vehicle is approximately 20cm from start line including tire radius
      if opponentDistanceFromStart < 2 and opponentDistanceFromStart > 1 and opponentPrestageReady == false then
        setupPrestage()
      end
      -- AI vehicle is approximately on the start line
      if opponentDistanceFromStart < 1 and opponentPrestageReady == true and opponentStageReady == false and playerStageReady == true then
        setupStage()
      end
    end
  end
end



local function setupVehicle()
  local pos = {
    x = -220.921,
    y = -207.704,
    z = 119.006
  }
  local rot = {
    x = 0,
    y = 0,
    z = 1,
    w = 234.052
  }
  rot = AngAxisF(rot.x, rot.y, rot.z, (rot.w * 3.1459) / 180.0 ):toQuatF()
  opponentVehicle:setPositionRotation(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
  opponentVehicle:setField('name', '', 'drag_opponent')
  opponentVehicle:queueLuaCommand('controller.setFreeze(0)')
  helper.setAiPath({vehicleName = 'drag_opponent', routeSpeed = 10, routeSpeedMode = 'set', waypoints = {'drag_1', 'drag_3', 'drag_4', 'drag_2'}, aggression = 0})
end

local function onVehicleSpawned(vehicleID) 
  if spawningOpponentVehicle == true then
    if scenetree.findObject("drag_opponent") then
      setupVehicle()
      spawningOpponentVehicle = false
    else  
      opponentVehicle = be:getObjectByID(vehicleID)
      opponentVehicle:setField('name', '', 'drag_opponent')
      setupVehicle()
      spawningOpponentVehicle = false
    end
    guihooks.trigger('MenuHide', true)
  end
  playerVehicle = be:getPlayerVehicle(0)
  -- guihooks.trigger('DragRaceMsg', "Please drive up to start line.")
end

-- Function to select a random vehicle based on current players vehicle class, not used currently
local function getVehicleOfSameClass() 
  local currentConfigKey = core_vehicles.getCurrentVehicleDetails().current.config_key
  local performanceClass = nil;
  local configs = core_vehicles.getConfigList()
  local similarVehicles = {}
  local similarVehicleCount = 0
  for _,v in pairs(configs.configs) do
    if v.key == currentConfigKey then
      for i,k in pairs(v.aggregates["Performance Class"]) do
        performanceClass = i
      end
    end
  end

  for i,v in pairs(configs.configs) do
    if (v.aggregates["Performance Class"]) then
      for class,k in pairs(v.aggregates["Performance Class"]) do
        if class == performanceClass then
          table.insert(similarVehicles, v)
        end
      end
    end
  end

  for i,v in pairs(similarVehicles) do
    similarVehicleCount = similarVehicleCount + 1
  end
  return similarVehicles[math.random(similarVehicleCount)]
end

local function onBeamNGTrigger(data)
  if data.triggerName == "prestageTrigger_R" then
    local prestageLight = scenetree.findObject("Prestagelight_" .. "r")
    if data.event == "enter" then
      started = false
      -- prestageLight:playAnim('prestage_start', false)
    end
  end

  if data.event == "enter" and (data.triggerName == "endTrigger_L" or data.triggerName == "endTrigger_R") then
    -- we remove vehicles from list once they reach the finish line
    for i=#vehicles, 1, -1 do
      if vehicles[i] == data.subjectID then
        table.remove(vehicles, i)
      end
    end

    if data.triggerName == "endTrigger_R" then
      local rightVehicle = be:getObjectByID(data.subjectID)
      -- Updating right display
      updateDisplay("r", time, rightVehicle:getVelocity():len() * speedUnit)
      table.insert(results, {time = time, speed = rightVehicle:getVelocity():len() * speedUnit, vehicle = core_vehicles.getCurrentVehicleDetails().configs.Name})
    end

    if data.triggerName == "endTrigger_L" then
      local leftVehicle = be:getObjectByID(data.subjectID)
      -- Updating left display
      updateDisplay("l", time, leftVehicle:getVelocity():len() * speedUnit)
      table.insert(results, {time = time, speed = leftVehicle:getVelocity():len() * speedUnit, vehicle = opponentVehicleName})
    end
    -- if there are no vehicles remaining then the race is over
    if #vehicles == 0 then
      started = false
      time = 0
      guihooks.trigger('MenuHide', false)
      guihooks.trigger('ChangeState', {state = "menu.dragRaceOverview", params = {results = results}})
      -- guihooks.trigger('DragRaceResult', results)
      results = {}
    end 
  end  

  if data.triggerName == "stageTrigger_R" then
    if data.event == "enter" then
      vehicles[1] = data.subjectID
    end
  end

  if data.triggerName == "stageTrigger_L" then
    if data.event == "enter" then
      vehicles[2] = data.subjectID
    end
  end

  if data.triggerName == "dragTrigger" then
    if data.event == "enter" then
      guihooks.trigger('MenuHide', false)
      guihooks.trigger('ChangeState', "menu.dragRaceOverview")
    end
  end
  if data.triggerName == "dragTrigger_L" then
    if data.event == "enter" then
      opponentVehicle:queueLuaCommand('ai.setSpeed('.. 5 ..')')
    end
  end
end

local function resetOpponent() 
  local opponent = scenetree.findObject("drag_opponent") 
  if opponent then
    opponent:reset()
    setupVehicle()
  end
end

local function resetStageLights()
  local stageLights = {
    prestageLightL = scenetree.findObject("Prestagelight_" .. "l"),
    prestageLightR = scenetree.findObject("Prestagelight_" .. "r"),
    stageLightL = scenetree.findObject("Stagelight_l"),
    stageLightR = scenetree.findObject("Stagelight_r")
  }
  for _,v in pairs(stageLights) do
    v:playAnim('prestage_end', false)
  end
end

local function init() 
  resetStageLights()
  spawningOpponentVehicle = false
  local unitType = settings.getValue('uiUnitLength')
  speedUnit = unitType == "metric" and 3.6 or 2.2369362920544
  started = false
  playerVehicle = be:getPlayerVehicle(0)
  guihooks.trigger('DragRaceMsg', "Drag race mode initialised.")
  local QuarterMileDisplayGroup = scenetree.QuarterMileDisplayGroup
  if QuarterMileDisplayGroup then
    -- Creating a table for the TStatics that are being used to display drag time and final speed
    for i=1, 5 do
      local leftTimeDigit = QuarterMileDisplayGroup:findObject("display_time_" .. i .. "_l")
      table.insert(leftTimeDigits, leftTimeDigit)

      local rightTimeDigit = QuarterMileDisplayGroup:findObject("display_time_" .. i .. "_r")
      table.insert(rightTimeDigits, rightTimeDigit)

      local rightSpeedDigit = QuarterMileDisplayGroup:findObject("display_speed_" .. i .. "_r")
      table.insert(rightSpeedDigits, rightSpeedDigit)

      local leftSpeedDigit = QuarterMileDisplayGroup:findObject("display_speed_" .. i .. "_l")
      table.insert(leftSpeedDigits, leftSpeedDigit)
    end
  end
end

local function onExtensionLoaded()
  init()
  guihooks.trigger('MenuHide', false)
  guihooks.trigger('ChangeState', "menu.dragRaceOverview")
end

local function onVehicleResetted(vid) 
  started = false
  jumpStarted = false
  -- playerReady = false
  opponentPrestageReady = false
  opponentStageReady = false
  playerPrestageReady = false
  playerStageReady = false 

  local vehicle = be:getObjectByID(vid)
  if vehicle:getName() == "drag_opponent" then
    helper.setAiPath({vehicleName = 'drag_opponent', routeSpeed = 10, routeSpeedMode = 'set', waypoints = {'drag_1', 'drag_3', 'drag_4', 'drag_2'}, aggression = 0})
  end
end

local function selectOpponent(selection)
  -- TODO: Find a way to replace vehicle if one is already existing.
  -- playerReady = false
  opponentPrestageReady = false
  opponentStageReady = false 
  playerPrestageReady = false
  playerStageReady = false 
  resetStageLights()
  core_vehicles.removeAllExceptCurrent()
  if not scenetree.findObject("drag_opponent") then
    spawningOpponentVehicle = true
    core_vehicles.spawnNewVehicle(selection.model, {config=selection.config, color=selection.color})
    opponentVehicleName = core_vehicles.getCurrentVehicleDetails().configs.Name
    -- core_camera.setByName(0, "external", true)
    be:enterVehicle(0, playerVehicle)
  else
    setupVehicle()
  end
  
end

M.onVehicleResetted = onVehicleResetted
M.onPreRender = onPreRender  
M.onUpdate = onUpdate
M.onBeamNGTrigger = onBeamNGTrigger
M.onExtensionLoaded = onExtensionLoaded
M.onClientStartMission = onClientStartMission
M.onVehicleSpawned = onVehicleSpawned
M.selectOpponent = selectOpponent
M.setupPrestage = setupPrestage
M.setupStage = setupStage
M.startRace = startRace
M.resetOpponent = resetOpponent


return M