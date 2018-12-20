local M = {}

local imguiUtils = require('ui/imguiUtils')
local im = extensions.ui_imgui
local ffi = require('ffi')
local def = 1
M.bLengths = {}

function M.visualization(curState)
  if im.TreeNodeEx1("Visualization", im.TreeNodeFlags_DefaultOpen) then
    im.Checkbox("selected beam  ",curState.selectedBeam)
    if (curState.selectedBeam[0]) then
      obj.debugDrawProxy:drawBeam3d(curState.beamID,curState.selectedBeamSize[0] ,  color(curState.selectedBeamColor[0] * 255, curState.selectedBeamColor[1] * 255, curState.selectedBeamColor[2] * 255, curState.selectedBeamColor[3] * 255))
      im.PushItemWidth(300)
      im.SameLine()
      im.SliderFloat("Selected Beam", curState.selectedBeamSize, 0.01, 1.0, "%.3f", 2)
      im.SameLine()
      im.ColorEdit4(" Selected Beam " , curState.selectedBeamColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
    end
    im.Separator()
    im.Checkbox("Node1           ",curState.Node1)
    if curState.Node1[0] then
      im.SameLine()
      obj.debugDrawProxy:drawNodeSphere(curState.selectedNodeId, curState.nodeSphereSize1[0], color(curState.nodeDebugColor1[0] * 255, curState.nodeDebugColor1[1] * 255,curState.nodeDebugColor1[2] * 255, curState.nodeDebugColor1[3] * 255))
      im.SliderFloat("Node1 Size   ", curState.nodeSphereSize1, 0.01, 1.0, "%.3f", 2)
      im.SameLine()
      im.ColorEdit4(" Node1 Color", curState.nodeDebugColor1, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
    end
    im.Separator()
    im.Checkbox("Node2           ",curState.Node2)
    if curState.Node2[0] then
      obj.debugDrawProxy:drawNodeSphere(curState.secNodeId, curState.nodeSphereSize2[0], color(curState.nodeDebugColor2[0] * 255, curState.nodeDebugColor2[1] * 255,curState.nodeDebugColor2[2] * 255, curState.nodeDebugColor2[3] * 255))
      im.SameLine()
      im.SliderFloat("Node2 Size   ", curState.nodeSphereSize2, 0.01, 1.0, "%.3f", 2)
      im.SameLine()
      im.ColorEdit4(" Node2 Color", curState.nodeDebugColor2, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
    end
    im.TreePop()
  end
end
function M.showBeamData(beamID)
  local selectedBeamdata = {}
  local hardCodedKeys = {}
  for k,val in pairs(v.data.beams[beamID]) do
    if k == 'beamType' or k == 'beamSpring' or k == 'beamDamp' or k == 'beamDeform' or k == 'beamStrength' or k == 'precompression' or k == 'partName' then
      hardCodedKeys[k] = val
    else
      selectedBeamdata[k] = val
    end
  end
  if im.TreeNodeEx1("Primary data", im.TreeNodeFlags_DefaultOpen) then
    imguiUtils.addRecursiveTreeTable(hardCodedKeys, '', false)
    im.TreePop()
  end
  if im.TreeNodeEx1("All jbeam data") then
    imguiUtils.addRecursiveTreeTable(selectedBeamdata, '', false)
    im.TreePop()
  end
end

function M.displayLiveData(bid,lens,node1,node2)
  M.bLengths = lens
  if not bid then return end
  if im.TreeNodeEx1("Live data", im.TreeNodeFlags_DefaultOpen) then
    im.BeginColumns("Beamlivetable", 2, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 200)
    im.SetColumnWidth(1, 1000)
    --------------------------------Beam length--------------------------
    imguiUtils.cell("Beam length", tostring(obj:getBeamLength(bid))..' meters')
  --  im.Separator()
    ---------------------------------Beam Stress--------------------------
    local c = color(0,0,0,255)
    local stress = obj:getBeamStress(bid) * 0.0002
    c.r = math.max(-1, math.min(0, stress)) * 255
    c.b = math.max( 0, math.min(1, stress)) * 255
    c.a = (math.abs(stress) * 500) * bdebug.state.vehicle.beamVisAlpha
    if c.a > 5 then
      obj.debugDrawProxy:drawBeam3d(bid, 0.005, c)
    end
    imguiUtils.cell("Stress ", tostring(stress))
    ------------------------------Beam deformation------------------------
  --  im.Separator()
    local deformation = obj:getBeamDebugDeformation(bid)
    local c = color(0,0,0,255)
    c.b = (1 - deformation) * 255
    c.r = (deformation - 1) * 255
    c.a = (math.abs((deformation - 1) * 10) * 255) * bdebug.state.vehicle.beamVisAlpha
    if c.a > 5 then
      obj.debugDrawProxy:drawBeam3d(bid, 0.005, c)
    end
    for i=0,#lens do
      if bid == i then
        def = obj:getBeamLength(bid)/lens[i]
      end
    end
    imguiUtils.cell("Deformation", tostring(def))
 --   imguiUtils.cell("Deformation", tostring(obj:getBeamDebugDeformation(bid)))
    ------------------------------node id1 live data------------------------
    if node1 then
     -- im.Separator()
      imguiUtils.cell('node1 Mass', tostring(obj:getNodeMass(node1)) .. ' kg')
      local pos = vec3(obj:getNodePosition(node1))
      imguiUtils.cell('node1 Pos', string.format("% 10f, % 10f, % 10f", pos.x, pos.y, pos.z))
    end
    ------------------------------node id2 live data------------------------
    if node2 then
     -- im.Separator()
      imguiUtils.cell('node2 Mass', tostring(obj:getNodeMass(node2)) .. ' kg')
      local pos = vec3(obj:getNodePosition(node2))
      imguiUtils.cell('node2 Pos', string.format("% 10f, % 10f, % 10f", pos.x, pos.y, pos.z))
    end
    im.EndColumns()
    im.TreePop()
  end
end

function M.connectedBeamVis(curState)
  --if im.TreeNodeEx1("Connected beams") then
    im.Checkbox("connected beams ",curState.BeamDebug)
    local beamsString = ''
    if curState.BeamDebug[0] then
      for _,b in pairs(curState.connectedBeams) do
        obj.debugDrawProxy:drawBeam3d(b, curState.beamSize[0] , color(curState.beamDebugColor[0] * 255, curState.beamDebugColor[1] * 255, curState.beamDebugColor[2] * 255, curState.beamDebugColor[3] * 255))
        beamsString = beamsString .. tostring(b).. "\0"
      end
      im.SameLine()
      im.SliderFloat(" Beams Size  ", curState.beamSize, 0.01, 1.0, "%.3f", 1)
      im.SameLine()
      im.ColorEdit4(" Beams Color"   , curState.beamDebugColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
      im.Text('                   ')
      im.SameLine()
      im.Combo2(" Connected Beam ID", curState.connBeamPtr, beamsString)
      im.Separator()
      M.displayLiveData(curState.connectedBeams[curState.connBeamPtr[0]+1],M.bLengths)
    --  im.TreePop()
  --  end
   
  end
end

return M