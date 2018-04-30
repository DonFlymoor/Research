local M  = {}
local logTag = 'spawn.lua'

local function spawnVehicle(jbeam, configuration, pos, rot, color, color2, color3)
  local veh = createObject("BeamNGVehicle")
  local spawnDatablock = String("default_vehicle")
  if not veh then
    log('E', logTag, 'Failed to create vehicle')
    return
  end

  local dataBlock = scenetree.findObject(spawnDatablock:c_str())

  if not datablock then
    veh.dataBlock = dataBlock
  else
    log('E', logTag, 'Failed to find dataBlock')
    return
  end

  local name = "clone"
  local i = 0
  while scenetree.findObject(name) do
    name = "clone" .. tostring(i)
    i = i + 1
  end

  veh:registerObject(name)

  veh.JBeam = jbeam
  veh.partConfig = configuration

  if color then
    veh.color = color:asLinear4F()
  end

  if color2 then
    veh.colorPalette0 = color2:asLinear4F()
  end

  if color3 then
    veh.colorPalette1 = color3:asLinear4F()
  end

  veh.licenseText = TorqueScript.getVar("$beamngVehicleLicenseName")
  rot = rot * quat(0,0,1,0) -- rotate 180 degrees
  veh:spawnObjectWithPosRot(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)

  local missionGroup = scenetree.MissionGroup
  if not missionGroup then
    log('E', logTag, 'MissionGroup does not exist')
    return
  end
  missionGroup:addObject(veh.obj)
  veh:autoplace()
end
--[[
pickSpawnPoint s responsible for finding a valid spawn point for a player and camera
@param spawnName string represent player or camera spawn point
]]
local function pickSpawnPoint(spawnName)
  local playerSP,spawnPointName
  local defaultSpawnPoint = setSpawnpoint.loadDefaultSpawnpoint()
  local spawnDefaultGroups = {"CameraSpawnPoints", "PlayerSpawnPoints", "PlayerDropPoints"}
  if defaultSpawnPoint then
    local spawnPoint = scenetree.findObject(defaultSpawnPoint)
    if spawnPoint then
      return spawnPoint
    else
      log('W', logTag, 'No SpawnPointName in mission file vehicle spawn in the default position')
    end
  end
  --Walk through the groups until we find a valid object
  for i,v in pairs(spawnDefaultGroups) do
    if scenetree.findObject(spawnDefaultGroups[i]) then
      local spawngroupPoint = scenetree.findObject(spawnDefaultGroups[i]):getRandom()
      if not spawngroupPoint then
        break
      end
      local sgPpointID = scenetree.findObjectById(spawngroupPoint:getID())
      if not sgPpointID then
        break
      end
      return sgPpointID
    end
  end

  --[[ ensuring backward compability with mods
  ]]
  local dps = scenetree.findObject("DefaultPlayerSpawnSphere")
  if dps then
    return scenetree.findObjectById(dps.obj:getID())
  end

  --[[Didn't find a spawn point by looking for the groups so let's return the
   "default" SpawnSphere First create it if it doesn't already exist
  ]]
  playerSP = createObject('SpawnSphere')
  if not playerSP then
    log('E', logTag, 'could not create playerSP')
    return
  end
  playerSP.dataBlock = scenetree.findObject('SpawnSphereMarker')
  if spawnName == "player" then
    playerSP.spawnClass = String("BeamNGVehicle")
    playerSP.spawnDatablock = String("default_vehicle")
    spawnPointName = "DefaultPlayerSpawnSphere"
    playerSP:registerObject(spawnPointName)
  elseif spawnName == 'camera' then
    playerSP.spawnClass = String("Camera")
    playerSP.spawnDatablock = String("Observer")
    spawnPointName = "DefaultCameraSpawnSphere"
    playerSP:registerObject(spawnPointName)
  end
  local missionCleanup = scenetree.MissionCleanup
  if not missionCleanup then
    log('E', logTag, 'MissionCleanup does not exist')
    return
  end
  --[[ Add it to the MissionCleanup group so that it doesn't get saved
    to the Mission (and gets cleaned up of course)
  ]]
  missionCleanup:addObject(playerSP.obj)
  return playerSP
end

--[[
spawnCamera is responsible for spawning a camera for a client
]]
local function spawnCamera()
  local gameConn = scenetree.findObject("Game")
  if gameConn then
  -- Set the control object to the default camera
    if not gameConn.camera then
      local cam = createObject('Camera')
      cam.dataBlock = scenetree.findObject("Observer")
      local res = cam:registerObject('myCamera')
      gameConn.camera = cam
    end
    --If we have a camera then set up some properties
    if gameConn.camera then
      local cameraID = gameConn.camera
      local camera = scenetree.findObjectById(cameraID)
      local missionCleanup = scenetree.MissionCleanup
      if not missionCleanup then
        log('E', logTag, 'missionCleanup does not exist')
        return
      end
      missionCleanup:addObject(camera.obj)
      gameConn.setCameraHandler(gameConn.obj, camera.obj)
      local csp = pickSpawnPoint('camera')
      if csp  then
        camera:setTransform(csp:getTransform())
      else
        camera:setTransform(csp)
      end
    end
  elseif not gameConn then
    log('E', logTag, 'gameConnection not found')
  end
end

--[[
spawnPlayer is responsible for spawning a player for a client
]]
local function spawnPlayer()
  local spawnClass, spawnDatablock,spawnProperties,spawnScript,player
  local spawnPoint = pickSpawnPoint('player')
  local preventPlayerSpawning = TorqueScript.getVar("$preventPlayerSpawning")
  if TorqueScript.getVar("$preventPlayerSpawning") ~= "" then
    log('D',logTag,'not spawning player upon request')
    return
  end
  local gameConn = scenetree.findObject("Game")
  if gameConn.player and scenetree.findObjectById(gameConn.player) then
    log('E', logTag, 'Attempting to create a player for a client that already has one!')
  end
  if spawnPoint then
    spawnClass      = String("BeamNGVehicle")
    spawnDatablock  = String("default_vehicle")
    if spawnPoint.spawnClass:c_str() ~=""  then
      spawnClass = spawnPoint.spawnClass
    end
    --[[
    This may seem redundant given the above but it allows
    the SpawnSphere to override the datablock without
    overriding the default player class
    ]]
    if spawnPoint.spawnDatablock and scenetree.findObject(spawnPoint.spawnDatablock:c_str()) then
      spawnDatablock = spawnPoint.spawnDatablock
    end
    player = createObject(spawnClass:c_str())
    if not player then
      player = createObject("BeamNGVehicle")
    end
    player.dataBlock = scenetree.findObject(spawnDatablock:c_str())
    player.spawnScript = spawnPoint.spawnScript:c_str()
    player.spawnProperties = spawnPoint.spawnProperties:c_str()
    player:registerObject("thePlayer")
    if player then
      if TorqueScript.getVar("$beamngVehicle") == "" then
        TorqueScript.setVar("$beamngVehicle","etk800")
      end
      player.JBeam = TorqueScript.getVar("$beamngVehicle")
      player.autoplaceOnSpawn = spawnPoint.autoplaceOnSpawn       -- place on the ground without dropping the vehicle - if requested by the spawn point
      player.partConfig = TorqueScript.getVar("$beamngVehicleConfig")
      if  TorqueScript.getVar("$beamngVehicleColor") ~= "" then
      local tempColor=ColorF( 1, 1, 1, 1)     --player.color is point4f object
        tempColor:setFromString( TorqueScript.getVar("$beamngVehicleColor"))
        player.color = tempColor:asLinear4F()
      end
      player.licenseText = TorqueScript.getVar("$beamngVehicleLicenseName")
      player:spawnObjectWithTransform(spawnPoint:getTransform())
    else
      if spawnDatablock then
        TorqueScript.call( 'MessageBoxOK', "Spawn Player Failed","Unable to create a player with class " .. spawnClass:c_str() ..
        " and datablock " .. spawnDatablock:c_str() .. ".\n\nStarting as an Observer instead."..tostring(gameConn)
        .. ".spawnCamera();")
      else
        TorqueScript.call( 'MessageBoxOK',"Spawn Player Failed","Unable to create a player with class ".. spawnClass:c_str() ..".\n\nStarting as an Observer instead.", tostring(gameConn)..".spawnCamera()")
      end
    end
  --[[else
    --Create a default player
    player = createObject("BeamNGVehicle")
    player.dataBlock = scenetree.findObject("default_vehicle")
    player:registerObject("thePlayer")
    player:setTransform(spawnPoint)   --]]
  end
  -- If we didn't actually create a player object then bail
  if not player then
    -- Make sure we at least have a camera
    spawnCamera()
    return
  end
  -- Update the default camera to start with the player
  if gameConn.camera then
    local camera = scenetree.findObjectById(gameConn.camera)
    if camera then
      if spawnClass== "Player" then
        camera:setTransform(player:getEyeTransform())
      else
        camera:setTransform(player:getTransform())
      end
    else
      log('E', logTag, 'gameConn camera not in scenetree')
    end
  end
  --[[Add the player object to MissionCleanup so that it
  won't get saved into the level files and will get
  cleaned up properly--]]
  local missionCleanup = scenetree.MissionCleanup
  if not missionCleanup then
    log('E', logTag, 'missionCleanup does not exist')
    return
  end
  missionCleanup:addObject(player.obj)
  local missionGroup = scenetree.MissionGroup
  if not missionGroup then
    log('E', logTag, 'MissionGroup does not exist')
    return
  end
  missionGroup:addObject(player.obj)
  player.canSave = false
  gameConn.player = player
  gameConn:setCameraHandler(player.obj)
end

M.spawnVehicle = spawnVehicle
M.spawnCamera = spawnCamera
M.spawnPlayer =spawnPlayer
return M