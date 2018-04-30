-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local max = math.max
local min = math.min

M.origState = {
  fov = 80,
  physicsEnabled = true,
  vehicleDebugVisible = false,
  vehicle = {
    beamVis = 'off',
    beamVis_modes = {'off','simple','type','with broken','broken only','stress','deformation', 'breakgroups', 'deformgroups'},
    beamVisAlpha=1,
    nodeVis = 'off',
    nodeVis_modes = {'off','simple','weights', 'velocities', 'forces', 'density'},
    nodeText = 'off',
    nodeText_modes = {'off','names','numbers','names+numbers','weights','materials'},
    flexmeshdebug = 'off',
    flexmeshdebug_modes = {'off','none', 'groups', 'distance', 'bindings'},
    collisionTriangle = false,
    aero = "off",
    aero_modes = {"off", "drag+lift", "aoa", "combined"},
    aerodynamicsScale = 0.1,
    tireContactPoint = false,
    objectData = false,
    meshVisibility = 100,
    cog = 1,
    cog_modes = {'off', 'on', 'nowheels'},
  },
  terrain = {
    staticCollision = false,
    groundmodel = false
  },
  renderer = {
    showFps = false,
    boundingboxes = false,
    disableShadows = false,
    wireframe = false,
    visualization = 'None'
  }
}

M.state = deepcopy(M.origState)

local nodeForceAvg = 1
local nodeDisplayDistance = 0 -- broken atm since it uses the center point of the camera :\

local wheelContacts = {}

local function nodeCollision(p)
  if not M.state.vehicle.tireContactPoint then
    M.nodeCollision = nop
    return
  end
  local wheelId = v.data.nodes[p.id1].wheelID
  if wheelId then
    if not wheelContacts[wheelId] then wheelContacts[wheelId] = {totalForce = 0, contactPoint = vec3(0,0,0)} end
    local wheelC = wheelContacts[wheelId]
    wheelC.totalForce = wheelC.totalForce + p.normalForce
    wheelC.contactPoint = wheelC.contactPoint + vec3(p.pos) * p.normalForce
  end
end

local function beamBroke(id, energy)
  local beam = v.data.beams[id]
  local m = string.format("beam %d broke: %s [%d]  ->  %s [%d]", id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2)
  log('I', "bdebug.beamBroken", m)
  gui.message({txt="vehicle.beamstate.beamBroke", context={id=id, id1=beam.id1, id2=beam.id2, id1name=v.data.nodes[beam.id1].name, id2name=v.data.nodes[beam.id2].name}})
end

local function beamDeformed(id, ratio)
  local beam = v.data.beams[id]
  if M.state.vehicle.beamVis == "deformgroups" and beam.deformGroup then
    local m = string.format("deformgroup triggered: %s beam %d, %s [%d]  ->  %s [%d]", beam.deformGroup, id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2)
    log('I', "bdebug.beamDeformed", m)
  else
    local m = string.format("beam %d deformed: %s [%d]  ->  %s [%d]", id, (v.data.nodes[beam.id1].name or "unnamed"), beam.id1, (v.data.nodes[beam.id2].name or "unnamed"), beam.id2)
    log('I', "bdebug.beamDeformed", m)
    gui.message({txt="vehicle.beamstate.beamDeformed", context={id=id, id1=beam.id1, id2=beam.id2, id1name=v.data.nodes[beam.id1].name, id2name=v.data.nodes[beam.id2].name}})
  end
end

local function debugDrawNode(col, node, txt)
  if node.name == nil then
    obj.debugDrawProxy:drawNodeText(node.cid, col, "["..tostring(node.cid).."] "..txt, nodeDisplayDistance)
  else
    obj.debugDrawProxy:drawNodeText(node.cid, col, tostring(node.name).." " ..txt, nodeDisplayDistance)
  end
end

local function debugDraw(focusPos)
  if M.state.vehicle.tireContactPoint then
    M.nodeCollision = nodeCollision
    for _, c in pairs(wheelContacts) do
      obj.debugDrawProxy:drawSphere(0.02, (c.contactPoint / c.totalForce):toFloat3(), color(255,0,0,255))
    end
    wheelContacts = {}
  end

  if M.state.vehicle.collisionTriangle then
    obj.debugDrawProxy:drawColTris(0, color(0,0,0,150), color(0,255,0,50), color(255,0,255,50), 1)
  end

  if M.state.vehicle.aero == "drag+lift" then
    obj.debugDrawProxy:drawAerodynamics(color(255,0,0,255), color(55,55,255,255), color(255,255,0,255), color(0,0,0,0), color(0,0,0,0), M.state.vehicle.aerodynamicsScale)
  elseif M.state.vehicle.aero == "aoa" then
    obj.debugDrawProxy:drawAerodynamics(color(255,0,0,0), color(55,55,255,0), color(255,255,0,0), color(0,0,0,255), color(0,0,0,0), M.state.vehicle.aerodynamicsScale)
  elseif M.state.vehicle.aero == "combined" then
    obj.debugDrawProxy:drawAerodynamics(color(255,0,0,255), color(55,55,255,255), color(255,255,0,255), color(0,0,0,255), color(0,0,0,0), M.state.vehicle.aerodynamicsScale)
  end

  if M.state.vehicle.cog and M.state.vehicle.cog > 1 then
    local p = obj:calcCenterOfGravity(M.state.vehicle.cog == 3)
    obj.debugDrawProxy:drawAerodynamics(color(0,0,0,0), color(0,0,0,0), color(0,0,0,0), color(0,0,0,0), color(0,0,255,255), 0.1)
    obj.debugDrawProxy:drawSphere(0.1, p, color(255,0,0,255))
    obj.debugDrawProxy:drawText(p + float3(0,0,0.3), color(255,0,0,255), "COG")

    obj.debugDrawProxy:drawText2D(float3(40,20,0), color(0,0,0,255), "COG distance above ground: " ..  string.format("%0.3f m", obj:getDistanceFromTerrainPoint(p)))
  end

-- beam visualization

-- highlighted beams
  local statusTxt = ''

  if M.state.vehicle.beamVis ~= 'off' then
    statusTxt = statusTxt .. '#beams: ' .. tostring(#v.data.beams) .. ' | '
    for _, beam in pairs (v.data.beams) do
      if beam.highlight then
        obj.debugDrawProxy:drawBeam3d(beam.cid, beam.highlight.radius, parseColor(beam.highlight.col))
      end
    end
  end

  if M.state.vehicle.beamVis == 'type' or M.state.vehicle.beamVis == 'with broken' or M.state.vehicle.beamVis == 'broken only' then
    local sm = 1
    if M.state.vehicle.beamVis == 'with broken' then sm = 2 end
    if M.state.vehicle.beamVis == 'broken only' then sm = 3 end
    obj.debugDrawProxy:drawBeams(sm, 255 * M.state.vehicle.beamVisAlpha) -- 1 == no broken beams, 3 = only broken beams

  elseif M.state.vehicle.beamVis == 'simple' then
    for _, beam in pairs (v.data.beams) do
      obj.debugDrawProxy:drawBeamColor(beam.cid, color(0,255,0,255 * M.state.vehicle.beamVisAlpha))
    end

  elseif M.state.vehicle.beamVis == 'stress' then
    for _, beam in pairs (v.data.beams) do
      local c = color(0,0,0,255)
      local stress = obj:getBeamStress(beam.cid) * 0.0002
      c.r = math.max(-1, math.min(0, stress)) * 255
      c.b = math.max( 0, math.min(1, stress)) * 255
      c.a = (math.abs(stress) * 500) * M.state.vehicle.beamVisAlpha

      if c.a > 5 then
        obj.debugDrawProxy:drawBeam3d(beam.cid, 0.005, c)
      end
    end
  elseif M.state.vehicle.beamVis == 'deformation' then
    for _, beam in pairs (v.data.beams) do
      if not obj:beamIsBroken(beam.cid) then
        local c = color(0,0,0,255)
        local deformation = obj:getBeamDebugDeformation(beam.cid)
        c.b = (1 - deformation) * 255
        c.r = (deformation - 1) * 255
        c.a = (math.abs((deformation - 1) * 10) * 255) * M.state.vehicle.beamVisAlpha

        if c.a > 5 then
          obj.debugDrawProxy:drawBeam3d(beam.cid, 0.005, c)
        end
      end
    end
  elseif M.state.vehicle.beamVis == 'breakgroups' then
    local i = 1
    local groups = {}
    local wasDrawn = {}
    for _, beam in pairs (v.data.beams) do
      if beam.breakGroup and beam.breakGroup ~= "" then
        local breakGroups = type(beam.breakGroup) == "table" and beam.breakGroup or {beam.breakGroup}
        for _,v in pairs(breakGroups) do
          if not groups[v] then
            groups[v] = i
            i = i + 1
          end
          local c = getContrastColor(groups[v])
          obj.debugDrawProxy:drawBeam3d(beam.cid, 0.005, c)
          if not wasDrawn[v] then
            obj.debugDrawProxy:drawNodeText(beam.id1, c, v, nodeDisplayDistance)
            wasDrawn[v] = 1
          end
        end
      end
    end
  elseif M.state.vehicle.beamVis == 'deformgroups' then
    local i = 1
    local groups = {}
    local wasDrawn = {}
    for _, beam in pairs (v.data.beams) do
      if beam.deformGroup and beam.deformGroup ~= "" then
        local deformGroups = type(beam.deformGroup) == "table" and beam.deformGroup or {beam.deformGroup}
        for _,v in pairs(deformGroups) do
          if not groups[v] then
            groups[v] = i
            i = i + 1
          end
          local c = getContrastColor(groups[v])
          obj.debugDrawProxy:drawBeam3d(beam.cid, 0.005, c)
          if not wasDrawn[v] then
            obj.debugDrawProxy:drawNodeText(beam.id1, c, v, nodeDisplayDistance)
            wasDrawn[v] = 1
          end
        end
      end
    end
  end

  -- node visualization
  --if M.state.vehicle.nodeText ~= '' or M.state.vehicle.nodeVis ~= 'off' then
  --  statusTxt = statusTxt .. "#nodes: " ..  tostring(#v.data.nodes)
  --end

  if M.state.vehicle.nodeText == 'numbers' then
    obj.debugDrawProxy:drawNodeNumbers(color(0,0,255,255), nodeDisplayDistance)

  elseif M.state.vehicle.nodeText == 'names+numbers' then
    local col = color(128,0,255,255)
    for _, node in pairs (v.data.nodes) do
      debugDrawNode(col, node, "" .. node.cid)
    end
  elseif M.state.vehicle.nodeText == 'names' then
    local col = color(128,0,255,255)
    for _, node in pairs (v.data.nodes) do
      debugDrawNode(col, node, "")
    end
  elseif M.state.vehicle.nodeText == 'weights' then
    local totalWeight = 0
    for _, node in pairs (v.data.nodes) do
      local nodeWeight = obj:getNodeMass(node.cid)
      local col = color(0,0,0,255)
      col.r = 255 - (nodeWeight* 20)
      col.g = 0
      col.b = 0
      totalWeight = totalWeight + nodeWeight
      local txt = string.format("%.2fkg", nodeWeight)
      obj.debugDrawProxy:drawNodeText(node.cid, col, txt, nodeDisplayDistance)
    end
    obj.debugDrawProxy:drawText2D(float3(40,60,0), color(0,0,0,255), "Total weight: " .. string.format("%.2f kg", totalWeight))
  elseif M.state.vehicle.nodeText == 'materials' then
    for _, node in pairs (v.data.nodes) do
      local mat = particles.getMaterialByID(v.materials, node.nodeMaterial)
      local matname = "unknown"
      local col = color(255,0,0,255) -- unknown material: red
      if mat ~= nil then
        col = color(mat.colorR, mat.colorG, mat.colorB, 255)
        matname = mat.name
      end
      debugDrawNode(col, node, matname)
    end
  end

  if M.state.vehicle.nodeVis ~= 'off' then
    for _, node in pairs (v.data.nodes) do
      if node.highlight then
        obj.debugDrawProxy:drawNodeSphere(node.cid, node.highlight.radius, parseColor(node.highlight.col))
      end
    end
  end

  if M.state.vehicle.nodeVis == 'simple' then
    for _, node in pairs (v.data.nodes) do
      local c = color(0,255,255,200)
      if node.fixed then
        c = color(255,0,255,200)
      elseif node.selfCollision then
        c = color(255,255,0,200)
      elseif node.collision then
        c = color(255,0,255,200)
      end
      obj.debugDrawProxy:drawNodeSphere(node.cid, 0.015, c)
    end
  elseif M.state.vehicle.nodeVis == 'weights' then
    local w = 0
    for _, node in pairs (v.data.nodes) do
      w = w + obj:getNodeMass(node.cid)
    end
    w = w / #v.data.nodes

    for _, node in pairs (v.data.nodes) do
      local c = color(0,255,255,150)
      local r = (obj:getNodeMass(node.cid) / w) ^ 0.4 * 0.05
      if node.fixed then
        c = color(255,0,255,200)
      elseif node.collision then
        c = color(255,0,0,200)
      elseif node.selfcollision then
        c = color(255,0,255,200)
      end
      obj.debugDrawProxy:drawNodeSphere(node.cid, r, c)
    end
  elseif M.state.vehicle.nodeVis == 'velocities' then
    local vel, c, col
    local vecVel = obj:getVelocity()
    for _, node in pairs (v.data.nodes) do
      vel = (obj:getNodeVelocityVector(node.cid) - vecVel)
      c = math.min(255, vel:length() * 10)
      col = color(c,0,0,c+60)
      obj.debugDrawProxy:drawNodeSphere(node.cid, 0.02, col)
      obj.debugDrawProxy:drawNodeVector(node.cid, vel * float3(0.3,0.3,0.3), col)
      ::continue::
    end
  elseif M.state.vehicle.nodeVis == 'forces' then
    local frc, c, col
    local newAvg = 0
    local nodeCount = 0
    local invAvgNodeForce = 1 / nodeForceAvg
    local frcMultiplier = float3(invAvgNodeForce, invAvgNodeForce, invAvgNodeForce)
    for _, node in pairs(v.data.nodes) do
      frc = obj:getNodeForceVector(node.cid)
      local frc_length = frc:length()
      newAvg = newAvg + frc_length
      nodeCount = nodeCount + 1
      c = math.min(255, (frc_length * invAvgNodeForce) * 255)
      col = color(c,0,0,c+100)
      obj.debugDrawProxy:drawNodeSphere(node.cid, 0.01, col)
      obj.debugDrawProxy:drawNodeVector3d(0.01, node.cid, frc * frcMultiplier, col)
      ::continue::
    end
    obj.debugDrawProxy:drawText2D(float3(40,40,0), color(0,0,0,255), "Average force: " .. string.format("%0.1f", nodeForceAvg))
    nodeForceAvg = (newAvg / (nodeCount + 1e-30)) * 10 + 300
  elseif M.state.vehicle.nodeVis == 'density' then
    local col
    local colorWater = color(255,0,0,200)
    local colorAir   = color(0,200,0,200)
    for _, node in pairs (v.data.nodes) do
      local inWater = obj:inWater(node.cid)
      if inWater then
        col = colorWater
      else
        col = colorAir
      end
      obj.debugDrawProxy:drawNodeSphere(node.cid, 0.02, col)
    end
  end

  obj.debugDrawProxy:drawText2D(float3(0,0,0), color(0,0,0,255), statusTxt)
end

local function updateDebugDraw()
  M.debugDraw = nop
  for k,v in pairs(M.state.vehicle) do
    if type(v) ~= "table" and v ~= M.origState.vehicle[k] and M.state.vehicleDebugVisible then
      M.debugDraw = debugDraw
    end
  end

  M.beamBroke = ((M.state.vehicle.beamVis == 'with broken' or M.state.vehicle.beamVis == 'broken only') and M.state.vehicleDebugVisible) and beamBroke or nop
  M.beamDeformed = ((M.state.vehicle.beamVis == 'deformation' or M.state.vehicle.beamVis == 'deformgroups') and M.state.vehicleDebugVisible) and beamDeformed or nop
end

local function sendState()
  updateDebugDraw()
  obj:executeJS("HookManager.trigger('BdebugUpdate', "..encodeJson(M.state)..");")
end

local function activated(m)
  if m then
    sendState()
  end
end

local function meshVisibilityChanged()
  if M.state.vehicle and obj.ibody then
    obj:setMeshNameAlpha((M.state.vehicle.meshVisibility or 100)/100, "", false)
  end
end

local function setFlexmeshDebugMode(newMode)
  M.state.vehicle.flexmeshdebug = newMode
  obj:queueGameEngineLua('be:getObjectByID('..tostring(obj:getID())..'):setFlexMeshDebugMode("'..tostring(M.state.vehicle.flexmeshdebug)..'")')
  sendState()
end

local function setState(state)
  --log('D', "lua","bdebug.setState called")
  --dump(state)
  M.state = state
  M.state.vehicle = M.state.vehicle or deepcopy(M.origState.vehicle)
  for k,v in pairs(M.state.vehicle) do
    if type(v) ~= "table" and v ~= M.origState.vehicle[k] then
      M.state.vehicleDebugVisible = true
    end
  end
  updateDebugDraw()
  meshVisibilityChanged()
  -- update flexbody debug state
  setFlexmeshDebugMode(M.state.vehicle.flexmeshdebug)
end

local function onDeserialized()
  --log('D', "lua","bdebug.onDeserialized()")
  --dump(M.state)
  sendState()
  meshVisibilityChanged()
end

local function reset()
  --log('D', "lua","bdebug.reset()")
end

local function init()
  --log('D', "lua","bdebug.init()")

  -- show all meshes
  obj:setMeshNameAlpha(1, "", false)
  sendState()
end

-- function used by the input subsystem - AND NOTHING ELSE
-- DO NOT use these from the UI
local function toggleEnabled()
  M.state.vehicleDebugVisible = not M.state.vehicleDebugVisible
  --  M.state.debugEnabled = not M.state.debugEnabled
  --  if M.state.debugEnabled then
  --    gui.message("vehicle.bdebug.enabled", 3, "debug")
  --  else
  --    gui.message("vehicle.bdebug.disabled", 3, "debug")
  --  end
  sendState()
end

local function getKey(dict, val)
  for k1,v1 in pairs(dict) do
    if v1 == val then return k1 end
  end
  return nil
end

local function skeletonModeChange(change)
  local i = getKey(M.state.vehicle.beamVis_modes, M.state.vehicle.beamVis)
  i = i + change
  if i > #M.state.vehicle.beamVis_modes then
    i = 1
  elseif i < 1 then
    i = #M.state.vehicle.beamVis_modes
  end
  M.state.vehicle.beamVis = M.state.vehicle.beamVis_modes[i]
  if M.state.vehicle.beamVis ~= M.origState.vehicle.beamVis then
    M.state.vehicleDebugVisible = true
  end
  gui.message({txt="vehicle.bdebug.beamVisMode", context={beamVisMode="vehicle.bdebug.beamVisMode."..M.state.vehicle.beamVis}}, 3, "debug")
  sendState()
end

local function nodetextModeChange(change)
  local i = getKey(M.state.vehicle.nodeText_modes, M.state.vehicle.nodeText)
  i = i + change
  if i > #M.state.vehicle.nodeText_modes then
    i = 1
  elseif i < 1 then
    i = #M.state.vehicle.nodeText_modes
  end
  M.state.vehicle.nodeText = M.state.vehicle.nodeText_modes[i]
  if M.state.vehicle.nodeText ~= M.origState.vehicle.nodeText then
    M.state.vehicleDebugVisible = true
  end
  gui.message({txt="vehicle.bdebug.nodeTextMode", context={nodeTextMode="vehicle.bdebug.nodeTextMode."..M.state.vehicle.nodeText}}, 3, "debug")
  sendState()
end

local function nodevisModeChange(change)
  local i = getKey(M.state.vehicle.nodeVis_modes, M.state.vehicle.nodeVis)
  i = i + change
  if i > #M.state.vehicle.nodeVis_modes then
    i = 1
  elseif i < 1 then
    i = #M.state.vehicle.nodeVis_modes
  end
  M.state.vehicle.nodeVis = M.state.vehicle.nodeVis_modes[i]
  if M.state.vehicle.nodeVis ~= M.origState.vehicle.nodeVis then
    M.state.vehicleDebugVisible = true
  end
  gui.message({txt="vehicle.bdebug.nodeVisMode", context={nodeVisMode="vehicle.bdebug.nodeVisMode."..M.state.vehicle.nodeVis}}, 3, "debug")
  sendState()
end

local function meshVisChange(val, isAbsoluteValue)
  if isAbsoluteValue then
    M.state.vehicle.meshVisibility = min(max(val * 100, 0), 100)
  else
    M.state.vehicle.meshVisibility = min(max(M.state.vehicle.meshVisibility + (val * 100), 0), 100)
  end
  gui.message({txt="vehicle.bdebug.meshVisibility", context={visibilityPercent=M.state.vehicle.meshVisibility}}, 3, "debug")
  meshVisibilityChanged()
  sendState()
end

local function resetModes()
  M.state = deepcopy(M.origState)
  gui.message("vehicle.bdebug.clear", 3, "debug")
  meshVisibilityChanged()
  sendState()
end

local function toggleColTris()
  M.state.vehicle.collisionTriangle = not M.state.vehicle.collisionTriangle
  if M.state.vehicle.collisionTriangle then
    gui.message("vehicle.bdebug.trisOn", 3, "debug")
  else
    gui.message("vehicle.bdebug.trisOff", 3, "debug")
  end
  if M.state.vehicle.collisionTriangle ~= M.origState.vehicle.collisionTriangle then
    M.state.vehicleDebugVisible = true
  end
  sendState()
end

local function cogChange(change)
  local i = M.state.vehicle.cog + change
  if i > #M.state.vehicle.cog_modes then
    i = 1
  elseif i < 1 then
    i = #M.state.vehicle.cog_modes
  end
  M.state.vehicle.cog = i
  if M.state.vehicle.cog ~= M.origState.vehicle.cog then
    M.state.vehicleDebugVisible = true
  end
  gui.message({txt="vehicle.bdebug.cogMode", context={cogMode="vehicle.bdebug.cogMode."..M.state.vehicle.cog_modes[i]}}, 3, "debug")
  sendState()
end

-- public interface
M.init = init
M.reset = reset
M.debugDraw = nop
M.beamBroke = nop
M.beamDeformed = nop
M.nodeCollision = nop
M.activated = activated
M.onDeserialized = onDeserialized
M.requestState = sendState
M.setState = setState

M.toggleEnabled = toggleEnabled
M.skeletonModeChange = skeletonModeChange
M.nodetextModeChange = nodetextModeChange
M.nodevisModeChange = nodevisModeChange
M.meshVisChange = meshVisChange
M.resetModes = resetModes
M.toggleColTris = toggleColTris
M.cogChange = cogChange
M.setFlexmeshDebugMode = setFlexmeshDebugMode

return M