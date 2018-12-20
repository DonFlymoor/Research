-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
local center = {}
local scale = 1
local r_major = 6378137.0

local useSingleMat = "road_asphalt_2lane"

local highwayInfo = {
-------- Main Roads   --------
  motorway = {
    defaultLanes = 2,
    defaultLaneWidth = 4,
    material = "road_asphalt_2lane"
  },
  trunk = {
    defaultLanes = 2,
    defaultLaneWidth = 3.5,
    material = "road_asphalt_2lane"
  },
  primary = {
    defaultLanes = 2,
    defaultLaneWidth = 3.15,
    material = "road_asphalt_2lane"
  },
  secondary = {
    defaultLanes = 2,
    defaultLaneWidth = 3.1,
    material = "road_asphalt_2lane"
  },
  tertiary = {
    defaultLanes = 2,
    defaultLaneWidth = 3,
    material = "road_asphalt_2lane"
  },
  unclassified = {
    defaultLanes = 2,
    defaultLaneWidth = 3,
    material = "road_asphalt_2lane"
  },
  residential = {
    defaultLanes = 2,
    defaultLaneWidth = 3.2,
    material = "AsphaltRoad_lanes_broken"
  },
  service = {
    defaultLanes = 2,
    defaultLaneWidth = 3.2,
    material = "road_asphalt_2lane"
  },
-------- Pedestrian   --------
  pedestrian = {
    defaultLanes = 1,
    defaultLaneWidth = 3.15,
    material = "asphaltroad_laned_nolines"
  },
  track = {
    defaultLanes = 1,
    defaultLaneWidth = 3.15,
    material = "asphaltroad_laned_nolines"
  },
-------- Small Stuff  --------
  footway = {
    defaultLanes = 1,
    defaultLaneWidth = 2.5,
    material = "asphaltroad_laned_nolines"
  },
  path = {
    defaultLanes = 1,
    defaultLaneWidth = 1.5,
    material = "BNG_Road_Dirt"
  },
  cycleway = {
    defaultLanes = 2,
    defaultLaneWidth = 1.8,
    material = "road_asphalt_2lane"
  },
  living_street = {
    defaultLanes = 2,
    defaultLaneWidth = 3.2,
    material = "asphaltroad_laned_nolines"
  },
--------  Life Cycle  --------
  construction = {
    defaultLanes = 1,
    defaultLaneWidth = 3.5,
    material = "DefaultDecalRoadMaterial"
  },
--------  Default     --------
  default = {
    defaultLanes = 2,
    defaultLaneWidth = 2.5,
    material = "DefaultDecalRoadMaterial"
  }
}


local roads = {}
local nodes = {}

-- Thus function transforms Lat/Lon to X/Y coordinates.
local function degrees2meters(lon, lat)
  return
    scale * (r_major * math.rad(lon)),
    scale * (0 - r_major * math.log(math.tan(.5 * ((math.pi * .5)-math.rad(lat)))))
end



-- Processes the Data from OSM. Data is parsed from XML. Node list will be created, then a Road list
local function processData(code, status, data)
  guihooks.trigger("osmFinished");
  writeFile('osm.xml', data)
  --data = readFile('osm.xml')
  local root = require('libs/slaxml/slaxml'):dom(data).root

  nodes = {}
  log('I', "OSM", 'Parsing Nodes...')
  for _, n in ipairs(root.kids) do
    if n.type == 'element' and n.name == 'node' then
      local x, y = degrees2meters(
        tonumber(n.attr.lon) ,
        tonumber(n.attr.lat)
      )
      nodes[n.attr.id] = vec3(x-center.x, y - center.y, 0)
    end
  end
  log('I', "OSM", '#nodes: ' .. tableSize(nodes))

  log('I', "OSM", 'Parsing Roads...')
  roads = {}
  --local roadTypes = {}
  for _, n in ipairs(root.kids) do
    if n.type == 'element' and n.name == 'way' then
      local tags = {}
      local nodes = {}
      for _, n2 in ipairs(n.kids) do
        if n2.type == 'element' and n2.name == 'nd' then
          table.insert(nodes, n2.attr.ref)
        elseif n2.type == 'element' and n2.name == 'tag' then
          tags[n2.attr.k] = n2.attr.v
        end
      end
      if tags.highway  then
        if not M.canIgnoreRoad(tags.highway) then
          table.insert(roads, {
            id = n.attr.id,
            tags = tags,
            nodes = nodes,
          })
        end
        --if roadTypes[tags.highway] then roadTypes[tags.highway] = (roadTypes[tags.highway]+1) else roadTypes[tags.highway] =  1 end
      end
    end
  end
  log('I', "OSM", '#roads: ' .. tableSize(roads))

  M.createRoads()
end

-- Creates all the roads stored in the roads-list. If the road has a name tag, the DecalRoad will be named appropriately.
local function createRoads()
  TorqueScript.eval([[
        if(isObject(OSM_Roadgroup)) {
            OSM_Roadgroup.delete();
        }
        new SimGroup(OSM_Roadgroup) {
          position = "0 0 0";
          canSave = "0";
        };
        OSM_Roadgroup.clear();
        MissionGroup.add(OSM_Roadgroup);
        ]])
  log('I', "OSM", 'Creating Roads...')
  for _, road in ipairs(roads) do

    local name = road.tags.name
    if name == nil then
      name = "highway_"..road.id
    else
      name = string.gsub(name,' ','_')
      name = string.gsub(name,'([^%d%u%l])','_')
      name = "highway_"..road.id.."__"..name
    end
    TorqueScript.eval(M.makeRoadTS(name,road))
  end
  log('I', "OSM", 'Finished!')
end


-- Creates Torquescript to create a road.
local function makeRoadTS(name, road)
  local matInfo = M.getHighwayInfo(road.tags.highway)
  local roadTS = [[
      OSM_Roadgroup.add(new DecalRoad(]]..name..[[) {
      Material = "]]..matInfo.material..[[";
      textureLength = "5";
      breakAngle = "1";
      renderPriority = "10";
      zBias = "0";
      startEndFade = "0 0";
      position = "0 0 0";
      rotation = "1 0 0 0";
      scale = "1 1 1";
      canSave = "0";
      canSaveDynamicFields = "0";
      drivability = "-1";
      improvedSpline = "1";
      detail = ".25";
      smoothness = "0.01";
    ]]

  for _, nId in pairs(road.nodes) do
    local p = nodes[nId]
    local laneWidth = matInfo.defaultLaneWidth
    local lanes = road.tags.lanes or matInfo.defaultLanes
    local w = lanes * laneWidth + .2

    roadTS = roadTS..'Node="'..(p.x)..' '..(p.y)..' 0 '..w..'";'
  end
  roadTS = roadTS..'});  '
  return roadTS
end


-- Returns a map containing material, default lanes and lane width for a road type.
local function getHighwayInfo(tag)
  local ret
  local isLink = string.sub(tag,-string.len("_link"))=="_link"

  if isLink then
    tag = string.gsub(tag,"_link","")
  end
  ret = highwayInfo[tag] or highwayInfo["default"]

  if isLink then
    ret.defaultLanes = 1
  end

  if highwayInfo[tag] == nil and tag ~= nil and not isLink then
    -- unknown tag, and not a _link tag
    log('W', "OSM", "Unspecified highway tag in data: "..tag..". Using default values.")
  end

  ret.material = useSingleMat or ret.material
  return ret
end

-- These Roads types can be Ignored.
local function canIgnoreRoad( tag )
  return tag == 'corridor' or tag == 'elevator' or tag =='platform' or tag == 'steps'
end



-- Test function used to measure road lenght to pin down exact scaling factor
--[[
function getRoadLength(roadName)
  local road = scenetree.findObject(roadName)
  if road == nil then
    return 0
  end
  local len = 0
  local segCount = road:getNodeCount()
  if segCount > 0 then
    for i = 0, segCount-2 do

        local p1 = vec3(road:getNodePosition(i))
        local p2 = vec3(road:getNodePosition(i+1))
        local d = vec3(p1.x-p2.x, p1.y-p2.y, p1.z-p2.z)
        len = len + math.sqrt(d.x * d.x + d.y * d.y)
              dump(i)
      dump(len)
    end
  end
  return len
end
]]

-- Prepares downloading of map data, then downloads. Lat/Lon = Position, Width/Height = Size in Degrees
local function getGeoData(lon, lat, width, height)
  if #(scenetree.findClassObjects('TerrainBlock')) == 0 then
    log("E","OSM","Terrain is Missing! Create a TerrainBlock or load a level that has an existing Terrain.")
    return
  end

 if lat > 89.5 then
    lat = 89.5
    log('W', "OSM", "Latitude was outside of allowed scope (-89.5 < lat < 89.5), has been readjusted to "..lat)
  end
  if lat < -89.5 then
    lat = -89.5
    log('W', "OSM", "Latitude was outside of allowed scope (-89.5 < lat < 89.5), has been readjusted to "..lat)
  end

  width = width or .008
  height = height or .008

  local l = lon - width
  local b = lat - height
  local r = lon + width
  local t = lat + height

  scale = math.cos(math.rad(lat))

  center.lon = lon
  center.lat = lat
  center.x, center.y = degrees2meters(lon,lat)


  local lp,bp = degrees2meters(l,b)
  local rp,tp = degrees2meters(r,t)
  log('I', "OSM", "The area will cover about ".. math.abs(rp-lp) .." x " .. math.abs(tp-bp) .. " of ingame units.")
  local url = 'http://api.openstreetmap.org/api/0.6/map?bbox=' .. l .. ',' .. b .. ',' ..  r .. ',' .. t
  log('I', "OSM", "Downloading Map data. This might take a few seconds...")
  core_online.downloadData(url, processData)
end



local function test(city)
  city = city or 'work'

 local coords = {
    nyc = {
      lat = 40.7552,
      lon = -73.9822
    }, hb = {
      lat = 53.08386,
      lon = 8.82464
    }, work = {
      lat = 53.10779,
      lon = 8.84751
    }, domsheide = {
      lat = 53.073641,
      lon = 8.806299
    }, nuernburgring = {
      lat = 50.334111,
      lon = 6.942689
    }, test = {
      lat = 71.290471,
      lon = -156.788719
    }
  }
  local pos = coords[city]
  if pos == nil then pos = coords[work] end
  M.getGeoData(pos.lon, pos.lat)
end


M.test = test
M.onDrawDebug = onDrawDebug
M.createRoads = createRoads
M.canIgnoreRoad = canIgnoreRoad
M.makeRoadTS = makeRoadTS
M.getHighwayInfo = getHighwayInfo
M.loadMap = loadMap
M.getGeoData = getGeoData
return M
