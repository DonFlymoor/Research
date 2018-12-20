local M = {}
local veNodeUtils = extensions.vehicleEditor_veNodeUtils

local im = extensions.ui_imgui
local ffi = require('ffi')
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
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(500, 100)
local nodeFilter = ffi.new('ImGuiTextFilter[1]')

function M.findNodeName()
  local nid = curState.selectedNodeId
  if im.TreeNodeEx1("find node by name##nodenamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(nodeFilter, "filter") then
      filterchanged = true
      nid = nil
    end
    if im.IsItemHovered() then
      im.BeginTooltip()
      im.Text([[Filter usage:
      ""         display all lines"
      "xxx"      display lines containing "xxx"
      "xxx,yyy"  display lines containing "xxx" or "yyy"
      "-xxx"     hide lines containing "xxx"]])
      im.EndTooltip()
    end

    im.BeginChild1("##nodefilterresults1", im.ImVec2(0, 200))
    im.BeginColumns("nodefiltertable1", 3, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 80)
    im.SetColumnWidth(1, 50)
    im.SetColumnWidth(2, 50)

    im.Separator()
    im.Text('Name')
    im.NextColumn()
    im.Text('Id')
    im.NextColumn()
    -- button column
    im.NextColumn()
    im.Separator()
    im.Separator()

    for lnid = 0, #v.data.nodes - 1 do
      local node = v.data.nodes[lnid]
      if node.name and im.ImGuiTextFilter_PassFilter(nodeFilter, node.name) then
        if (filterchanged and not nid) or nid == node.cid then
          nid = node.cid
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
        else
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
        end
        im.Text(tostring(node.name))
        im.NextColumn()
        im.Text(tostring(node.cid))
        im.NextColumn()
        if im.SmallButton('sel##nodeselect'..tostring(node.cid)) then
          nid = node.cid
        end
        im.PopStyleColor()
        im.NextColumn()
      end
    end
    im.EndColumns()
    im.EndChild()
    im.TreePop()
  end
  if nid and nid >= 0 and nid < #v.data.nodes then
    curState.selectedNodeId = nid
    local node = v.data.nodes[nid]
    im.Separator()
    im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
    im.Text("Selected node: " .. tostring(node.name) .. ' [' .. tostring(curState.selectedNodeId) .. ']')
    im.PopStyleColor()
    im.Separator()
    veNodeUtils.showNodeData(node)
    if im.Button("node Visualization") then
      curState.toggleButton[0] = not curState.toggleButton[0]
      im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
      im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
    end
    if curState.toggleButton[0] then
      if im.Begin("Node Visualization##nodevis",ffi.new("bool[1]", false),0) then
        veNodeUtils.visualization(curState,node)
        im.Separator()
        veNodeUtils.displayLivedata(nid)
      end
      im.End()
    end
  else
    im.Text('No node selected')
  end
end

function M.onSerialize()
  return{
  selectedNodeId = curState.selectedNodeId,
  nodeSphereDebug = curState.nodeSphereDebug[0],
  nodeDebugColor0 = curState.nodeDebugColor[0],
  nodeDebugColor1 = curState.nodeDebugColor[1],
  nodeDebugColor2 = curState.nodeDebugColor[2],
  nodeDebugColor3 = curState.nodeDebugColor[3],
  nodeSphereSize = curState.nodeSphereSize[0],
  nodeVeloDebug = curState.nodeVeloDebug[0],
  toggleButton = curState.toggleButton[0],
}
end

function M.onDeserialized(data)
  curState.selectedNodeId = data.selectedNodeId
  curState.nodeSphereDebug[0] = data.nodeSphereDebug
  curState.nodeForcePlot = data.nodeForcePlot
  curState.nodeSphereSize[0] = data.nodeSphereSize
  curState.nodeVeloDebug[0] = data.nodeVeloDebug
  curState.nodeDebugColor[0] = data.nodeDebugColor0
  curState.nodeDebugColor[1] = data.nodeDebugColor1
  curState.nodeDebugColor[2] = data.nodeDebugColor2
  curState.nodeDebugColor[3] = data.nodeDebugColor3
  curState.toggleButton[0] = data.toggleButton
end


return M