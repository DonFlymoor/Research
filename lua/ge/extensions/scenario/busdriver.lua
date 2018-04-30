local M = {}
M.dependencies = {'scenario_scenarios'}
local helper = require('scenario/scenariohelper')
local logTag = 'scenario_busdriver'

local finalWaypointName = 'scenario_finish1'
local playerInstance = 'scenario_player0'
local playerVehicleID = 0
local running = false
local playerWon = false
local wpList = {}
local busConfig = {}
local passedWp={}
local currentLine = {}
local nextStop = nil
local stopTimer = -1
local markers = {}
local monitorMarker = false
local currentAlphaMarker = 0
local setpointAlphaMarker = 0
local nameMarkers = {"busMarkerTL","busMarkerTR","busMarkerBL","busMarkerBR"}
local markerIndexCorrection = {{3,4,2,1},{1,2,4,3} }
local stopComplete = false
local camera = nil
local timeToWaitAtStop = 5
local exitTggBeforeTimer = false
local origSpawnAABB = nil

local function reset()
  running = false
  playerWon = false
  exitTggBeforeTimer = false
  local playerVehicle = scenetree.findObject(playerInstance)
  if playerVehicle then
    playerVehicleID = playerVehicle:getID()
    playerVehicle:queueLuaCommand('controller.setFreeze(1)')     
  end
  passedWp={}
  nextStop = nil
  for _,m in ipairs(markers) do
    m:setField('instanceColor', 0, '1 1 1 0')
    m:setPosition(Point3F(0, 0, 0))
  end
  setpointAlphaMarker,currentAlphaMarker = 0,0
  monitorMarker = false  
  
  be:getPlayerVehicle(0):setSpawnLocalAABB(Box3F())
end

local function fail(reason)
  --log('E', logTag,"FAIL ======="..reason)
  scenario_scenarios.finish({failed = reason})
  reset()
end

local function success(reason)
  --log('E', logTag,"success ======="..reason)
  scenario_scenarios.finish({msg = reason})
  reset()
end


local function initBusLine() 
  busConfig = scenario_scenarios.getScenario().busdriver
  currentLine = extensions.core_busRouteManager.setLine(playerVehicleID,busConfig.routeID,busConfig.variance)
  nextStop = currentLine.tasklist[1]  
  -- log("E", logTag, "onRaceStart  nextStop '"..dumps(nextStop).."'   currentLine.tasklist ='"..dumps(currentLine.tasklist).."'")
  if currentLine == nil then
    fail('Failed to load the line data for '..tostring(busConfig.routeID).."  "..tostring(busConfig.variance))
  end  --core_busRouteManager.onAtStop({cur=1,next=2,vehicleId=playerVehicleID})
end

local function onScenarioRestarted(scenario)
  reset()
  initBusLine() 
end

local function createBusMarker(markerName)
  local marker =  createObject('TSStatic')
  marker:setField('shapeName', 0, "art/shapes/interface/position_marker.dae")
  marker:setPosition(Point3F(0, 0, 0))
  marker.scale = Point3F(1, 1, 1)
  marker:setField('rotation', 0, '1 0 0 0')
  marker.useInstanceRenderData = true
  marker:setField('instanceColor', 0, '1 1 1 0')
  marker:setField('collisionType', 0, "Collision Mesh")
  marker:setField('decalType', 0, "Collision Mesh")
  marker:setField('playAmbient', 0, "1")
  marker:setField('allowPlayerStep', 0, "1")
  marker:setField('canSave', 0, "0")
  marker:setField('canSaveDynamicFields', 0, "1")
  marker:setField('renderNormals', 0, "0")
  marker:setField('meshCulling', 0, "0")
  marker:setField('originSort', 0, "0")
  marker:setField('forceDetail', 0, "-1")
  marker.canSave = false
  marker:registerObject(markerName)  
  return marker
end

local function onRaceStart()
  -- log('I', logTag,'onRaceStart called')
  reset()
  initBusLine() 
  be:getPlayerVehicle(0):queueLuaCommand('controller.setFreeze(0)')     
  if scenetree.ScenarioObjectsGroup then
    log('I', logTag,'Creating markers')
    local ScenarioObjectsGroup = scenetree.ScenarioObjectsGroup
    if #markers == 0 then
      for k,v in pairs(nameMarkers) do
        local mk = scenetree.findObject(v)
        if mk == nil then
          log('I', logTag,'Creating marker '..tostring(v))
          mk = createBusMarker(v)
          ScenarioObjectsGroup:addObject(mk.obj)
        end
        table.insert(markers, mk)
      end
    end
  end

  -- check navhelp
  if currentLine.navhelp then
    local mapData = map.getMap()
    for k, v in pairs(currentLine.navhelp) do
      for _, wp in pairs(v) do
        if not mapData.nodes[wp] then
          log('E', logTag,'Missing navhelp '.. wp)
        end
      end
    end
  end

  --log('I', logTag,'get scenar . lapConfig')
  --wpList = scenario_scenarios.getScenario().lapConfig
  --be:getObjectByID(vehicleId):queueLuaCommand("controller.getController('busNextStopDsp').onDepartedStop( "..dumps({unpack(wpList, 1,#wpList)}).." )")


  --scenario_scenarios.trackVehicleMovementAfterDamage(playerInstance, {waitTimerLimit=2})


  initBusLine() 
  running = true
end

local function moveBusMarkers()
  local tpos,pos = vec3(nextStop[3]), vec3(0,0,0)
  local tr = quat(nextStop[4])
  local r
  local zVec,yVec,xVec = tr*vec3(0,0,1), tr*vec3(0,1,0), tr*vec3(1,0,0)

  local d = nextStop[5][1]*0.5-1.0
  local w = nextStop[5][2]*0.5-1.0
  -- local bext = ob:getHalfExtents()
  -- if bext.x*1.25 < d then d = bext.x*1.25 end
  -- if bext.y*1.25 < w then w = bext.y*1.25 end
  for k,marker in pairs(markers)do 
    if k == 1 then --top left
      pos = (tpos-xVec*d+yVec*w)
      r = tr * quatFromEuler(0, 0, math.rad(90))
    elseif k == 2 then --Top Right
      pos = (tpos+xVec*d+yVec*w)
      r = tr * quatFromEuler(0, 0, math.rad(180))
    elseif k == 3 then --Bottom Right
      pos = (tpos+xVec*d-yVec*w)
      r = tr * quatFromEuler(0, 0, math.rad(270))
    elseif k == 4 then --Botton Left
      pos = (tpos-xVec*d-yVec*w)
      r = tr
    end
    local heightCorrection = be:castRay( (pos):toPoint3F(), (pos-vec3(0,0,10)):toPoint3F() )
    if heightCorrection < 1 then
      local tHeight = be:castRay( (tpos):toPoint3F(), (tpos-vec3(0,0,10)):toPoint3F() )
      if tHeight *0.8 > heightCorrection then
        pos.z = pos.z-tHeight*0.8
        heightCorrection = be:castRay( (pos):toPoint3F(), (pos-vec3(0,0,10)):toPoint3F() )
      end
    end
    pos.z = pos.z-heightCorrection
    marker:setPosRot(pos.x, pos.y, pos.z, r.x,r.y,r.z,r.w)
    marker:setField('instanceColor', 0, "1 0 0 1")
  end

end

--duplicate code at vehicle/controller/busLineCtrl.lua:123
local function isTriggerOnBusLine(tasks,tname)
  for k,v in pairs(tasks) do
    if v[1] == tname then return true end
  end
  return false
end

local function onBeamNGTrigger(data)
  if running == false then return end
  -- log('E', logTag,'onBeamNGTrigger called '..dumps(data))
  if data.type and data.type == "busstop" and isTriggerOnBusLine(currentLine.tasklist,data.triggerName) then

    --core_busRouteManager.onAtStop(data)

    if data.event == "enter" then
      exitTggBeforeTimer = false
      if tableContains(passedWp, data.triggerName) then guihooks.trigger('ScenarioRealtimeDisplay', {msg = 'scenarios.busRoutes.alreadyStop'});return end
      -- if busConfig.strictStop then
        stopTimer = 0
        stopComplete = false
        local cur =1
        if currentLine.tasklist then
          for i=1, #currentLine.tasklist, 1 do
            if currentLine.tasklist[i][1] == data.triggerName then cur=i; break end
          end
        end
        if cur > 1 and not tableContains(passedWp, currentLine.tasklist[cur-1][1]) then 
          fail( "scenarios.busRoutes.skip" )
        end
      -- end
    end

    if data.event == "exit" then
      -- if not busConfig.strictStop then
      --   if not tableContains(passedWp, data.triggerName) then
      --     table.insert( passedWp, data.triggerName )
      --   end
      -- end
      guihooks.trigger('ScenarioRealtimeDisplay', {msg = ''})

      if (not stopComplete or stopTimer < timeToWaitAtStop) then
        -- fail("you didn't wait !!! timer="..tostring(stopTimer)) 
        exitTggBeforeTimer = true
        return
      end

      monitorMarker = false
      for _,m in ipairs(markers) do
        m:setField('instanceColor', 0, '0 1 0 1')
        currentAlphaMarker=1
      end
      setpointAlphaMarker = 0

      local cur =1
      if currentLine.tasklist then
        for i=1, #currentLine.tasklist, 1 do
          if currentLine.tasklist[i][1] == data.triggerName then cur=i; break end
        end
      end
      if currentLine.tasklist and cur == #currentLine.tasklist then success("scenarios.busRoutes.success")end
    end
  end

  if data.type and data.type == "buswp" and data.event == "enter" then
    if not tableContains(passedWp, data.triggerName) then
      table.insert( passedWp, data.triggerName )
    end
  end

end

local function onRaceResult(final)
  if playerWon == true then
    local scenario = scenario_scenarios.getScenario()
    local vehicle = core_vehicles.getCurrentVehicleDetails()
    local record = {
      playerName = getVehicleLicenseName(be:getPlayerVehicle(0)),
      vehicleBrand = vehicle.model.Brand,
      vehicleName = vehicle.model.Name,
      vehicleConfig = vehicle.current.pc_file,
      vehicleModel = vehicle.model
    }
    core_highscores.setScenarioHighscoresCustom(final.finalTime*1000, record, scenario.levelName, scenario.name, "busRoute")
  end
end

local function onVehicleStoppedMoving(vehicleID, damaged)
  if running then
    local playerVehicleID = scenetree.findObject(playerInstance):getID()
    if vehicleID == playerVehicleID and damaged then
      if not playerWon then
        fail('scenarios.utah.chapter_2.chapter_2_6_canyon.fail.msg')
      end
    end
  end
end

local function onVehicleSpawned(vehicleID)
  log('I', logTag,'vehicleSpawned called...'..tostring(vehicleID))
  local playerVehicleID = be:getPlayerVehicleID(0)
  
  if playerVehicleID or (playerVehicleID == vehicleID) then
    reset()
    be:getPlayerVehicle(0):queueLuaCommand('controller.setFreeze(1)')     
    busConfig = scenario_scenarios.getScenario().busdriver
    currentLine = extensions.core_busRouteManager.setLine(playerVehicleID,busConfig.routeID,busConfig.variance)    
    if currentLine == nil then
      fail('Failed to load the line data for '..tostring(busConfig.routeID).."  "..tostring(busConfig.variance))
    end
  end
end

local isRightNode = function(triggerPos, first, second)
  local mapData = map.getMap()
  local pos0 = mapData.nodes[first].pos
  local pos1 = mapData.nodes[second].pos
  return (pos1-pos0):normalized():cross(vec3(0, 0, 1)):dot((triggerPos-pos0):normalized()) > 0
end

local function renderDebugLine()
  local wps = {}
  for i, stop in ipairs(currentLine.tasklist) do
    local vec3Destination = vec3(stop[3])
    debugDrawer:drawTextAdvanced(vec3Destination:toPoint3F(), String('['..i..'] '..stop[2] .. ' / ' .. stop[1]), ColorF(0,0,0,1), true, false, ColorI(255, 255, 255, 255))
    local firstDest, secondDest, distanceDest = map.findClosestRoad(vec3Destination)
    local trigger = scenetree.findObject(nextStop[1])
    if not isRightNode(vec3Destination, firstDest, secondDest) then
      local temp = firstDest
      firstDest = secondDest
      secondDest = temp
    end
    if currentLine.navhelp and currentLine.navhelp[stop[1]] then
      for i, wp in ipairs(currentLine.navhelp[stop[1]]) do
        table.insert(wps, wp)
      end
    end

    table.insert(wps, firstDest)
    table.insert(wps, secondDest)
  end
  core_groundMarkers.setFocus(wps, 10, 150 * 1000, 200 * 1000, vec3Destination, true, {hex2rgb(currentLine.routeColor)})
end

local function onPreRender(dt)
  -- local debugPath = true
  core_groundMarkers.setFocus(nil)
  if (not nextStop) or nextStop == "nil" then return end
  if nextStop == nil then return end

  if currentAlphaMarker ~= setpointAlphaMarker and #markers > 0 then
    if currentAlphaMarker > setpointAlphaMarker then currentAlphaMarker=currentAlphaMarker-dt*0.5
    elseif currentAlphaMarker < setpointAlphaMarker then currentAlphaMarker=currentAlphaMarker+dt*0.5 end
    if currentAlphaMarker < 0 then currentAlphaMarker = 0 elseif currentAlphaMarker > 1 then currentAlphaMarker=1 end
    for _,m in ipairs(markers) do
      m:setField('instanceColor', 0, (setpointAlphaMarker ==0 and '0 1 0 ' or '1 0 0 ')..tostring(currentAlphaMarker))
    end
    monitorMarker = currentAlphaMarker ==1
  end

  local pv = be:getPlayerVehicle(0)
  if not pv then return end

  --log("E", logTag, "onPreRender  nextStop("..dumps(type(nextStop))..")="..dumps(nextStop))
  local vec3Destination = vec3(nextStop[3])
  local proj = vec3(0,0,5)
  local heightCorrection = be:castRay( (vec3Destination+proj):toPoint3F(), (vec3Destination-proj*3):toPoint3F() )
  if debugPath then
    debugDrawer:drawSphere(vec3Destination:toPoint3F(), 1.6, ColorF(1.0,0.0,0.0,1.0))
    debugDrawer:drawSphere(vec3(vec3Destination.x,vec3Destination.y,vec3Destination.z-heightCorrection+proj.z ):toPoint3F(), 0.9, ColorF(0.5,0.0,0.0,1.0))
    debugDrawer:drawLine((vec3Destination+proj):toPoint3F(), (vec3Destination-proj*2):toPoint3F(), ColorF(0.5,0.0,0.5,1.0))
  end
  vec3Destination.z = vec3Destination.z-heightCorrection+proj.z
  local firstDest, secondDest, distanceDest = map.findClosestRoad(vec3Destination)

  local trigger = scenetree.findObject(nextStop[1])
  if not trigger.bidirectional and not isRightNode(vec3Destination, firstDest, secondDest) then
    local temp = firstDest
    firstDest = secondDest
    secondDest = temp
  end


  local wps = {}
  do 
    local mapData = map.getMap()
    local vehPos = vec3(be:getPlayerVehicle(0):getPosition())
    local distanceToWp = function(wp)
      return (mapData.nodes[wp] and vehPos:distance(vec3(mapData.nodes[wp].pos))) or 0
    end

    if currentLine.navhelp and currentLine.navhelp[nextStop[1]] then
      for i, wp in ipairs(currentLine.navhelp[nextStop[1]]) do
        if passedWp[wp] or distanceToWp(wp) < 15 then
          passedWp[wp] = true
        else
          table.insert(wps, wp)
        end
      end
    end
  end
  table.insert(wps, firstDest)
  table.insert(wps, secondDest)

  core_groundMarkers.setFocus(wps, 10, 150, 200, vec3Destination, nil, {hex2rgb(currentLine.routeColor)})

  if M.enabledLineDebug then
    renderDebugLine()
  end

  if exitTggBeforeTimer then
    local vpos = vec3(pv:getPosition())
    -- disabled for now, sometimes make fail the scenario when maneuvering the bus.
    -- 20m is from the center of the trigger, with big trigger can fail after exit 1m from trigger
    --if vec3Destination:distance(vpos) > 20 then fail("scenarios.busRoutes.exitTggBeforeTimer") end
  end

  if monitorMarker then
    local ob = pv:getSpawnWorldOOBB()
    local vDirVec=vec3(pv:getDirectionVector())
    local tr = quat(nextStop[4])
    local yVec = tr*vec3(0,1,0)
    local trigger = scenetree.findObject(nextStop[1])
    trigger = Sim.upcast(trigger)
    -- local vUpVec=vec3(pv:getDirectionVectorUp())
    -- local vLeftVec=vDirVec:cross(vUpVec)
    local front = ((vDirVec:dot(yVec) > 0) and 1 or 0) +1
    local contained = false
    for i=0, 3, 1 do
      contained = trigger:isPointContained(ob:getPoint(i*2)) and trigger:isPointContained(ob:getPoint(i*2+1))
      markers[markerIndexCorrection[front][i+1]]:setField('instanceColor', 0, (contained and "1 0.5 0 1" or "1 0 0 1") )
    end
  end
  
end


local function onBusUpdate(state)
  -- log('E', logTag..".onBusUpdate",'event='..dumps(state))
  if state.event == "onTriggerTick" and not stopComplete and nextStop and nextStop[1] == state.triggerName then
    if not origSpawnAABB then origSpawnAABB =  be:getPlayerVehicle(0):getSpawnLocalAABB() end

    if state.speed > 0.1 and stopTimer < timeToWaitAtStop then
      be:getPlayerVehicle(0):setSpawnLocalAABB(origSpawnAABB)
      stopTimer = 0
      guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.stop"})
    elseif (not state.bus_dooropen or not state.bus_kneel) and busConfig.strictStop and stopTimer < timeToWaitAtStop then
      
      -- make bus box smaller to avoid keel can make the test fail
      do
        local box = Box3F()
        box:setExtents(origSpawnAABB:getExtents() * Point3F(0.75, 0.75, 0.75))
        box:setCenter(origSpawnAABB:getCenter())
        be:getPlayerVehicle(0):setSpawnLocalAABB(box)
      end

      if camera == nil then camera = core_camera.getActiveCamName(0) end
      core_camera.setByName(0, "onboard.rider", true)
      stopTimer = 0
      if not state.bus_kneel then
        guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.kneel"})
      elseif not state.bus_dooropen then
        guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.open"})
      end
    elseif stopTimer < timeToWaitAtStop then
      if camera == nil then camera = core_camera.getActiveCamName(0) end
      core_camera.setByName(0, "external", true)
      guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.wait", context = {time=tostring(timeToWaitAtStop - stopTimer)}})  
      stopTimer = stopTimer + 1
    elseif (state.bus_dooropen or state.bus_kneel) and busConfig.strictStop then
      core_camera.setByName(0, "onboard.rider", true)
      if state.bus_dooropen then
        guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.close"})
      elseif state.bus_kneel then
        guihooks.trigger('ScenarioRealtimeDisplay', {msg = "scenarios.busRoutes.raise"})      
      end
    else
      if camera ~= nil then core_camera.setByName(0, camera, true) end
      camera = nil
      stopComplete = true
      monitorMarker = false
      local cur =1
      if currentLine.tasklist then
        for i=1, #currentLine.tasklist, 1 do
          if currentLine.tasklist[i][1] == state.triggerName then cur=i; break end
        end
      end
      if currentLine.tasklist and cur == #currentLine.tasklist then success("scenarios.busRoutes.success");return end
      guihooks.trigger('ScenarioRealtimeDisplay', { msg = 'scenarios.busRoutes.proceed'})
      -- if busConfig.strictStop then
        if not tableContains(passedWp, state.triggerName) then
          table.insert( passedWp, state.triggerName )
        end
      -- end  
      for _,m in ipairs(markers) do
        m:setField('instanceColor', 0, '0 1 0 1')
      end

      -- next stop
      local cur = 1
      if currentLine.tasklist then
        for i=1, #currentLine.tasklist, 1 do
          if currentLine.tasklist[i][1] == nextStop[1] then cur=i; break end
        end
        if cur < #currentLine.tasklist then 
          nextStop = currentLine.tasklist[cur+1]
        else
          nextStop = nil
        end
        -- log("E", logTag, "onBeamNGTrigger  nextStop '"..dumps(nextStop).."'   cur ='"..dumps(cur).."'")
      end

    end
  end
  if state.event == "onApproachStop" then
    if nextStop then
      moveBusMarkers()
      -- monitorMarker = true
      setpointAlphaMarker = 1
    end
  elseif state.event == "onDepartedStop" then
    if origSpawnAABB then be:getPlayerVehicle(0):setSpawnLocalAABB(origSpawnAABB) end
  end
end

local function onScenarioLoaded(scenario)
  markers = {}
  if scenario.busdriver.simulatePassengers == true then
    -- getting current vehicle
    local playerVehicle = be:getPlayerVehicle(0)
    local configPath = playerVehicle:getField('partConfig', '0')
    -- reading in config file so we can add seat ballast
    local vehicleConfig = readJsonFile(configPath)
    vehicleConfig.parts.citybus_seats_ballast = "citybus_seats_ballast"
    -- applying new config to vehicle
    playerVehicle:queueLuaCommand("partmgmt.setConfig(".. serialize(vehicleConfig) ..")")
  end
end

local function onExtensionUnloaded()
  core_groundMarkers.setFocus(nil)

  --we freeze in the reset(), we need to unfreeze manually
  local playerVehicle = be:getObject(0)
  if playerVehicle then playerVehicle:queueLuaCommand('controller.setFreeze(0)') end
end

local function requestState()
  local tmp = currentLine
  local bsList = {}
  local cur = 1
  if nextStop then
    for i=1, #currentLine.tasklist, 1 do
      if currentLine.tasklist[i][1] == nextStop[1] then cur=i; break end
    end
  end
  for i=cur, #currentLine.tasklist, 1 do table.insert(bsList, currentLine.tasklist[i]) end
  tmp.tasklist = bsList
  guihooks.trigger('BusDisplayUpdate', tmp)
end

M.onBusUpdate = onBusUpdate
M.onPreRender = onPreRender
M.onVehicleSpawned = onVehicleSpawned
M.onRaceStart = onRaceStart
M.onBeamNGTrigger = onBeamNGTrigger
M.onRaceResult = onRaceResult
M.onExtensionUnloaded = onExtensionUnloaded
M.fail=fail
M.onScenarioRestarted = onScenarioRestarted
M.onScenarioLoaded = onScenarioLoaded
M.enabledLineDebug = false
M.requestState = requestState

--M.onVehicleStoppedMoving = onVehicleStoppedMoving
return M