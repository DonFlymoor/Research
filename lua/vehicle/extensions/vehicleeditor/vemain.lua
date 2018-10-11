-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local ffi = require('ffi')

extensions.load('core_imgui')
local c = core_imgui

local data_window_open = ffi.new("bool[1]", false)
local console_window_open = ffi.new("bool[1]", false)
local parts_window_open = ffi.new("bool[1]", false)
local nodeinspect_window_open = ffi.new("bool[1]", false)


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

local function addRecursiveTreeTable(data, fullpath, noColumns, highlightCallback, itemCallback)
  if type(data) == 'table' then
    if tableSize(data) == 0 then
      c.Text('{empty}')
    else
      local sortedKeys = {}
      for k in pairs(data) do table.insert(sortedKeys, k) end

      table.sort(sortedKeys)
      if testTableRecursive(data) or noColumns then
        -- normal tree node
        for _, k in ipairs(sortedKeys) do
          local val = data[k]
          if itemCallback then itemCallback(true, fullpath, k, val) end
          local newPath = fullpath .. '/' .. tostring(k)
          if c.TreeNode2(newPath, tostring(k)) then
            addRecursiveTreeTable(val, newPath, noColumns, highlightCallback, itemCallback)
            c.TreePop()
          end
          if highlightCallback and c.IsItemHovered() then
            highlightCallback(fullpath, k, val)
          end
          if itemCallback then itemCallback(false, fullpath, k, val) end
        end
      else
        -- key value table for simplicity
        c.Columns(2, tostring(k))
        --c.SetColumnOffset(-1, 40)
        for _, k in ipairs(sortedKeys) do
          local val = data[k]
          if itemCallback then itemCallback(true, fullpath, k, val) end
          c.Text(tostring(k))
          c.NextColumn()
          addRecursiveTreeTable(val, fullpath .. '/' .. tostring(k), true, highlightCallback, itemCallback)
          c.NextColumn()
          if itemCallback then itemCallback(false, fullpath, k, val) end
        end
        c.Columns(1)
      end
    end
  else
    c.Text(tostring(data))
  end
  --c.Separator()
end

local function renderDataWindow()

  local function datahighlightcb(fullpath, k, val)
    if fullpath == '/beams' then
      obj.debugDrawProxy:drawBeam3d(val.cid, 0.1, color(255,0,0,255))
    elseif fullpath == '/nodes' then
      obj.debugDrawProxy:drawNodeSphere(val.cid, 0.1, color(255,0,0,255))
    else
      --print('hovered item: ' .. tostring(k) .. ' , path: ' .. tostring(fullpath))
    end
  end


  if c.Begin("VehicleData", data_window_open, 0) then
    addRecursiveTreeTable(v.data, '', false, datahighlightcb)
  end
  c.End()
end

local console_log_buffer = {}
local consoleInputField = ffi.new("char[4096]", "print(v.data.information.authors)")
local function renderConsoleWindow()
  if c.Begin("Console", console_window_open, 0) then
    c.BeginChild("result", c.ImVec2(0, -c.GetTextLineHeight() * 2))
      for _, le in ipairs(console_log_buffer) do
        if le[1] == 'i' then
          c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(0.8, 0.8, 0.8, 1))
        elseif le[1] == 'r' then
          c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(0.5, 1, 0.5, 1))
        elseif le[1] == 'o' then
          c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(0.5, 0.5, 1, 1))
        else
          c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(1, 1, 1, 1))
        end
        c.TextUnformatted(le[2])
        c.PopStyleColor()
      end
      c.SetScrollHere(1) -- scroll to the bottom always
    c.EndChild()
    local flags = 0
    flags = bit.bor(flags, c.ImGuiInputTextFlags('ImGuiInputTextFlags_EnterReturnsTrue'))
    -- FIXME:
    --flags = bit.bor(flags, c.ImGuiInputTextFlags('ImGuiInputTextFlags_CallbackCompletion'))
    --flags = bit.bor(flags, c.ImGuiInputTextFlags('ImGuiInputTextFlags_CallbackHistory'))

    local reclaimFocus = false
    if c.InputText("execute", consoleInputField, ffi.sizeof(consoleInputField), flags) then
      local cmd = ffi.string(consoleInputField)
      --print(" CMD = " .. tostring(cmd))
      table.insert(console_log_buffer, {'i', "> " .. tostring(cmd)})
      local res, out = executeLuaSandboxed(cmd, 'VEConsole')
      --print(" RES = " .. tostring(res))
      --print(" OUT = " .. dumps(out))
      if res then
        table.insert(console_log_buffer, {'r', tostring(res)})
      end
      if out and #out > 0 then
        for _, le in ipairs(out) do
          table.insert(console_log_buffer, {'o', tostring(le)})
        end
      end
      ffi.fill(consoleInputField, ffi.sizeof(consoleInputField))
      reclaimFocus = true
    end

    c.SetItemDefaultFocus()
    if reclaimFocus then c.SetKeyboardFocusHere(-1) end
  end

  c.End()
end

local function renderPartsWindow()

  local function partshighlightcb(fullpath, k, val)
    if type(val) == 'table' and val.partName then
      partmgmt.selectPart(val.partName, true)
    end
    --print('hovered item: ' .. tostring(k) .. ' , path: ' .. tostring(fullpath))
  end

  local function itemCallback(begin, fullpath, k, val)
    if type(val) ~= 'table' then return end
    if begin then
      if val.active then
        c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(0.5, 1, 0.5, 1))
      else
        c.PushStyleColor2(c.ImGuiCol('ImGuiCol_Text'), c.ImVec4(0.6, 0.6, 0.6, 1))
      end
    else
      c.PopStyleColor()
    end
  end

  if c.Begin("Parts", parts_window_open, 0) then
    if c.CollapsingHeader1("Slots Raw") then
      addRecursiveTreeTable(v.slotMap, '', false, partshighlightcb, itemCallback)
    end
    if c.CollapsingHeader1("Part tree [BROKEN]") then

      local function displayPart(parts, fullpath)
        for k, p in pairs(parts) do
          local newPath = fullpath .. '/' .. tostring(k)
          local open = c.TreeNode2(newPath, k)
          local comboItems = ''
          c.SameLine()
          local itemActiveId = 1
          local itemActive = nil
          for kp, pp in pairs(p) do
            comboItems = comboItems .. pp.partName .. '\0'
            if pp.active then
              itemActiveId = kp
              itemActive = pp
            end
          end
          local curItem = c.IntPtr(itemActiveId)
          comboItems = comboItems .. '\0\0'
          c.Combo2("", curItem, comboItems)
          if open then
            if itemActive and itemActive.parts and tableSize(itemActive.parts) > 0 then
              displayPart(itemActive.parts, newPath)
            end
            c.TreePop()
          end
        end
      end

      displayPart(v.slotMap, 'parts')

    end
    --if c.CollapsingHeader1("Descriptions") then
    --  addRecursiveTreeTable(v.slotDescriptions, '')
    --end
    if c.CollapsingHeader1("Variables") then
      addRecursiveTreeTable(v.variables, '')
    end
  end
  c.End()
end

local nodeIdInt = c.IntPtr(0)
local nodeSphereDebug = ffi.new("bool[1]", false)
local nodeSphereSize = ffi.new("float[1]", 0.1)
local nodeDebugColor = ffi.new("float[4]", {[0] = 1.0, 0, 0, 1})

local nodeVeloDebug = ffi.new("bool[1]", false)

local nodeForcePlotLen = 200
local nodeForceOffset = 0
local nodeForcePlot = ffi.new('float[' .. nodeForcePlotLen .. ']', 0)

local function renderNodeInspectWindow()
  if c.Begin("Node Inspector", nodeinspect_window_open, 0) then
    c.InputInt("node id", nodeIdInt, 1, 20, 0)
    local nid = nodeIdInt[0]
    --c.Text("node: " .. tostring(nid))
    -- int id, float3 pos, float mass, int type, float frictionCoef, float slidingFrictionCoef, float stribeckA, float stribeckVcoef, float noLoadCoef, float fullLoadCoef, float loadSensitivitySlope, float softnessCoef, float treadCoef, std::string &nodeTag, float couplerStrength, int groupID, bool nodeSelfCollision, bool nodeOtherCollision, int materialTypeID
    if nid >= 0 and nid < #v.data.nodes then
      local node = v.data.nodes[nid]
      local function cell(a, b)
        c.Text(a)
        c.NextColumn()
        c.Text(b)
        c.NextColumn()
      end

      if c.TreeNode1("Offline data") then
        local sortedKeys = {}
        for k in pairs(node) do table.insert(sortedKeys, k) end

        table.sort(sortedKeys)

        c.Columns(2, 'nodeinspector')
        for _, k in ipairs(sortedKeys) do
          local val = node[k]
          if k == 'pos' or k == 'nodeOffset' and type(val) == 'table' and val.x and val.y and val.z then
            val = vec3(val)
          elseif k == 'group' and type(val) == 'table' then
            if #val > 0 then
              local nv = {}
              for k, v in pairs(val) do table.insert(nv, tostring(v)) end
              val = table.concat(nv, ', ')
            else
              val = '{empty}'
            end
          end
          cell(tostring(k), tostring(val))
        end
        c.Columns(1)

        c.TreePop()
      end
      if c.TreeNode1("Live data") then

        c.Columns(2, 'nodeinspector')


        cell('Mass', tostring(obj:getNodeMass(node.cid)))
        cell('Pos', tostring(vec3(obj:getNodePosition(node.cid))))

        c.Columns(1)
        c.TreePop()
      end
      if c.TreeNode1("Visualization") then
        c.Checkbox("Sphere", nodeSphereDebug)
        if nodeSphereDebug[0] then
          c.SameLine()
          c.PushItemWidth(200)
          c.SliderFloat("Size", nodeSphereSize, 0.01, 1.0, "%.3f", 2)
          c.SameLine()
          c.ColorEdit4("Color", nodeDebugColor, bit.bor(bit.bor(c.ImGuiColorEditFlags('ImGuiColorEditFlags_NoInputs'), c.ImGuiColorEditFlags('ImGuiColorEditFlags_NoLabel')), c.ImGuiColorEditFlags('ImGuiColorEditFlags_AlphaBar')))
          obj.debugDrawProxy:drawNodeSphere(node.cid, nodeSphereSize[0], color(nodeDebugColor[0] * 255, nodeDebugColor[1] * 255, nodeDebugColor[2] * 255, nodeDebugColor[3] * 255))
        end
        c.Checkbox("Velocities", nodeVeloDebug)
        if nodeVeloDebug[0] then
          local vecVel = obj:getVelocity()
          local vel = (obj:getNodeVelocityVector(node.cid) - vecVel)
          local cc = math.min(255, vel:length() * 10)
          local col = color(cc,0,0,cc+60)
          obj.debugDrawProxy:drawNodeSphere(node.cid, 0.02, col)
          obj.debugDrawProxy:drawNodeVector(node.cid, vel * float3(0.3,0.3,0.3), col)
        end
        c.TreePop()
      end
      if c.TreeNode1("Plots") then
        local frc = vec3(obj:getNodeForceVector(node.cid))
        nodeForcePlot[nodeForceOffset] = frc:length()
        nodeForceOffset = nodeForceOffset + 1
        if nodeForceOffset >= nodeForcePlotLen then nodeForceOffset = 0 end
        c.PlotLines("m/s", nodeForcePlot, nodeForcePlotLen, nodeForceOffset, "forces", FLT_MAX, FLT_MAX, c.ImVec2(300, 100))
        c.TreePop()
      end


    else
      c.Text("Invalid node id: " .. tostring(nid) ..' . Max node id = ' .. tostring(#v.data.nodes))
    end
  end
  c.End()
end

local function onDebugDraw(dt)
  if c.BeginMainMenuBar() then
    if c.BeginMenu("Views") then
      if c.MenuItem("Data") then
        data_window_open[0] = not data_window_open[0]
      end
      if c.MenuItem("Console") then
        console_window_open[0] = not console_window_open[0]
      end
      if c.MenuItem("Parts") then
        parts_window_open[0] = not parts_window_open[0]
      end
      if c.MenuItem("Node Inspector") then
        nodeinspect_window_open[0] = not nodeinspect_window_open[0]
      end
      c.EndMenu()
    end
    c.EndMainMenuBar()
  end

  if data_window_open[0] then renderDataWindow() end
  if console_window_open[0] then renderConsoleWindow() end
  if parts_window_open[0] then renderPartsWindow() end
  if nodeinspect_window_open[0] then renderNodeInspectWindow() end

end

-- public interface
M.onDebugDraw = onDebugDraw

return M
