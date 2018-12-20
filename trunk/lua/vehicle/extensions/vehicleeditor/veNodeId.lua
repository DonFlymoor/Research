local M = {}
local im = extensions.ui_imgui
local ffi = require('ffi')
local veNodeUtils = extensions.vehicleEditor_veNodeUtils

local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(500, 100)

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
local nid = 0

local function displayNodeData()
  if nid and nid >= 0 and nid < #v.data.nodes then
    curState.selectedNodeId = nid
    local node = v.data.nodes[nid]
    im.Separator()
    im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
    im.Text("Selected node: " .. tostring(node.name) .. ' [' .. tostring(curState.selectedNodeId) .. ']')
    im.PopStyleColor()
    im.Separator()
    veNodeUtils.showNodeData(node)
    im.Separator()
    if im.Button("node Visualization") then
      curState.toggleButton[0] = not curState.toggleButton[0]
      im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
      im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
    end
    if curState.toggleButton[0] then
      if im.Begin("Node visualization##",ffi.new("bool[1]", false),0) then
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

curState.nodeID = im.IntPtr(0)

function M.findNodeById()
  nid = curState.nodeID[0]
  im.InputInt("input int", curState.nodeID)
  im.Text("node: " .. tostring(nid))
  displayNodeData()
end


function M.onSerialize()
  return{
  selectedNodeId = curState.selectedNodeId,
  toggleButton = curState.toggleButton[0],
  nodeSphereDebug = curState.nodeSphereDebug[0],
  nodeDebugColor0 = curState.nodeDebugColor[0],
  nodeDebugColor1 = curState.nodeDebugColor[1],
  nodeDebugColor2 = curState.nodeDebugColor[2],
  nodeDebugColor3 = curState.nodeDebugColor[3],
  nodeSphereSize = curState.nodeSphereSize[0],
  nodeVeloDebug = curState.nodeVeloDebug[0],
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