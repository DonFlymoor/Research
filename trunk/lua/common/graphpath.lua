--[[
Copyright (c) 2012 Hello!Game, 2015 BeamNG GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of newinst software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and newinst permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

----------------------------------------------------------------
-- example :
--[[
gp = newGraphpath()
gp:edge("a", "b", 7)
gp:edge("a", "c", 9)
gp:edge("a", "f", 14)
gp:edge("b", "d", 15)
gp:edge("b", "c", 10)
gp:edge("c", "d", 11)
gp:edge("c", "f", 2)
gp:edge("d", "e", 6)
gp:edge("e", "f", 9)

print( table.concat( gp:getPath("a","e"), "->") )
]]

require('mathlib')
local M = {}

local tableInsert = table.insert
local max = math.max
local min = math.min

local Graphpath = {}
Graphpath.__index = Graphpath

local minheap = {}
minheap.__index = minheap

function minheap:new()
  return setmetatable( { length = 0 }, self)
end

function minheap:next_key()
  assert(self.left, "The minheap is empty")
  return self[1].key
end

function minheap:empty()
  return self.length == 0
end

function minheap:insert(k, v)
  -- float the new key up from the bottom of the heap
  local child_index = self.length + 1 -- array index of the new child node to be added to heap
  self.length = child_index -- update the central heap length record
  local new_record = self[child_index]  -- keep the old table to save garbage
  while child_index > 1 do
    local parent_index = bit.rshift(child_index, 1)
    local parent_rec = self[parent_index]
    if k < parent_rec.key then
      self[child_index] = parent_rec
    else
      break
    end
    child_index = parent_index
  end
  if new_record then
    new_record.key = k
    new_record.value = v
  else
    new_record = {key = k, value = v}
  end
  self[child_index] = new_record
end

function minheap:pop()
  if self.length <= 0 then return end
  -- pop the top of the heap
  local result = self[1]
  local heapLength = self.length
  -- push the last element in the heap down from the top
  local last = self[heapLength]
  -- local last_key = (last and last.key) or nil
  local last_key = last.key
  -- keep the old record around to save on garbage
  self[heapLength] = result
  heapLength = heapLength - 1
  self.length = heapLength

  local parent_index = 1
  local child_index = 2
  while child_index <= heapLength do
    if child_index+1 <= heapLength and
    self[child_index+1].key < self[child_index].key then
      child_index = child_index + 1
    end
    local child_rec = self[child_index]
    local child_key = child_rec.key
    if last_key < child_key then
      break
    else
      self[parent_index] = child_rec
      parent_index = child_index
    end
    child_index = parent_index * 2
  end
  self[parent_index] = last
  return result.key, result.value
end

local function newGraphpath()
  local gp = {graph = {}, positions = {}}
  setmetatable(gp, Graphpath)
  return gp
end

function Graphpath:clear()
  self.graph = {}
end

function Graphpath:edge(sp, ep, dist)
  if self.graph[sp] == nil then
    self.graph[sp] = {}
  end

  self.graph[sp][ep] = {dist or 1}

  if self.graph[ep] == nil then
    self.graph[ep] = {}
  end
end

function Graphpath:uniEdge(sp, ep, dist, drivability)
  dist = dist or 1
  if self.graph[sp] == nil then
    self.graph[sp] = {}
  end

  self.graph[sp][ep] = {dist, 1, drivability}

  if self.graph[ep] == nil then
    self.graph[ep] = {}
  end

  self.graph[ep][sp] = {dist, 2, drivability}
end

function Graphpath:bidiEdge(sp, ep, dist, drivability)
  dist = dist or 1
  if self.graph[sp] == nil then
    self.graph[sp] = {}
  end

  self.graph[sp][ep] = {dist, 1, drivability}

  if self.graph[ep] == nil then
    self.graph[ep] = {}
  end

  self.graph[ep][sp] = {dist, 1, drivability}
end

function Graphpath:setPointPosition(p, pos)
  self.positions[p] = pos
end

local function invertPath(goal, road)
  local t = table.new(#road, 0)
  t[1] = goal
  local tidx = 2
  local node = road[goal]
  while node do
    t[tidx] = node
    tidx = tidx + 1
    node = road[node]
  end

  local s = 1
  local e = #t
  while s < e do
    t[s], t[e] = t[e], t[s]
    s = s + 1
    e = e - 1
  end

  return t
end

do
  local graph
  local index
  local S
  local nodeData
  local allSCC

  local function strongConnect(node)
    -- Set the depth index for node to the smallest unused index
    index = index + 1
    nodeData[node] = {index = index, lowlink = index, onStack = true}
    tableInsert(S, node)

    -- Consider succesors of node
    for adjNode, value in pairs(graph[node]) do
      if value[2] == 1 then
        if nodeData[adjNode] == nil then -- adjNode is a descendant of 'node' in the search tree
          strongConnect(adjNode)
          nodeData[node].lowlink = min(nodeData[node].lowlink, nodeData[adjNode].lowlink)
        elseif nodeData[adjNode].onStack then -- adjNode is not a descendant of 'node' in the search tree
          nodeData[node].lowlink = min(nodeData[node].lowlink, nodeData[adjNode].index)
        end
      end
    end

    -- generate an scc (smallest possible scc is one node)
    -- i.e. in a directed accyclic graph each node constitutes an scc
    if nodeData[node].lowlink == nodeData[node].index then
      local currentSCC = {}
      local currentSCCLen = 0
      repeat
        local w = table.remove(S)
        nodeData[w].onStack = false
        currentSCC[w] = true
        currentSCCLen = currentSCCLen + 1
      until node == w
      currentSCC[0] = currentSCCLen
      tableInsert(allSCC, currentSCC)
    end
  end

  function Graphpath:scc(v)
    --[[
    calculates the strongly connected components (scc) of the map graph
    if v is provided, it only calculates the scc containing/reachable from v
    returns an array of dicts ('allSCC')
    https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
    --]]

    graph = self.graph
    if v and graph[v] == nil then return {} end

    index = 0
    S = {}
    nodeData = {}
    allSCC = {}

    if v then
      -- get only the scc containing/reachable from v
      strongConnect(v)
    else
      -- get all scc of the map graph
      for node, _ in pairs(graph) do
        if nodeData[node] == nil then
          strongConnect(node)
        end
      end
    end
    return allSCC
  end
end

function Graphpath:getPath(start, goal, dirMult)
  local graph = self.graph
  if graph[start] == nil or graph[goal] == nil then return {} end

  local dirCoeff = {1, dirMult or 1}

  local q = minheap:new()
  local cost, t = 0, {start, false}
  local road = {} -- predecessor subgraph
  local queued = {}

  repeat
    local node = t[1]
    if road[node] == nil then
      road[node] = t[2]
      if node == goal then break end
      for child, data in pairs(graph[node]) do
        if road[child] == nil then
          local currentChildCost = queued[child]
          local newChildCost = cost + data[1] * dirCoeff[data[2]] -- data[2] equals either 1 (legal direction) or 2 (illegal direction).
          if currentChildCost == nil or currentChildCost > newChildCost then
            q:insert(newChildCost, {child, node})
            queued[child] = newChildCost
          end
        end
      end
    end
    cost, t = q:pop()
  until not cost

  return invertPath(goal, road)
end

function Graphpath:getFilteredPath(start, goal, cutOffDrivability, dirMult)
  local graph = self.graph
  if graph[start] == nil or graph[goal] == nil then return {} end

  local cutOffDrivability = cutOffDrivability or 0
  local dirCoeff = {1, dirMult or 1}

  local q = minheap:new()
  local cost, t = 0, {start, false}
  local road = {} -- predecessor subgraph
  local queued = {}

  repeat
    local node = t[1]
    if road[node] == nil then
      road[node] = t[2]
      if node == goal then break end
      for child, data in pairs(graph[node]) do
        if road[child] == nil then
          local currentChildCost = queued[child]
          local drivabilityPenalty = 1 / (max(0, fsign(data[3] - cutOffDrivability)) + 1e-4)
          local newChildCost = cost + data[1] * dirCoeff[data[2]] * drivabilityPenalty -- data[2] equals either 1 (legal direction) or 2 (illegal direction).
          if currentChildCost == nil or currentChildCost > newChildCost then
            q:insert(newChildCost, {child, node})
            queued[child] = newChildCost
          end
        end
      end
    end
    cost, t = q:pop()
  until not cost

  return invertPath(goal, road)
end

function Graphpath:spanMap(source, nodeBehind, target, edgeDict, dirMult)
  local graph = self.graph
  if graph[source] == nil or graph[target] == nil then return {} end

  local dirCoeff = {1, dirMult or 1}

  local q = minheap:new()
  local cost, t = 0, {source, false}
  local road = {} -- predecessor subgraph
  local queued = {}

  repeat
    local node = t[1]
    if road[node] == nil then
      road[node] = t[2]
      if node == target then break end
      for child, data in pairs(graph[node]) do
        if road[child] == nil then
          local currentChildCost = queued[child]
          local newChildCost = cost + data[1] * dirCoeff[data[2]] * (edgeDict[node..'\0'..child] or 1e20) * ((node == source and child == nodeBehind and 300) or 1)
          if currentChildCost == nil or currentChildCost > newChildCost then
            q:insert(newChildCost, {child, node})
            queued[child] = newChildCost
          end
        end
      end
    end
    cost, t = q:pop()
  until not cost

  return invertPath(target, road)
end

function Graphpath:getPathAwayFrom(start, goal, mePos, stayAwayPos, dirMult)
  local graph = self.graph
  if graph[start] == nil or graph[goal] == nil then return {} end

  local dirCoeff = {1, dirMult or 1}

  local positions = self.positions
  local q = minheap:new()
  local cost, t = 0, {start, false}
  local road = {} -- predecessor subgraph
  local queued = {}

  repeat
    local node = t[1]
    if road[node] == nil then
      road[node] = t[2]
      if node == goal then break end
      for child, data in pairs(graph[node]) do
        if road[child] == nil then
          local currentChildCost = queued[child]
          local childPos = positions[child]
          local newChildCost = cost + data[1] * dirCoeff[data[2]] * mePos:squaredDistance(childPos) / (stayAwayPos:squaredDistance(childPos) + 1e-30)
          if currentChildCost == nil or currentChildCost > newChildCost then
            q:insert(newChildCost, {child, node})
            queued[child] = newChildCost
          end
        end
      end
    end
    cost, t = q:pop()
  until not cost

  return invertPath(goal, road)
end

function Graphpath:getFleePath(source, ai, player, dirMult)
  local graph = self.graph
  if graph[source] == nil then return {} end

  local dirCoeff = {1, dirMult or 1} -- the higher dirMult the higher the penalty (i.e. harder) to choose an illegal path

  local positions = self.positions

  local q = minheap:new()
  local cost, t = 0, {source, false}
  local road = {} -- predecessor subgraph
  local augmentedDistance = {}
  local roadLen = {[source] = 0}

  local stayAwayPos = player.pos
  local playerDirVec = player.dirVec
  local mePos = ai.pos
  local ai2pLen = (stayAwayPos - mePos):length()

  local switch = max(fsign(ai2pLen / (max(player.vel:dot(ai.dirVec) - 6, 0) + 1e-30) - 3), 0) * max(fsign(250 - ai2pLen), 0) * max(fsign(ai2pLen - 20, 0))

  local target
  local minCost = math.huge

  repeat
    local node = t[1]
    if road[node] == nil then -- a node might have entered the que multiple times (the second and subsequent times it enterd the que with a lower cost value (a decrease key function has not been implemented))
      road[node] = t[2] -- parent of node
      if mePos:squaredDistance(positions[node]) <= 160000 or not t[2] then -- try with both road distance and radial distance (distance[node]). Second conditions covers the case of a first node being more than 300m away
        local rdLen2Node = roadLen[node]
        for child, data in pairs(graph[node]) do -- the "child" here is really a neighboor not a child
          if road[child] == nil then -- if the neighboor node hasn't already been poped from the que
            local childCurrCost = augmentedDistance[child] -- child node might have already entered the que through a different path
            local childPos = positions[child]
            local pl2childNd = childPos - stayAwayPos
            local me2ChildSqDist = mePos:squaredDistance(childPos)
            local dist = data[1] * dirCoeff[data[2]]

            local childNewCost = cost + dist * me2ChildSqDist /
                  ((stayAwayPos:squaredDistance(childPos) + 1e-30) *
                    (square(square(pl2childNd.x / playerDirVec.x - pl2childNd.y / playerDirVec.y)) + 1e-30)^switch)

            local normalizedCost = childNewCost / ((rdLen2Node + dist)^switch * math.sqrt(me2ChildSqDist)^(1-switch) + 1e-30)

            if (childCurrCost == nil or childCurrCost > childNewCost) and normalizedCost < minCost then -- childCurrCost == nil means child has not yet gone into cue
              augmentedDistance[child] = childNewCost
              roadLen[child] = roadLen[node] + dist
              q:insert(childNewCost, {child, node})
            end
          end
        end
      else
        local normalizedCost = augmentedDistance[node] / (roadLen[node]^switch * mePos:distance(positions[node])^(1-switch) + 1e-30) -- if the popped node is at a distance greater than x meters from the source do not explore it but put it in the choiceSet.
        if normalizedCost < minCost then
          minCost = normalizedCost
          target = node
        end
      end
    end
    cost, t = q:pop()
  until not cost
  return invertPath(target, road)
end

-- produces a random path with a bias towards edge coliniarity
function Graphpath:getRandomPath(nodeAhead, nodeBehind, dirMult)
  local graph = self.graph
  if graph[nodeAhead] == nil or graph[nodeBehind] == nil then return {} end

  local dirCoeff = {1, dirMult or 1}

  local positions = self.positions
  local sourceNodePos = positions[nodeAhead]

  local q = minheap:new()
  local cost, t = 0, {nodeAhead, false}
  local road = {} -- predecessor subgraph
  local queued = {}
  local node
  local choiceSet = {}
  local costSum = 0
  local pathLength = {[nodeBehind] = 0}

  repeat
    if road[t[1]] == nil then
      node = t[1]
      local parent = t[2] or nodeBehind
      road[node] = t[2]
      pathLength[node] = pathLength[parent] + (positions[node] - positions[parent]):length()
      if pathLength[node] <= 300 or not t[2] then
        local nodePos = positions[node]
        local edgeDirVec = (positions[parent] - nodePos):normalized()
        for child, data in pairs(graph[node]) do
          if road[child] == nil then
            local childCurrCost = queued[child]
            local penalty = 1 + 10 * square(max(0, edgeDirVec:dot((positions[child] - nodePos):normalized()) - 0.2))
            local childNewCost = cost + penalty * data[1] * dirCoeff[data[2]] * ((node == nodeAhead and child == nodeBehind) and 1e4 or 1)
            if childCurrCost == nil or childCurrCost > childNewCost then
              queued[child] = childNewCost
              q:insert(childNewCost, {child, node})
            end
          end
        end
      else
        tableInsert(choiceSet, {node, square(1/cost)})
        costSum = costSum + square(1/cost)
        if #choiceSet == 5 then
          break
        end
      end
    end
    cost, t = q:pop()
  until not cost

  local randNum = costSum * math.random()
  local runningSum = 0

  for i = 1, #choiceSet do
    local newRunningSum = choiceSet[i][2] + runningSum
    if runningSum <= randNum and randNum <= newRunningSum then
      node = choiceSet[i][1]
      break
    end
    runningSum = newRunningSum
  end

  return invertPath(node, road)
end

-- public interface
M.newGraphpath = newGraphpath
return M