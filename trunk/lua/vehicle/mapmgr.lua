-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local graphpath = require('graphpath')
local quadtree = require('quadtree')

local string_find = string.find
local string_sub = string.sub
local strformat = string.format
local max = math.max

local M = {}

M.map = nil
M.objects = {}
M.objectCollisionIds = {}

local serTmp = {}
local gp
local qt
local maxRadius

local function getPath(source, target, dirMult)
  if gp == nil then return {} end
  return gp:getPath(source, target, dirMult)
end

local function spanMap(source, nodeBehind, target, visitedEdges, dirMult)
  if gp == nil then return {} end
  return gp:spanMap(source, nodeBehind, target, visitedEdges, dirMult)
end

local function getPathAwayFrom(start, goal, mePos, stayAwayPos, dirMult)
  if gp == nil then return {} end
  return gp:getPathAwayFrom(start, goal, mePos, stayAwayPos, dirMult)
end

local function getFleePath(source, ai, player, dirMult)
  if gp == nil then return {} end
  return gp:getFleePath(source, ai, player, dirMult)
end

local function getRandomPath(nodeAhead, nodeBehind, dirMult)
  if gp == nil then return {} end
  return gp:getRandomPath(nodeAhead, nodeBehind, dirMult)
end

local function getSCC(node)
  if gp == nil then return {} end
  return gp:scc(node)
end

local function setMap(_map)
  M.map = _map
  if not M.map or next(M.map) == nil then return end
  M.mapLinks = {} -- TODO: this seems to be useless?

  local nodeDrivabilities = {}
  local mapNodes = M.map.nodes

  -- build the graph and the tree
  maxRadius = 4 -- case there are no nodes in the map i.e. next(map.nodes) == nil avoids infinite loop in findClosestRoad()
  gp = graphpath.newGraphpath()
  for k, n in pairs(mapNodes) do
    nodeDrivabilities[k] = obj:getTerrainDrivability(n.pos:toFloat3(), n.radius)
  end

  qt = quadtree.newQuadtree()
  for nid, n in pairs(mapNodes) do
    local radius = n.radius
    maxRadius = max(maxRadius, radius)
    local nPos = n.pos
    local nidDrivability = nodeDrivabilities[nid]
    gp:setPointPosition(nid, vec3(nPos))
    for lid, data in pairs(n.links) do
      local lPos = mapNodes[lid].pos
      local edgeDrivability = (nodeDrivabilities[lid] + nidDrivability) * 0.5 * data.drivability
      if data.oneWay then
        local inNode = data.inNode
        local outNode = inNode == nid and lid or nid
        gp:uniEdge(inNode, outNode, nPos:distance(lPos)/(edgeDrivability + 1e-30), data.drivability)
      else
        gp:bidiEdge(nid, lid, nPos:distance(lPos)/(edgeDrivability + 1e-30), data.drivability)
      end
      qt:preLoad(nid..'\0'..lid, quadtree.lineBBox(nPos.x, nPos.y, lPos.x, lPos.y, radius)) -- TODO: shouldn't the radius here be the max between the two?
    end
  end
  qt:build(5)
  qt:compress()
end

local function requestMap()
  obj:queueGameEngineLua("map.request("..tostring(objectId)..')')
end

M.sendTracking = nop
local function sendTracking()
  local objCols = M.objectCollisionIds
  table.clear(objCols)
  obj:getObjectCollisionIds(objCols)

  local colsStr
  local objColsCount = #objCols
  if objColsCount > 0 then
    table.clear(serTmp)
    for i = 1, objColsCount do
      serTmp[i] = strformat('[%s]=1', objCols[i])
    end
    colsStr = strformat('{%s}', table.concat(serTmp, ','))
  else
    colsStr = "{}"
  end

  obj:queueGameEngineLua(strformat('map.objectData(%s,%s,%s,%s,%s)', objectId, tostring(playerInfo.anyPlayerSeated),
      vec3toString(obj:getVelocity()), math.floor(beamstate.damage), colsStr))
end

local function enableTracking(name)
  obj:queueGameEngineLua(strformat('map.setNameForId(%s, %s)', name and '"'..name..'"' or objectId, objectId))
  M.sendTracking = sendTracking
end

local function disableTracking()
  if not playerInfo.anyPlayerSeated then
    M.sendTracking = nop
  end
end

local function findClosestRoad(position)
  --log('A','mapmgr', 'findClosestRoad called with '..position.x..','..position.y..','..position.z)
  local mapNodes = M.map.nodes
  local bestRoad1 = nil
  local bestRoad2 = nil
  local bestDist = math.huge
  local radius = maxRadius
  repeat
    for item_id in qt:query(quadtree.pointBBox(position.x, position.y, radius)) do
      local i = string_find(item_id, '\0')
      local n1id = string_sub(item_id, 1, i-1)
      local n2id = string_sub(item_id, i+1, #item_id)
      local curDist = position:squaredDistanceToLineSegment(mapNodes[n1id].pos, mapNodes[n2id].pos)
      if curDist < bestDist then
        bestDist = curDist
        bestRoad1 = n1id
        bestRoad2 = n2id
      end
    end
    radius = radius * 2
  until bestRoad1 or radius > 200
  return bestRoad1, bestRoad2, math.sqrt(bestDist)
end

local function reset()
  M.objects = {}

  -- if M.map ~= nil then
  --     M.map = nil
  --     gp = nil
  --     mapRequestCounter = 4 -- request a new map
  --     M.updateGFX = updateGFX
  -- end
end

local function init()
  if wheels.wheelCount > 0 or (v.data.general and v.data.general.enableTracking) then
    enableTracking()
  end
end

local function objectData(objectsData)
  M.objects = objectsData
end

M.findClosestRoad = findClosestRoad
M.objectData = objectData
M.init = init
M.reset = reset
M.getPath = getPath
M.spanMap = spanMap
M.getPathAwayFrom = getPathAwayFrom
M.getFleePath = getFleePath
M.getRandomPath = getRandomPath
M.getSCC = getSCC
M.requestMap = requestMap
M.setMap = setMap
M.enableTracking = enableTracking
M.disableTracking = disableTracking
return M