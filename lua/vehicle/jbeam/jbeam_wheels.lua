--[[--
This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
If a copy of the bCDDL was not distributed with this
file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
This module contains a set of functions which manipulate behaviours of vehicles.
]]

require("jbeam_common")

function float3ToTable(f)
  return {x=f.x, y=f.y, z=f.z}
end

--[[doxygen
addWheel  add wheel
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addWheel(table vehicle, number wheelKey, table wheel);
--]]
function addWheel(vehicle, wheelKey, wheel)
  --log_jbeam('D', "jbeam.addWheel","wheel jbeam.")
  --dump(wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]
  local nodeArm = vehicle.nodes[wheel.nodeArm]

  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addWheel","invalid wheel")
    return
  end
  --[[
  log_jbeam('D', "jbeam.addWheel","wheel N1")
  dump(node1)
  log_jbeam('D', "jbeam.addWheel","wheel N2")
  dump(node2)
  log_jbeam('D', "jbeam.addWheel","wheel NArm")
  dump(nodeArm)

  log_jbeam('D', "jbeam.addWheel",">>>>")
  dump(vehicle)
  log_jbeam('D', "jbeam.addWheel","<<<<")
  ]]--

  local nodebase = vehicle.maxIDs.nodes

  if wheel.radius == nil then wheel.radius = 0.5 end
  if wheel.numRays == nil then wheel.numRays = 10 end

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- TODO: fix mass
  wheel.mass = nil

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)

  --log_jbeam('D', "jbeam.addWheel","n1 = " .. tostring(node1_pos) .. " , n2 = " .. tostring(node2_pos))

  local width = node1_pos:distance(node2_pos)
  --log_jbeam('D', "jbeam.addWheel","wheel width: "..width)

  -- swap nodes?
  if node1_pos.z > node2_pos.z then
    log_jbeam('D', "jbeam.addWheel","swapping wheel nodes ...")
    node1, node2 = node2, node1
  end

  -- calculate axis
  local axis = node2_pos - node1_pos
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  --log_jbeam('D', "jbeam.addWheel","wheel axis:" .. tostring(axis))


  local rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
  --log_jbeam('D', "jbeam.addWheel","rayVector: " .. tostring(rayVec))

  local rayRot = Quaternion():fromAngleAxis( -360 / (wheel.numRays* 2), axis)
  --log_jbeam('D', "jbeam.addWheel","rayRot: " .. tostring(rayRot))

  if wheel.tireWidth ~= nil then
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  -- add nodes first
  local wheelNodes = {}
  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
    table.insert(wheelNodes, n)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
    table.insert(wheelNodes, n)
  end

  -- then add the beams
  --local wheelBeams = {}
  local b = 0

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength

  local reinforcementOptions = deepcopy(wheel)
  reinforcementOptions.beamSpring   = reinforcementOptions.wheelReinforcementBeamSpring
  reinforcementOptions.beamDamp     = reinforcementOptions.wheelReinforcementBeamDamp
  reinforcementOptions.beamDeform   = reinforcementOptions.wheelReinforcementBeamDeform
  reinforcementOptions.beamStrength = reinforcementOptions.wheelReinforcementBeamStrength
  reinforcementOptions.springExpansion = reinforcementOptions.wheelReinforcementBeamSpringExpansion
  reinforcementOptions.dampExpansion   = reinforcementOptions.wheelReinforcementBeamDampExpansion

  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength
  treadOptions.springExpansion = treadOptions.wheelTreadBeamSpringExpansion
  treadOptions.dampExpansion   = treadOptions.wheelTreadBeamDampExpansion

  local peripheryOptions     = deepcopy(treadOptions)
  if peripheryOptions.wheelPeripheryBeamSpring ~=nil then peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring end
  if peripheryOptions.wheelPeripheryBeamDamp ~= nil then peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp end
  if peripheryOptions.wheelPeripheryBeamDeform ~= nil then peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform end
  if peripheryOptions.wheelPeripheryBeamStrength ~= nil then peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength end

  --dump(wheel)
  -- the rest
  for i = 0, wheel.numRays - 1, 1 do
    local intirenode = nodebase + 2*i
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + 2*((i+1)%wheel.numRays)
    local nextouttirenode = nextintirenode + 1
    -- sides
    b = addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_ANISOTROPIC, sideOptions)
    --table.insert(wheelBeams, b.cid)
    b = addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_ANISOTROPIC, sideOptions)
    --table.insert(wheelBeams, b.cid)

    -- reinforcement (X) beams
    b = addBeamWithOptions(vehicle, 'wheels', wheel.node2, intirenode,   BEAM_ANISOTROPIC,    reinforcementOptions)
    --table.insert(wheelBeams, b.cid)
    b = addBeamWithOptions(vehicle, 'wheels', wheel.node1, outtirenode, BEAM_ANISOTROPIC,    reinforcementOptions)
    --table.insert(wheelBeams, b.cid)

    -- tread
    b = addBeamWithOptions(vehicle, 'wheels', intirenode, outtirenode,  BEAM_ANISOTROPIC, treadOptions)
    --table.insert(wheelBeams, b.cid)
    -- Periphery beam
    b = addBeamWithOptions(vehicle, 'wheels', intirenode, nextintirenode, NORMALTYPE, peripheryOptions)
    --table.insert(wheelBeams, b.cid)
    -- Periphery beam
    b = addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)
    --table.insert(wheelBeams, b.cid)
    b = addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, BEAM_ANISOTROPIC, treadOptions)
    --table.insert(wheelBeams, b.cid)
  end

  -- record the wheel nodes
  wheel.nodes = wheelNodes
  -- record the wheel beams
  -- vehicle.wheels[wheelKey].beams = wheelBeams
end

--[[doxygen
addMonoHubWheel  add MonoHubwheel
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addMonoHubWheel(table vehicle, number wheelKey, table wheel);
--]]
function addMonoHubWheel(vehicle, wheelKey, wheel)
  --log_jbeam('D', "jbeam.addMonoHubWheel","wheel jbeam.")
  --dump(wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]
  local nodeArm = vehicle.nodes[wheel.nodeArm]

  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addMonoHubWheel","invalid monohub wheel")
    return
  end

  if wheel.radius == nil then    wheel.radius = 0.5 end
  if wheel.hubRadius == nil then wheel.hubRadius = 0.65 * wheel.radius end
  if wheel.numRays == nil then wheel.numRays = 10 end

  local nodebase = vehicle.maxIDs.nodes

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- TODO: fix mass
  wheel.mass = nil

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)

  --log_jbeam('D', "jbeam.addMonoHubWheel","n1 = " .. tostring(node1_pos) .. " , n2 = " .. tostring(node2_pos))

  local width = node1_pos:distance(node2_pos)
  --log_jbeam('D', "jbeam.addMonoHubWheel","monohub wheel width: "..width)

  -- swap nodes?
  if node1_pos.z > node2_pos.z then
    log_jbeam('D', "jbeam.addMonoHubWheel","swapping monohub wheel nodes ...")
    node1, node2 = node2, node1
  end

  -- calculate axis
  local axis = node2_pos - node1_pos
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheel.wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  --log_jbeam('D', "jbeam.addMonoHubWheel","wheel axis:" .. tostring(axis))

  local rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
  --log_jbeam('D', "jbeam.addMonoHubWheel","rayVector: " .. tostring(rayVec))

  local rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays* 2), axis)

  --log_jbeam('D', "jbeam.addMonoHubWheel","rayRot: " .. tostring(rayRot))

  if wheel.tireWidth ~= nil then
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  -- add nodes first
  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
  end

  -- then add the beams

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength

  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength
  treadOptions.springExpansion = treadOptions.wheelTreadBeamSpringExpansion
  treadOptions.dampExpansion   = treadOptions.wheelTreadBeamDampExpansion

  local peripheryOptions     = deepcopy(treadOptions)
  if peripheryOptions.wheelPeripheryBeamSpring ~=nil then peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring end
  if peripheryOptions.wheelPeripheryBeamDamp ~= nil then peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp end
  if peripheryOptions.wheelPeripheryBeamDeform ~= nil then peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform end
  if peripheryOptions.wheelPeripheryBeamStrength ~= nil then peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength end

  local hubOptions = deepcopy(wheel)
  if hubOptions.hubNodeWeight ~= nil then hubOptions.nodeWeight = hubOptions.hubNodeWeight end
  if hubOptions.hubCollision ~= nil then hubOptions.collision = hubOptions.hubCollision end
  if hubOptions.hubNodeMaterial ~= nil then hubOptions.nodeMaterial = hubOptions.hubNodeMaterial end
  if hubOptions.hubFrictionCoef ~= nil then hubOptions.frictionCoef = hubOptions.hubFrictionCoef end

  local supportOptions = deepcopy(hubOptions)
  supportOptions.beamPrecompression = (0.75 * wheel.hubRadius / wheel.radius) + 0.25

  for i = 0, wheel.numRays - 1, 1 do
    local intirenode = nodebase + 2*i
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + 2*((i+1)%wheel.numRays)
    local nextouttirenode = nextintirenode + 1
    -- Sides
    addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_ANISOTROPIC, sideOptions)
    addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_ANISOTROPIC, sideOptions)
    -- Tire tread
    addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode,    BEAM_ANISOTROPIC, treadOptions)
    addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, BEAM_ANISOTROPIC, treadOptions)
    -- Periphery beams
    addBeamWithOptions(vehicle, 'wheels', intirenode,  nextintirenode,  NORMALTYPE, peripheryOptions)
    addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)
    -- Support beams
    addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_SUPPORT, supportOptions)
    addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_SUPPORT, supportOptions)
  end

  -- monoHub
  local rayVec = axis:getPerpendicularVector() * float3(wheel.hubRadius, wheel.hubRadius, wheel.hubRadius)

  -- initial rotation
  local tmpRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays * 4), axis)

  rayVec = tmpRot:multiply(rayVec)
  -- all hub node rotation
  rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays), axis)
  --log_jbeam('D', "jbeam.addMonoHubWheel","rayVector: " .. tostring(rayVec))

  -- add monoHub nodes
  local hubNodes = {}
  local n = 0
  local hubnodebase = vehicle.maxIDs.nodes

  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = midpoint + rayVec
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    rayVec = rayRot:multiply(rayVec)
    table.insert(hubNodes, n)
  end

  if hubOptions.hubBeamSpring ~= nil then hubOptions.beamSpring = hubOptions.hubBeamSpring end
  if hubOptions.hubBeamDamp ~= nil then hubOptions.beamDamp = hubOptions.hubBeamDamp end
  if hubOptions.hubBeamDeform ~= nil then hubOptions.beamDeform = hubOptions.hubBeamDeform end
  if hubOptions.hubBeamStrength ~=nil then hubOptions.beamStrength = hubOptions.hubBeamStrength end

  -- hub-tire beams options
  local reinforcementOptions = deepcopy(wheel)
  reinforcementOptions.beamSpring   = reinforcementOptions.wheelReinforcementBeamSpring
  reinforcementOptions.beamDamp     = reinforcementOptions.wheelReinforcementBeamDamp
  reinforcementOptions.beamDeform   = reinforcementOptions.wheelReinforcementBeamDeform
  reinforcementOptions.beamStrength = reinforcementOptions.wheelReinforcementBeamStrength
  reinforcementOptions.springExpansion = reinforcementOptions.wheelReinforcementBeamSpringExpansion
  reinforcementOptions.dampExpansion   = reinforcementOptions.wheelReinforcementBeamDampExpansion

  for i = 0, wheel.numRays - 1, 1 do
    local hubnode = hubnodebase + i
    local nexthubnode = hubnodebase + ((i+1)%wheel.numRays)
    local intirenode = nodebase + 2*i
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + 2*((i+1)%wheel.numRays)
    -- hub-axis beams
    addBeamWithOptions(vehicle, 'wheels', wheel.node2, hubnode, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', wheel.node1, hubnode, NORMALTYPE, hubOptions)
    -- hub periphery beams
    addBeamWithOptions(vehicle, 'wheels', hubnode, nexthubnode, NORMALTYPE, hubOptions)

    -- hub-tire beams
    addBeamWithOptions(vehicle, 'wheels', hubnode, intirenode,  BEAM_ANISOTROPIC, reinforcementOptions)
    addBeamWithOptions(vehicle, 'wheels', hubnode, outtirenode, BEAM_ANISOTROPIC, reinforcementOptions)
    addBeamWithOptions(vehicle, 'wheels', hubnode, nextintirenode,  BEAM_ANISOTROPIC, reinforcementOptions)
    addBeamWithOptions(vehicle, 'wheels', outtirenode, nexthubnode, BEAM_ANISOTROPIC, reinforcementOptions)

  end

  wheel.nodes = hubNodes
end

--[[doxygen
addHubWheelTSV  add Hub wheel TSV
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addHubWheelTSV(table vehicle, number wheelKey, table wheel);
--]]
function addHubWheelTSV(vehicle, wheelKey, wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]
  local nodeArm = vehicle.nodes[wheel.nodeArm]

  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addHubWheelTSV","invalid hubWheel")
    return
  end

  local nodebase = vehicle.maxIDs.nodes
  wheel.treadCoef = wheel.treadCoef or 1
  if wheel.radius == nil then    wheel.radius = 0.5 end
  if wheel.hubRadius == nil then wheel.hubRadius = 0.65 * wheel.radius end
  if wheel.numRays == nil then wheel.numRays = 10 end

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)

  local width = node1_pos:distance(node2_pos)

  -- swap nodes?
  if node1_pos.z > node2_pos.z then
    log_jbeam('D', "jbeam.addHubWheelTSV","swapping hubWheel nodes ...")
    node1, node2 = node2, node1
  end

  -- calculate axis
  local axis = node2_pos - node1_pos
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheel.wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  if wheel.tireWidth ~= nil then
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  local rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
  local rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays* 2), axis)

  -- add nodes first
  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
  end

  -- add Hub nodes
  local hubNodes = {}
  local n = 0
  local hubnodebase = vehicle.maxIDs.nodes

  local hubOptions = deepcopy(wheel)
  if hubOptions.hubBeamSpring ~= nil then hubOptions.beamSpring = hubOptions.hubBeamSpring end
  if hubOptions.hubBeamDamp ~= nil then hubOptions.beamDamp = hubOptions.hubBeamDamp end
  if hubOptions.hubBeamDeform ~= nil then hubOptions.beamDeform = hubOptions.hubBeamDeform end
  if hubOptions.hubBeamStrength ~=nil then hubOptions.beamStrength = hubOptions.hubBeamStrength end
  if hubOptions.hubNodeWeight ~= nil then hubOptions.nodeWeight = hubOptions.hubNodeWeight end
  if hubOptions.hubCollision ~= nil then hubOptions.collision = hubOptions.hubCollision end
  if hubOptions.hubNodeMaterial ~= nil then hubOptions.nodeMaterial = hubOptions.hubNodeMaterial end
  if hubOptions.hubFrictionCoef ~= nil then hubOptions.frictionCoef = hubOptions.hubFrictionCoef end

  rayVec = axis:getPerpendicularVector() * float3(wheel.hubRadius, wheel.hubRadius, wheel.hubRadius)

  if wheel.hubWidth ~= nil then
    local halfWidth = 0.5 * wheel.hubWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)

    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)
  end

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength

  -- hub-tire beams options
  local reinforcementOptions = deepcopy(wheel)
  reinforcementOptions.beamSpring   = reinforcementOptions.wheelReinforcementBeamSpring
  reinforcementOptions.beamDamp     = reinforcementOptions.wheelReinforcementBeamDamp
  reinforcementOptions.beamDeform   = reinforcementOptions.wheelReinforcementBeamDeform
  reinforcementOptions.beamStrength = reinforcementOptions.wheelReinforcementBeamStrength
  reinforcementOptions.springExpansion = reinforcementOptions.wheelReinforcementBeamSpringExpansion
  reinforcementOptions.dampExpansion   = reinforcementOptions.wheelReinforcementBeamDampExpansion

  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength
  treadOptions.springExpansion = treadOptions.wheelTreadBeamSpringExpansion
  treadOptions.dampExpansion   = treadOptions.wheelTreadBeamDampExpansion

  local peripheryOptions     = deepcopy(treadOptions)
  if peripheryOptions.wheelPeripheryBeamSpring ~=nil then peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring end
  if peripheryOptions.wheelPeripheryBeamDamp ~= nil then peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp end
  if peripheryOptions.wheelPeripheryBeamDeform ~= nil then peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform end
  if peripheryOptions.wheelPeripheryBeamStrength ~= nil then peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength end

  local supportOptions = deepcopy(hubOptions)
  supportOptions.beamPrecompression = (0.75 * wheel.hubRadius / wheel.radius) + 0.25

  local reinforcementBeams = {}
  local sideBeams = {}
  local treadBeams = {}

  for i = 0, wheel.numRays - 1, 1 do
    local i2 = 2*i
    local nextdelta = 2*((i+1)%wheel.numRays)
    local outhubnode = hubnodebase + i2
    local inhubnode = outhubnode + 1
    local nextouthubnode = hubnodebase + nextdelta
    local nextinhubnode = nextouthubnode + 1
    local intirenode = nodebase + i2
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + nextdelta
    local nextouttirenode = nextintirenode + 1
    --tire tread
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode,    BEAM_ANISOTROPIC, treadOptions) )
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, BEAM_ANISOTROPIC, treadOptions) )
    -- Periphery beams
    addBeamWithOptions(vehicle, 'wheels', intirenode,  nextintirenode,  NORMALTYPE, peripheryOptions)
    addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)

    --hub tread
    addBeamWithOptions(vehicle, 'wheels', outhubnode, inhubnode,      NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextouthubnode, NORMALTYPE, hubOptions)
    --hub periphery beams
    addBeamWithOptions(vehicle, 'wheels', outhubnode, nextouthubnode, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextinhubnode,  NORMALTYPE, hubOptions)

    --hub axis beams
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node1, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node2, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node1, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node2, NORMALTYPE, hubOptions)

    --hub tire beams
    table.insert( reinforcementBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  intirenode,     BEAM_ANISOTROPIC, reinforcementOptions) )
    table.insert( reinforcementBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    BEAM_ANISOTROPIC, reinforcementOptions) )
    table.insert( sideBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  outtirenode,    BEAM_ANISOTROPIC, sideOptions) )
    table.insert( sideBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouthubnode, BEAM_ANISOTROPIC, sideOptions) )
    table.insert( sideBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   intirenode,     BEAM_ANISOTROPIC, sideOptions) )
    table.insert( sideBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   nextintirenode, BEAM_ANISOTROPIC, sideOptions) )

    -- Support beams
    if wheel.enableTireSideSupportBeams then
      addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_SUPPORT, supportOptions)
      addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_SUPPORT, supportOptions)
    end
  end

  wheel.nodes = hubNodes
  wheel.reinforcementBeams = reinforcementBeams
  wheel.sideBeams = sideBeams
  wheel.treadBeams = treadBeams
end

--[[doxygen
addHubWheelTSI  add Hub wheel TSI
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addHubWheelTSI(table vehicle, number wheelKey, table wheel);
--]]
function addHubWheelTSI(vehicle, wheelKey, wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]
  local nodeArm = vehicle.nodes[wheel.nodeArm]

  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addHubWheelTSI","invalid hubWheel")
    return
  end

  local nodebase = vehicle.maxIDs.nodes
  wheel.treadCoef = wheel.treadCoef or 1
  if wheel.radius == nil then    wheel.radius = 0.5 end
  if wheel.hubRadius == nil then wheel.hubRadius = 0.65 * wheel.radius end
  if wheel.numRays == nil then wheel.numRays = 10 end

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)
  local width = node1_pos:distance(node2_pos)

  -- swap nodes?
  if node1_pos.z > node2_pos.z then
    log_jbeam('D', "jbeam.addHubWheelTSI","swapping hubWheel nodes ...")
    node1, node2 = node2, node1
  end

  -- calculate axis
  local axis = node2_pos - node1_pos
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheel.wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  if wheel.tireWidth ~= nil then
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  else
    wheel.tireWidth = width
  end

  local rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
  local rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays* 2), axis)

  -- add nodes first
  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
  end

  -- add Hub nodes
  local hubNodes = {}
  local n = 0
  local hubnodebase = vehicle.maxIDs.nodes

  local hubOptions = deepcopy(wheel)
  if hubOptions.hubBeamSpring ~= nil then hubOptions.beamSpring = hubOptions.hubBeamSpring end
  if hubOptions.hubBeamDamp ~= nil then hubOptions.beamDamp = hubOptions.hubBeamDamp end
  if hubOptions.hubBeamDeform ~= nil then hubOptions.beamDeform = hubOptions.hubBeamDeform end
  if hubOptions.hubBeamStrength ~=nil then hubOptions.beamStrength = hubOptions.hubBeamStrength end
  if hubOptions.hubNodeWeight ~= nil then hubOptions.nodeWeight = hubOptions.hubNodeWeight end
  if hubOptions.hubCollision ~= nil then hubOptions.collision = hubOptions.hubCollision end
  if hubOptions.hubNodeMaterial ~= nil then hubOptions.nodeMaterial = hubOptions.hubNodeMaterial end
  if hubOptions.hubFrictionCoef ~= nil then hubOptions.frictionCoef = hubOptions.hubFrictionCoef end

  rayVec = axis:getPerpendicularVector() * float3(wheel.hubRadius, wheel.hubRadius, wheel.hubRadius)

  if wheel.hubWidth ~= nil then
    local halfWidth = 0.5 * wheel.hubWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  else
    wheel.hubWidth = width
  end

  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)
  end

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength

  -- hub-tire beams options
  local reinforcementOptions = deepcopy(wheel)
  reinforcementOptions.beamSpring   = reinforcementOptions.wheelReinforcementBeamSpring
  reinforcementOptions.beamDamp     = reinforcementOptions.wheelReinforcementBeamDamp
  reinforcementOptions.beamDeform   = reinforcementOptions.wheelReinforcementBeamDeform
  reinforcementOptions.beamStrength = reinforcementOptions.wheelReinforcementBeamStrength
  reinforcementOptions.springExpansion = reinforcementOptions.wheelReinforcementBeamSpringExpansion
  reinforcementOptions.dampExpansion   = reinforcementOptions.wheelReinforcementBeamDampExpansion

  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength
  treadOptions.springExpansion = treadOptions.wheelTreadBeamSpringExpansion
  treadOptions.dampExpansion   = treadOptions.wheelTreadBeamDampExpansion

  local peripheryOptions     = deepcopy(treadOptions)
  if peripheryOptions.wheelPeripheryBeamSpring ~=nil then peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring end
  if peripheryOptions.wheelPeripheryBeamDamp ~= nil then peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp end
  if peripheryOptions.wheelPeripheryBeamDeform ~= nil then peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform end
  if peripheryOptions.wheelPeripheryBeamStrength ~= nil then peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength end

  local supportOptions = deepcopy(hubOptions)
  supportOptions.beamPrecompression = (0.75 * wheel.hubRadius / wheel.radius) + 0.25

  local pressuredOptions = deepcopy(reinforcementOptions)
  pressuredOptions.pressurePSI = pressuredOptions.pressurePSI or 30
  pressuredOptions.beamSpring = pressuredOptions.pressureSpring or pressuredOptions.springExpansion
  pressuredOptions.beamDamp = pressuredOptions.pressureDamp or pressuredOptions.dampExpansion
  pressuredOptions.volumeCoef = 1 / (wheel.numRays * 6)
  pressuredOptions.surface = math.pi * (
                wheel.radius * wheel.tireWidth + wheel.hubRadius * wheel.hubWidth
                + wheel.radius * wheel.radius - wheel.hubRadius * wheel.hubRadius) / (wheel.numRays * 6)

  local reinfPressureOptions = deepcopy(pressuredOptions)
  reinfPressureOptions.pressurePSI = reinfPressureOptions.reinforcementPressurePSI or reinfPressureOptions.pressurePSI
  reinfPressureOptions.beamSpring = reinfPressureOptions.reinforcementPressureSpring or reinfPressureOptions.beamSpring
  reinfPressureOptions.beamDamp = reinfPressureOptions.reinforcementPressureDamp or reinfPressureOptions.beamDamp

  local pressuredBeams = {}
  local treadBeams = {}
  local reinforcementBeams = {}

  for i = 0, wheel.numRays - 1, 1 do
    local i2 = 2*i
    local nextdelta = 2*((i+1)%wheel.numRays)
    local inhubnode = hubnodebase + i2
    local outhubnode = inhubnode + 1
    local nextinhubnode = hubnodebase + nextdelta
    local nextouthubnode = nextinhubnode + 1
    local intirenode = nodebase + i2
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + nextdelta
    local nextouttirenode = nextintirenode + 1

    --tire tread
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode,    BEAM_ANISOTROPIC, treadOptions) )
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, BEAM_ANISOTROPIC, treadOptions) )

    -- paired treadnodes
    vehicle.nodes[intirenode].pairedNode = outtirenode
    vehicle.nodes[outtirenode].pairedNode = nextintirenode

    -- Periphery beams
    addBeamWithOptions(vehicle, 'wheels', intirenode,  nextintirenode,  NORMALTYPE, peripheryOptions)
    addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)

    --hub tread
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  outhubnode,    NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', outhubnode, nextinhubnode, NORMALTYPE, hubOptions)

    --hub periphery beams
    addBeamWithOptions(vehicle, 'wheels', outhubnode, nextouthubnode, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextinhubnode,  NORMALTYPE, hubOptions)

    --hub axis beams
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node1, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node2, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node1, NORMALTYPE, hubOptions)
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node2, NORMALTYPE, hubOptions)

    --hub tire beams
    -- table.insert( sideBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', inhubnode,   intirenode,     BEAM_ANISOTROPIC, sideOptions) )
    -- table.insert( sideBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', outhubnode,  outtirenode,    BEAM_ANISOTROPIC, sideOptions) )
    -- table.insert( reinforcementBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', intirenode,  outhubnode,     BEAM_ANISOTROPIC, reinforcementOptions)    )
    -- table.insert( reinforcementBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    BEAM_ANISOTROPIC, reinforcementOptions) )
    -- table.insert( reinforcementBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', outtirenode, nextinhubnode,  BEAM_ANISOTROPIC, reinforcementOptions) )
    -- table.insert( reinforcementBeams,
    --     self:addBeamWithOptions(vehicle, 'wheels', outhubnode,  nextintirenode, BEAM_ANISOTROPIC, reinforcementOptions)    )

    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   intirenode,     BEAM_PRESSURED, pressuredOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  outtirenode,    BEAM_PRESSURED, pressuredOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', intirenode,  outhubnode,     BEAM_PRESSURED, reinfPressureOptions)    )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    BEAM_PRESSURED, reinfPressureOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextinhubnode,  BEAM_PRESSURED, reinfPressureOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  nextintirenode, BEAM_PRESSURED, reinfPressureOptions) )

    --tire side V beams
    -- if wheel.enableTireSideVBeams ~= nil and wheel.enableTireSideVBeams == true then
    --     self:addBeamWithOptions(vehicle, 'wheels', outtirenode,    nextouthubnode,  BEAM_ANISOTROPIC, sideOptions)
    --     self:addBeamWithOptions(vehicle, 'wheels', outhubnode,     nextouttirenode, BEAM_ANISOTROPIC, sideOptions)
    --     self:addBeamWithOptions(vehicle, 'wheels', nextintirenode, inhubnode,       BEAM_ANISOTROPIC, sideOptions)
    --     self:addBeamWithOptions(vehicle, 'wheels', nextinhubnode,  intirenode,      BEAM_ANISOTROPIC, sideOptions)
    -- end

    -- Support beams
    if wheel.enableTireSideSupportBeams then
      addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_SUPPORT, supportOptions)
      addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_SUPPORT, supportOptions)
    end
  end

  wheel.nodes = hubNodes
  wheel.pressuredBeams = pressuredBeams
  -- wheel.treadBeams = treadBeams
end

--[[doxygen
addHubWheel  add Hub wheel
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addHubWheel(table vehicle, number wheelKey, table wheel);
--]]
function addHubWheel(vehicle, wheelKey, wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]
  local nodeArm = vehicle.nodes[wheel.nodeArm]
  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addHubWheel","invalid hubWheel")
    return
  end

  local nodebase = vehicle.maxIDs.nodes
  wheel.treadCoef = wheel.treadCoef or 1

  if wheel.radius == nil then    wheel.radius = 0.5 end
  if wheel.hubRadius == nil then wheel.hubRadius = 0.65 * wheel.radius end
  if wheel.numRays == nil then wheel.numRays = 10    end

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)

  --log_jbeam('D', "jbeam.addHubWheel","n1 = " .. tostring(node1_pos) .. " , n2 = " .. tostring(node2_pos))

  local tireWidth = node1_pos:distance(node2_pos)
  local hubWidth = tireWidth
  --log_jbeam('D', "jbeam.addHubWheel","hubWheel width: "..width)

  -- swap nodes?
  if node1_pos.z > node2_pos.z then
    log_jbeam('D', "jbeam.addHubWheel","swapping hubWheel nodes ...")
    node1, node2 = node2, node1
  end

  -- calculate axis
  local axis = node2_pos - node1_pos
  local axisLength = axis:length()
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheel.wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  if wheel.tireWidth ~= nil then
    tireWidth = wheel.tireWidth
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  --log_jbeam('D', "jbeam.addHubWheel","wheel axis:" .. tostring(axis))

  local rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
  --log_jbeam('D', "jbeam.addHubWheel","rayVector: " .. tostring(rayVec))

  local rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays* 2), axis)
  --log_jbeam('D', "jbeam.addHubWheel","rayRot: " .. tostring(rayRot))

  -- add tire nodes first
  local n = 0
  local rayPoint
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
  end

  -- add Hub nodes
  local hubNodes = {}
  local n = 0
  local hubnodebase = vehicle.maxIDs.nodes

  local hubOptions = deepcopy(wheel)
  hubOptions.beamSpring = hubOptions.hubBeamSpring or hubOptions.beamSpring
  hubOptions.beamDamp = hubOptions.hubBeamDamp or hubOptions.beamDamp
  hubOptions.beamDeform = hubOptions.hubBeamDeform or hubOptions.beamDeform
  hubOptions.beamStrength = hubOptions.hubBeamStrength or hubOptions.beamStrength
  hubOptions.nodeWeight = hubOptions.hubNodeWeight or hubOptions.nodeWeight
  hubOptions.collision = hubOptions.hubCollision or hubOptions.collision
  hubOptions.nodeMaterial = hubOptions.hubNodeMaterial or hubOptions.nodeMaterial
  hubOptions.frictionCoef = hubOptions.hubFrictionCoef or hubOptions.frictionCoef

  rayVec = axis:getPerpendicularVector() * float3(wheel.hubRadius, wheel.hubRadius, wheel.hubRadius)

  if wheel.hubWidth ~= nil then
    hubWidth = wheel.hubWidth
    local halfWidth = 0.5 * wheel.hubWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- outer
    rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)

    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)
  end

  -- Hub Cap
  local hubcapOptions = deepcopy(wheel)
  hubcapOptions.beamSpring = hubcapOptions.hubcapBeamSpring or hubcapOptions.beamSpring
  hubcapOptions.beamDamp = hubcapOptions.hubcapBeamDamp or hubcapOptions.beamDamp
  hubcapOptions.beamDeform = hubcapOptions.hubcapBeamDeform or hubcapOptions.beamDeform
  hubcapOptions.beamStrength = hubcapOptions.hubcapBeamStrength or hubcapOptions.beamStrength
  hubcapOptions.nodeWeight = hubcapOptions.hubcapNodeWeight or hubcapOptions.nodeWeight
  hubcapOptions.collision = hubcapOptions.hubcapCollision or hubcapOptions.collision
  hubcapOptions.nodeMaterial = hubcapOptions.hubcapNodeMaterial or hubcapOptions.nodeMaterial
  hubcapOptions.frictionCoef = hubcapOptions.hubcapFrictionCoef or hubcapOptions.frictionCoef
  hubcapOptions.hubcapRadius = hubcapOptions.hubcapRadius or hubcapOptions.hubRadius
  hubcapOptions.group = hubcapOptions.hubcapGroup or hubcapOptions.group
  hubcapOptions.wheelID = nil

  local hubcapnodebase
  if wheel.enableHubcaps ~= nil and wheel.enableHubcaps == true and wheel.numRays%2 ~= 1 then
    local hubcapOffset
    if wheel.hubcapOffset ~= nil then
      hubcapOffset = wheel.hubcapOffset
      hubcapOffset = axis * float3(hubcapOffset, hubcapOffset, hubcapOffset)
    end

    local n = 0
    hubcapnodebase = vehicle.maxIDs.nodes

    local hubCapNumRays = wheel.numRays/2
    rayVec = axis:getPerpendicularVector() * float3(hubcapOptions.hubcapRadius, hubcapOptions.hubcapRadius, hubcapOptions.hubcapRadius)

    local tmpRot = Quaternion():fromAngleAxis(-360 / (hubCapNumRays * 4), axis)

    rayVec = tmpRot:multiply(rayVec)
    -- all hub node rotation
    rayRot = Quaternion():fromAngleAxis(-360 / (hubCapNumRays), axis)

    for i = 0, hubCapNumRays -1, 1 do
      local rayPoint = node1_pos + rayVec - hubcapOffset
      rayVec = rayRot:multiply(rayVec)
      n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubcapOptions)
    end

    --hubcapOptions.collision = false
    --hubcapOptions.selfCollision = false
    hubcapOptions.nodeWeight = wheel.hubcapCenterNodeWeight
    --make the center rigidifying node
    local hubcapAxis = node1_pos + axis * float3(wheel.hubcapWidth,wheel.hubcapWidth,wheel.hubcapWidth)
    n = addNodeWithOptions(vehicle, 'wheels', hubcapAxis, NORMALTYPE, hubcapOptions)

    --hubcapOptions.collision = nil
    --hubcapOptions.selfCollision = nil
    hubcapOptions.nodeWeight = nil
  end

  local hubcapAttachOptions = deepcopy(wheel)
  hubcapAttachOptions.beamSpring = hubcapAttachOptions.hubcapAttachBeamSpring or hubcapAttachOptions.beamSpring
  hubcapAttachOptions.beamDamp = hubcapAttachOptions.hubcapAttachBeamDamp or hubcapAttachOptions.beamDamp
  hubcapAttachOptions.beamDeform = hubcapAttachOptions.hubcapAttachBeamDeform or hubcapAttachOptions.beamDeform
  hubcapAttachOptions.beamStrength = hubcapAttachOptions.hubcapAttachBeamStrength or hubcapAttachOptions.beamStrength
  hubcapAttachOptions.breakGroup = hubcapAttachOptions.hubcapBreakGroup or hubcapAttachOptions.breakGroup
  hubcapAttachOptions.wheelID = nil

  -- hub-tire beams options
  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring or treadOptions.beamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp or treadOptions.beamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform or treadOptions.beamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength or treadOptions.beamStrength
  treadOptions.springExpansion = treadOptions.wheelTreadBeamSpringExpansion or treadOptions.springExpansion
  treadOptions.dampExpansion   = treadOptions.wheelTreadBeamDampExpansion or treadOptions.dampExpansion

  local enableTreadReinforcementBeams = false
  if wheel.enableTreadReinforcementBeams ~= nil and wheel.enableTreadReinforcementBeams == true then
    enableTreadReinforcementBeams = true
  end

  local treadReinfOptions           = deepcopy(treadOptions)
  treadReinfOptions.beamSpring      = treadReinfOptions.wheelTreadReinforcementBeamSpring or treadReinfOptions.beamSpring
  treadReinfOptions.beamDamp        = treadReinfOptions.wheelTreadReinforcementBeamDamp or treadReinfOptions.beamDamp
  treadReinfOptions.beamDeform      = treadReinfOptions.wheelTreadReinforcementBeamDeform or treadReinfOptions.beamDeform
  treadReinfOptions.beamStrength    = treadReinfOptions.wheelTreadReinforcementBeamStrength or treadReinfOptions.beamStrength

  local peripheryOptions     = deepcopy(treadOptions)
  peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring or peripheryOptions.beamSpring
  peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp or peripheryOptions.beamDamp
  peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform or peripheryOptions.beamDeform
  peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength or peripheryOptions.beamStrength

  local supportOptions = deepcopy(hubOptions)
  supportOptions.beamPrecompression = (0.75 * wheel.hubRadius / wheel.radius) + 0.25

  -- Pressured Beam options
  local sideBeamLength =     wheel.radius - wheel.hubRadius
  local reinfBeamLength = math.sqrt(sideBeamLength * sideBeamLength + axisLength * axisLength)
  local pressuredOptions = deepcopy(wheel)
  pressuredOptions.pressurePSI = pressuredOptions.pressurePSI or 30
  pressuredOptions.beamSpring = pressuredOptions.pressureSpring or pressuredOptions.springExpansion
  pressuredOptions.beamDamp = pressuredOptions.pressureDamp or pressuredOptions.dampExpansion
  pressuredOptions.beamStrength = pressuredOptions.pressureStrength or pressuredOptions.beamStrength
  pressuredOptions.beamDeform = pressuredOptions.pressureDeform or pressuredOptions.beamDeform
  pressuredOptions.volumeCoef = 1 --2 * sideBeamLength / (wheel.numRays * sideBeamLength) --sideBeamLength / (wheel.numRays * (2 * sideBeamLength + 4 * reinfBeamLength))
  pressuredOptions.surface = math.pi * (wheel.radius * tireWidth + wheel.hubRadius * hubWidth) / (wheel.numRays*2)

  local reinfPressureOptions = deepcopy(pressuredOptions)
  reinfPressureOptions.pressurePSI = reinfPressureOptions.reinforcementPressurePSI or reinfPressureOptions.pressurePSI
  reinfPressureOptions.beamSpring = reinfPressureOptions.reinforcementPressureSpring or reinfPressureOptions.pressureSpring
  reinfPressureOptions.beamDamp = reinfPressureOptions.reinforcementPressureDamp or reinfPressureOptions.pressureDamp
  reinfPressureOptions.beamStrength = reinfPressureOptions.reinforcementPressureStrength or reinfPressureOptions.pressureStrength
  reinfPressureOptions.beamDeform = reinfPressureOptions.reinforcementPressureDeform or reinfPressureOptions.pressureDeform
  reinfPressureOptions.volumeCoef = 1 --reinfBeamLength / (wheel.numRays * (2 * sideBeamLength + 4 * reinfBeamLength))
  reinfPressureOptions.surface = math.pi * (wheel.radius*wheel.radius - wheel.hubRadius*wheel.hubRadius) / (wheel.numRays*4)

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring or 0
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp or 0
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform or sideOptions.beamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength or sideOptions.beamStrength
  sideOptions.springExpansion = sideOptions.wheelSideBeamSpringExpansion or sideOptions.springExpansion
  sideOptions.dampExpansion   = sideOptions.wheelSideBeamDampExpansion or sideOptions.dampExpansion

  local VDisplacement = wheel.wheelSideDisplacement or 1

  local enableVbeams = false
  if wheel.enableTireSideVBeams ~= nil and wheel.enableTireSideVBeams == true then
    enableVbeams = true
  end

  local pressuredBeams = {}
  local treadBeams = {}
  local b = 0
  for i = 0, wheel.numRays - 1, 1 do
    local i2 = 2*i
    local nextdelta = 2*((i+1)%wheel.numRays)
    local inhubnode = hubnodebase + i2
    local outhubnode = inhubnode + 1
    local nextinhubnode = hubnodebase + nextdelta
    local nextouthubnode = nextinhubnode + 1
    local intirenode = nodebase + i2
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + nextdelta
    local nextouttirenode = nextintirenode + 1

    if wheel.enableHubcaps ~= nil and wheel.enableHubcaps == true and wheel.numRays%2 ~= 1 and i < ((wheel.numRays)/2) then
      local hubcapnode = hubcapnodebase + i
      local nexthubcapnode = hubcapnodebase + ((i+1)%(wheel.numRays/2))
      local nextnexthubcapnode = hubcapnodebase + ((i+2)%(wheel.numRays/2))
      local hubcapaxisnode = hubcapnode + (wheel.numRays/2) - i
      local hubcapinhubnode = inhubnode + i2
      local nexthubcapinhubnode = hubcapinhubnode + 2
      local hubcapouthubnode = hubcapinhubnode + 1

      --hubcap periphery
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nexthubcapnode,    NORMALTYPE, hubcapOptions)
      --attach to center node
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapaxisnode,    NORMALTYPE, hubcapOptions)
      --attach to axis
      if wheel.enableExtraHubcapBeams == true then
        addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node1, NORMALTYPE, hubcapOptions)
        addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node2, NORMALTYPE, hubcapOptions)
        if i == 1 then
          addBeamWithOptions(vehicle, 'wheels', hubcapaxisnode, wheel.node1, NORMALTYPE, hubcapOptions)
          addBeamWithOptions(vehicle, 'wheels', hubcapaxisnode, wheel.node2, NORMALTYPE, hubcapOptions)
        end
      end

      --span beams
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nextnexthubcapnode,    NORMALTYPE, hubcapOptions)

      --attach it
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapinhubnode,    NORMALTYPE, hubcapAttachOptions)
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nexthubcapinhubnode,    NORMALTYPE, hubcapAttachOptions)
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapouthubnode,    BEAM_SUPPORT, hubcapAttachOptions)

      --self:addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node1,    NORMALTYPE, hubcapAttachOptions)
      --self:addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node2,    NORMALTYPE, hubcapAttachOptions)
    end

    --tire tread
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode,    BEAM_ANISOTROPIC, treadOptions) )
    table.insert( treadBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, BEAM_ANISOTROPIC, treadOptions) )

    -- paired treadnodes
    vehicle.nodes[intirenode].pairedNode = outtirenode
    vehicle.nodes[outtirenode].pairedNode = nextintirenode

    -- Periphery beams
    b = addBeamWithOptions(vehicle, 'wheels', intirenode,  nextintirenode,  NORMALTYPE, peripheryOptions)
    b = addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)

    --hub tread
    b = addBeamWithOptions(vehicle, 'wheels', inhubnode,  outhubnode,      NORMALTYPE, hubOptions)
    b = addBeamWithOptions(vehicle, 'wheels', outhubnode, nextinhubnode, NORMALTYPE, hubOptions)

    --hub periphery beams
    b = addBeamWithOptions(vehicle, 'wheels', outhubnode, nextouthubnode, NORMALTYPE, hubOptions)
    b = addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextinhubnode,  NORMALTYPE, hubOptions)

    --hub axis beams
    b = addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node1, NORMALTYPE, hubOptions)
    b = addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node2, NORMALTYPE, hubOptions)
    b = addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node1, NORMALTYPE, hubOptions)
    b = addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node2, NORMALTYPE, hubOptions)

    --hub tire beams
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   intirenode,     BEAM_PRESSURED, pressuredOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  outtirenode,    BEAM_PRESSURED, pressuredOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', intirenode,  outhubnode,     BEAM_PRESSURED, reinfPressureOptions)    )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    BEAM_PRESSURED, reinfPressureOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextinhubnode,  BEAM_PRESSURED, reinfPressureOptions) )
    table.insert( pressuredBeams,
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  nextintirenode, BEAM_PRESSURED, reinfPressureOptions) )

    --tire side V beams
    if enableVbeams then
      local inhubDnode = hubnodebase + 2*((i+1-VDisplacement)%wheel.numRays)
      local outhubDnode = inhubDnode + 1
      local nextinhubDnode = hubnodebase + 2*((i+VDisplacement)%wheel.numRays)
      local nextouthubDnode = nextinhubDnode + 1
      b = addBeamWithOptions(vehicle, 'wheels', outtirenode,  nextouthubDnode,  BEAM_ANISOTROPIC, sideOptions)
      b = addBeamWithOptions(vehicle, 'wheels', outhubDnode,   nextouttirenode, BEAM_ANISOTROPIC, sideOptions)
      b = addBeamWithOptions(vehicle, 'wheels', nextintirenode, inhubDnode,  BEAM_ANISOTROPIC, sideOptions)
      b = addBeamWithOptions(vehicle, 'wheels', nextinhubDnode,  intirenode, BEAM_ANISOTROPIC, sideOptions)
    end

    if enableTreadReinforcementBeams then
      local intirenode2 = nodebase + 2*((i+2)%wheel.numRays)
      local outtirenode2 = intirenode2 + 1
      table.insert( treadBeams,
        addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode2, NORMALTYPE, treadReinfOptions) )
      table.insert( treadBeams,
        addBeamWithOptions(vehicle, 'wheels', outtirenode, intirenode2, NORMALTYPE, treadReinfOptions) )
    end

    -- Support beams
    if wheel.enableTireSideSupportBeams then
      addBeamWithOptions(vehicle, 'wheels', wheel.node1, intirenode,  BEAM_SUPPORT, supportOptions)
      addBeamWithOptions(vehicle, 'wheels', wheel.node2, outtirenode, BEAM_SUPPORT, supportOptions)
    end
  end

  wheel.nodes = hubNodes
  wheel.pressuredBeams = pressuredBeams
end

--[[doxygen
addPressureWheel  add Pressure wheel
@param vehicle    a table type for vehicle
@param wheelKey    wheel key
@param wheel    a table type for wheel
@return void
void addPressureWheel(table vehicle, number wheelKey, table wheel);
--]]
function addPressureWheel(vehicle, wheelKey, wheel)
  local node1   = vehicle.nodes[wheel.node1]
  local node2   = vehicle.nodes[wheel.node2]

  -- Stabilizer
  wheel.nodeStabilizer = wheel.nodeStabilizer or wheel.nodeS
  wheel.treadCoef = wheel.treadCoef or 1
  wheel.nodeS = nil
  local nodeStabilizerExists = false
  local wheelAngle = wheel.wheelAngle or 0

  if wheel.nodeStabilizer and wheel.nodeStabilizer ~= 9999 and vehicle.nodes[wheel.nodeStabilizer] then
    nodeStabilizerExists = true
  else
    wheel.nodeStabilizer = nil
  end

  if node1 == nil or node2 == nil then
    log_jbeam('W', "jbeam.addPressureWheel","invalid pressureWheel")
    return
  end

  local nodebase = vehicle.maxIDs.nodes

  local tireExists = true
  if wheel.radius == nil then
    tireExists = false
    wheel.radius = 0.5
  end

  if wheel.pressurePSI == nil then
    tireExists = false
  end

  if wheel.hasTire ~= nil and wheel.hasTire == false then
    tireExists = false
  end

  if wheel.hubRadius == nil then wheel.hubRadius = 0.65 * wheel.radius end
  if wheel.numRays == nil then wheel.numRays = 10 end

  -- add collision to the wheels nodes ;)
  wheel.collision = true

  -- fix it like this
  local node1_pos = tableToFloat3(node1.pos)
  local node2_pos = tableToFloat3(node2.pos)

  local width = node1_pos:distance(node2_pos)

  -- calculate axis
  local axis = node2_pos - node1_pos
  axis:normalize()

  local midpoint = (node2_pos + node1_pos) * float3(0.5, 0.5, 0.5)
  if wheel.wheelOffset ~= nil then
    local offset = wheel.wheelOffset
    midpoint = midpoint + axis * float3(offset, offset, offset)
  end

  midpointT = float3ToTable(midpoint)

  if wheel.tireWidth ~= nil then
    local halfWidth = 0.5 * wheel.tireWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  local rayRot = Quaternion():fromAngleAxis(-360 / (wheel.numRays* 2), axis)
  local rayVec
  local treadNodes = {}
  if tireExists then
    rayVec = axis:getPerpendicularVector() * float3(wheel.radius, wheel.radius, wheel.radius)
    rayVec = Quaternion():fromAngleAxis(wheelAngle, axis):multiply(rayVec)
    -- add nodes first
    local n = 0
    for i = 0, wheel.numRays - 1, 1 do
      -- outer
      local rayPoint = node1_pos + rayVec
      rayVec = rayRot:multiply(rayVec)
      n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
      table.insert(treadNodes, vehicle.nodes[n])

      -- inner
      rayPoint = node2_pos + rayVec
      rayVec = rayRot:multiply(rayVec)
      n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, wheel)
      table.insert(treadNodes, vehicle.nodes[n])
    end
  end

  -- add Hub nodes
  local hubNodes = {}
  local n = 0
  local hubnodebase = vehicle.maxIDs.nodes

  local hubOptions = deepcopy(wheel)
  hubOptions.beamSpring = hubOptions.hubBeamSpring or hubOptions.beamSpring
  hubOptions.beamDamp = hubOptions.hubBeamDamp or hubOptions.beamDamp
  hubOptions.beamDeform = hubOptions.hubBeamDeform or hubOptions.beamDeform
  hubOptions.beamStrength = hubOptions.hubBeamStrength or hubOptions.beamStrength
  hubOptions.nodeWeight = hubOptions.hubNodeWeight or hubOptions.nodeWeight
  hubOptions.collision = hubOptions.hubCollision or hubOptions.collision
  hubOptions.nodeMaterial = hubOptions.hubNodeMaterial or hubOptions.nodeMaterial
  hubOptions.frictionCoef = hubOptions.hubFrictionCoef or hubOptions.frictionCoef
  hubOptions.group = hubOptions.hubGroup or hubOptions.group
  hubOptions.disableMeshBreaking = hubOptions.disableHubMeshBreaking or hubOptions.disableMeshBreaking

  local hubSideOptions = deepcopy(hubOptions)
  hubSideOptions.beamSpring = hubSideOptions.hubSideBeamSpring or hubSideOptions.beamSpring
  hubSideOptions.beamDamp = hubSideOptions.hubSideBeamDamp or hubSideOptions.beamDamp
  hubSideOptions.beamDeform = hubSideOptions.hubSideBeamDeform or hubSideOptions.beamDeform
  hubSideOptions.beamStrength = hubSideOptions.hubSideBeamStrength or hubSideOptions.beamStrength
  --hubSideOptions.disableMeshBreaking = true

  local hubTreadOptions = deepcopy(hubOptions)
  hubTreadOptions.beamSpring = hubTreadOptions.hubTreadBeamSpring or hubTreadOptions.beamSpring
  hubTreadOptions.beamDamp = hubTreadOptions.hubTreadBeamDamp or hubTreadOptions.beamDamp
  hubTreadOptions.beamDeform = hubTreadOptions.hubTreadBeamDeform or hubTreadOptions.beamDeform
  hubTreadOptions.beamStrength = hubTreadOptions.hubTreadBeamStrength or hubTreadOptions.beamStrength

  local hubPeripheryOptions = deepcopy(hubOptions)
  hubPeripheryOptions.beamSpring = hubPeripheryOptions.hubPeripheryBeamSpring or hubPeripheryOptions.beamSpring
  hubPeripheryOptions.beamDamp = hubPeripheryOptions.hubPeripheryBeamDamp or hubPeripheryOptions.beamDamp
  hubPeripheryOptions.beamDeform = hubPeripheryOptions.hubPeripheryBeamDeform or hubPeripheryOptions.beamDeform
  hubPeripheryOptions.beamStrength = hubPeripheryOptions.hubPeripheryBeamStrength or hubPeripheryOptions.beamStrength

  local hubStabilizerOptions = deepcopy(hubSideOptions)
  hubStabilizerOptions.beamSpring = hubStabilizerOptions.hubStabilizerBeamSpring or hubStabilizerOptions.beamSpring
  hubStabilizerOptions.beamDamp = hubStabilizerOptions.hubStabilizerBeamDamp or hubStabilizerOptions.beamDamp
  hubStabilizerOptions.beamDeform = hubStabilizerOptions.hubStabilizerBeamDeform or hubStabilizerOptions.beamDeform
  hubStabilizerOptions.beamStrength = hubStabilizerOptions.hubStabilizerBeamStrength or hubStabilizerOptions.beamStrength

  if wheel.hubWidth ~= nil then
    local halfWidth = 0.5 * wheel.hubWidth
    node1_pos = midpoint - axis * float3(halfWidth, halfWidth, halfWidth)
    node2_pos = midpoint + axis * float3(halfWidth, halfWidth, halfWidth)
  end

  rayVec = axis:getPerpendicularVector() * float3(wheel.hubRadius, wheel.hubRadius, wheel.hubRadius)
  rayVec = Quaternion():fromAngleAxis(wheelAngle, axis):multiply(rayVec)

  local n = 0
  for i = 0, wheel.numRays - 1, 1 do
    -- inner
    rayPoint = node2_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)

    -- outer
    local rayPoint = node1_pos + rayVec
    rayVec = rayRot:multiply(rayVec)
    n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubOptions)
    table.insert(hubNodes, n)
  end
-- Hub Cap
  local hubcapOptions = deepcopy(wheel)
  hubcapOptions.beamSpring = hubcapOptions.hubcapBeamSpring or hubcapOptions.beamSpring
  hubcapOptions.beamDamp = hubcapOptions.hubcapBeamDamp or hubcapOptions.beamDamp
  hubcapOptions.beamDeform = hubcapOptions.hubcapBeamDeform or hubcapOptions.beamDeform
  hubcapOptions.beamStrength = hubcapOptions.hubcapBeamStrength or hubcapOptions.beamStrength
  hubcapOptions.nodeWeight = hubcapOptions.hubcapNodeWeight or hubcapOptions.nodeWeight
  hubcapOptions.collision = hubcapOptions.hubcapCollision or hubcapOptions.collision
  hubcapOptions.nodeMaterial = hubcapOptions.hubcapNodeMaterial or hubcapOptions.nodeMaterial
  hubcapOptions.frictionCoef = hubcapOptions.hubcapFrictionCoef or hubcapOptions.frictionCoef
  hubcapOptions.hubcapRadius = hubcapOptions.hubcapRadius or hubcapOptions.hubRadius
  hubcapOptions.group = hubcapOptions.hubcapGroup or hubcapOptions.group
  hubcapOptions.disableMeshBreaking = hubcapOptions.disableHubcapMeshBreaking or hubOptions.disableMeshBreaking
  hubcapOptions.wheelID = nil

  local hubcapnodebase
  if wheel.enableHubcaps ~= nil and wheel.enableHubcaps == true and wheel.numRays%2 ~= 1 then
    local hubcapOffset
    if wheel.hubcapOffset ~= nil then
      hubcapOffset = wheel.hubcapOffset
      hubcapOffset = axis * float3(hubcapOffset, hubcapOffset, hubcapOffset)
    end

    local n = 0
    hubcapnodebase = vehicle.maxIDs.nodes

    local hubCapNumRays = wheel.numRays/2
    rayVec = axis:getPerpendicularVector() * float3(hubcapOptions.hubcapRadius, hubcapOptions.hubcapRadius, hubcapOptions.hubcapRadius)
    rayVec = Quaternion():fromAngleAxis(wheelAngle -360 / (hubCapNumRays * 4), axis):multiply(rayVec)
    rayRot = Quaternion():fromAngleAxis(-360 / (hubCapNumRays), axis)

    for i = 0, hubCapNumRays -1, 1 do
      local rayPoint = node1_pos + rayVec - hubcapOffset
      rayVec = rayRot:multiply(rayVec)
      n = addNodeWithOptions(vehicle, 'wheels', rayPoint, NORMALTYPE, hubcapOptions)
    end

    --hubcapOptions.collision = false
    --hubcapOptions.selfCollision = false
    hubcapOptions.nodeWeight = wheel.hubcapCenterNodeWeight
    --make the center rigidifying node
    local hubcapAxis = node1_pos + axis * float3(wheel.hubcapWidth,wheel.hubcapWidth,wheel.hubcapWidth)
    n = addNodeWithOptions(vehicle, 'wheels', hubcapAxis, NORMALTYPE, hubcapOptions)

    --hubcapOptions.collision = nil
    --hubcapOptions.selfCollision = nil
    hubcapOptions.nodeWeight = nil
  end

  local hubcapAttachOptions = deepcopy(wheel)
  hubcapAttachOptions.beamSpring = hubcapAttachOptions.hubcapAttachBeamSpring or hubcapAttachOptions.beamSpring
  hubcapAttachOptions.beamDamp = hubcapAttachOptions.hubcapAttachBeamDamp or hubcapAttachOptions.beamDamp
  hubcapAttachOptions.beamDeform = hubcapAttachOptions.hubcapAttachBeamDeform or hubcapAttachOptions.beamDeform
  hubcapAttachOptions.beamStrength = hubcapAttachOptions.hubcapAttachBeamStrength or hubcapAttachOptions.beamStrength
  hubcapAttachOptions.breakGroup = hubcapAttachOptions.hubcapBreakGroup or hubcapAttachOptions.breakGroup
  hubcapAttachOptions.wheelID = nil
  hubcapAttachOptions.disableMeshBreaking = true

  local sideOptions = deepcopy(wheel)
  sideOptions.beamSpring   = sideOptions.wheelSideBeamSpring or 0
  sideOptions.beamDamp     = sideOptions.wheelSideBeamDamp or 0
  sideOptions.beamDeform   = sideOptions.wheelSideBeamDeform or sideOptions.beamDeform
  sideOptions.beamStrength = sideOptions.wheelSideBeamStrength or sideOptions.beamStrength
  sideOptions.springExpansion = sideOptions.wheelSideBeamSpringExpansion or sideOptions.springExpansion
  sideOptions.dampExpansion   = sideOptions.wheelSideBeamDampExpansion or sideOptions.dampExpansion
  sideOptions.transitionZone  = sideOptions.wheelSideTransitionZone or sideOptions.transitionZone
  sideOptions.beamPrecompression = sideOptions.wheelSideBeamPrecompression or 1

  local sideReinfOptions = deepcopy(sideOptions)
  sideReinfOptions.beamSpring   = sideOptions.wheelSideReinfBeamSpring or 0
  sideReinfOptions.beamDamp     = sideOptions.wheelSideReinfBeamDamp or 0
  sideReinfOptions.beamDeform   = sideOptions.wheelSideReinfBeamDeform or sideOptions.beamDeform
  sideReinfOptions.beamStrength = sideOptions.wheelSideReinfBeamStrength or sideOptions.beamStrength
  sideReinfOptions.springExpansion = sideOptions.wheelSideReinfBeamSpringExpansion or sideOptions.springExpansion
  sideReinfOptions.dampExpansion   = sideOptions.wheelSideReinfBeamDampExpansion or sideOptions.dampExpansion
  sideReinfOptions.transitionZone  = sideOptions.wheelSideReinfTransitionZone or sideOptions.transitionZone
  sideReinfOptions.beamPrecompression = sideOptions.wheelSideReinfBeamPrecompression or 1
  sideReinfOptions.disableMeshBreaking = true

  local reinfOptions = deepcopy(wheel)
  reinfOptions.beamSpring   = reinfOptions.wheelReinfBeamSpring or 0
  reinfOptions.beamDamp     = reinfOptions.wheelReinfBeamDamp or 0
  reinfOptions.beamDamp     = reinfOptions.wheelReinfBeamDamp or 0
  reinfOptions.springExpansion = reinfOptions.wheelReinfBeamSpringExpansion
  reinfOptions.dampExpansion = reinfOptions.wheelReinfBeamDampExpansion
  reinfOptions.beamDeform   = reinfOptions.wheelReinfBeamDeform or reinfOptions.beamDeform
  reinfOptions.beamStrength = reinfOptions.wheelReinfBeamStrength or reinfOptions.beamStrength
  reinfOptions.beamPrecompression = reinfOptions.wheelReinfBeamPrecompression or 1
  reinfOptions.dampCutoffHz = reinfOptions.wheelReinfBeamDampCutoffHz or nil

  reinfOptions.disableMeshBreaking = true

  local treadOptions = deepcopy(wheel)
  treadOptions.beamSpring      = treadOptions.wheelTreadBeamSpring or treadOptions.beamSpring
  treadOptions.beamDamp        = treadOptions.wheelTreadBeamDamp or treadOptions.beamDamp
  treadOptions.beamDeform      = treadOptions.wheelTreadBeamDeform or treadOptions.beamDeform
  treadOptions.beamStrength    = treadOptions.wheelTreadBeamStrength or treadOptions.beamStrength
  treadOptions.beamPrecompression = treadOptions.wheelTreadBeamPrecompression or 1
  treadOptions.dampCutoffHz = treadOptions.wheelTreadBeamDampCutoffHz or nil
  treadOptions.disableMeshBreaking = true

  local treadReinfOptions = deepcopy(treadOptions)
  treadReinfOptions.beamSpring      = treadOptions.wheelTreadReinfBeamSpring or 0
  treadReinfOptions.beamDamp        = treadOptions.wheelTreadReinfBeamDamp or 0
  treadReinfOptions.beamDeform      = treadOptions.wheelTreadReinfBeamDeform or treadOptions.beamDeform
  treadReinfOptions.beamStrength    = treadOptions.wheelTreadReinfBeamStrength or treadOptions.beamStrength
  treadReinfOptions.beamPrecompression = treadOptions.wheelTreadReinfBeamPrecompression or 1
  treadReinfOptions.dampCutoffHz = treadOptions.wheelTreadReinfBeamDampCutoffHz or nil
  treadReinfOptions.disableMeshBreaking = true

  local peripheryOptions = deepcopy(treadOptions)
  peripheryOptions.beamSpring = peripheryOptions.wheelPeripheryBeamSpring or peripheryOptions.beamSpring
  peripheryOptions.beamDamp = peripheryOptions.wheelPeripheryBeamDamp or peripheryOptions.beamDamp
  peripheryOptions.beamDeform = peripheryOptions.wheelPeripheryBeamDeform or peripheryOptions.beamDeform
  peripheryOptions.beamStrength = peripheryOptions.wheelPeripheryBeamStrength or peripheryOptions.beamStrength
  peripheryOptions.beamPrecompression = peripheryOptions.wheelPeripheryBeamPrecompression or 1

  local peripheryReinfOptions = deepcopy(peripheryOptions)
  peripheryReinfOptions.beamSpring = peripheryReinfOptions.wheelPeripheryReinfBeamSpring or peripheryOptions.beamSpring
  peripheryReinfOptions.beamDamp = peripheryReinfOptions.wheelPeripheryReinfBeamDamp or peripheryOptions.beamDamp
  peripheryReinfOptions.beamDeform = peripheryReinfOptions.wheelPeripheryReinfBeamDeform or peripheryOptions.beamDeform
  peripheryReinfOptions.beamStrength = peripheryReinfOptions.wheelPeripheryReinfBeamStrength or peripheryOptions.beamStrength
  peripheryReinfOptions.beamPrecompression = peripheryReinfOptions.wheelPeripheryReinfBeamPrecompression or 1

  vehicle.triangles = vehicle.triangles or {}
  local pressureGroupName = '_wheelPressureGroup' .. wheel.wheelID
  local wheelPressure = wheel.pressurePSI or 10
  local wheelDragCoef = wheel.dragCoef or 100
  local wheelTreadTriangleType = NORMALTYPE
  local wheelSide1TriangleType = NORMALTYPE
  local wheelSide2TriangleType = NORMALTYPE
  local hubTriangleCollision = false
  if (wheel.triangleCollision or false) == false then
    wheelTreadTriangleType = NONCOLLIDABLE
    wheelSide1TriangleType = NONCOLLIDABLE
    wheelSide2TriangleType = NONCOLLIDABLE
  end

  if wheel.treadTriangleCollision == false then
    wheelTreadTriangleType = NONCOLLIDABLE
  end

  if wheel.side1TriangleCollision == false then
    wheelSide1TriangleType = NONCOLLIDABLE
  end

  if wheel.side2TriangleCollision == false then
    wheelSide2TriangleType = NONCOLLIDABLE
  end

  if wheel.hubTriangleCollision == true then
    hubTriangleCollision = true
  end

  local function addPressTri(n1, n2, n3, dCoef, tType)
      table.insert(vehicle.triangles, {
          id1 = n1, id2 = n2, id3 = n3,
          dragCoef = dCoef, triangleType = tType,
          pressureGroup = pressureGroupName, pressurePSI = wheelPressure
        })
  end

  local function addTri(n1, n2, n3, dCoef, tType)
    table.insert(vehicle.triangles, {
        id1 = n1, id2 = n2, id3 = n3,
        dragCoef = dCoef, triangleType = tType
      })
  end

  local sideBeams = {}
  local treadBeams = {}
  local reinfBeams = {}

  for i = 0, wheel.numRays - 1, 1 do
    local i2 = 2*i
    local nextdelta = 2*((i+1)%wheel.numRays)
    local outhubnode = hubnodebase + i2
    local inhubnode = outhubnode + 1
    local nextouthubnode = hubnodebase + nextdelta
    local nextinhubnode = nextouthubnode + 1
    local intirenode = nodebase + i2
    local outtirenode = intirenode + 1
    local nextintirenode = nodebase + nextdelta
    local nextouttirenode = nextintirenode + 1
    local nextnextintirenode = nodebase + 2*((i+2)%wheel.numRays)
    local nextnextouttirenode = nextnextintirenode + 1

    -- Hub caps
    if (wheel.enableHubcaps or false) and wheel.numRays%2 ~= 1 and i < ((wheel.numRays)/2) then
      local hubcapnode = hubcapnodebase + i
      local nexthubcapnode = hubcapnodebase + ((i+1)%(wheel.numRays/2))
      local nextnexthubcapnode = hubcapnodebase + ((i+2)%(wheel.numRays/2))
      local hubcapaxisnode = hubcapnode + (wheel.numRays/2) - i
      local hubcapinhubnode = inhubnode + i2
      local nexthubcapinhubnode = hubcapinhubnode + 2
      local hubcapouthubnode = hubcapinhubnode + 1

      --hubcap periphery
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nexthubcapnode,    NORMALTYPE, hubcapOptions)
      --attach to center node
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapaxisnode,    NORMALTYPE, hubcapOptions)
      --attach to axis
      if wheel.enableExtraHubcapBeams == true then
        addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node1, NORMALTYPE, hubcapAttachOptions)
        addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node2, NORMALTYPE, hubcapAttachOptions)
        if i == 1 then
          addBeamWithOptions(vehicle, 'wheels', hubcapaxisnode, wheel.node1, NORMALTYPE, hubcapAttachOptions)
          addBeamWithOptions(vehicle, 'wheels', hubcapaxisnode, wheel.node2, NORMALTYPE, hubcapAttachOptions)
        end
      end

      --span beams
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nextnexthubcapnode,    NORMALTYPE, hubcapOptions)

      --attach it
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapinhubnode,    NORMALTYPE, hubcapAttachOptions)
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, nexthubcapinhubnode,    NORMALTYPE, hubcapAttachOptions)
      b = addBeamWithOptions(vehicle, 'wheels', hubcapnode, hubcapouthubnode,    BEAM_SUPPORT, hubcapAttachOptions)

      --self:addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node1,    NORMALTYPE, hubcapAttachOptions)
      --self:addBeamWithOptions(vehicle, 'wheels', hubcapnode, wheel.node2,    NORMALTYPE, hubcapAttachOptions)
    end

    --hub tread
    addBeamWithOptions(vehicle, 'wheels', outhubnode, inhubnode,      NORMALTYPE, hubTreadOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextouthubnode, NORMALTYPE, hubTreadOptions)

    --hub periphery beams
    addBeamWithOptions(vehicle, 'wheels', outhubnode, nextouthubnode, NORMALTYPE, hubPeripheryOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  nextinhubnode,  NORMALTYPE, hubPeripheryOptions)

    --hub axis beams
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node1, NORMALTYPE, hubSideOptions)
    addBeamWithOptions(vehicle, 'wheels', outhubnode, wheel.node2, NORMALTYPE, hubSideOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node1, NORMALTYPE, hubSideOptions)
    addBeamWithOptions(vehicle, 'wheels', inhubnode,  wheel.node2, NORMALTYPE, hubSideOptions)

    --Beams to stability node
    if nodeStabilizerExists then
      addBeamWithOptions(vehicle, 'wheels', outhubnode,  wheel.nodeStabilizer, NORMALTYPE, hubStabilizerOptions)
    end

    if tireExists then
      --tire tread
      table.insert( treadBeams,
        addBeamWithOptions(vehicle, 'wheels', intirenode,  outtirenode,    NORMALTYPE, treadOptions) )
      table.insert( treadBeams,
        addBeamWithOptions(vehicle, 'wheels', outtirenode, nextintirenode, NORMALTYPE, treadOptions) )

      --tread reinforcement
      if wheel.enableTreadReinfBeams or false then
        table.insert( treadBeams,
          addBeamWithOptions(vehicle, 'wheels', intirenode, nextouttirenode, NORMALTYPE, treadReinfOptions) )
        table.insert( treadBeams,
          addBeamWithOptions(vehicle, 'wheels', outtirenode, nextnextintirenode, NORMALTYPE, treadReinfOptions) )
      end

      -- paired treadnodes
      vehicle.nodes[intirenode].pairedNode = outtirenode
      vehicle.nodes[outtirenode].pairedNode = nextintirenode

      -- Periphery beams
      addBeamWithOptions(vehicle, 'wheels', intirenode,  nextintirenode,  NORMALTYPE, peripheryOptions)
      addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouttirenode, NORMALTYPE, peripheryOptions)

      --hub tire beams
      table.insert( sideBeams,
        addBeamWithOptions(vehicle, 'wheels', outhubnode,  outtirenode,    BEAM_ANISOTROPIC, sideOptions) )
      table.insert( sideBeams,
        addBeamWithOptions(vehicle, 'wheels', outtirenode, nextouthubnode, BEAM_ANISOTROPIC, sideOptions) )
      table.insert( sideBeams,
        addBeamWithOptions(vehicle, 'wheels', inhubnode,   intirenode,     BEAM_ANISOTROPIC, sideOptions) )
      table.insert( sideBeams,
        addBeamWithOptions(vehicle, 'wheels', inhubnode,   nextintirenode, BEAM_ANISOTROPIC, sideOptions) )

      --reinf beams
      if wheel.enableTireReinfBeams or false then
        table.insert( reinfBeams,
          addBeamWithOptions(vehicle, 'wheels', intirenode,  outhubnode,     NORMALTYPE, reinfOptions) )
        table.insert( reinfBeams,
          addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    NORMALTYPE, reinfOptions) )
      elseif wheel.enableTireLbeams or false then
          table.insert( reinfBeams,
            addBeamWithOptions(vehicle, 'wheels', intirenode,  outhubnode,     BEAM_LBEAM, reinfOptions, inhubnode ))
          table.insert( reinfBeams,
            addBeamWithOptions(vehicle, 'wheels', inhubnode,   outtirenode,    BEAM_LBEAM, reinfOptions, outhubnode ))
      end

      --side reinf beams
      if wheel.enableTireSideReinfBeams or false then
        table.insert( sideBeams,
          addBeamWithOptions(vehicle, 'wheels', outhubnode, nextouttirenode, BEAM_ANISOTROPIC, sideReinfOptions) )
        table.insert( sideBeams,
          addBeamWithOptions(vehicle, 'wheels', outtirenode, hubnodebase + 2*((i+2)%wheel.numRays), BEAM_ANISOTROPIC, sideReinfOptions) )
        table.insert( sideBeams,
          addBeamWithOptions(vehicle, 'wheels', intirenode, nextinhubnode, BEAM_ANISOTROPIC, sideReinfOptions) )
        table.insert( sideBeams,
          addBeamWithOptions(vehicle, 'wheels', inhubnode, nodebase + 2*((i+2)%wheel.numRays), BEAM_ANISOTROPIC, sideReinfOptions) )
      end

      if wheel.enableTirePeripheryReinfBeams or false then
          addBeamWithOptions(vehicle, 'wheels', intirenode, nextnextintirenode, NORMALTYPE, peripheryReinfOptions)
          addBeamWithOptions(vehicle, 'wheels', outtirenode, nextnextouttirenode, NORMALTYPE, peripheryReinfOptions)
      end

      -- hub pressure tris
      addPressTri(inhubnode, nextouthubnode, outhubnode, wheelDragCoef * 0.1, NONCOLLIDABLE)
      addPressTri(inhubnode, nextinhubnode, nextouthubnode, wheelDragCoef * 0.1, NONCOLLIDABLE)

      -- tread pressure tris
      addPressTri(intirenode, outtirenode, nextintirenode, wheelDragCoef * 0.2, wheelTreadTriangleType)
      addPressTri(nextintirenode, outtirenode, nextouttirenode, wheelDragCoef * 0.2, wheelTreadTriangleType)

      -- outside pressure tris
      addPressTri(outtirenode, outhubnode, nextouthubnode, wheelDragCoef * 0.5, wheelSide1TriangleType)
      addPressTri(outtirenode, nextouthubnode, nextouttirenode, wheelDragCoef * 0.5, wheelSide1TriangleType)

      -- inside pressure tris
      addPressTri(inhubnode, intirenode, nextintirenode, wheelDragCoef * 0.5, wheelSide2TriangleType)
      addPressTri(nextinhubnode, inhubnode, nextintirenode, wheelDragCoef * 0.5, wheelSide2TriangleType)
    else
      if hubTriangleCollision then
        -- hub pressure tris
        addTri(nextouthubnode, inhubnode, outhubnode, wheelDragCoef * 0.1, NORMALTYPE)
        addTri(nextinhubnode, inhubnode, nextouthubnode, wheelDragCoef * 0.1, NORMALTYPE)
      end
    end
  end

  wheel.nodes = hubNodes
  wheel.treadNodes = treadNodes
  wheel.sideBeams = sideBeams
  --wheel.reinfBeams = reinfBeams
  wheel.treadBeams = treadBeams
  wheel.pressureGroup = pressureGroupName
end
