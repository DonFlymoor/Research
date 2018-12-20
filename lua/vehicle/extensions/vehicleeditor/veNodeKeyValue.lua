local M = {}

local im = extensions.ui_imgui
local ffi = require('ffi')
local veNodeUtils = extensions.vehicleEditor_veNodeUtils
local curState = {}

curState.nodeSphereDebug = ffi.new("bool[1]", true)
curState.nodeSphereSize = ffi.new("float[1]", 0.05)
curState.nodeDebugColor = ffi.new("float[4]", {[0] = 1.0, 0, 0, 0.3})

curState.nodeVeloDebug = ffi.new("bool[1]", false)
curState.toggleButton = ffi.new("bool[1]", false)
curState.nodeForcePlotLen = 400
curState.nodeForceOffset = 0
curState.nodeForcePlot = nil
curState.selectedNodeId = 0

local nodeFilter = ffi.new('ImGuiTextFilter[1]')
local nodeFilter2 = ffi.new('ImGuiTextFilter[1]')

function M.findNodeByKey()
  local nid = curState.selectedNodeId
  if im.TreeNodeEx1("find node by key/property##nodenamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(nodeFilter2, "filter") then
      filterchanged = true
      nid = nil
    end
    if im.IsItemHovered() then
      im.BeginTooltip()
      im.Text([[Searches the leaf keys/values. First 300 results only. Filter usage:
      ""         display all lines"
      "xxx"      display lines containing "xxx"
      "xxx,yyy"  display lines containing "xxx" or "yyy"
      "-xxx"     hide lines containing "xxx"]])
      im.EndTooltip()
    end

    im.BeginChild1("##nodefilterresults2", im.ImVec2(0, 200))
    im.BeginColumns("nodefiltertable2", 3, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 300)
    im.SetColumnWidth(1, 200)
    im.SetColumnWidth(2, 60)

    im.Separator()
    im.Text('Key Path')
    im.NextColumn()
    im.Text('Value')
    im.NextColumn()
    im.NextColumn()
    im.Separator()
    im.Separator()
    local colorHit = im.ImVec4(0.5, 1, 0.5, 1)
    local colorMiss = im.ImVec4(0.6, 0.8, 0.8, 1)
    local results = 0
    local function matchRecurive(node,t, fullpath)
      for nk, vk in pairs(t) do
        if type(vk) == 'table' then
          matchRecurive(node,vk, fullpath .. '/' .. tostring(nk) .. '/')
        else
          local hitKey = im.ImGuiTextFilter_PassFilter(nodeFilter2, tostring(nk))
          local hitValue = im.ImGuiTextFilter_PassFilter(nodeFilter2, tostring(vk))
          if (hitKey or hitValue) and results < 50 then
            results = results + 1
            if (filterchanged and not nid) or nid == node.cid then
              nid = node.cid
            end
            if hitKey then
              im.PushStyleColor2(im.Col_Text, colorHit)
            else
              im.PushStyleColor2(im.Col_Text, colorMiss)
            end
            im.Text(tostring(results) .. ' - ' .. fullpath .. tostring(nk))
            im.PopStyleColor()
            im.NextColumn()
            if hitValue then
              im.PushStyleColor2(im.Col_Text, colorHit)
            else
              im.PushStyleColor2(im.Col_Text, colorMiss)
            end
            im.Text(tostring(vk))
            im.PopStyleColor()
            im.NextColumn()
            if node.cid then
              if im.SmallButton('sel##nodeselect'..tostring(node.cid)) then
                nid = node.cid
              end
            end
            im.NextColumn()
          end
        end
      end
    end
    for lnid = 0, #v.data.nodes - 1 do
      local node = v.data.nodes[lnid]
      matchRecurive(node,node, '/nodes/' .. tostring(node.cid) .. '/')
    end
    im.EndColumns()
    im.EndChild()
    if nid and nid >= 0 and nid < #v.data.nodes then
      curState.selectedNodeId = nid
      local node = v.data.nodes[nid]
      im.Separator()
      im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
      im.Text("Selected node: " .. tostring(node.name) .. ' [' .. tostring(curState.selectedNodeId) .. ']')
      im.PopStyleColor()
      im.Separator()
      veNodeUtils.showNodeData(node)
    else
      im.Text('No node selected')
    end
  im.TreePop()
  end
end




return M