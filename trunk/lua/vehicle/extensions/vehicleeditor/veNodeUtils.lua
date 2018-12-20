local M = {}

local imguiUtils = require("ui/imguiUtils")
local im = extensions.ui_imgui
local ffi = require("ffi")
local totalWeight = 0
local nodeForceAvg = 1
local nodeDisplayDistance = 0
local fire = require("fire")
local nodeFire = fire.debugData.flammableNodes 

function M.displayFiredata(nid)
  if im.TreeNodeEx1('fire') then
    if nid then
      imguiUtils.addRecursiveTreeTable(nodeFire[nid],'',false)
    else
      imguiUtils.addRecursiveTreeTable(nodeFire,'',false)
    end
    im.TreePop()
  end
end

function M.displayLivedata(nodeId)
  if im.TreeNodeEx1("Live data", im.TreeNodeFlags_DefaultOpen) then
    im.BeginColumns("nodelivetable", 2, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 200)
    im.SetColumnWidth(1, 1000)
    ----------------------------Mass----------------------------------
    imguiUtils.cell("Mass", tostring(obj:getNodeMass(nodeId)) .. " kg")
    local pos = vec3(obj:getNodePosition(nodeId))
    imguiUtils.cell("Pos", string.format("% 10f, % 10f, % 10f", pos.x, pos.y, pos.z))
    --------------------------forces----------------------------------
    local frc, c, col
    local newAvg = 0
    local nodeCount = 0
    local invAvgNodeForce = 1 / nodeForceAvg
    local frcMultiplier = float3(invAvgNodeForce, invAvgNodeForce, invAvgNodeForce)
    frc = obj:getNodeForceVector(nodeId)
    local frc_length = frc:length()
    newAvg = newAvg + frc_length
    nodeCount = nodeCount + 1
    c = math.min(255, (frc_length * invAvgNodeForce) * 255)
    col = color(c, 0, 0, c + 100)
    obj.debugDrawProxy:drawNodeSphere(nodeId, 0.01, col)
    obj.debugDrawProxy:drawNodeVector3d(0.01, nodeId, frc * frcMultiplier, col)
    imguiUtils.cell("Average force", tostring(nodeForceAvg))
    nodeForceAvg = (newAvg / (nodeCount + 1e-30)) * 10 + 300
    --------------------------velocity----------------------------------
    local vecVel = obj:getVelocity()
    local vel = (obj:getNodeVelocityVector(nodeId) - vecVel)
    imguiUtils.cell("Velocity", tostring(vel:length()))
    local mat = particles.getMaterialByID(v.materials, v.data.nodes[nodeId].nodeMaterial)
    imguiUtils.cell("materials", mat.name)
    --------------------------fire-------------------------
    im.EndColumns()
    im.Separator()
    im.TextColored(im.ImVec4(1.0, 1.0, 0.0, 1.0), "Fire")
    M.displayFiredata(nodeId)
    im.TreePop()
  end
end

function M.visualization(curState, node)
  if im.TreeNodeEx1("Visualization", im.TreeNodeFlags_DefaultOpen) then
    im.Checkbox("Sphere", curState.nodeSphereDebug)
    if curState.nodeSphereDebug[0] then
      im.SameLine()
      im.PushItemWidth(200)
      im.SliderFloat("Size", curState.nodeSphereSize, 0.01, 1.0, "%.3f", 2)
      im.SameLine()
      im.ColorEdit4("Color", curState.nodeDebugColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
      obj.debugDrawProxy:drawNodeSphere(node.cid, curState.nodeSphereSize[0], color(curState.nodeDebugColor[0] * 255, curState.nodeDebugColor[1] * 255, curState.nodeDebugColor[2] * 255, curState.nodeDebugColor[3] * 255))
    end
    im.Checkbox("Velocities", curState.nodeVeloDebug)
    if curState.nodeVeloDebug[0] then
      local vecVel = obj:getVelocity()
      local vel = (obj:getNodeVelocityVector(node.cid) - vecVel)
      local cc = math.min(255, vel:length() * 10)
      local col = color(cc, 0, 0, cc + 60)
      obj.debugDrawProxy:drawNodeSphere(node.cid, 0.02, col)
      obj.debugDrawProxy:drawNodeVector(node.cid, vel * float3(0.8, 0, 0.8), col)
    end
    im.TreePop()
  end
  if im.TreeNodeEx1("Plots", im.TreeNodeFlags_DefaultOpen) then
    im.SameLine()
    im.Text("frames: " .. tostring(curState.nodeForcePlotLen))
    if not curState.nodeForcePlot then
      curState.nodeForcePlot = ffi.new("float[" .. curState.nodeForcePlotLen .. "]", 0)
    end

    local frc = vec3(obj:getNodeForceVector(node.cid))
    curState.nodeForcePlot[curState.nodeForceOffset] = frc:length()
    curState.nodeForceOffset = curState.nodeForceOffset + 1
    if curState.nodeForceOffset >= curState.nodeForcePlotLen then
      curState.nodeForceOffset = 0
    end
    im.PlotLines1("m/s", curState.nodeForcePlot, curState.nodeForcePlotLen, curState.nodeForceOffset, "forces", FLT_MAX, FLT_MAX, im.ImVec2(300, 100))
    im.TreePop()
  end
end

function M.showNodeData(node)
  local hardcodedKeys = {}
  local nodeData = {}
  for k, v in pairs(node) do
    if k == "pos" or k == "collision" or k == "selfCollision" or k == "frictionCoef" or k == "nodeWeight" or k == "group" or k == "partName" then
      hardcodedKeys[k] = v
    else
      nodeData[k] = v
    end
  end

  if im.TreeNodeEx1("Primary data", im.TreeNodeFlags_DefaultOpen) then
    imguiUtils.addRecursiveTreeTable(hardcodedKeys, "", false)
    im.TreePop()
  end
  if im.TreeNodeEx1("All jbeam data") then
    imguiUtils.addRecursiveTreeTable(nodeData, "", false)
    im.TreePop()
  end
end

return M
