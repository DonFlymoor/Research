-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local ffi = require('ffi')
local im = extensions.ui_imgui


local function itemCallback(begin, fullpath, k, val)
  if type(val) ~= 'table' then return end
  if begin then
    if val.active then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
    else
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
    end
  else
    im.PopStyleColor()
  end
  return true
end

local function testTableRecursive(t)
  local primaryType = 0
  local tableType = 0
  for _, tv in pairs(t) do
    if type(tv) == 'table' then
      tableType = tableType + 1
    else
      primaryType = primaryType + 1
    end
  end
  return tableType > primaryType
end

local function getTableKeysSorted(t)
  local sortedKeys = {}
  for k in pairs(t) do table.insert(sortedKeys, k) end
  table.sort(sortedKeys)
  return sortedKeys
end

function M.keyValueTable(data, fullpath, highlightCallback, itemCallback)
  local sortedKeys = getTableKeysSorted(data)

  -- key value table for simplicity
  im.Columns(2, tostring(k))
  --im.SetColumnOffset(-1, 40)
  for _, k in ipairs(sortedKeys) do
    local val = data[k]
    local display = true
    local newPath = fullpath .. '/' .. tostring(k)

    if itemCallback then display = itemCallback(true, newPath, k, val) end

    if display then
      im.Text(tostring(k))
      im.NextColumn()
      M.addRecursiveTreeTable(val, newPath, true, highlightCallback, itemCallback)
      im.NextColumn()
    end

    if itemCallback then itemCallback(false, newPath, k, val) end

  end
  im.Columns(1)
end

local function renderSubTree(data, fullpath, highlightCallback, itemCallback)

  local sortedKeys = getTableKeysSorted(data)

  for _, k in ipairs(sortedKeys) do
    local val = data[k]
    local display = true
    local newPath = fullpath .. '/' .. tostring(k)

    if itemCallback then display = itemCallback(true, newPath, k, val) end

    if display then
      if im.TreeNode2(newPath, tostring(k)) then
        M.addRecursiveTreeTable(val, newPath, noColumns, highlightCallback, itemCallback)
        im.TreePop()
      end
      if highlightCallback and im.IsItemHovered() then
        highlightCallback(newPath, k, val)
      end
    end

    if itemCallback then itemCallback(false, newPath, k, val) end
  end
end

function M.addRecursiveTreeTable(data, fullpath, noColumns, highlightCallback, itemCallback)
  local _, level = string.gsub(fullpath, "%/", "")

  if type(data) == 'table' then
    local tsize = tableSize(data)
    if tsize == 0 then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 0.7, 0.7, 1))
      im.Text('{empty}')
      im.PopStyleColor()
    else
      if testTableRecursive(data) or noColumns then
        if level > 2 and tsize > 3 then
          if im.CollapsingHeader1(tostring(tsize)..' items##' .. fullpath) then
            renderSubTree(data, fullpath, highlightCallback, itemCallback)
          end
        else
          renderSubTree(data, fullpath, highlightCallback, itemCallback)
        end
      else
        M.keyValueTable(data, fullpath, highlightCallback, itemCallback)
      end
    end

  elseif type(data) == 'boolean' then
    if data then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 1, 0.7, 1))
    else
      im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 0.7, 0.7, 1))
    end
    im.Text(tostring(data))
    im.PopStyleColor()

  elseif type(data) == 'number' then
    im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 0.7, 1, 1))
    im.Text(tostring(data))
    im.PopStyleColor()

  elseif type(data) == 'string' then
    if string.len(data) == 0 then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 0.7, 0.7, 1))
      im.Text('{empty string}')
      im.PopStyleColor()
    else
      im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 0.7, 1, 1))
      im.Text(tostring(data))
      im.PopStyleColor()
    end

  elseif type(data) == 'userdata' then
    -- implement some LuaIntF types
    local ctype = getmetatable(data).___type
    ctype = string.match(ctype, "class<([^>]*)>")
    if ctype == 'float3' then
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 1, 1, 1))
      im.Text(string.format('float3(%g,%g,%g)', data.x, data.y, data.z))
      im.PopStyleColor()
    else
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.7, 0.8, 0.5, 1))
      im.Text('class instance: ' .. tostring(ctype))
      im.PopStyleColor()
    end

  else
    im.Text(tostring(data))
  end
end

function M.cell(a, b)
  im.Text(a)
  im.NextColumn()
  im.Text(b)
  im.NextColumn()
end



return M
