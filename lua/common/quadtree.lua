-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- Description
-- The following module implements a quadtree data structure with insert, remove and query and compress facilities.
-- The Query function is remove-safe i.e. if an item is removed while a query is active, query is not affected.

-- Variable qt is a table and a sequence (number indexed array with no holes).
-- The table part contains the tree canvas size data (tree bounding box). Each array entry is a tree node (root node is index 1 i.e. self[1] is root node).
-- Each tree node is itself a table and a sequence. The table part contains the index of the "first" child node of the particular node (i.e self[node_i].children is the index, in the tree array, of the "first")
-- and the array part contains every item (item id, and bounding box data) "stored" in the particular node (self[node_i][item_i] = {itm_id, itm_xmin, itm_xmax, itm_ymin, itm_ymax})

-- Additions with this version (20/04/2016) - A compress function has been added. See below for usage. This function affects none of the previous functionality.

--[[ Usage
  q = newQuadtree() -- initialize a new empty quadtree

  -- Preload items.

  for (items in list) do
    q:preLoad(itm_id, itm_xmin, itm_ymin, itm_xmax, itm_ymax)
  end

  -- The build function calculates the tree canvas bounds from the preloaded items and inserts them in the tree.
  -- After a tree build, the canvas size does not change.
  -- Items outside the bounds of the canvas can still be inserted/removed in/from the tree as per usual (without affecting canvas bounds). Query will also work correctly.
  -- Argument max_depth is optional and defaults to 10 (root node is at depth zero). Max depth is implemented with y_size limit on item size
  -- Expect a +/-1 margin on the max_depth value that is passed.

  q:build(max_depth)

  -- The q:compress function can be optionally used to optimize memory usage after a build.
  -- Item insertions after a compress call on the quadtree might be slower.

  q:compress()

  -- Insert (additional items) or remove items from the tree.

  q:insert(itm_id, itm_xmin, itm_ymin, itm_xmax, itm_ymax)
  q:remove(itm_id, itm_x, itm_y) -- where itm_x and itm_y is the item center

  -- The query function returns an iterator.

  for item_id in q:query(query_xmin, query_ymin, query_xmax, query_ymax) do
    -- do something with item_id --
  end

  Example: Create table containing all item_ids of items in a query area
  for item_id in q:query(query_xmin, query_ymin, query_xmax, query_ymax) do table.insert(results, item_id) end
--]]

local M = {}
-- Cache often-used functions from other modules in upvalues
local max = math.max
local min = math.min
local tableInsert = table.insert

local quadTree = {}
quadTree.__index = quadTree

local ok, _ = pcall(require, "table.new")
if not ok then
  table.new = function() return {} end
end

local function pointBBox(x, y, radius)
  return x - radius, y - radius, x + radius, y + radius
end

local function lineBBox(x1, y1, x2, y2, radius)
  local enlarge = radius or 0
  return min(x1, x2) - enlarge, min(y1, y2) - enlarge, max(x1, x2) + enlarge, max(y1, y2) + enlarge
end

local function newQuadtree()
  local qt = {itm_preld = {len = 0}, min_ysize = nil, xmin = nil, xmax = nil, ymin = nil, ymax = nil}
  setmetatable(qt, quadTree)
  return qt
end

function quadTree:preLoad(itm_id, itm_xmin, itm_ymin, itm_xmax, itm_ymax)
  local len = self.itm_preld.len + 1
  self.itm_preld.len = len
  self.itm_preld[len] = {itm_id, itm_xmin, itm_xmax, itm_ymin, itm_ymax}
end

local function createChildNodes(self, node_i)
  local scount = #self + 1
  self[node_i].children = scount
  self[scount] = {children = -10}
  self[scount + 1] = {children = -10}
  self[scount + 2] = {children = -10}
  self[scount + 3] = {children = -10}
end

function quadTree:insert(itm_id, itm_xmin, itm_ymin, itm_xmax, itm_ymax)
  local node_i = 1
  local node_xmin = self.xmin
  local node_xmax = self.xmax
  local node_ymin = self.ymin
  local node_ymax = self.ymax
  local cup_itm_ymax = max(min(itm_ymax, node_ymax), node_ymin)
  local cup_itm_ymin = min(max(itm_ymin, node_ymin), node_ymax )
  local diff_ysize = (self.min_ysize - (cup_itm_ymax - cup_itm_ymin)) * 0.5
  local phantom_ymax = max(cup_itm_ymax + diff_ysize , cup_itm_ymax)
  local phantom_ymin = min(cup_itm_ymin - diff_ysize , cup_itm_ymin)
  repeat -- this is O(D) complexity where D is the depth of the tree.
    local node_xmid = (node_xmin + node_xmax) * 0.5
    local node_ymid = (node_ymin + node_ymax) * 0.5
    if phantom_ymax <= node_ymid then -- check if item is contained in lower half space
      if itm_xmax <= node_xmid then -- check if item is contained in left half space
        if self[node_i].children <= 0 then createChildNodes(self, node_i) end
        node_i = self[node_i].children
        node_xmax = node_xmid
        node_ymax = node_ymid
      elseif itm_xmin >= node_xmid then -- check if item is contained in right half space
        if self[node_i].children <= 0 then createChildNodes(self, node_i) end
        node_i = self[node_i].children + 1
        node_xmin = node_xmid
        node_ymax = node_ymid
      else -- item is not contained in either left or right half spaces
        tableInsert(self[node_i], {itm_id, itm_xmin, itm_xmax, itm_ymin, itm_ymax})
        return
      end
    elseif phantom_ymin >= node_ymid then -- check if item is contained in upper half space
      if itm_xmin >= node_xmid then -- check if item is contained in right half space
        if self[node_i].children <= 0 then createChildNodes(self, node_i) end
        node_i = self[node_i].children + 2
        node_xmin = node_xmid
        node_ymin = node_ymid
      elseif itm_xmax <= node_xmid then -- check if item is contained in left half space
        if self[node_i].children <= 0 then createChildNodes(self, node_i) end
        node_i = self[node_i].children + 3
        node_xmax = node_xmid
        node_ymin = node_ymid
      else -- item is not contained in either left or right half spaces
        tableInsert(self[node_i], {itm_id, itm_xmin, itm_xmax, itm_ymin, itm_ymax} )
        return
      end
    else -- item is not contained in either upper or lower half spaces
      tableInsert(self[node_i], {itm_id, itm_xmin, itm_xmax, itm_ymin, itm_ymax})
      return
    end
  until false
end

function quadTree:remove(itm_id, itm_x, itm_y)
  local node_i = 1
  local node_xmin = self.xmin
  local node_xmax = self.xmax
  local node_ymin = self.ymin
  local node_ymax = self.ymax
  repeat -- This is worst case O(D*N) complexity where D is the tree depth and N is the total number of items in the tree
    local node_iLen = #self[node_i] -- this is the number of items in node_i
    for j = 1, node_iLen do -- removes an item from a node without affecting query traversal of given node's item list
      local itemData = self[node_i][j]
      if itemData[1] == itm_id and square((itemData[2] + itemData[3]) * 0.5 - itm_x) + square((itemData[4] + itemData[5]) * 0.5 - itm_y) < 1e-8 then
        local tmp_items = table.new(node_iLen, 1)
        local itemsNode_i = self[node_i]
        for i = 1, j-1 do tmp_items[i] = itemsNode_i[i] end
        for i = j+1, node_iLen do tmp_items[i-1] = itemsNode_i[i] end
        tmp_items.children = itemsNode_i.children
        self[node_i] = tmp_items
        return
      end
    end

    local node_xmid = (node_xmin + node_xmax) * 0.5
    local node_ymid = (node_ymin + node_ymax) * 0.5
    if itm_y <= node_ymid then -- check if item center is in the lower half space
      if itm_x <= node_xmid then -- check if item center is in left half space
        node_i = self[node_i].children
        node_xmax = node_xmid
        node_ymax = node_ymid
      else -- if item is not in parent node and item center is in the lower half space but not in the left half space then it must be within the lower right quad.
        node_i = self[node_i].children + 1
        node_xmin = node_xmid
        node_ymax = node_ymid
      end
    else
      if itm_x >= node_xmid  then -- check if item is contained in right half space
        node_i = self[node_i].children + 2
        node_xmin = node_xmid
        node_ymin = node_ymid
      else -- check if item is contained in right half space
        node_i = self[node_i].children + 3
        node_xmax = node_xmid
        node_ymin = node_ymid
      end
    end
  until node_i < 1 -- nodes with no children have "node.children = -10"
end

function quadTree:build(max_depth)
  local canvas_xmin = math.huge
  local canvas_xmax = -math.huge
  local canvas_ymin = math.huge
  local canvas_ymax = -math.huge
  local itm_preld = self.itm_preld
  self.itm_preld = nil
  for i = 1, itm_preld.len do
    canvas_xmin = min(canvas_xmin, itm_preld[i][2])
    canvas_xmax = max(canvas_xmax, itm_preld[i][3])
    canvas_ymin = min(canvas_ymin, itm_preld[i][4])
    canvas_ymax = max(canvas_ymax, itm_preld[i][5])
  end
  self.xmin = canvas_xmin
  self.xmax = canvas_xmax
  self.ymin = canvas_ymin
  self.ymax = canvas_ymax
  self[1] = {children = -10} -- create root node
  self.min_ysize = (canvas_ymax - canvas_ymin) * 0.5^((max_depth or 10) + 1) -- calculates min quad y-size based on tree max_depth
  for i = 1, itm_preld.len do
    self:insert(itm_preld[i][1], itm_preld[i][2], itm_preld[i][4], itm_preld[i][3], itm_preld[i][5])
  end
end

function quadTree:query(query_xmin, query_ymin, query_xmax, query_ymax)
  local stack = {}
  local stackidx = 1
  local node = {1, self.xmin, self.xmax, self.ymin, self.ymax}
  local itm_in_node = self[node[1]] -- list of items in a given node
  local i = 1
  local function query_it()
    repeat
      local item = itm_in_node[i]
      if item then
        i = i + 1
        if query_xmin <= item[3] and query_xmax >= item[2] and query_ymin <= item[5] and query_ymax >= item[4] then -- check if item intersects query bounds
          return item[1]
        end
      else -- if there are no more items in the current node's items list, find a new node get it's items and continue
        local children = self[node[1]].children
        if children > 0 then
          local node_xmid = (node[2] + node[3]) * 0.5
          local node_ymid = (node[4] + node[5]) * 0.5
          if node_ymid >= query_ymin then
            if node_xmid >= query_xmin and (#self[children] > 0 or self[children].children > 0) then
              stack[stackidx] = {children, node[2], node_xmid, node[4], node_ymid}
              stackidx = stackidx + 1
            end
            if node_xmid <= query_xmax and (#self[children + 1] > 0 or self[children + 1].children > 0) then
              stack[stackidx] = {children + 1, node_xmid, node[3], node[4], node_ymid}
              stackidx = stackidx + 1
            end
          end
          if node_ymid <= query_ymax then
            if node_xmid <= query_xmax and (#self[children + 2] > 0 or self[children + 2].children > 0) then
              stack[stackidx] = {children + 2, node_xmid, node[3], node_ymid, node[5]}
              stackidx = stackidx + 1
            end
            if node_xmid >= query_xmin and (#self[children + 3] > 0 or self[children + 3].children > 0) then
              stack[stackidx] = {children + 3, node[2], node_xmid, node_ymid, node[5]}
              stackidx = stackidx + 1
            end
          end
        end
        stackidx = stackidx - 1
        node = stack[stackidx] or {}
        itm_in_node = self[node[1]]
        i = 1
      end
    until not itm_in_node
    return nil
  end
  return query_it
end

function quadTree:compress()
  -- O(n + N) complexity. n = # of tree nodes, N = total # of items in tree
  for node = 1, #self do
    local tmp = table.new(#self[node], 1)
    tmp.children = self[node].children
    for i = 1, #self[node] do
      tmp[i] = self[node][i]
    end
    self[node] = tmp
  end
  collectgarbage()
end

M.newQuadtree = newQuadtree
M.pointBBox = pointBBox
M.lineBBox = lineBBox
return M