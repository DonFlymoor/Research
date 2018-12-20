-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'imguiUtils'

local imgui = ui_imgui

local mousePos = ffi.new('ImVec2[1]')
local style = ffi.new('ImGuiStyle[1]')

function M.texObj(path)
  local res = {}
  res.file = string.match(path, "^.+/(.+)$")
  res.path = path
  res.tex = imgui.ImTextureHandler(path)
  res.texId = res.tex:getID()
  res.size = res.tex:getSize()
  return res
end

function M.DropdownItem(label, icon, func)
  local item = {}
  item.label = label
  item.icon = icon
  item.func = func
  return item
end

function M.DropdownSelectableItem(label, active, func)
  local item = {}
  item.label = label
  item.active = active
  item.func = func
  return item
end

function M.DropdownButton(label, size, items, icon, horizontal)
  local x = imgui.GetCursorPosX()
  local y = imgui.GetCursorPosY()
  local open_popup
  if not icon then
    open_popup = imgui.Button(label, size)
  else
    open_popup = editor.uiIconImageButton(icon, size, nil, nil, nil, label)
  end

  if #items == 0 then return end

  local windowPos = ffi.new("ImVec2[1]")
  imgui.GetWindowPos(windowPos)
  local popupPos = imgui.ImVec2(0,0)
  if not horizontal then
    popupPos.x = x + windowPos[0].x - 8
    popupPos.y = y + windowPos[0].y + size.y + 4
  else
    popupPos.x = x + windowPos[0].x + size.x + 4
    popupPos.y = y + windowPos[0].y - 8
  end

  if open_popup == true then
    imgui.OpenPopup(label)
    return true
  end
  imgui.SetNextWindowPos(popupPos)
  if not horizontal then
    imgui.SetNextWindowSize(imgui.ImVec2(size.x+16,#items*size.y+16+(#items-1)*4))
  else
    imgui.SetNextWindowSize(imgui.ImVec2(#items*size.x+16+(#items-1)*8, size.y+16))
  end
  if imgui.BeginPopup(label) then
    for k, item in pairs(items) do
      local lbl = item.label .. "###" .. label .. tostring(k)
      if not item.icon then
        if imgui.Button(lbl, size) then
          item.func()
          imgui.CloseCurrentPopup()
        end
      else
        if editor.uiIconImageButton(item.icon, imgui.ImVec2(size.x-2, size.y-2), nil, nil, nil, lbl) then
          item.func()
          imgui.CloseCurrentPopup()
        end
      end
      if horizontal then imgui.SameLine() end
    end
    imgui.EndPopup()
  end
  return false
end

-- imguiUtils.DropdownSelectable("FileTypeDropdown", fileTypes, editor.icons.widgets, im.ImVec2(16,16), 90, applyFilesFilter, "Filter by type", {{},{},{}})
function M.DropdownSelectable(label, items, icon, iconSize, popupWidth, onChangeFunc, tooltip, itemsRMB)
  local x = imgui.GetCursorPosX()
  local y = imgui.GetCursorPosY()
  local open_popup
  local open_popup_rmb

  if not icon then
    open_popup = imgui.SmallButton(label)
  else
    open_popup = editor.uiIconImageButton(icon, iconSize, nil, nil, nil, label)
  end
  if itemsRMB and imgui.IsItemClicked(1) then
    open_popup_rmb = true
  end
  if tooltip then imgui.tooltip(tooltip) end

  if #items == 0 then return end

  local fontSize = imgui.GetFontSize()
  -- hardcoded for the time being
  -- 2 * (padding to border + border) + #items * (fontsize + item padding)
  local popupHeight = 2 * (5 + 1) + #items * 17
  local popupRMBHeight = 2 * (5 + 1) + #itemsRMB * 17


  local windowPos = ffi.new("ImVec2[1]")
  imgui.GetWindowPos(windowPos)
  local popupPos = imgui.ImVec2(0,0)

  popupPos.x = x + windowPos[0].x
  popupPos.y = y + windowPos[0].y + iconSize.y

  if open_popup == true then
    imgui.OpenPopup(label)
    return true
  end

  imgui.SetNextWindowPos(popupPos)
  imgui.SetNextWindowSize(imgui.ImVec2(popupWidth or 120, popupHeight))
  if imgui.BeginPopup(label) then
    for k, item in pairs(items) do
      local curX = imgui.GetCursorPosX()
      if item.active[0] == true then
        editor.uiIconImage(editor.icons.done, imgui.ImVec2(fontSize, fontSize))
        imgui.SameLine()
      end
      imgui.SetCursorPosX(curX + 20)
      if imgui.Selectable1(item.label .. "##", nil, imgui.ImGuiSelectableFlags_DontClosePopups) then
        if item.active[0] == true then item.active[0] = false else item.active[0] = true end
        if onChangeFunc then onChangeFunc(item) end
        if item.func then item.func(item) end
      end
    end
    imgui.EndPopup()
  end

  if open_popup_rmb == true then
    print("DSADSA")
    imgui.OpenPopup(label.."rmb")
  end

  imgui.SetNextWindowPos(popupPos)
  imgui.SetNextWindowSize(imgui.ImVec2(popupWidth or 120, popupRMBHeight))
  if imgui.BeginPopup(label.."rmb") then
    for k, item in pairs(itemsRMB) do
      if imgui.SmallButton(item.label.."##") then
        if item.func then item.func(item.args) end
        imgui.CloseCurrentPopup()
      end
    end
    imgui.EndPopup()
  end
  return false
end

function M.DropdownSelect(label, size, selectedItem, items, horizontal, excludeCurrent)
  local x = imgui.GetCursorPosX()
  local y = imgui.GetCursorPosY()
  local open_popup
  local curItem = items[selectedItem[0]]
  if not curItem.icon then
    open_popup = imgui.Button(curItem.label, size)
  else
    open_popup = editor.uiIconImageButton(curItem.icon, size, nil, nil, nil, curItem.label)
  end

  local windowPos = ffi.new("ImVec2[1]")
  imgui.GetWindowPos(windowPos)
  local popupPos = imgui.ImVec2(0,0)
  if not horizontal then
    popupPos.x = x + windowPos[0].x - 8
    popupPos.y = y + windowPos[0].y + size.y + 4
  else
    popupPos.x = x + windowPos[0].x + size.x + 4
    popupPos.y = y + windowPos[0].y - 8
  end

  if open_popup == true then
    imgui.OpenPopup(label)
    return true
  end
  imgui.SetNextWindowPos(popupPos)
  if not horizontal then
    if excludeCurrent then
      imgui.SetNextWindowSize(imgui.ImVec2(size.x+16,(#items-1)*size.y+16+(#items-2)*4))
    else
      imgui.SetNextWindowSize(imgui.ImVec2(size.x+16,#items*size.y+16+(#items-1)*4))
    end
  else
    if excludeCurrent then
      imgui.SetNextWindowSize(imgui.ImVec2((#items-1)*size.x+16+(#items-2)*8, size.y+16))
    else
      imgui.SetNextWindowSize(imgui.ImVec2(#items*size.x+16+(#items-1)*8, size.y+16))
    end
  end
  if imgui.BeginPopup(label) then
    for k, item in pairs(items) do
      if excludeCurrent then
        if k ~= selectedItem[0] then
          local lbl = item.label .. "###" .. label .. tostring(k)
          if not item.icon then
            if imgui.Button(lbl, size) then
              selectedItem[0] = k
              item.func()
              imgui.CloseCurrentPopup()
            end
            imgui.tooltip(item.label)
          else
            if editor.uiIconImageButton(item.icon, imgui.ImVec2(size.x-2, size.y-2), nil, nil, nil, lbl) then
              selectedItem[0] = k
              item.func()
              imgui.CloseCurrentPopup()
            end
            imgui.tooltip(item.label)
          end
          if horizontal then imgui.SameLine() end
        end
      else
        local lbl = item.label .. "###" .. label .. tostring(k)
        if not item.icon then
          if imgui.Button(lbl, size) then
            selectedItem[0] = k
            item.func()
            imgui.CloseCurrentPopup()
          end
          imgui.tooltip(item.label)
        else
          if editor.uiIconImageButton(item.icon, imgui.ImVec2(size.x-2, size.y-2), nil, nil, nil, lbl) then
            selectedItem[0] = k
            item.func()
            imgui.CloseCurrentPopup()
          end
          imgui.tooltip(item.label)
        end
        if horizontal then imgui.SameLine() end
      end
    end
    imgui.EndPopup()
  end
  return false
end

-- check if a window with given pos and size is hovered
-- local windowPos = ffi.new('ImVec2[1]')
-- local windowSize = ffi.new('ImVec2[1]')
-- im.GetWindowPos(windowPos)
-- im.GetWindowSize(windowSize)
function M.IsWindowHovered(windowPos, windowSize)
  imgui.GetMousePos(mousePos)
  if (mousePos[0].x > windowPos[0].x and mousePos[0].x < (windowPos[0].x + windowSize[0].x)) and (mousePos[0].y > windowPos[0].y and mousePos[0].y < (windowPos[0].y + windowSize[0].y)) then
    return true
  else
    return false
  end
end

-- displays key/values aof a lua table
function M.displayKeyValues(tbl)
  if tbl then
    for k,v in pairs(tbl) do
      if type(v) ~= 'table' then
        imgui.Text(tostring(k) .. ' :')
        imgui.SameLine()
        imgui.Text(tostring(v))
        -- imgui.Separator()
      else
        if imgui.TreeNode1(tostring(k)) then
          M.displayKeyValues(v)
          imgui.TreePop()
        end
      end
    end
  end
end

-- Creates a simple Key/Value app with a lua table
function M.CreateKeyValApp( window, section, tbl, callback )
  if imgui.Begin(window, imgui.BoolPtr(true), 0) then
    if imgui.TreeNode1(section) then
      -- call callback function when TreeNode is open
      if callback then callback() end
      M.displayKeyValues(tbl)
      imgui.TreePop()
    end
  end
end

local function itemCallback(begin, fullpath, k, val)
  if type(val) ~= 'table' then return end
  if begin then
    if val.active then
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.5, 1, 0.5, 1))
    else
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.6, 0.6, 0.6, 1))
    end
  else
    imgui.PopStyleColor()
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
  imgui.Columns(2, tostring(k))
  --imgui.SetColumnOffset(-1, 40)
  for _, k in ipairs(sortedKeys) do
    local val = data[k]
    local display = true
    local newPath = fullpath .. '/' .. tostring(k)

    if itemCallback then display = itemCallback(true, newPath, k, val) end

    if display then
      imgui.Text(tostring(k))
      imgui.NextColumn()
      M.addRecursiveTreeTable(val, newPath, true, highlightCallback, itemCallback)
      imgui.NextColumn()
    end

    if itemCallback then itemCallback(false, newPath, k, val) end

  end
  imgui.Columns(1)
end

local function renderSubTree(data, fullpath, highlightCallback, itemCallback)

  local sortedKeys = getTableKeysSorted(data)

  for _, k in ipairs(sortedKeys) do
    local val = data[k]
    local display = true
    local newPath = fullpath .. '/' .. tostring(k)

    if itemCallback then display = itemCallback(true, newPath, k, val) end

    if display then
      if imgui.TreeNode2(newPath, tostring(k)) then
        M.addRecursiveTreeTable(val, newPath, noColumns, highlightCallback, itemCallback)
        imgui.TreePop()
      end
      if highlightCallback and imgui.IsItemHovered() then
        highlightCallback(newPath, k, val)
      end
    end

    if itemCallback then itemCallback(false, newPath, k, val) end
  end
end
--[[
Returns the name and the value of the local variable with index local of the function
]]
local function getlocal(func)
  local index = 2
  local param = debug.getlocal( func, 1 )
  if not param then
    imgui.Text('NIL')
    return
  end
  while param ~= nil do
    imgui.Text(tostring(param))
    param = debug.getlocal( func, index )
    index = index + 1
  end

end
function M.addRecursiveTreeTable(data, fullpath, noColumns, highlightCallback, itemCallback)
  local _, level = string.gsub(fullpath, "%/", "")
  if type(data) == 'table' then
    local tsize = tableSize(data)
    if tsize == 0 then
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 0.7, 0.7, 1))
      imgui.Text('{empty}')
      imgui.PopStyleColor()
    else
      if testTableRecursive(data) or noColumns then
        if level > 2 and tsize > 3 then
          if imgui.CollapsingHeader1(tostring(tsize)..' items##' .. fullpath) then
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
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 1, 0.7, 1))
    else
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(1, 0.7, 0.7, 1))
    end
    imgui.Text(tostring(data))
    imgui.PopStyleColor()

  elseif type(data) == 'number' then
    imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 0.7, 1, 1))
    imgui.Text(tostring(data))
    imgui.PopStyleColor()

  elseif type(data) == 'string' then
    if string.len(data) == 0 then
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 0.7, 0.7, 1))
      imgui.Text('{empty string}')
      imgui.PopStyleColor()
    else
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(1, 0.7, 1, 1))
      imgui.Text(tostring(data))
      imgui.PopStyleColor()
    end

  elseif type(data) == 'userdata' then
    -- implement some LuaIntF types
    local ctype = getmetatable(data).___type
    ctype = string.match(ctype, "class<([^>]*)>")
    if ctype == 'float3' then
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 1, 1, 1))
      imgui.Text(string.format('float3(%g,%g,%g)', data.x, data.y, data.z))
      imgui.PopStyleColor()
    else
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 0.8, 0.5, 1))
      imgui.Text('class instance: ' .. tostring(ctype))
      imgui.PopStyleColor()
    end
  elseif type(data) == 'function' then
      imgui.PushStyleColor2(imgui.Col_Text, imgui.ImVec4(0.7, 0.6, 0.4, 1))
      getlocal(data)
      imgui.PopStyleColor()
  else
    imgui.Text(tostring(data))
  end
end

function M.cell(a, b)
  imgui.Text(a)
  imgui.NextColumn()
  imgui.Text(b)
  imgui.NextColumn()
end

return M