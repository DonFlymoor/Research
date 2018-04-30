-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.outputPorts = {[1] = true}
M.deviceCategories = {shaft = true}

local max = math.max
local min = math.min
local abs = math.abs

local function updateVelocity(device, dt)
  device.inputAV = device[device.outputAVName] * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function updateTorque(device)
  device[device.outputTorqueName] = device.parent[device.parentOutputTorqueName] * device.gearRatio - device.friction * min(max(device.inputAV, -1), 1)
end

local function disconnectedUpdateVelocity(device, dt)
  --use the speed of the inertial load, not the drivetrain on other side if the shaft is broken or disconnected, otherwise, pass through
  device.inputAV = device.virtualMassAV * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function disconnectedUpdateTorque(device, dt)
  local outputTorque = device.parent[device.parentOutputTorqueName] * device.gearRatio - device.friction * min(max(device.inputAV, -1), 1)
  --accelerate a virtual mass with the output torque if the shaft is disconnected or broken
  device.virtualMassAV = device.virtualMassAV + outputTorque * device.invCumulativeInertia * dt
  --TODO: implement this cap once we are sure the auto calc is stable
  --device.virtualMassAV = device.virtualMassAV + max(min(outputTorque * device.invCumulativeInertia * dt, 10), -10)
  device[device.outputTorqueName] = 0 --set to 0 to stop children receiving torque
end

local function wheelShaftUpdateVelocity(device, dt)
  device[device.outputAVName] = device.wheel.angularVelocity * device.wheelDirection
  device.inputAV = device[device.outputAVName] * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function wheelShaftUpdateTorque(device)
  local outputTorque = device.parent[device.parentOutputTorqueName] * device.gearRatio
  local wheel = device.wheel
  wheel.propulsionTorque = outputTorque * device.wheelDirection
  wheel.frictionTorque = device.friction
  device[device.outputTorqueName] = outputTorque
  local trIdx = wheel.torsionReactorIdx
  powertrain.torqueReactionCoefs[trIdx] = powertrain.torqueReactionCoefs[trIdx] + abs(outputTorque)
end

local function wheelShaftDisconnectedUpdateVelocity(device, dt)
  device[device.outputAVName] = device.wheel.angularVelocity * device.wheelDirection
  device.inputAV = device.virtualMassAV * device.gearRatio
  device.parent[device.parentOutputAVName] = device.inputAV
end

local function wheelShaftDisconnectedUpdateTorque(device, dt)
  local outputTorque = device.parent[device.parentOutputTorqueName] * device.gearRatio - device.friction * min(max(device.inputAV, -1), 1)
  --accelerate a virtual mass with the output torque if the shaft is disconnected or broken
  device.virtualMassAV = device.virtualMassAV + outputTorque * device.invCumulativeInertia * dt
  device[device.outputTorqueName] = 0 --set to 0 to stop children receiving torque
  device.wheel.propulsionTorque = 0
  device.wheel.frictionTorque = device.friction
end

local function selectUpdates(device)
  device.velocityUpdate = updateVelocity
  device.torqueUpdate = updateTorque

  if device.connectedWheel then
    device.velocityUpdate = wheelShaftUpdateVelocity
    device.torqueUpdate = wheelShaftUpdateTorque
  end

  if device.isBroken or device.mode == "disconnected" then
    device.velocityUpdate = disconnectedUpdateVelocity
    device.torqueUpdate = disconnectedUpdateTorque
    if device.connectedWheel then
      device.velocityUpdate = wheelShaftDisconnectedUpdateVelocity
      device.torqueUpdate = wheelShaftDisconnectedUpdateTorque
    end
    --make sure the virtual mass has the right AV
    device.virtualMassAV = device.inputAV
  end
end

local function validate(device)
  if device.isPhysicallyDisconnected then
    device.mode = "disconnected"
    selectUpdates(device)
  end

  if (not device.connectedWheel) and (not device.children or #device.children <= 0) then
    --print(device.name)
    local parentDiff = device.parent
    while parentDiff.parent and not parentDiff.deviceCategories.differential do
      parentDiff = parentDiff.parent
      --print(parentDiff and parentDiff.name or "nil")
    end

    if parentDiff and parentDiff.deviceCategories.differential and parentDiff.defaultVirtualInertia then
      --print("Found parent diff, using its default virtual inertia: "..parentDiff.defaultVirtualInertia)
      device.virtualInertia = parentDiff.defaultVirtualInertia
    end
  end

  if device.connectedWheel and device.parent then
    --print(device.connectedWheel)
    --print(device.name)
    local torsionReactor = device.parent
    while torsionReactor.parent and torsionReactor.type ~= "torsionReactor" do
      torsionReactor = torsionReactor.parent
      --print(torsionReactor and torsionReactor.name or "nil")
    end

    if torsionReactor and torsionReactor.type == "torsionReactor" and torsionReactor.torqueReactionNodes then
      local wheel = powertrain.wheels[device.connectedWheel]
      local reactionNodes = torsionReactor.torqueReactionNodes
      wheel.obj:setEngineAxisCoupleNodes(reactionNodes[1], reactionNodes[2], reactionNodes[3])
      device.torsionReactor = torsionReactor
      wheel.torsionReactor = torsionReactor
    end
  end

  return true
end

local function setMode(device, mode)
  device.mode = mode
  selectUpdates(device)
end

local function onBreak(device)
  device.isBroken = true
  selectUpdates(device)
end

local function calculateInertia(device)
  local outputInertia = 0
  local cumulativeGearRatio = 1
  local maxCumulativeGearRatio = 1
  if device.children and #device.children > 0 then
    local child = device.children[1]
    outputInertia = child.cumulativeInertia
    cumulativeGearRatio = child.cumulativeGearRatio
    maxCumulativeGearRatio = child.maxCumulativeGearRatio
  elseif device.connectedWheel then
    local axisInertia = 0
    local wheel = powertrain.wheels[device.connectedWheel]
    local hubNode1 = vec3(v.data.nodes[wheel.node1].pos)
    local hubNode2 = vec3(v.data.nodes[wheel.node2].pos)

    for _, nid in pairs (wheel.nodes) do
      local n = v.data.nodes[nid]
      local distanceToAxis = vec3(n.pos):distanceToLine(hubNode1, hubNode2)
      axisInertia = axisInertia + (n.nodeWeight * (distanceToAxis * distanceToAxis))
    end

    --print(device.connectedWheel.." Hub-Axis: "..axisInertia.." kgm²")
    outputInertia = axisInertia
  else
    --Nothing connected to this shaft :(
    outputInertia = device.virtualInertia --some default inertia
  end

  device.cumulativeInertia = outputInertia / device.gearRatio / device.gearRatio
  device.invCumulativeInertia = device.cumulativeInertia > 0 and 1 / device.cumulativeInertia or 0
  device.cumulativeGearRatio = cumulativeGearRatio * device.gearRatio
  device.maxCumulativeGearRatio = maxCumulativeGearRatio * device.gearRatio
end

local function reset(device)
  local jbeamData = device.jbeamData
  device.gearRatio = jbeamData.gearRatio or 1
  device.friction = jbeamData.friction or 0
  device.cumulativeInertia = 1
  device.invCumulativeInertia = 1
  device.cumulativeGearRatio = 1
  device.maxCumulativeGearRatio = 1

  device.inputAV = 0
  device.visualShaftAngle = 0
  device.virtualMassAV = 0
  device.isBroken = false

  device[device.outputTorqueName] = 0
  device[device.outputAVName] = 0

  selectUpdates(device)

  return device
end

local function new(jbeamData)
  local device = {
    deviceCategories = shallowcopy(M.deviceCategories),
    requiredExternalInertiaOutputs = shallowcopy(M.requiredExternalInertiaOutputs),
    outputPorts = shallowcopy(M.outputPorts),

    name = jbeamData.name,
    type = jbeamData.type,
    inputName = jbeamData.inputName,
    inputIndex = jbeamData.inputIndex,
    gearRatio = jbeamData.gearRatio or 1,
    friction = jbeamData.friction or 0,
    cumulativeInertia = 1,
    invCumulativeInertia = 1,
    virtualInertia = 2,
    cumulativeGearRatio = 1,
    maxCumulativeGearRatio = 1,
    isPhysicallyDisconnected = true,
    electricsName = jbeamData.electricsName,

    inputAV = 0,
    visualShaftAngle = 0,
    virtualMassAV = 0,
    isBroken = false,

    torsionReactor = nil,

    reset = reset,
    onBreak = onBreak,
    setMode = setMode,
    validate = validate,
    calculateInertia = calculateInertia,
  }

  if jbeamData.connectedWheel and powertrain.wheels[jbeamData.connectedWheel] then
    device.connectedWheel = jbeamData.connectedWheel
    device.wheel = powertrain.wheels[device.connectedWheel]
    device.wheelDirection = powertrain.wheels[device.connectedWheel].wheelDir

    device.cumulativeInertia = 1

    local pos = v.data.nodes[device.wheel.node1].pos
    device.visualPosition = pos
    device.visualType = "wheel"
  end

  local outputPortIndex = 1
  if jbeamData.outputPortOverride then
    device.outputPorts = {}
    for _,v in pairs(jbeamData.outputPortOverride) do
      device.outputPorts[v] = true
      outputPortIndex = v
    end
  end

  device.outputTorqueName = "outputTorque"..tostring(outputPortIndex)
  device.outputAVName = "outputAV"..tostring(outputPortIndex)
  device[device.outputTorqueName] = 0
  device[device.outputAVName] = 0

  if jbeamData.canDisconnect then
    device.availableModes = {"connected", "disconnected"}
    device.mode = jbeamData.isDisconnected and "disconnected" or "connected"
  else
    device.availableModes = {"connected"}
    device.mode = "connected"
  end

  device.breakTriggerBeam = jbeamData.breakTriggerBeam
  if device.breakTriggerBeam and device.breakTriggerBeam == "" then
    --get rid of the break beam if it's just an empty string (cancellation)
    device.breakTriggerBeam = nil
  end

  device.jbeamData = jbeamData

  selectUpdates(device)

  return device
end

M.new = new

return M
