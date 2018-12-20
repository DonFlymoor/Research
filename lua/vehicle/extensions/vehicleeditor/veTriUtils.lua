local M = {}

local imguiUtils = require('ui/imguiUtils')
local im = extensions.ui_imgui
local ffi = require('ffi')

local function drawTri(tid,c)
  if not tid then return end
  for i=0, #v.data.triangles do
    if v.data.triangles[i].cid == tid then
      obj.debugDrawProxy:drawNodeTriangle(v.data.triangles[i].id1,v.data.triangles[i].id2,v.data.triangles[i].id3,0, color(c[0]*255,c[1]*255,c[2]*255,c[3]*255))
    end
  end
end
function M.visualization(curState,nid)
  if im.TreeNodeEx1("Visualization", im.TreeNodeFlags_DefaultOpen) then
    im.Checkbox("Sphere", curState.nodeSphereDebug)
    if curState.nodeSphereDebug[0] then
      im.SameLine()
      im.PushItemWidth(300)
      im.SliderFloat("Size", curState.nodeSphereSize, 0.01, 1.0, "%.3f", 2)
      im.SameLine()
      im.ColorEdit4("Node Color", curState.nodeDebugColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
      obj.debugDrawProxy:drawNodeSphere(nid, curState.nodeSphereSize[0], color(curState.nodeDebugColor[0] * 255, curState.nodeDebugColor[1] * 255,curState.nodeDebugColor[2] * 255, curState.nodeDebugColor[3] * 255))
    end
    im.Checkbox("Collison Triangle", curState.triDebug)
    if curState.triDebug[0] then
      obj.debugDrawProxy:drawColTris(0, color(0,0,0,150), color(0,100,0,50), color(100,0,0,50), 1, color(0,0,255,255))
    end
    im.Checkbox("Selected Triangle", curState.singleTriDebug)
    if curState.singleTriDebug[0] then
      im.SameLine()
      im.ColorEdit4("Tri Color", curState.triDebugColor, im.flags(im.ColorEditFlags_NoInputs, im.ColorEditFlags_NoLabel, im.ColorEditFlags_AlphaBar))
      drawTri(curState.tid,curState.triDebugColor)
    end
  end
end
function M.showTriData(triID)
  local selectedTridata = {}
  local hardCodedKeys = {}
  --dump(v.data.triangles[155])
  if not v.data.triangles[triID] then
    im.Text('no Triangle connected to this node')
   return
  end
  for k,val in pairs(v.data.triangles[triID]) do
    if k == 'triangleType' or k == 'dragCoef' or k == 'liftCoef' or k == 'stallAngle' or k == 'pressureGroup' or k == 'groundModel' or k == 'partName' then
      hardCodedKeys[k] = val
    else
      selectedTridata[k] = val
    end
  end
  if im.TreeNodeEx1("Primary data", im.TreeNodeFlags_DefaultOpen) then
    imguiUtils.addRecursiveTreeTable(hardCodedKeys, '', false)
    im.TreePop()
  end
  if im.TreeNodeEx1("All triangle data") then
    imguiUtils.addRecursiveTreeTable(selectedTridata, '', false)
    im.TreePop()
  end
end
return M