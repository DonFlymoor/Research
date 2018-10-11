-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local endWP = nil
local endPos = nil
local lastControlPoints = {{}, {}}
local debugPath = false
local fadeStart
local fadeEnd
local stepDistance
local disableVeh
local path = {{}}
local decals = {}
local pathSize = 0
local color = {}
local previousWp
local dist = 0

local function setFocus(wp, step, fStart, fEnd, _endPos, _disableVeh, _color)
  --print(dumps(wp), step, fStart, fEnd, _endPos, _disableVeh)
  endWP = nil
  if wp then endWP = (type(wp) == 'table' and wp) or {wp} end
  stepDistance = step or 8
  fadeStart = fStart or 100
  fadeEnd = fEnd or 150
  endPos = _endPos
  disableVeh = _disableVeh
  color = _color or {0.2, 0.53, 1}
end

local function getPathLength()
  dist = 0
  previousWp = {}
  for k, p in pairs(path) do
    if previousWp.pos ~= nil and p.pos ~= nil then
      local newDist = (p.pos - previousWp.pos):length()
      if newDist == newDist then
        dist = dist + newDist
      end
    end
    previousWp = p
  end
  return dist
end

local function getPathPositionDirection(dist, lastNodeData)
  local walkDist = lastNodeData.dist
  for i = lastNodeData.i, (lastNodeData.pathSize - 1) do
    local a = lastNodeData.path[i].pos
    local b = lastNodeData.path[i + 1].pos
    local nodeDist = (b-a):length()
    if walkDist + nodeDist >= dist then
      local factor = (dist - walkDist) / nodeDist
      local position = (a * (1 - factor)) + (b * factor)
      local normal = (b-a):normalized()
      lastNodeData.i = i
      lastNodeData.dist = walkDist
      return position, normal
    else
      walkDist = walkDist + nodeDist
    end
  end
  lastNodeData.i = lastNodeData.pathSize
  lastNodeData.dist = walkDist
  return nil
end

local function getFrontNode(vPos, vFVec, wpNameA, wpNameB)
  local mapData = map.getMap()
  local a = (vec3(mapData.nodes[wpNameA].pos) - vPos):normalized()
  local b = (vec3(mapData.nodes[wpNameB].pos) - vPos):normalized()
  local dotPosA = vFVec:dot(a)
  local dotPosB = vFVec:dot(b)
  if dotPosA < dotPosB then
    return wpNameB
  else
    return wpNameA
  end
end

local function getNewData()
  -- create decals
  local data = {
    texture = 'art/arrow_waypoint_1.dds',
    position = Point3F(0, 0, 0),
    forwardVec = Point3F(0, 0, 0),
    color = ColorF(color[1], color[2], color[3], 0 ),
    scale = Point3F(4, stepDistance, 1.5),
    fadeStart = fadeStart,
    fadeEnd = fadeEnd
  }
  return data
end

local function calculateAlpha(pos, start, dist)
  return math.min(dist, math.max(0, pos - start)) / dist
end

local function onPreRender(dt)
  --setFocus({ "busRoad_12", "busRoad_320" }, 10, 150, 200, vec3(118.884,46.4706,0.154408), nil)

  if not endWP then return end

  local pv = be:getPlayerVehicle(0)
  if not pv then return end

  local mapData = map.getMap()
  local vec3Pos = vec3(pv:getPosition())
  local first = nil
  local second = nil

  do
    local lastDistance = math.huge
    for i = 2, math.min(5, pathSize) do
      if path[i-1].wp and path[i].wp then
        local dist = vec3Pos:distanceToLineSegment(mapData.nodes[path[i-1].wp].pos, mapData.nodes[path[i].wp].pos)
        if dist > lastDistance then break end
        if dist < 10 then
          lastDistance = dist
          first = path[i-1].wp
          second = path[i].wp
        end
      end
    end
  end

  if not first then first, second = map.findClosestRoad(vec3Pos) end
  if not first or not second then return end

  local wp1 = getFrontNode(vec3Pos, -vec3(pv:getRefNodeMatrix():getColumn(1)):normalized(), first, second)
  local wp0 = (wp1 ~= first and first) or second

  if not disableVeh and not tableContains(endWP, wp1) then table.insert(endWP, 1, wp1) end
  if not disableVeh and not tableContains(endWP, wp0) then table.insert(endWP, 1, wp0) end

  path[1].wp = nil
  pathSize = 0
  local lastPair = {}
  for i, v in ipairs(endWP) do
    if i > 1 then
      if lastPair[1] == endWP[i-1] then endWP[i-1] = path[pathSize].wp end
      if lastPair[1] == endWP[i] then endWP[i] = path[pathSize].wp end
      local pair = {endWP[i-1], endWP[i]}
      local pathWp = map.getPath(pair[1], pair[2])
      for i, wpName in ipairs(pathWp) do
        pathSize = pathSize + 1
        local node = path[pathSize] or {}
        path[pathSize] = node
        node.wp = wpName
        node.pos = mapData.nodes[wpName].pos
      end
      if pathSize >= 2 then lastPair = {path[pathSize - 1].wp, path[pathSize].wp} end
    end
  end

  if endPos then
    if #path > 1 then
      local wp = path[pathSize].wp
      while path[pathSize].wp == wp do
        pathSize = pathSize - 1
      end
    end
    pathSize = pathSize + 1
    local node = path[pathSize] or {}
    path[pathSize] = node
    node.wp = nil
    node.pos = vec3(endPos.x, endPos.y, endPos.z)
  end

  if debugPath then
    debugDrawer:drawSphere(vec3(mapData.nodes[wp1].pos):toPoint3F(), 3, ColorF(1.0,1.0,1.0,1.0))
    debugDrawer:drawSphere(vec3(mapData.nodes[wp0].pos):toPoint3F(), 2, ColorF(1.0,1.0,1.0,1.0))
    for i, v in ipairs(path) do
      debugDrawer:drawSphere(vec3(v.pos):toPoint3F(), 2, ColorF(0.0,1.0,0.0,1.0))
    end
  end

  -- stabilize decals positions
  if lastControlPoints[1].wp == path[1].wp then
    path[1].pos = lastControlPoints[1].pos
  elseif lastControlPoints[2].wp == path[1].wp then
    path[1].pos = lastControlPoints[2].pos
  end

  -- move start pos close to vehicle
  local startDist = 0
  local vecDist = 0
  do
    local dot = (vec3Pos - path[1].pos):normalized():dot((path[2].pos - path[1].pos):normalized())
    local dist = math.max(0, vec3Pos:distance(path[1].pos))
    vecDist = dist * dot
    startDist = math.floor(vecDist / stepDistance) * stepDistance
  end

  do
    local dist = startDist
    local lastNodeData = { i = 1, dist = 0, path = path, pathSize = pathSize }
    lastControlPoints[1].pos = getPathPositionDirection(dist, lastNodeData)
    lastControlPoints[1].wp = path[lastNodeData.i].wp

    lastControlPoints[2].wp = nil
    if pathSize >= lastNodeData.i+1 then
      dist = dist + lastControlPoints[1].pos:distance(path[lastNodeData.i+1].pos)
      dist = math.ceil(dist / stepDistance) * stepDistance
      local pos = getPathPositionDirection(dist, lastNodeData)
      lastControlPoints[2].pos = pos
      lastControlPoints[2].wp = (pos and path[lastNodeData.i].wp) or nil
    end
  end

  local decalsSize = 0
  local lastNodeData = { i = 1, dist = 0, path = path, pathSize = pathSize }
  for i = startDist, fadeEnd, stepDistance do
    local pos, normal = getPathPositionDirection(i, lastNodeData)
    local alphaNear = calculateAlpha(i - vecDist, 10, 30 - 10)
    local alphaFar = 1 - calculateAlpha(i - vecDist, fadeStart, (fadeEnd - fadeStart))
    if not pos or alphaFar < 0.01 then break end
    decalsSize = decalsSize + 1
    local data = decals[decalsSize] or getNewData()
    decals[decalsSize] = data
    data.position:set(pos.x, pos.y, pos.z)
    data.forwardVec:set(normal.x, normal.y, normal.z)
    data.color.a = math.min(alphaNear, alphaFar)
  end

  Engine.Render.DynamicDecalMgr.addDecals('art/arrow_waypoint_1.dds', decals, decalsSize)
end

local function onClientEndMission()
  --cleanup on level exit
  setFocus(nil)

  -- allow gc of big tables
  path = {{}}
  pathSize = 0
  decals = {}
end
-- public interface
M.onPreRender = onPreRender
M.setFocus = setFocus
M.getPathLength = getPathLength
M.onClientEndMission = onClientEndMission
return M
