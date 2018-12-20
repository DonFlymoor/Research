local M = {}

local veTriUtils = extensions.vehicleEditor_veTriUtils
local im = extensions.ui_imgui
local ffi = require('ffi')
local curState = {}
curState.nodeSphereSize = ffi.new("float[1]", 0.05)
curState.nodeSphereDebug = ffi.new("bool[1]", true)
curState.nodeDebugColor = ffi.new("float[4]", {[0] = 1.0, 0.8, 0, 0.5})
curState.triDebugColor = ffi.new("float[4]", {[0] = 0.0, 0.0, 1.0, 0.3})
curState.selectedTriPtr = im.IntPtr(0)
curState.triDebug = ffi.new("bool[1]",false)
curState.singleTriDebug = ffi.new("bool[1]",false)
curState.selectedNodeId = 0
local nodeFilter = ffi.new('ImGuiTextFilter[1]')
local nodeFilter2 = ffi.new('ImGuiTextFilter[1]')


local function findConnectedtri(nid)
  local node = v.data.nodes[nid]
  local triString = ''
  curState.connectedTri = {}
  for _, t in pairs(v.data.triangles) do
    if t.id1 == curState.selectedNodeId  then
      local triID = t.cid
      triString = triString .. tostring(triID).. "\0"
      table.insert(curState.connectedTri,t.cid)
    end
    if t.id2 == curState.selectedNodeId then
      local triID = t.cid
      triString = triString .. tostring(triID).. "\0"
      table.insert(curState.connectedTri,t.cid)
    end
    if t.id3 == curState.selectedNodeId then
      local triID = t.cid
      triString = triString .. tostring(triID).. "\0"
      table.insert(curState.connectedTri,t.cid)
    end
  end
  im.Separator()
  im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
  im.Text("Selected node: " .. tostring(node.name) .. ' is connecting  ' .. tostring(#curState.connectedTri) .. ' triangles')
  im.PopStyleColor()
  im.Separator()
  im.Combo2("Connected triangles IDs ", curState.selectedTriPtr, triString)
end

function M.findTriByNode()
  local nid = curState.selectedNodeId
  if im.TreeNodeEx1("find node by name##nodenamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(nodeFilter, "filter") then
      filterchanged = true
      nid = nil
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
    findConnectedtri(nid)
    curState.tid = curState.connectedTri[curState.selectedTriPtr[0]+1]
    veTriUtils.showTriData(curState.tid)
    im.Separator()
    veTriUtils.visualization(curState,nid)
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
  selectedTriPtr = curState.selectedTriPtr[0],
  singleTriDebug = curState.singleTriDebug[0],
  triDebug = curState.triDebug[0],
}
end

function M.onDeserialized(data)
  curState.selectedNodeId = data.selectedNodeId
  curState.nodeSphereDebug[0] = data.nodeSphereDebug
  curState.nodeSphereSize[0] = data.nodeSphereSize
  curState.nodeDebugColor[0] = data.nodeDebugColor0
  curState.nodeDebugColor[1] = data.nodeDebugColor1
  curState.nodeDebugColor[2] = data.nodeDebugColor2
  curState.nodeDebugColor[3] = data.nodeDebugColor3
  curState.selectedTriPtr[0] = data.selectedTriPtr
  curState.singleTriDebug[0] = data.singleTriDebug
  curState.triDebug[0] = data.triDebug
end


return M