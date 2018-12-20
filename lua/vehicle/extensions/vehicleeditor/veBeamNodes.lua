local M = {}
local veBeamUtils = extensions.vehicleEditor_veBeamUtils

local im = extensions.ui_imgui
local ffi = require('ffi')

local visWindow = im.BoolPtr(false)
local initialWindowSize = im.ImVec2(700, 700)
local nextWindowPos = im.ImVec2(600,100)
local curState = {}
curState.BeamDebug = ffi.new("bool[1]", true)
curState.selectedBeam = ffi.new("bool[1]", true)
curState.Node1 = ffi.new("bool[1]", true)
curState.Node2 = ffi.new("bool[1]", true)

curState.selectedBeamSize = ffi.new("float[1]", 0.01)
curState.beamDebugColor = ffi.new("float[4]", {[0] = 0, 0.9, 1.0, 0.3})
curState.selectedBeamColor = ffi.new("float[4]", {[0] = 1.0, 0, 0, 0.8})
curState.selectedNodeId = 0
curState.secNodeId      = 0
curState.nodeVeloDebug = ffi.new("bool[1]",true)
curState.beamStress = ffi.new("bool[1]",true)
curState.beamLength = ffi.new("bool[1]",true)
curState.selectedBeamPtr = im.IntPtr(0)
curState.connBeamPtr = im.IntPtr(0)
curState.nodeSphereSize1 = ffi.new("float[1]", 0.05)
curState.nodeDebugColor1 = ffi.new("float[4]", {[0] = 1.0, 1.0, 0, 0.3})
curState.nodeSphereSize2 = ffi.new("float[1]", 0.03)
curState.nodeDebugColor2 = ffi.new("float[4]", {[0] = 0, 0, 1.0, 0.3})
----find beam by name
curState.beamSize = ffi.new("float[1]", 0.01)
curState.beamID = 0
curState.toggleButton = ffi.new("bool[1]",false)
local beamDeformRatio = ffi.new("bool[1]",true)
local beamFilter = ffi.new('ImGuiTextFilter[1]')
local nodeFilter = ffi.new('ImGuiTextFilter[1]')
local checkBeamPtr = true


local function searchSecNode(selectedNodeName)
  if not selectedNodeName then return end
  local nodeId = string.gsub(selectedNodeName, ".*%a?%d*%a*%s", "")
 -- print(nodeId)
  for i=0,#v.data.nodes-1 do
    if i == tonumber(nodeId) then
      curState.secNodeId = i
    end
  end
  for i=0,#v.data.beams do
    if (v.data.beams[i].id1 == curState.selectedNodeId and v.data.beams[i].id2 == curState.secNodeId) or (v.data.beams[i].id1 == curState.secNodeId and v.data.beams[i].id2 == curState.selectedNodeId) then
      curState.beamID = v.data.beams[i].cid
    end
  end
end

local function findConnectedBeams(nid)
  local node = v.data.nodes[nid]
  local beamsString = ''
  local secondNode = {}
  curState.connectedBeams = {}
  for b=0,#v.data.beams do
    if v.data.beams[b].id1 == curState.selectedNodeId  then
      local nodeName = v.data.nodes[v.data.beams[b].id2].name
      beamsString = beamsString .. tostring(nodeName).. "\0"
      table.insert(curState.connectedBeams,v.data.beams[b].cid)
      table.insert(secondNode,nodeName.." "..tostring(v.data.beams[b].id2))
    end
    if v.data.beams[b].id2 == curState.selectedNodeId then
      local nodeName = v.data.nodes[v.data.beams[b].id1].name
      beamsString = beamsString .. tostring(nodeName).. "\0"
      table.insert(secondNode,nodeName .." " .. tostring(v.data.beams[b].id1))
      table.insert(curState.connectedBeams,v.data.beams[b].cid)
    end
  end
  im.Separator()
  im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
  im.Text("Selected node: " .. tostring(node.name) .. ' is connecting  ' .. tostring(#secondNode) .. ' beams')
  im.PopStyleColor()
  im.Separator()
  if im.Combo2("Second Node Name ", curState.selectedBeamPtr, beamsString)  then
    searchSecNode(secondNode[curState.selectedBeamPtr[0]+1])
  end
  if checkBeamPtr then
    if curState.selectedBeamPtr[0]+1 >#curState.connectedBeams then
      curState.selectedBeamPtr[0] = 0
    end
    searchSecNode(secondNode[curState.selectedBeamPtr[0]+1])
    checkBeamPtr = false
  end
end
local function findBeamByConnectedNode(beamLengths)
  local nid = curState.selectedNodeId
  if im.TreeNodeEx1("find Beams by connected node name##nodenamefilter",im.TreeNodeFlags_DefaultOpen) then
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
          checkBeamPtr = true
        end
        im.PopStyleColor()
        im.NextColumn()
      end
    end
    im.EndColumns()
    im.EndChild()

    if (nid and nid >= 0 and nid < #v.data.nodes) then
      curState.selectedNodeId = nid
      findConnectedBeams(nid)
      veBeamUtils.showBeamData(curState.beamID)
      if im.Button("Beams Visualization") then
        curState.toggleButton[0] = not curState.toggleButton[0]
        im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
        im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
      end
      if curState.toggleButton[0] then
        if im.Begin("Beams Visualization ##beamvis",visWindow) then
          veBeamUtils.visualization(curState)
          im.Separator()
          veBeamUtils.displayLiveData(curState.beamID,beamLengths,curState.selectedNodeId,curState.secNodeId)
          im.Separator()
          veBeamUtils.connectedBeamVis(curState)
        end
        im.End()
      end
    else
      im.Text('No node selected')
    end
    im.TreePop()
  end
end
local function onSerialize()
  return {
    selectedNodeId = curState.selectedNodeId,
    secNodeId   = curState.secNodeId,
    selectedBeamPtr = curState.selectedBeamPtr[0],
    BeamDebug = curState.BeamDebug[0],
    beamSize = curState.beamSize[0],
    toggleButton = curState.toggleButton[0],
    nodeSphereSize1 = curState.nodeSphereSize1[0],
    selectedBeamSize = curState.selectedBeamSize[0],
    nodeSphereSize2 = curState.nodeSphereSize2[0],
    node1Color0 = curState.nodeDebugColor1[0],
    node1Color1 = curState.nodeDebugColor1[1],
    node1Color2 = curState.nodeDebugColor1[2],
    node1Color3 = curState.nodeDebugColor1[3],
    node2Color0 = curState.nodeDebugColor2[0],
    node2Color1 = curState.nodeDebugColor2[1],
    node2Color2 = curState.nodeDebugColor2[2],
    node2Color3 = curState.nodeDebugColor2[3],
    beamDebugColor0  = curState.beamDebugColor[0],
    beamDebugColor1  = curState.beamDebugColor[1],
    beamDebugColor2  = curState.beamDebugColor[2],
    beamDebugColor3  = curState.beamDebugColor[3],
    selectedBeamColor0 = curState.selectedBeamColor[0],
    selectedBeamColor1 = curState.selectedBeamColor[1],
    selectedBeamColor2 = curState.selectedBeamColor[2],
    selectedBeamColor3 = curState.selectedBeamColor[3],
    selectedBeam = curState.selectedBeam[0],
    connBeamPtr = curState.connBeamPtr[0],
    Node1 = curState.Node1[0],
    Node2 = curState.Node2[0],
  }
end
local function onDeserialized(data)
  curState.selectedNodeId = data.selectedNodeId
  curState.secNodeId = data.secNodeId
  curState.selectedBeamPtr[0] = data.selectedBeamPtr
  curState.BeamDebug[0] = data.BeamDebug
  curState.beamSize[0] = data.beamSize
  curState.selectedBeamSize[0] = data.selectedBeamSize
  curState.nodeSphereSize1[0] = data.nodeSphereSize1
  curState.nodeSphereSize2[0] = data.nodeSphereSize2
  curState.nodeDebugColor1[0] = data.node1Color0
  curState.nodeDebugColor1[1] = data.node1Color1
  curState.nodeDebugColor1[2] = data.node1Color2
  curState.nodeDebugColor1[3] = data.node1Color3
  curState.nodeDebugColor2[0] = data.node2Color0
  curState.nodeDebugColor2[1] = data.node2Color1
  curState.nodeDebugColor2[2] = data.node2Color2
  curState.nodeDebugColor2[3] = data.node2Color3
  curState.beamDebugColor[0] = data.beamDebugColor0
  curState.beamDebugColor[1] = data.beamDebugColor1
  curState.beamDebugColor[2] = data.beamDebugColor2
  curState.beamDebugColor[3] = data.beamDebugColor3
  curState.selectedBeamColor[0] = data.selectedBeamColor0
  curState.selectedBeamColor[1] = data.selectedBeamColor1
  curState.selectedBeamColor[2] = data.selectedBeamColor2
  curState.selectedBeamColor[3] = data.selectedBeamColor3
  curState.selectedBeam[0] = data.selectedBeam
  curState.toggleButton[0] = data.toggleButton
  curState.Node1[0] = data.Node1
  curState.Node2[0] = data.Node2
  curState.connBeamPtr[0] = data.connBeamPtr

end

M.onDeserialized = onDeserialized
M.onSerialize = onSerialize
M.findBeamByConnectedNode = findBeamByConnectedNode
return M