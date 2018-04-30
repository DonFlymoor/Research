-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.commands = {}
M.t = 0

local function toInputSpace(h, state)
  if state > h.center then
    return (state - h.center) * h.invMultOut
  else
    return (state - h.center) * h.invMultIn
  end
end

local function updateGFX(dt) -- dt in seconds
  -- update the source command value
  for _,h in pairs(M.commands) do
    h.cmd = math.min(math.max(electrics.values[h.inputSource] or 0, h.inputInLimit), h.inputOutLimit) * h.inputFactor

    if h.cmd ~= h.inputCenter or h.analogue == true then
      h._inrate = h.inRate
      h._outrate = h.outRate
    else
      -- set autocenter rate
      h._inrate = h.autoCenterRate
      h._outrate = h.autoCenterRate
    end

    if h.cmd >= h.inputCenter then
      h.cmd = h.cOut + h.cmd * h.multOut
    else
      h.cmd = h.cIn + h.cmd * h.multIn
    end

    h.hydroDirState = toInputSpace(h, h.state)
  end
end

local function onPhysicsStep(dtSim)
  -- state: the state of the hydro from -1 to 1
  -- cmd the input value
  -- note: state is scaled to the ratio as the last step
  M.t = M.t + dtSim
  for _,h in pairs(M.commands) do
    -- slowly approach the desired value
    if h.cmd < h.state then
      h.state = math.max(h.state - dtSim * h._inrate, h.cmd)
    else
      h.state = math.min(h.state + dtSim * h._outrate, h.cmd)
    end

    obj:setBeamLengthRefRatio(h.beam.cid, h.state + math.sin(M.t) * 0.1)
  end
end

local function onReset()
  for _,h in pairs(M.commands) do
    h.state = h.center
    h.cmd = h.inputCenter
    h._inrate = h.inRate
    h._outrate = h.outRate
  end
end

local function onDebugDraw(focusPos)
  -- this code is rather slow
  local origin = vec3(obj:getPosition())
  for _, command in pairs (M.commands) do
    local col = color(84, 71, 112, 150)
    local txt = string.format("%s %0.2f", command.name or '', command.state)
    if obj:beamIsBroken(command.beam.cid) then
      col = color(255, 71, 0, 230)
      txt = txt .. ' (BROKEN)'
    end

    local p1 = origin + vec3(obj:getNodePosition(command.beam.id1))
    local p2 = origin + vec3(obj:getNodePosition(command.beam.id2))

    obj.debugDrawProxy:drawCylinder(p1:toFloat3(), p2:toFloat3(), 0.05, col)
    obj.debugDrawProxy:drawText((p1 + (p2 - p1) * 0.5):toFloat3(), color(255,0,0,255), txt, 0)

    obj.debugDrawProxy:drawSphere(0.03, p1:toFloat3(), color(170, 57, 57,230))
    obj.debugDrawProxy:drawSphere(0.03, p2:toFloat3(), color(170, 57, 57,230))

    obj.debugDrawProxy:drawText(p1:toFloat3(), color(10,10,10,100), v.data.nodes[command.beam.id1].name or '', 0)
    obj.debugDrawProxy:drawText(p2:toFloat3(), color(10,10,10,100), v.data.nodes[command.beam.id2].name or '', 0)
  end

  -- this does not belong here
  if v.data and v.data.ropes then
    for _, rope in pairs(v.data.ropes) do
      for _, beam in pairs(rope.beams) do
        local p1 = origin + vec3(obj:getNodePosition(beam.id1))
        local p2 = origin + vec3(obj:getNodePosition(beam.id2))

        obj.debugDrawProxy:drawCylinder(p1:toFloat3(), p2:toFloat3(), 0.03, color(50, 50, 200, 100))
      end
      for _, nodeid in pairs(rope.nodes) do
        local p1 = origin + vec3(obj:getNodePosition(nodeid))
        obj.debugDrawProxy:drawSphere(0.03, p1:toFloat3(), color(0, 0, 255, 255))
      end
    end
  end

end

local function onExtensionLoaded()
  -- decide if we want this module to be loaded or not:
  -- if it has flexbodies, unload again
  --if v.data.commands == nil or #v.data.commands == 0 then
  --    -- unload again
  --    return false
  --end
  if true then return end

  M.commands = shallowcopy(v.data.commands)
  for _, h in pairs (M.commands) do
    h.inputCenter = h.inputCenter * h.inputFactor
    h.inputInLimit = h.inputInLimit * h.inputFactor
    h.inputOutLimit = h.inputOutLimit * h.inputFactor
    local inputFactorSign = sign(h.inputFactor)

    if h.inputFactor < 0 then
      h.inputInLimit, h.inputOutLimit = h.inputOutLimit, h.inputInLimit
    end

    local inputMiddle = (h.inputOutLimit + h.inputInLimit) * 0.5
    if h.inputCenter >= inputMiddle then
      h.center = 1 + (h.outLimit - 1) * (h.inputCenter - inputMiddle) / (h.inputOutLimit - inputMiddle)
    else
      h.center = 1 - (1 - h.inLimit) * (inputMiddle - h.inputCenter) / (inputMiddle - h.inputInLimit)
    end
    h.state = h.center
    h.multOut = (h.outLimit - h.center) / (h.inputOutLimit - h.inputCenter)
    h.cOut = h.center - h.inputCenter * h.multOut
    h.multIn = (h.center - h.inLimit) / (h.inputCenter - h.inputInLimit)
    h.cIn = h.center - h.inputCenter * h.multIn
    h.cmd = h.inputCenter
    h.invMultOut = 1 / (h.outLimit - h.center) * inputFactorSign
    h.invMultIn = 1 / (h.center - h.inLimit) * inputFactorSign
    h._inrate = h.inRate
    h._outrate = h.outRate
    h.hydroDirState = 0
  end
  -- keep module loaded
  return true
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded

M.onReset = onReset
M.onPhysicsStep = onPhysicsStep

M.onDebugDraw = onDebugDraw
M.updateGFX = updateGFX

return M
