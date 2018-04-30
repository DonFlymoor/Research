-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require('mathlib')
local graphpath = require('graphpath')
local quadtree = require('quadtree')

local M = {}

M.objects = {}
M.objectNames = {}
M.debugMode = ''
M.debugDrawDistance = 200
M.debugDrawDistanceLabels = 10

-- cache frequently used functions in upvalues
local min = math.min
local max = math.max
local abs = math.abs
local sqrt = math.sqrt
local tableInsert = table.insert
local stringMatch = string.match
local stringFind = string.find
local stringSub = string.sub

local mapFilename = ''
local displaceLimit = 0.1
local map = {nodes = {}}
local loadedMap = false
local objectsReset = true
local maxRadius = nil
local nodeSegTags = {}
local isEditorEnabled
local visualLog = {}
local gp = nil
local qt = nil
local delayedLoad = newSingleEventTimer()
local allManualWaypoints

local function visLog(type, pos, msg)
  tableInsert(visualLog, {type=type, pos=pos, msg=msg})
end

local function mergeSegTags(to, from)
  for s in pairs(map.nodes[from].segTags) do map.nodes[to].segTags[s] = 1 end
end

local function is2SegMergeValid(middleNode, d1, d2)
  if d1.oneWay == d2.oneWay then
    return (d1.oneWay == false) or (not (d1.inNode == d2.inNode or (d1.inNode ~= middleNode and d2.inNode ~= middleNode)))
  else
    return false
  end
end

local function is3SegMergeValid(middleNode, d1, d2, dchord)
  if is2SegMergeValid(middleNode, d1, d2) and (dchord.oneWay == d1.oneWay) then
    return (dchord.oneWay == false) or (d1.inNode == dchord.inNode or d2.inNode == dchord.inNode)
  else
    return false
  end
end

local function mergeNodes(n1id, n2id)
  local mapNodes = map.nodes
  if mapNodes[n2id].manual ~= nil then --> TODO: what if both are manual?
    n1id, n2id = n2id, n1id
  end

  local n1 = mapNodes[n1id]
  local n2 = mapNodes[n2id]
  n1.pos = (n1.pos + n2.pos) * 0.5
  n1.radius = (n1.radius + n2.radius) * 0.5

  for nid, d in pairs(n2.links) do
    --remap neighbors
    if nid ~= n1id and mapNodes[nid] ~= nil then
      local dm = mapNodes[nid].links[n2id] or d -- this should be the same as v given that roads are bidirectional with equal drivability on both direction
      dm.inNode = dm.inNode == n2id and n1id or nid
      if dm ~= nil then
        mapNodes[nid].links[n2id] = nil
        mapNodes[nid].links[n1id] = dm
      end
      n1.links[nid] = dm
    end
  end
  mergeSegTags(n1id, n2id)
  mapNodes[n2id] = nil
  return n1id
end

local function edgeList()
  -- each edge goes in the table exactly once!
  local edges = {}
  local noOfEdges = 0
  local nodeDegree = {} -- number of vertices incident on each node
  for n1id, n in pairs(map.nodes) do
    local degree = 0
    for n2id, d in pairs(n.links) do
      if n1id ~= n2id and map.nodes[n2id] ~= nil then
        degree = degree + 1
        if n2id > n1id then -- every edge gets in the array once
          tableInsert(edges, {n1 = n1id, n2 = n2id, data = {drivability = d.drivability, oneWay = d.oneWay, inNode = d.inNode}})
          noOfEdges = noOfEdges + 1
        end
      end
    end
    nodeDegree[n1id] = degree
  end
  return edges, nodeDegree, noOfEdges
end

local function resetLinksFromEdges(edges)
  local mapNodes = map.nodes
  for nid, n in pairs(mapNodes) do
    n.links = {}
  end

  for _, e in ipairs(edges) do
    local d = e.data
    mapNodes[e.n1].links[e.n2] = d
    mapNodes[e.n2].links[e.n1] = d
  end

  for nid, n in pairs_safe(mapNodes) do
    if next(n.links) == nil and n.manual == nil then
      mapNodes[nid] = nil
    end
  end
end

local function linkSegments()
  local mapNodes = map.nodes
  local edges, nodeDegree, noOfEdges = edgeList()

  -- Resolve T junctions
  local q_edges = quadtree.newQuadtree()
  for i = 1, noOfEdges do
    local n1 = mapNodes[edges[i].n1]
    local n1pos = n1.pos
    local n1rad = n1.radius
    local n2 = mapNodes[edges[i].n2]
    local n2pos = n2.pos
    local n2rad = n2.radius
    q_edges:preLoad(i, quadtree.lineBBox(n1pos.x, n1pos.y, n2pos.x, n2pos.y, max(n1rad, n2rad)))
  end
  q_edges:build()

  local i = 1
  while i <= noOfEdges do -- the vertical edge in the T junction
    local l1n1id = edges[i].n1
    local l1n2id = edges[i].n2
    if nodeDegree[l1n1id] == 1 or nodeDegree[l1n2id] == 1 then
      local l1n1pos = mapNodes[l1n1id].pos
      local l1n2pos = mapNodes[l1n2id].pos
      local l1n1rad = mapNodes[l1n1id].radius
      local l1n2rad = mapNodes[l1n2id].radius
      local posEdge = nil
      local posXnorm = math.huge
      local pos2Xnorm
      local negEdge = nil
      local negXnorm = -math.huge
      local neg2Xnorm
      for l_id in q_edges:query(quadtree.lineBBox(l1n1pos.x, l1n1pos.y, l1n2pos.x, l1n2pos.y, max(l1n1rad, l1n2rad))) do -- the horizontal edge in the T junction. TODO: Maybe find the edge that is closest?
        local l2n1id = edges[l_id].n1
        local l2n2id = edges[l_id].n2
        if l1n1id ~= l2n1id and l1n1id ~= l2n2id and l1n2id ~= l2n1id and l1n2id ~= l2n2id then
          local l1xn, l2xn = closestLinePoints(l1n1pos, l1n2pos, mapNodes[l2n1id].pos, mapNodes[l2n2id].pos)
          if l2xn >= 0 and l2xn <= 1 then
            if l1xn <= 0 and l1xn > negXnorm then
              negEdge = l_id
              negXnorm = l1xn
              neg2Xnorm = l2xn
            elseif l1xn >= 1 and l1xn < posXnorm then
              posEdge = l_id
              posXnorm = l1xn
              pos2Xnorm = l2xn
            end
          end
        end
      end
      if negEdge ~= nil and nodeDegree[l1n1id] == 1 then
        local l2n1id = edges[negEdge].n1
        local l2n2id = edges[negEdge].n2
        local l2n1pos = mapNodes[l2n1id].pos
        local l2n2pos = mapNodes[l2n2id].pos
        local l2n1rad = mapNodes[l2n1id].radius
        local l2n2rad = mapNodes[l2n2id].radius
        local t = linePointFromXnorm(l2n1pos, l2n2pos, neg2Xnorm)
        if t:squaredDistance(l1n1pos) < square(min(l2n1rad, l2n2rad) + l1n1rad) then
          q_edges:remove(negEdge, (l2n1pos.x + l2n2pos.x) * 0.5, (l2n1pos.y + l2n2pos.y) * 0.5)
          q_edges:remove(i, (l1n1pos.x + l1n2pos.x) * 0.5, (l1n1pos.y + l1n2pos.y) * 0.5)

          local l2Data = edges[negEdge].data
          local l2inNode = l2Data.inNode

          -- change the already existing edge (l2) in the edges dict
          edges[negEdge].n2 = l1n1id
          l2Data.inNode = l2inNode == l2n1id and l2n1id or l1n1id

          -- add the new edge in the edges dict
          tableInsert(edges, {n1 = l1n1id, n2 = l2n2id, data = {drivability = l2Data.drivability, oneWay = l2Data.oneWay, inNode = l2inNode == l2n2id and l2n2id or l1n1id}})
          noOfEdges = noOfEdges + 1

          mapNodes[l1n1id].pos = t
          local l1n1rad = (l2n1rad + l2n2rad + l1n1rad) / 3
          mapNodes[l1n1id].radius = l1n1rad

          local t_x = t.x
          local t_y = t.y

          q_edges:insert(negEdge, quadtree.lineBBox(l2n1pos.x, l2n1pos.y, t_x, t_y, max(l2n1rad, l1n1rad)))
          q_edges:insert(noOfEdges, quadtree.lineBBox(l2n2pos.x, l2n2pos.y, t_x, t_y, max(l2n2rad, l1n1rad)))
          q_edges:insert(i, quadtree.lineBBox(t_x, t_y, l1n2pos.x, l1n2pos.y, max(l1n1rad, l1n2rad)))

          mergeSegTags(l1n1id, l2n1id)
          mergeSegTags(l1n1id, l2n2id)
          nodeDegree[l1n1id] = nodeDegree[l1n1id] + 2
        end
      end
      if posEdge ~= nil and nodeDegree[l1n2id] == 1 then
        local l2n1id = edges[posEdge].n1
        local l2n2id = edges[posEdge].n2
        local l2n1pos = mapNodes[l2n1id].pos
        local l2n2pos = mapNodes[l2n2id].pos
        local l2n1rad = mapNodes[l2n1id].radius
        local l2n2rad = mapNodes[l2n2id].radius
        local t = linePointFromXnorm(l2n1pos, l2n2pos, pos2Xnorm)
        if t:squaredDistance(l1n2pos) < square(min(l2n1rad, l2n2rad) + l1n2rad) then
          q_edges:remove(posEdge, (l2n1pos.x + l2n2pos.x) * 0.5, (l2n1pos.y + l2n2pos.y) * 0.5)
          q_edges:remove(i, (l1n1pos.x + l1n2pos.x) * 0.5, (l1n1pos.y + l1n2pos.y) * 0.5)

          local l2Data = edges[posEdge].data
          local l2inNode = l2Data.inNode

          edges[posEdge].n2 = l1n2id
          l2Data.inNode = l2inNode == l2n1id and l2n1id or l1n2id

          tableInsert(edges, {n1 = l1n2id, n2 = l2n2id, data = {drivability = l2Data.drivability, oneWay = l2Data.oneWay, inNode = l2inNode == l2n2id and l2n2id or l1n2id}})
          noOfEdges = noOfEdges + 1

          mapNodes[l1n2id].pos = t
          local l1n2rad = (l2n1rad + l2n2rad + l1n2rad) / 3
          mapNodes[l1n2id].radius = l1n2rad

          local t_x = t.x
          local t_y = t.y

          q_edges:insert(posEdge, quadtree.lineBBox(l2n1pos.x, l2n1pos.y, t_x, t_y, max(l2n1rad, l1n2rad)))
          q_edges:insert(noOfEdges, quadtree.lineBBox(l2n2pos.x, l2n2pos.y, t_x, t_y, max(l2n2rad, l1n2rad)))
          q_edges:insert(i, quadtree.lineBBox(l1n1pos.x, l1n1pos.y, t_x, t_y, max(l1n1rad, l1n2rad)))

          mergeSegTags(l1n2id, l2n1id)
          mergeSegTags(l1n2id, l2n2id)
          nodeDegree[l1n2id] = nodeDegree[l1n2id] + 2
        end
      end
    end
    i = i + 1
  end
  q_edges = nil
  nodeDegree = nil

  -- Merge nodes to lines if they are closeby
  local q = quadtree.newQuadtree()
  for k, v in pairs(mapNodes) do
    q:preLoad(k, quadtree.pointBBox(v.pos.x, v.pos.y, v.radius))
  end
  q:build()

  i = 1
  while i <= noOfEdges do
    local l1n1id = edges[i].n1
    local l1n2id = edges[i].n2
    local l1n1pos = mapNodes[l1n1id].pos
    local l1n2pos = mapNodes[l1n2id].pos
    local l1n1rad = mapNodes[l1n1id].radius
    local l1n2rad = mapNodes[l1n2id].radius
    for nid in q:query(quadtree.lineBBox(l1n1pos.x, l1n1pos.y, l1n2pos.x, l1n2pos.y)) do
      if nid ~= l1n1id and nid ~= l1n2id then
        local n = mapNodes[nid]
        local xnorm = n.pos:xnormOnLine(l1n1pos, l1n2pos)
        if xnorm > 0 and xnorm < 1 then
          local lp = linePointFromXnorm(l1n1pos, l1n2pos, xnorm)
          if n.pos:squaredDistance(lp) < square(min(l1n1rad, l1n2rad, n.radius)) then
            q:remove(nid, n.pos.x, n.pos.y)

            mergeSegTags(nid, l1n1id)
            mergeSegTags(nid, l1n2id)

            if not (next(n.links) == nil and n.manual == 1) then
              n.pos = (n.pos + lp) * 0.5
              n.radius = (l1n1rad + l1n2rad + n.radius) / 3
            end

            q:insert(nid, quadtree.pointBBox(n.pos.x, n.pos.y, n.radius))

            local l1Data = edges[i].data
            local l1inNode = l1Data.inNode

            edges[i].n2 = nid
            l1Data.inNode = (l1inNode == l1n1id and l1n1id) or nid

            tableInsert(edges, {n1 = nid, n2 = l1n2id, data = {drivability = l1Data.drivability, oneWay = l1Data.oneWay, inNode = (l1inNode == l1n2id and l1n2id) or nid}})
            noOfEdges = noOfEdges + 1
            i = i - 1 -- this is needed given we want to recheck edge[i]
            break
          end
        end
      end
    end
    i = i + 1
  end
  q = nil

  -- Resolve X junctions
  local q_edges = quadtree.newQuadtree()
  for i = 1, noOfEdges do
    local n1pos = mapNodes[edges[i].n1].pos
    local n2pos = mapNodes[edges[i].n2].pos
    q_edges:preLoad(i, quadtree.lineBBox(n1pos.x, n1pos.y, n2pos.x, n2pos.y))
  end
  q_edges:build()
  local junctionid = 1

  i = 1
  while i <= noOfEdges do
    local l1n1id = edges[i].n1
    local l1n2id = edges[i].n2
    local l1n1pos = mapNodes[l1n1id].pos
    local l1n2pos = mapNodes[l1n2id].pos
    local l1n1rad = mapNodes[l1n1id].radius
    local l1n2rad = mapNodes[l1n2id].radius
    for l_id in q_edges:query(quadtree.lineBBox(l1n1pos.x, l1n1pos.y, l1n2pos.x, l1n2pos.y)) do
      local l2n1id = edges[l_id].n1
      local l2n2id = edges[l_id].n2
      if l1n1id ~= l2n1id and l1n1id ~= l2n2id and l1n2id ~= l2n1id and l1n2id ~= l2n2id then
        local l2n1pos = mapNodes[l2n1id].pos
        local l2n2pos = mapNodes[l2n2id].pos
        local l2n1rad = mapNodes[l2n1id].radius
        local l2n2rad = mapNodes[l2n2id].radius
        local l1xn, l2xn = closestLinePoints(l1n1pos, l1n2pos, l2n1pos, l2n2pos)
        if l1xn > 0 and l1xn < 1 and l2xn > 0 and l2xn < 1 then
          local t1 = linePointFromXnorm(l1n1pos, l1n2pos, l1xn)
          local t2 = linePointFromXnorm(l2n1pos, l2n2pos, l2xn)
          if t1:squaredDistance(t2) < square(min(l1n1rad, l1n2rad, l2n1rad, l2n2rad) * 0.5) then
            local xid = 'autojunction_'..junctionid
            junctionid = junctionid + 1
            local xid_pos = (t1 + t2) * 0.5
            mapNodes[xid] = {pos = xid_pos,
              radius = (l1n1rad + l1n2rad + l2n1rad + l2n2rad) * 0.25,
              links = {}, segTags = {}}

            mergeSegTags(xid, l1n1id)
            mergeSegTags(xid, l1n2id)
            mergeSegTags(xid, l2n1id)
            mergeSegTags(xid, l2n2id)

            q_edges:remove(i, (l1n1pos.x + l1n2pos.x) * 0.5, (l1n1pos.y + l1n2pos.y) * 0.5)
            q_edges:remove(l_id, (l2n1pos.x + l2n2pos.x) * 0.5, (l2n1pos.y + l2n2pos.y) * 0.5)

            local l1Data = edges[i].data
            local l1inNode = l1Data.inNode

            edges[i].n2 = xid
            l1Data.inNode = l1inNode == l1n1id and l1n1id or xid

            tableInsert(edges, {n1 = xid, n2 = l1n2id, data = {drivability = l1Data.drivability, oneWay = l1Data.oneWay, inNode = l1inNode == l1n2id and l1n2id or xid}})
            noOfEdges = noOfEdges + 1
            q_edges:insert(noOfEdges, quadtree.lineBBox(xid_pos.x, xid_pos.y, l1n2pos.x, l1n2pos.y))
            q_edges:insert(i, quadtree.lineBBox(xid_pos.x, xid_pos.y, l1n1pos.x, l1n1pos.y))

            local l2Data = edges[l_id].data
            local l2inNode = l2Data.inNode

            edges[l_id].n2 = xid
            l2Data.inNode = l2inNode == l2n1id and l2n1id or xid

            tableInsert(edges, {n1 = xid, n2 = l2n2id, data = {drivability = l2Data.drivability, oneWay = l2Data.oneWay, inNode = l2inNode == l2n2id and l2n2id or xid}})
            noOfEdges = noOfEdges + 1
            q_edges:insert(l_id, quadtree.lineBBox(xid_pos.x, xid_pos.y, l2n1pos.x, l2n1pos.y))
            q_edges:insert(noOfEdges, quadtree.lineBBox(xid_pos.x, xid_pos.y, l2n2pos.x, l2n2pos.y))
            -- TODO: shouldn't we have a i = i - 1 as in resolve T junctions
            break
          end
        end
      end
    end
    i = i + 1
  end
  q_edges = nil

  resetLinksFromEdges(edges)
end

local function loadJsonDecalMap()
  local mapNodes = map.nodes
  allManualWaypoints = {}

  -- load BeamNG Waypoint data
  for _, nodeName in ipairs(scenetree.findClassObjects('BeamNGWaypoint')) do
    local o = scenetree.findObject(nodeName)
    if o and mapNodes[nodeName] == nil then
      local radius = getSceneWaypointRadius(o)
      local pos = o:getPosition()
      tableInsert(allManualWaypoints, {nodeName = nodeName, pos = vec3(pos), radius = radius})
      mapNodes[nodeName] = {pos = vec3(pos), radius = radius, links = {}, segTags = {}, manual = 1}
    end
  end

  -- load DecalRoad data
  for _, decalRoadName in ipairs(scenetree.findClassObjects('DecalRoad')) do
    local o = scenetree.findObject(decalRoadName)
    if o and o.drivability > 0 then
      local segCount = o:getNodeCount() - 1
      if segCount > 0 then
        local prefix
        if tonumber(decalRoadName) == nil then
          prefix = decalRoadName
        else
          prefix = "DecalRoad" .. decalRoadName .. "_"
        end

        local drivability = o.drivability
        local oneWay = o.oneWay or false
        local flipDirection = o.flipDirection or false
        local nodeName = nil

        for i = 0, segCount do
          local prevName = nodeName
          nodeName = prefix .. i+1
          if mapNodes[nodeName] ~= nil then
            local newNodeName = nodeName .. '_1'
            if mapNodes[newNodeName] ~= nil then
              local pfix = 2
              newNodeName = nodeName .. '_' .. pfix
              while mapNodes[newNodeName] ~= nil do
                pfix = pfix + 1
                newNodeName = nodeName .. '_' .. pfix
              end
            end
            nodeName = newNodeName
          end

          mapNodes[nodeName] = {pos = vec3(o:getNodePosition(i)),
            radius = o:getNodeWidth(i) * 0.5,
            links = {}, segTags = {}}
          if prevName then
            local data = {drivability = drivability, oneWay = oneWay, inNode = flipDirection and nodeName or prevName}
            mapNodes[prevName].links[nodeName] = data
            mapNodes[nodeName].links[prevName] = data
          end
        end
      end
    end
  end

  -- load manual road segments
  local missionFile = getMissionFilename()
  local levelDir, filename, ext = path.split(missionFile, "(.-)([^/]-([^%.]*))$")
  if not levelDir then return end
  mapFilename = levelDir .. 'map.json'
  --log('D', 'map', 'loading map.json: '.. mapFilename)
  local content = readFile(mapFilename)
  if content == nil then
    --log('D', 'map', 'map system disabled due to missing/unreadable file: '.. mapFilename)
    return
  end

  local state, jsonMap = pcall(json.decode, content)
  if state == false then
    log('W', 'map', 'unable to parse file: '.. mapFilename)
    return
  end

  for _, v in pairs(jsonMap.segments) do
    if type(v.nodes) == 'string' then
      local nodeList = {}
      local nargs = split(v.nodes, ',')
      for ni, nv in pairs(nargs) do
        local nargs2 = split(nv, '-')
        if #nargs2 == 1 then
          tableInsert(nodeList, trim(nargs2[1]))
        elseif #nargs2 == 2 then
          local prefix1 = stringMatch(nargs2[1], "[^%d]+")
          local num1 = stringMatch(nargs2[1], "[%d]+")
          local prefix2 = stringMatch(nargs2[2], "[^%d]+")
          local num2 = stringMatch(nargs2[2], "[%d]+")
          if prefix1 ~= prefix2 then
            log('E', 'map', "segment format issue: not the same prefix: ".. tostring(nargs2[1]) .. " and " .. tostring(nargs2[2]) .. " > discarding nodes. Please fix")
          end
          for k = num1, num2 do
            tableInsert(nodeList, prefix1 .. tostring(k))
          end
        end
        v.nodes = nodeList
      end
    end

    local drivability = v.drivability
    local flipDirection = v.flipDirection or false
    local oneWay = v.oneWay or false
    for i = 2, #v.nodes do
      local wp1 = v.nodes[i-1]
      local wp2 = v.nodes[i]
      if mapNodes[wp1] == nil then log('E', 'map', "waypoint p1 not found: "..tostring(wp1)); break; end
      if mapNodes[wp2] == nil then log('E', 'map', "waypoint p2 not found: "..tostring(wp2)); break; end
      local data = {drivability = drivability, oneWay = oneWay, inNode = flipDirection and wp2 or wp1}
      mapNodes[wp1].links[wp2] = data
      mapNodes[wp2].links[wp1] = data
    end
  end
end

local function cleanupNodes()
  for n1id, n1 in pairs_safe(map.nodes) do
    local newLinks = {}
    for lnid, data in pairs(n1.links) do
      if lnid ~= n1id and map.nodes[lnid] ~= nil then
        newLinks[lnid] = data
      end
    end

    if next(newLinks) == nil and n1.manual == nil then
      visLog("error", n1.pos:toPoint3F(), "isolated node:"..tostring(n1id))
      map.nodes[n1id] = nil
    else
      n1.links = newLinks
    end
  end
end

local function validateEdgeData()
  local noOfNodes = 0
  local noOfValidEdges = 0
  local noOfInvalidEdges = 0
  local noOfSingleSidedEdges = 0
  for n1id, n1 in pairs(map.nodes) do
    noOfNodes = noOfNodes + 1
    for n2id, data in pairs(n1.links) do
      if map.nodes[n1id].links[n2id] == map.nodes[n2id].links[n1id] then
        noOfValidEdges = noOfValidEdges + 1
      else
        if map.nodes[n1id].links[n2id] == nil or map.nodes[n2id].links[n1id] == nil then
          noOfSingleSidedEdges = noOfSingleSidedEdges + 1
        else
          noOfInvalidEdges = noOfInvalidEdges + 1
        end
      end
    end
  end
  if noOfValidEdges > 0 then
    print("There are "..tonumber(noOfValidEdges).." valid edges")
  end
  if noOfInvalidEdges > 0 then
    print("There are "..tonumber(noOfInvalidEdges).." invalid edges")
  end
  if noOfSingleSidedEdges > 0 then
    print("There are "..tonumber(noOfSingleSidedEdges).." single sided edges")
  end
end

local function dedupNodes()
  -- merge closeby nodes together

  local mapNodes = map.nodes

  local q = quadtree.newQuadtree()
  for k, v in pairs(mapNodes) do
    q:preLoad(k, quadtree.pointBBox(v.pos.x, v.pos.y, v.radius))
  end
  q:build()

  local nodes = tableKeys(mapNodes)
  for i = 1, #nodes do
    local n1id = nodes[i]
    local n1 = mapNodes[n1id]
    if n1 ~= nil then
      if next(n1.links) == nil and n1.manual == nil then
        visLog("error", n1.pos:toPoint3F(), "isolated node: "..tostring(n1id))
        q:remove(n1id, n1.pos.x, n1.pos.y)
        mapNodes[n1id] = nil
      else
        for n2id in q:query(quadtree.pointBBox(n1.pos.x, n1.pos.y, n1.radius)) do -- give me the id of every node that overlaps this bounding box
          local n2 = mapNodes[n2id]
          if n1id ~= n2id and n2 ~= nil and n1.pos:squaredDistance(n2.pos) < square(min(n1.radius, n2.radius)) then -- center of the larger is within the radius of the smaller
            q:remove(n1id, n1.pos.x, n1.pos.y)
            q:remove(n2id, n2.pos.x, n2.pos.y)
            local nid = mergeNodes(n1id, n2id) -- create a new node (in place of the two being merged) and give me its name
            local n = mapNodes[nid]
            q:insert(nid, quadtree.pointBBox(n.pos.x, n.pos.y, n.radius))
            if nid ~= n1id then break end
          end
        end
      end
    end
  end

  cleanupNodes()
end

local function optimizeNodes()
  -- optimize paths and throw away nodes that are below a certain displacement
  -- n1id <-> nid (to delete) <-> n2id
  local optimizedNodes = 0
  local nodesToDelete = {}
  for nid, n in pairs(map.nodes) do
    if tableSize(n.links) == 2 and n.manual == nil then
      local n1id = next(n.links)
      local n2id = next(n.links, n1id)
      local n1 = map.nodes[n1id]
      local n2 = map.nodes[n2id]

      local d1 = n1.links[nid]
      local d2 = n2.links[nid]

      if abs(min(n1.radius, n2.radius) - n.radius + n.pos:distanceToLine(n1.pos, n2.pos)) < 0.1 and is2SegMergeValid(nid, d1, d2) then
        tableInsert(nodesToDelete, nid)
        d1.drivability = min(d1.drivability, d2.drivability)
        d1.inNode = d1.inNode == nid and n2id or n1id
        n1.links[nid] = nil
        n1.links[n2id] = d1
        n2.links[nid] = nil
        n2.links[n1id] = d1
        optimizedNodes = optimizedNodes + 1
      end
    end
  end

  for _, nid in ipairs(nodesToDelete) do
    map.nodes[nid] = nil
  end

  --if optimizedNodes > 0 then
  --  log('D', 'map', "optimized nodes: " .. optimizedNodes .. " of " .. tableSize(map.nodes) .. " total nodes")
  --end
end

local function optimizeEdges()
  -- triangle n1id, nid, n2id
  -- deletes n1id, n2id segment
  for nid, n in pairs(map.nodes) do
    if tableSize(n.links) == 2 and n.manual == nil then
      local n1id = next(n.links)
      local n2id = next(n.links, n1id)
      local n1 = map.nodes[n1id]
      local n2 = map.nodes[n2id]
      local dchord = n1.links[n2id]
      local d1 = n.links[n1id]
      local d2 = n.links[n2id]
      if (n1.links[n2id] ~= nil or n2.links[n1id] ~= nil) and is3SegMergeValid(nid, d1, d2, dchord) then
        local xnorm, dist = n.pos:xnormDistanceToLineSegment(n1.pos, n2.pos)
        if xnorm >= 0 and xnorm <= 1 and dist <= n.radius + max(n1.radius, n2.radius) then
          local lnPoint = linePointFromXnorm(n1.pos, n2.pos, xnorm)
          n.pos = n.pos + (lnPoint - n.pos):normalized() * (dist - n.radius + max(n1.radius, n2.radius)) * 0.5
          n.radius = (dist + n.radius + max(n1.radius, n2.radius)) * 0.5
          n.links[n1id].drivability = min(n.links[n1id].drivability, n1.links[n2id].drivability)
          n.links[n2id].drivability = min(n.links[n2id].drivability, n1.links[n2id].drivability)
          n1.links[n2id] = nil
          n2.links[n1id] = nil
        end
      end
    end
  end
end

local function generateVisLog()
  visualLog = {}
  for nid, n in pairs(map.nodes) do
    local linksize = tableSize(n.links)
    if linksize == 1 then
      visLog("warn", n.pos, "dead end:"..tostring(nid))
    end
    if linksize == 0 then
      visLog("error", n.pos, "isolated node:"..tostring(nid))
    end
  end
end

local function convertToSingleSided()
  for nid, n in pairs(map.nodes) do
    local newLinks = {}
    for lid, data in pairs(n.links) do
      if lid ~= nid and map.nodes[lid] ~= nil then
        if lid > nid then
          newLinks[lid] = data
        end
      end
    end
    n.links = newLinks
    n.manual = nil
    nodeSegTags[nid] = n.segTags
    n.segTags = nil
  end
end

local function loadMap()
  --log('A', "map.loadMap-calledby", debug.traceback())
  --local timer = hptimer()
  M.objects = {}
  M.objectNames = {}
  map = {nodes = {}}

  loadJsonDecalMap()
  dedupNodes()
  linkSegments()
  dedupNodes()
  optimizeEdges()
  optimizeNodes()
  --validateEdgeData() --> For testing the one way road data
  generateVisLog()
  convertToSingleSided()
  --validateEdgeData() --> For testing the one way road data

  local mapNodes = map.nodes

  -- build the graph and the tree
  maxRadius = 4 -- case there are no nodes in the map i.e. next(map.nodes) == nil avoids infinite loop in findClosestRoad()
  gp = graphpath.newGraphpath()
  qt = quadtree.newQuadtree()
  local qtNodes = quadtree.newQuadtree()

  for nid, n in pairs(mapNodes) do -- remember edges are now single sided
    local nPos = n.pos
    local radius = n.radius
    qtNodes:preLoad(nid, quadtree.pointBBox(nPos.x, nPos.y, radius))
    maxRadius = max(maxRadius, radius)
    for lid, data in pairs(n.links) do
      local lPos = mapNodes[lid].pos
      local edgeDrivability = data.drivability
      if data.oneWay then
        local inNode = data.inNode
        local outNode = inNode == nid and lid or nid
        gp:uniEdge(inNode, outNode, nPos:distance(lPos)/(edgeDrivability + 1e-30), edgeDrivability)
      else
        gp:bidiEdge(nid, lid, nPos:distance(lPos)/(edgeDrivability + 1e-30), edgeDrivability)
      end
      qt:preLoad(nid..'\0'..lid, quadtree.lineBBox(nPos.x, nPos.y, lPos.x, lPos.y, radius))
    end
  end

  qt:build(5)
  qt:compress()

  qtNodes:build()

  local nodeAliases = {}

  -- Find closest mapNode to a manualWaypoint not in the map and create Alias
  for i, v in ipairs(allManualWaypoints) do
    if mapNodes[v.nodeName] == nil then
      local closestNode
      local minDist = math.huge
      local vPos = v.pos
      for item_id in qtNodes:query(quadtree.pointBBox(vPos.x, vPos.y, v.radius)) do
        local dist = mapNodes[item_id].pos:squaredDistance(vPos)
        if dist < minDist then
          closestNode = item_id
          minDist = dist
        end
      end
      nodeAliases[v.nodeName] = closestNode
    end
  end

  -- calculate surface' normals
  local vecX = vec3(1,0,0)
  local vecY = vec3(0,1,0)
  local vecUp = vec3(0,0,1)
  for nid, n in pairs(mapNodes) do
    local radiusH = n.radius * 0.5
    local nPos = n.pos + vecUp * radiusH
    local p1 = vec3(nPos)
    p1.z = be:getSurfaceHeightBelow(p1:toPoint3F())
    local p2 = nPos + vecX * radiusH
    p2.z = be:getSurfaceHeightBelow(p2:toPoint3F())
    local p3 = nPos + vecY * radiusH
    p3.z = be:getSurfaceHeightBelow(p3:toPoint3F())
    if (min(p1.z, p2.z, p3.z) < nPos.z - n.radius) then
      n.normal = vecUp
    else
      n.normal = (p2-p1):cross(p3-p1):normalized()
    end
  end

  map.nodeAliases = nodeAliases
  allManualWaypoints = nil

  --log('D', 'map', "generating roads took " .. string.format("%2.3f ms", timer:stopAndReset()))
  guihooks.trigger("NavigationMapChanged", map)
end

local function getPath(wp1, wp2, cutOffDrivability, dirMult)
  -- arguments:
  -- wp1: starting node
  -- wp2: target node
  -- cutOffDrivability: penalize roads with drivability <= cutOffDrivability
  -- dirMult: amount of penalty to impose to path if it does not respect road
  --          legal directions (should be larger than 1). If equal to nil or 1 then it means no penalty.
  if gp == nil then return {} end
  return gp:getFilteredPath(wp1, wp2, cutOffDrivability, dirMult)
end

-- this is also in vehicle/mapmgr.lua
local function findClosestRoad(position)
  if qt == nil then return end
  local mapNodes = map.nodes
  local bestRoad1 = nil
  local bestRoad2 = nil
  local bestDist = math.huge
  local radius = maxRadius
  repeat
    for item_id in qt:query(quadtree.pointBBox(position.x, position.y, radius)) do
      local i = stringFind(item_id, '\0')
      local n1id = stringSub(item_id, 1, i-1)
      local n2id = stringSub(item_id, i+1, #item_id)
      local curDist = position:squaredDistanceToLineSegment(mapNodes[n1id].pos, mapNodes[n2id].pos)
      if curDist < bestDist then
        bestDist = curDist
        bestRoad1 = n1id
        bestRoad2 = n2id
      end
    end
    radius = radius * 2
  until bestRoad1 or radius > 200
  return bestRoad1, bestRoad2, sqrt(bestDist)
end

M.drawDebug = nop
local function drawDebug(dtReal, lastFocusPos)
  if isEditorEnabled and tonumber(getTSVar('$pref::BeamNGNavGraph::drawDebug')) == 1 or
    not isEditorEnabled and M.debugMode == 'graph' and next(map.nodes) ~= nil then
    local segNums = {}
    local segmentNumber
    local maxSegNum = 1
    local mapNodes = map.nodes
    local lastFocusPosVec = vec3(lastFocusPos)
    for nid, n in pairs(mapNodes) do
      local s = next(nodeSegTags[nid])
      if s == nil then
        segmentNumber = 1
      elseif segNums[s] ~= nil then
        segmentNumber = segNums[s]
      else
        maxSegNum = maxSegNum + 1
        segNums[s] = maxSegNum
        segmentNumber = maxSegNum
      end
      if n.pos:squaredDistance(lastFocusPosVec) < square(M.debugDrawDistance) then
        -- draw nodes
        local nPosPoint3F = n.pos:toPoint3F()
        debugDrawer:drawSphere(nPosPoint3F, n.radius, ColorF(0.5,0.5,0.5,0.3))

        -- local col = getContrastColorF(segmentNumber)
        -- col.alpha = 0.5
        local arrowCol = getContrastColorF(segmentNumber+1)
        -- draw edges
        for lid, data in pairs(n.links) do
          if mapNodes[lid] ~= nil then
            local adjustedDrivability = max(0, 2 * data.drivability - 1)
            local colVec = (vec3(255, 0, 0) * (1-adjustedDrivability) + vec3(0, 255, 0) * adjustedDrivability) / 255
            local col = ColorF(colVec.x, colVec.y, colVec.z, 0.5)
            debugDrawer:drawSquarePrism(nPosPoint3F, mapNodes[lid].pos:toPoint3F(), Point2F(0.6, n.radius*2), Point2F(0.6, mapNodes[lid].radius*2), col)

            if data.oneWay then -- draw road direction arrows if the segment is one way
              local inNodePos = mapNodes[data.inNode].pos
              local edgeDirVec = mapNodes[data.inNode ~= lid and lid or nid].pos - inNodePos
              local edgeLength = edgeDirVec:length()
              edgeDirVec = edgeDirVec / (edgeLength + 1e-30)
              debugDrawer:drawSquarePrism((inNodePos + 0.5*edgeDirVec):toPoint3F(), (inNodePos + min(2.5, 0.5*edgeLength)*edgeDirVec):toPoint3F(), Point2F(0.7, 1), Point2F(0.7, 0), arrowCol)
              if edgeLength > 100 then -- if edge is too long also place direction arrows at 70% distance
                debugDrawer:drawSquarePrism((inNodePos + 0.7*edgeLength*edgeDirVec):toPoint3F(), (inNodePos + (0.7*edgeLength+2)*edgeDirVec):toPoint3F(), Point2F(0.7, 1), Point2F(0.7, 0), arrowCol)
              end
            end

          end
        end
        debugDrawer:drawText(nPosPoint3F, String(tostring(nid)), ColorF(0,0,0,1))
      end
    end
  end
  if M.debugMode == 'vislog' and #visualLog > 0 then
    for _, v in pairs(visualLog) do
      if not v.pos or not v.msg then break end -- work around engine crash

      local col = ColorF(0,1,0,1)
      if v.type == 'warn' then
        col = ColorF(1,1,0,1)
      elseif v.type == 'error' then
        col = ColorF(1,0,0,1)
      end

      debugDrawer:drawCylinder(v.pos:toPoint3F(), (v.pos + vec3(0, 0, 10)):toPoint3F(), 1, col)
      debugDrawer:setLastZTest(false)
      debugDrawer:drawText((v.pos + vec3(0, 0, 10.2)):toPoint3F(), String(v.msg), col)
    end
  end
end

local function saveSVG(filename)
  local svg = require('svgwriter')

  local terrain = scenetree.findObject(scenetree.findClassObjects('TerrainBlock')[1])
  local terrainPosition = vec3(terrain:getPosition())

  local svgDoc = svg.Document(2048, 2048, svg.gray(255))
  local lines = svg.Group()

  local m = map
  if not m or not next(m.nodes) then return end
  -- draw edges
  for nid, n in pairs(m.nodes) do
    for lid, dif in pairs(n.links) do
      local p1 = n.pos - terrainPosition
      local p2 = m.nodes[lid].pos - terrainPosition

      -- TODO: add proper fading between some colors
      local typeColor = 'black'
      if dif < 0.9 and dif >= 0 then
        typeColor = svg.rgb(170, 68, 0) -- dirt road = brown
      end

      local l = svg.Polyline({2048 - p1.x, p1.y, 2048 - p2.x, p2.y}, {
        fill = 'none',
        stroke = typeColor,
        stroke_width = n.radius * 2,
        stroke_opacity=0.4,
      })
      lines:add(l)
    end
  end
  svgDoc:add(lines)

  -- draw nodes
  local nodes = svg.Group()
  for nid, n in pairs(m.nodes) do
    local p = n.pos - terrainPosition
    local circle = svg.Circle(2048 - p.x, p.y, n.radius, {
      fill = 'black',
      fill_opacity=0.4,
      stroke = 'none',
    })
    nodes:add(circle)
  end
  svgDoc:add(nodes)

  svgDoc:writeTo(filename or 'map.svg')
end

local function updateGFX(dtReal)
  for _, o in pairs(M.objects) do
    if o.active == false then
      be:queueAllObjectLua('mapmgr.objectData(' .. serialize(M.objects) .. ')')
      break
    end
  end

  objectsReset = true

  delayedLoad:update(dtReal)
end

local function load()
  if loadedMap then return end
  loadedMap = true
  loadMap()
end

local function assureLoad()
  if not loadedMap then
    loadMap()
  end
  loadedMap = false
end

local function onMissionLoaded()
  loadedMap = false
end

local function onWaypoint(args)
  --print('onWaypoint')
  --dump(args)

  -- local aiData = {subjectName = args.subjectName, triggerName = args.triggerName, event = args.event, mode = args.mode}
  -- args.subject:queueLuaCommand('ai.onWaypoint(' .. serialize(aiData) .. ')')

  --[[
  --if args.triggerName
  local triggerName = string.match(args.triggerName, "(%a*)(%d+)")
  local triggerNum = string.match(args.triggerName, "(%d+)")

  local v = scenetree.findObject(args.subjectName)
  local nextTrigger = scenetree.findObject(triggerName .. (triggerNum + 1))
  if args.subject and nextTrigger then
    --local ppos = player:getPosition()
    local tpos = nextTrigger:getPosition()
    --print("player pos: " .. tostring(ppos))
    --print("trigger pos: " .. tostring(tpos))
    local l = 'ai.setTarget('..tostring(tpos)..')'
    --print(l)
    args.subject:queueLuaCommand(l)

  end
  ]]

  --local t = {msg = 'Trigger "' .. args.triggerName .. '" : ' .. args.event, time = 1}
  --local js = 'HookManager.trigger("Message",' .. encodeJson(t) .. ')'
  --print(js)
  --be:executeJS(js)
end

-- TODO: please fix these functions, so users can interactively add/remove/modify the waypoints in the editor and directly see changes.
local function onAddWaypoint(wp)
  --print("waypoint added: " .. tostring(wp))
  if isEditorEnabled and M.drawDebug ~= nop then
    delayedLoad:callAfter(0.5, loadMap)
  end
end

local function onRemoveWaypoint(wp)
  --print("waypoint removed: " .. tostring(wp))
  if isEditorEnabled and M.drawDebug ~= nop then
    delayedLoad:callAfter(0.5, loadMap)
  end
end

local function onModifiedWaypoint(wp)
  --print("waypoint modified: " .. tostring(wp))
  if isEditorEnabled and M.drawDebug ~= nop then
    delayedLoad:callAfter(0.5, loadMap)
  end
end

local function onFileChanged(filename, type)
  if filename == mapFilename then
    log('D', 'map', "map.json changed, reloading map")
    loadMap()
  end
end

local function request(objId)
  queueObjectLua(objId, 'mapmgr.setMap(' .. serialize(map) .. ')')
end

local function setDrawDebug()
  if isEditorEnabled or M.debugMode == 'graph' or M.debugMode == 'vislog' then
    M.drawDebug = drawDebug
  else
    M.drawDebug = nop
  end
end

local function onSerialize()
  return {M.debugMode, M.debugDrawDistance, M.debugDrawDistanceLabels, isEditorEnabled}
end

local function onDeserialize(s)
  M.debugMode, M.debugDrawDistance, M.debugDrawDistanceLabels, isEditorEnabled = unpack(s)
  setDrawDebug()
end

local function setEditorState(enabled)
  isEditorEnabled = enabled
  setDrawDebug()
end

local function setDebugMode(mode)
  M.debugMode = mode
  setDrawDebug()
end

local function setState(newState)
  tableMerge(M, newState)
  setDrawDebug()
end

local function getState()
  for k,v in pairs(M.objectNames) do
    if type(k) == 'string' then
      if M.objects[v] then
        M.objects[v].name = k
      end
    end
  end
  for k, v in pairs(M.objects) do
    v.name = v.name or ''
    local vehicle = be:getObjectByID(k)
    v.licensePlate = vehicle and vehicle:getDynDataFieldbyName("licenseText", 0) or dumps(k)
  end
  return M
end

local function getMap()
  return map
end

local function getTrackedObjects()
  return M.objects
end

-- recieves vehicle data from vehicles
local function objectData(objId, isactive, vel, dirVec, dirVecUp, damage, objectCollisions)
  if objectsReset then
    table.clear(M.objects)
    objectsReset = false
  end
  local object = be:getObjectByID(objId)
  if object and M.objects[objId] == nil then
    M.objects[objId] = {id = objId, active = isactive, pos = vec3(object:getPosition()), vel = vel,
        dirVec = dirVec, dirVecUp = dirVecUp, damage = damage, objectCollisions = objectCollisions}
  end
end

-- recieves temporary vehicle data from vehicles
local function tempObjectData(objId, isactive, pos, vel, dirVec, dirVecUp, damage, objectCollisions)
  if objectsReset then
    table.clear(M.objects)
    objectsReset = false
  end
  M.objects[objId] = {id = objId, active = isactive, pos = pos, vel = vel,
      dirVec = dirVec, dirVecUp = dirVecUp, damage = damage, objectCollisions = objectCollisions}
end

local function setNameForId(name, id)
  M.objectNames[name] = id
end

-- public interface
M.updateGFX = updateGFX
M.objectData = objectData
M.tempObjectData = tempObjectData
M.setNameForId = setNameForId
M.onWaypoint = onWaypoint
M.reset = loadMap
M.load = load
M.assureLoad = assureLoad
M.onMissionLoaded = onMissionLoaded
M.request = request
M.onAddWaypoint = onAddWaypoint
M.onRemoveWaypoint = onRemoveWaypoint
M.onModifiedWaypoint = onModifiedWaypoint
M.onFileChanged = onFileChanged
M.setState = setState
M.getState = getState
M.setDebugMode = setDebugMode
M.setEditorState = setEditorState
M.getMap = getMap
M.getTrackedObjects = getTrackedObjects
M.getPath = getPath
M.findClosestRoad = findClosestRoad
M.saveSVG = saveSVG
M.onSerialize = onSerialize
M.onDeserialize = onDeserialize

-- backward compatibility fixes below
local backwardCompatibility = {
  __index = function(tbl, key)
    if key == 'map' then
      if not M.warnedMapBackwardCompatibility then
        log('E', 'map', 'map.map API is deprecated. Please use map.getMap()')
        M.warnedMapBackwardCompatibility = true
      end
      return M.getMap()
    end
    return rawget(tbl, key)
  end
}
setmetatable(M, backwardCompatibility)

return M
