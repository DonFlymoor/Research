-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this extension draws the debug representation of paths

local M = {}

local drawDistance = 200 -- only draw in 200 meter radius

local cameraObj = nil
local ctrlPoint = 1
local camT = 0

local defaultSplineSmoothing = 0.5

local debugEnabled = false

local function getPath(pathName)
  -- find any path (chooses first)
  if not pathName then
    local objNames = scenetree.findClassObjects('SimPath')
    if not objNames or #objNames == 0 then
      -- if not SimPath on level return
      --log('E', 'core_paths.getPath', 'unable to find any path') 
      return
    end
    pathName = objNames[1]
  end
  local pathObj = scenetree.findObject(pathName)
  if not pathObj then
    log('E', 'core_paths.getPath', 'unable to find path: ' .. tostring(pathName)) 
    return
  end

  local res = { nodes = {}}
  
  res.smoothing = defaultSplineSmoothing
  if pathObj.smoothing then
    res.smoothing = tonumber(pathObj.smoothing)
  end

  res.looped = false
  if pathObj.looped then
    res.looped = pathObj.looped == '1'
  end
  
  -- extract all its markers
  --pathObj:sortMarkers()
  res.nodeCount = pathObj:size()
  for i = 0, res.nodeCount do
    local markerId = pathObj:idAt(i)
    if markerId >= 0 then
      local marker = scenetree.findObjectById(markerId)
      if marker then
        local d = {
          pos = vec3(marker:getPosition()),
          rot = quat(marker:getRotation()),
          time = marker.timeToNext or marker.seconds,
          positionSmooth = marker.positionSmooth,
          rotationSmooth = marker.rotationSmooth,
          speedSmooth = marker.speedSmooth,
        }
        res.nodes[marker.seqNum] = d
      end
    end
  end

  res.endIdx = res.nodeCount - 2
  if res.looped then
    res.endIdx = res.nodeCount - 1
  end

  res.getNodeIds = function(idx)
    if res.looped then
      return 
        (idx - 1) % res.nodeCount,
        idx % res.nodeCount,
        (idx + 1) % res.nodeCount,
        (idx + 2) % res.nodeCount
    else
      return 
        math.max(idx - 1, 0),
        idx,
        math.min(idx + 1, res.nodeCount - 1),
        math.min(idx + 2, res.nodeCount - 1)
    end
  end

  return res
end

local function onEditorEnabled(enabled)
  debugEnabled = enabled
  cameraObj = scenetree.findObject("PathTestCamera")
  if debugEnabled and not cameraObj then
    cameraObj = createObject('TSStatic')
    cameraObj.shapeName = "core/art/shapes/camera.dts"
    cameraObj.scale = Point3F(1, 1, 1)
    cameraObj:registerObject("PathTestCamera")
  elseif not debugEnabled and cameraObj then
    cameraObj:deleteObject()
  end    
end

local function drawDebugPath(path, focusPos, dt)
  if not path or #path.nodes < 2 then return end
  local nodes = path.nodes

  local lastPoint = nil
  for k, p in pairs(nodes) do
    p.pos = vec3(p.pos)
    p.rot = quat(p.rot)
    --print("node " .. tostring(k))
    --dump(p)
    if (p.pos - focusPos):length() < drawDistance then
      debugDrawer:drawSphere(p.pos:toPoint3F(), 0.2, ColorF(1,0,0,0.2))
      debugDrawer:drawText(p.pos:toPoint3F(), String(tostring(k - 1) .. "/" .. (#path - 1)  .. ' -- ' .. string.format('%0.1f', p.time) .. 's'), ColorF(0,0,0,1))
      
      -- draw camera view viz
      local viewBoxHeight = 1.5
      local viewBoxWidth = viewBoxHeight * 16 / 9
      local viewBoxSize = 0.3
      
      local p1 = (p.pos + p.rot * vec3(viewBoxWidth, viewBoxSize, -viewBoxHeight))
      debugDrawer:drawLine(p.pos:toPoint3F(), p1:toPoint3F(), ColorF(1,0,1,1))
      local p2 = (p.pos + p.rot * vec3(-viewBoxWidth, viewBoxSize, -viewBoxHeight))
      debugDrawer:drawLine(p.pos:toPoint3F(), p2:toPoint3F(), ColorF(1,0,1,1))
      debugDrawer:drawLine(p1:toPoint3F(), p2:toPoint3F(), ColorF(1,0,1,1))

      local p3 = (p.pos + p.rot * vec3(viewBoxWidth, viewBoxSize, viewBoxHeight))
      debugDrawer:drawLine(p.pos:toPoint3F(), p3:toPoint3F(), ColorF(1,0,1,1))
      local p4 = (p.pos + p.rot * vec3(-viewBoxWidth, viewBoxSize, viewBoxHeight))
      debugDrawer:drawLine(p.pos:toPoint3F(), p4:toPoint3F(), ColorF(1,0,1,1))
      debugDrawer:drawLine(p3:toPoint3F(), p4:toPoint3F(), ColorF(1,0,1,1))

      debugDrawer:drawLine(p1:toPoint3F(), p3:toPoint3F(), ColorF(1,0,1,1))
      debugDrawer:drawLine(p2:toPoint3F(), p4:toPoint3F(), ColorF(1,0,1,1))

      if lastPoint then
        debugDrawer:drawLine(p.pos:toPoint3F(), lastPoint:toPoint3F(), ColorF(1,0,0,0.5))
      end
      lastPoint = p.pos
    end
  end

  -- draw interpolated spline
  local lastPoint = nil
  for i = 0, path.endIdx do
    local n1, n2, n3, n4 = path.getNodeIds(i)
    if (nodes[n1].pos - focusPos):length() > drawDistance then
      goto continue
    end
    for t = 0, 1, 0.2 do
      local p = catmullRom(nodes[n1].pos, nodes[n2].pos, nodes[n3].pos, nodes[n4].pos, t, nodes[n2].positionSmooth)
      if (p - focusPos):length() < drawDistance then
        --debugDrawer:drawSphere(p:toPoint3F(), 0.1, ColorF(0,0,1,1))
        if lastPoint then
          debugDrawer:drawLine(p:toPoint3F(), lastPoint:toPoint3F(), ColorF(0,0,1,1))
        end
        lastPoint = p
      end
    end
    ::continue::
  end

  -- simulate interpolated camera
  local n1, n2, n3, n4 = path.getNodeIds(ctrlPoint)

  camT = camT + dt
  local nextTime = nodes[n2].time
  if camT > nextTime and ctrlPoint <= path.endIdx - 1 then
    ctrlPoint = ctrlPoint + 1
    n1, n2, n3, n4 = path.getNodeIds(ctrlPoint)
    camT = camT - nextTime
    nextTime = nodes[n2].time
  end
 
  local t = math.min(camT / nextTime, 1)
  local pos = catmullRom(nodes[n1].pos, nodes[n2].pos, nodes[n3].pos, nodes[n4].pos, t, nodes[n2].positionSmooth)
  local rot = catmullRomQuat(nodes[n1].rot, nodes[n2].rot, nodes[n3].rot, nodes[n4].rot, t, nodes[n2].rotationSmooth):normalized()
  cameraObj:setPosRot(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)

  debugDrawer:drawText(pos:toPoint3F(), String(tostring(ctrlPoint)), ColorF(0,0,0,1))

  -- restarting when reached the end
  if ctrlPoint >= path.endIdx - 1 and t >= 1 then
    ctrlPoint = 0
    camT = 0
  end
end

local function onDrawDebug(focusPos, dt)
  -- only draw when editor is enabled
  if not debugEnabled then return end 

  local pathNames = scenetree.findClassObjects('SimPath')
  for k, v in pairs(pathNames) do
    local path = getPath(v)
    drawDebugPath(path, focusPos, dt)
  end
end

local function onExtensionLoaded()
  onEditorEnabled(tonumber(getTSVar('$isEditorEnabled')))
end 

-- callbacks
M.onDrawDebug = onDrawDebug
M.onEditorEnabled = onEditorEnabled
M.onExtensionLoaded = onExtensionLoaded
M.getPath = getPath

return M
