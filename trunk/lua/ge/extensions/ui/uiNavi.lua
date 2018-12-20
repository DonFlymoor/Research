-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local lastObjPosition
local objSpeed_smooth = newExponentialSmoothing(60)

local function findClosestRoad (x, y, z)
  return map.findClosestRoad(vec3(x, y, z))
end

local function getSpawnpoints ()
  -- spawn points
  -- TODO: make this available if the level is not loaded yet, so we can use the spawnpoint positions in the levelselector
  local spawnpoints = scenetree.findClassObjects("SpawnSphere")
  local spawnPointAdditionalInfo = {}
  local res = {}

  if FS:fileExists(getMissionFilename()) then
    info = jsonReadFile(getMissionFilename())
    if info.spawnPoints then
      for _, point in pairs(info.spawnPoints) do
        spawnPointAdditionalInfo[point.objectname] = point
      end
    end
  end

  for _, pid in pairs(spawnpoints) do
    local o = scenetree.findObject(pid)
    if o then
      local tmp = {}
      if spawnPointAdditionalInfo[o.name] then
        tmp = spawnPointAdditionalInfo[o.name]
      end
      tmp.pos = vec3(o:getPosition()):toTable()
      table.insert(res, tmp)
    end
  end

  return res
end

local function getPointsOfInterest ()
  -- points of interest
  local poi_set = scenetree.PointOfInterestSet
  local pois = {}
  if poi_set then
  local poios = poi_set:getObjects() or {}
  for _, pid in pairs(poios) do
    local o = scenetree.findObject(pid)
    if o then
      table.insert(pois, {name = o.name, pos = vec3(o:getPosition()):toTable(), desc = o.desc, title = o.title, type = o.type})
    end
  end
  return pois
 end
end

local function requestPoi ()
  guihooks.trigger('MapPointsOfInterest', getPointsOfInterest())
end

local missions = {
  -- {
  --   pos = {569.385, 175.0835, 0},
  --   desc =  "campaigns.utah.chapter_1.cliffjump.title",
  --   title =  "campaigns.utah.chapter_1.cliffjump.title",
  --   state =  "ready",
  --   new = true,
  --   objectives =  {
  --     bla1 =  true,
  --     bla2 =  false,
  --     bla3 =  false
  --   },
  --   type =  "delivery"
  -- },
  -- {
  --   pos = {-10.2638, 509, 0},
  --   desc =  "campaigns.training.training.training_acceleration_braking.description",
  --   title =  "campaigns.training.training.training_acceleration_braking.title",
  --   state =  "ready",
  --   new = false,
  --   objectives =  {
  --     bla1 =  true,
  --     bla2 =  false,
  --     bla3 =  false
  --   },
  --   type =  "training"
  -- },
  -- {
  --   pos = {136.2955, 488.8725, 0},
  --   desc =  "campaigns.utah.chapter_1.highway.title",
  --   title =  "campaigns.utah.chapter_1.highway.title",
  --   state =  "failed",
  --   new = false,
  --   objectives =  {
  --     bla1 =  true,
  --     bla2 =  false,
  --     bla3 =  false
  --   },
  --   type =  "race"
  -- },
  -- {
  --   pos = {215.064, 427.08, 0},
  --   desc =  "campaigns.training.training.training_acceleration_braking.description",
  --   title =  "campaigns.training.training.training_acceleration_braking.title",
  --   state =  "bronze",
  --   new = false,
  --   objectives =  {
  --     bla1 =  true,
  --     bla2 =  false,
  --     bla3 =  false
  --   },
  --   type =  "training"
  -- }
}

local function getMissions ()
  return missions
end

local function sendMissions ()
  guihooks.trigger('MapMissions', getMissions())
end

local function setMissions (m)
  missions = m
  sendMissions()
end

local lastPlayerPosition
local destination = nil
local destinationPos = nil

-- // WARNING: multiseat might result in several active players (?)
-- // in this case we will currently only render the path for the last player.
-- // in the future we might want to support rendering several paths
local function route_start (wp, pos)
  core_groundMarkers.setFocus(wp)
  destination = wp
  destinationPos = vec3(pos[1], pos[2], pos[3])
end

local function route_end ()
  destination = nil
  destinationPos = nil
  core_groundMarkers.setFocus(nil)
  guihooks.trigger('RouteUpdate', {})
  guihooks.trigger('RouteEnded')
end

-- // TODO: figure out good distance
local function route_update ()
  local route = map.getPath(findClosestRoad(lastPlayerPosition), destination)
  core_groundMarkers.setFocus(destination)
  guihooks.trigger('RouteUpdate', route)
  if lastPlayerPosition:distance(destinationPos) < 50 then
    guihooks.trigger('RouteReachedDestination')
    route_end()
  end
end

local function route_inprogress ()
  return destination ~= nil
end

local function planRoute (posX, posY)
  local x = vec3(posX[1], posX[2], posX[3])
  local y = vec3(posY[1], posY[2], posY[3])
  local route = map.getPath(findClosestRoad(x), findClosestRoad(y))
  guihooks.trigger('RoutePlanned', route)
end

local function getBusStops ()
  local stops = scenetree.findClassObjects("BeamNGTrigger")
  local interm = {}
  local res = {}

  for _, pid in pairs(stops) do
    local o = scenetree.findObject(pid)
    if o and o.type == 'busstop' then
      table.insert(interm,  vec3(o:getPosition()))
    end
  end

  -- quick and dirty merge of bus stops that are on different sides of the road
  local foundCoresponding = {}
  for id, vec in pairs(interm) do
    for id2, vec2 in pairs(interm) do
      if id < id2 and vec:distance(vec2) < 70 then
        local tmp = {}
        local merged = vec - (vec - vec2) / 2
        foundCoresponding[id] = true
        foundCoresponding[id2] = true
        tmp.pos = merged:toTable()
        table.insert(res, tmp)
      end
    end
    -- sometimes there is only one bus station
    if not foundCoresponding[id] then
      table.insert(res, {pos = vec:toTable()})
    end
  end

  -- for id, vec in pairs(interm) do
  --   table.insert(res, {pos = vec:toTable()})
  -- end

  return res
end

local function onUpdate()
  if not scenetree.Game then return end

  local cameraHandler = scenetree.Game:getCameraHandler()
  if not cameraHandler then return end

  local objs = {
    controlID = cameraHandler:getID(),
  }

  local mapObjects = deepcopy(map.objects)
  -- convert vec3 to JS table
  for k, v in pairs(mapObjects) do
    v.pos = v.pos:toTable()
    v.vel = v.vel:toTable()
    local dir = v.dirVec:normalized()
    v.rot = math.deg(math.atan2(dir:dot(vec3(1,0,0)), dir:dot(vec3(0,-1,0))))
    v.dirVec = v.dirVec:toTable()
    v.speed = vec3(v.vel):length()
    v.type = 'BeamNGVehicle' -- vehicle
  end

  if not mapObjects[objs.controlID] then
    local sobj = scenetree[objs.controlID]

    local matrix = sobj:getTransform()
    local forVec = vec3(matrix:getColumn(1))
    local heading = math.atan2(forVec.x, -forVec.y) * 180 / math.pi

    local pos = vec3(sobj:getPosition())
    local vel = vec3(0,0,0)
    if lastObjPosition then
      vel = (lastObjPosition - pos)
    end
    lastObjPosition = pos

    mapObjects[objs.controlID] = {
      pos = pos:toTable(),
      vel = vel:toTable(),
      speed = objSpeed_smooth:get(vel:length()),
      rot = heading,
      dirvec = forVec:toTable(),
      type = sobj.className,
    }

  end

  lastPlayerPosition = vec3(mapObjects[objs.controlID].pos)

  if route_inprogress() then
    route_update()
  end

  objs.objects = mapObjects
  guihooks.triggerStream('NavigationMapUpdate', objs)
end

local function requestUIDashboardMap()
  local m = map.getMap()
  local tmpmap = deepcopy(m)
  for _, v in pairs(tmpmap.nodes) do
    v.pos = {v.pos.x, v.pos.y, v.pos.z}
  end

  local d = {}
  d.nodes = tmpmap.nodes

  local terr = getObjectByClass("TerrainBlock")
  if terr then
    d.terrainOffset = vec3(terr:getPosition()):toTable()
    local blockSize = terr:getWorldBlockSize()
    d.terrainSize = vec3(blockSize, blockSize, terr.maxHeight):toTable()
    d.minimapImage = terr.minimapImage:c_str() -- minimapImage is a BString
    d.squareSize = terr:getSquareSize()
  end

  local tmp = getPointsOfInterest()
  if tmp then d.poi = tmp end

  guihooks.trigger('NavigationMap', d)
end

local function requestVehicleDashboardMap(dashboard)
  local m = map.getMap()
  local tmpmap = deepcopy(m)
  for _, v in pairs(tmpmap.nodes) do
    v.pos = {v.pos.x, v.pos.y, v.pos.z}
  end
  local veh = be:getPlayerVehicle(0)
  if veh then
    veh:queueJSUITexture(dashboard, 'map.setData('..jsonEncode(tmpmap.nodes)..')')
  end
end

local function onVehicleSwitched(oid, nid)
  -- we need the tracking information for the ui navigation, so enable it
  --if oid ~= -1 then
  --  local veh = scenetree.findObject(oid)
  --  if veh then
  --    veh:queueLuaCommand("mapmgr.enableTracking()")
  --  end
  --end
  --if nid ~= -1 then
   -- local veh = scenetree.findObject(nid)
   -- if veh then
      --veh:queueLuaCommand("mapmgr.enableTracking()")
   -- end
  --end
end

local function onExtensionLoaded ()
  guihooks.trigger('RouteUpdate', {})
end

-- public interface
M.onUpdate = onUpdate
M.onVehicleSwitched = onVehicleSwitched


M.requestUIDashboardMap = requestUIDashboardMap
M.requestVehicleDashboardMap = requestVehicleDashboardMap

M.findClosestRoad = findClosestRoad
M.route_start = route_start
M.route_end = route_end
M.route_requestStatus = route_update

-- dev things
M.planRoute = planRoute
M.getBusStops = getBusStops

M.getSpawnpoints = getSpawnpoints
M.getPointsOfInterest = getPointsOfInterest
M.requestMissions = sendMissions
M.getMissions = getMissions
M.setMissions = setMissions
M.requestPoi = requestPoi

M.onExtensionLoaded = onExtensionLoaded

return M


