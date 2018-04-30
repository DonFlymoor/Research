-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local flammableNodes = {}
local hotNodes = {}
local wheelNodes = {}
local fireNodeCounter = 0
local currentNodeKey = nil
local centreNode = 0

local tEnv = 0
local tSteam = 100
local maxNodeTemp = 1950
local tirePopTemp = 650
local waterCoolingCoef = 6000
local collisionEnergyMultiplier = 1
local vaporFlashPointModifier = 0.5
local vaporCondenseTime = 10 --seconds
local vaporCondenseCoef = 100 / vaporCondenseTime

local fireballSoundDelay = 2
local fireballSoundTimer = 0
local fireSoundDelay = 6
local fireSoundTimer = 6
local fireSoundIntensity = 0

--shorter functions for increased performance
local random = math.random
local sqrt = math.sqrt
local min = math.min
local max = math.max

local function updateGFX(dt)
  local rand = random(1)    --use the same random value for all effects in this frame

  --we combine these two values only once per frame here, we need the result of this quite often below
  local nodeCountTimeFactor = dt * fireNodeCounter
  local airSpeed = electrics.values['airspeed'] or 0
  tEnv = obj:getEnvTemperature() - 273.15

  -- Node Iteration --
  local currentNode = nil
  --get the next node for this frame's comparision, returns nil if we reached the end of the table
  currentNodeKey, currentNode = next(flammableNodes, currentNodeKey)
  if not currentNode then --if we reached the end
    currentNodeKey, currentNode = next(flammableNodes, nil) --get the first one instead
  end
  local mycid = currentNodeKey


  -- Steam Handling --
  local underWater = obj:inWater(mycid) and 1 or 0
  currentNode.lastUnderWaterValue = underWater

  --dynamic baseTemp handling, either use the exhaust manifold temp from the drivetrain or the static base temp from jbeam
  currentNode.baseTemp = currentNode.useThermalsBaseTemp and controller.mainController.fireEngineTemperature or currentNode.staticBaseTemp

  --emit steam if indicated
  if currentNode.temperature > tSteam and underWater == 1 then
    obj:addParticleByNodesRelative(currentNodeKey, centreNode, rand * -2, 24, 0, 1)
  end


  -- Vapor Handling --
  if currentNode.containerBeam then
    local containerBeamBroken = obj:beamIsBroken(currentNode.containerBeam)
    if not currentNode.containerBeamBroken and containerBeamBroken then
      currentNode.vaporState = 20 + random(80)
      currentNode.containerBeamBroken = true
      currentNode.canIgnite = true
      if not currentNode.ignoreContainerBeamBreakMessage then
        gui.message("vehicle.fire.fuelTankRuptured", 10, "vehicle.damage.fueltank")
      end
    end
    currentNode.vaporState = max(currentNode.vaporState - (vaporCondenseCoef * dt), 0) -- condense fuel again
    currentNode.isVapor = currentNode.vaporState >= currentNode.vaporPoint and 1 or 0
  end

  --reduce smokePoint by X% if the node is vaporized
  local vaporCorrectedSmokePoint = currentNode.smokePoint - (currentNode.smokePoint * currentNode.isVapor * vaporFlashPointModifier)

  -- Fire / Smoke --
  if currentNode.canIgnite and currentNode.temperature >= vaporCorrectedSmokePoint then
    if currentNode.chemEnergy > 0 and underWater == 0 then
      --increase burnrate by a factor of x when node is vaporized
      local burnRate = currentNode.burnRate + currentNode.burnRate * currentNode.isVapor * 10
      local chemEnergyRatio = currentNode.chemEnergy / currentNode.originalChemEnergy

      currentNode.intensity = min(2 * chemEnergyRatio, 1) * (currentNode.temperature / maxNodeTemp) * burnRate
      currentNode.heatEnergy = currentNode.heatEnergy + currentNode.intensity * 100 * nodeCountTimeFactor
      currentNode.chemEnergy = max(currentNode.chemEnergy - currentNode.intensity * 3 * nodeCountTimeFactor, 0)

      if currentNode.chemEnergy / currentNode.originalChemEnergy < 0.01 then
        currentNode.chemEnergy = 0
      end

      -- TODO: test new dynamic node properties code
      --[[
            local np = obj:getNodeState(mycid)
            np.burnedness = (currentNode.originalChemEnergy - currentNode.chemEnergy) / currentNode.originalChemEnergy * 255 --0-255
            obj:setNodeState(mycid, np)
            --]]
    else
      currentNode.intensity = 0
    end

    hotNodes[mycid] = currentNode --add it to the hot node list

    if wheelNodes[mycid] and currentNode.temperature > tirePopTemp then --tire popping
      local wheelData = wheelNodes[mycid]
      beamstate.deflateTire(wheelData.wheelID, 1)
      sounds.playSoundOnceAtNode("event:>Vehicle>Fire>Fire_Ignition", mycid, 2)
      --puff of flame on tire burst
        obj:addParticleByNodesRelative(mycid, centreNode, 0, 31, 0.5, 20)

        obj:addParticleByNodesRelative(mycid, centreNode, 0, 29, 0.5, 20)

        --obj:addParticleByNodesRelative(mycid, centreNode, 0, 9, 0.5, 100)

      -- we only want to deflate the tires once, so we just pretend this wheel node is not actually a wheel node anymore
      wheelNodes[wheelData.node1] = nil
      wheelNodes[wheelData.node2] = nil
    end
  else
    --we are below flashpoint, which means that this node is not hot (anymore)
    hotNodes[mycid] = nil --remove hotnode from list
    currentNode.intensity = 0 --kill any flames that might still exist
  end


  -- Heat Transfer --
  --radiate, conduct heat from current node to all other nodes, one per frame
  if hotNodes[mycid] or currentNode.baseTemp > tEnv then
    local burningCoef = currentNode.temperature > vaporCorrectedSmokePoint and 1 or 0 --1 when actually burning, 0 otherwise
    for cid, otherNode in pairs(flammableNodes) do
      if cid ~= mycid then
        local dist = obj:nodeLength(mycid, cid) --distance to nearby nodes, for heat radiation
        local contact = dist <= currentNode.conductionRadius and 1 or 0    --determine whether the two nodes are in contact
        local radiation = (24 * currentNode.intensity * burningCoef) / (1 + dist * dist * dist)  --radiation of heat depends on flame intensity, base heat, and distance to surrounding nodes, factor is arbitary, can be adjusted to change radiation speed
        local conduction = max(1 * contact * (currentNode.temperature - otherNode.temperature), 0)
        otherNode.heatEnergy = otherNode.heatEnergy + (radiation + conduction) * nodeCountTimeFactor --radiate heat to another node; multiply it by the delta T (hotNum)
      end
    end
  end


  -- Cooling Down ---
  --coefficient of heat transfer, based on airspeed
  local hc = 0.0006 * ((waterCoolingCoef * underWater) + 1) * (10.45 - airSpeed  + 10 * sqrt(airSpeed))
  --if the engine is dead, our nodes can cool below their baseTemp (baseTemp represents the engine's constant heat)
  local minTemp = (drivetrain.engineDisabled or underWater == 1) and tEnv or currentNode.baseTemp
  --heat is lost to the surroundings at a rate of temperature * hc. Lower limit = 0
  currentNode.heatEnergy = max(min(currentNode.heatEnergy - (currentNode.temperature - minTemp) * hc * nodeCountTimeFactor, currentNode.maxHeatEnergy), 0)
  --temperature is the node's heat divided by its mass * specific heat
  currentNode.temperature = max(min(currentNode.heatEnergy / currentNode.weightSpecHeatCoef, maxNodeTemp), minTemp)

  fireballSoundTimer = fireballSoundTimer >= fireballSoundDelay and 0 or min(fireballSoundTimer + dt, fireballSoundDelay)
  fireSoundTimer = min(fireSoundTimer + dt, fireSoundDelay)
  fireSoundIntensity = max(0, fireSoundIntensity - (0.3 * dt))

  -- Particles --
  for hotcid, node in pairs(hotNodes) do
    node.flameTick = node.flameTick >= 1 and 0 or node.flameTick + 10 * (1 + airSpeed * 0.05) * dt
    node.smokeTick = node.smokeTick >= 1 and 0 or node.smokeTick + 1.2 * (1 + airSpeed * 0.05) * dt

    local vaporCorrectedSmokePoint = node.smokePoint - (node.smokePoint * node.isVapor * vaporFlashPointModifier)
    local vaporCorrectedFlashPoint = node.flashPoint - (node.flashPoint * node.isVapor * vaporFlashPointModifier)

    if node.flameTick >= 1 then
      if node.intensity > 0 and node.temperature >= vaporCorrectedFlashPoint and currentNode.lastUnderWaterValue == 0 then
        local rootedIntensity = sqrt(node.intensity)
        --small flames for low intensity fire
        obj:addParticleByNodesRelative(hotcid, centreNode, rand * -2 * rootedIntensity, 25, 0, 1)
        fireSoundIntensity = max(node.intensity, fireSoundIntensity) --find the most intensely burning node and set the fire sound volume accordingly
        if fireSoundTimer >= fireSoundDelay then
          local playsound = "event:>Vehicle>Fire>Fire_Burn"
          sounds.playSoundOnceAtNode(playsound, mycid, sqrt(min(fireSoundIntensity, 0.9)) * 1)
          fireSoundTimer = 0
        end

        if node.intensity > 0.15 then
          --medium flames for medium intensity fire
          obj:addParticleByNodesRelative(hotcid, centreNode, rand * -2 * rootedIntensity, 27, 0, 1)

          if node.intensity > 0.3 then
            --large flames for high-intensity fire
            obj:addParticleByNodesRelative(hotcid, centreNode, rand * -2 * rootedIntensity, 29, 0, 1)

            if node.intensity > 10 then
              node.vaporState = 0
              --huge fireball for explosions
              if fireballSoundTimer >= fireballSoundDelay then
                sounds.playSoundOnceAtNode("event:>Vehicle>Fire>Fire_Ignition", mycid, 3)
              end

                obj:addParticleByNodesRelative(hotcid, centreNode, 0, 31, 0.5, 10)
              --huge smoke puff for explosions
              obj:addParticleByNodesRelative(hotcid, centreNode, 0, 32, 0, 1)
              --spray of sparks
                obj:addParticleByNodesRelative(hotcid, centreNode, 0, 9, 0.5, 100)
            end
          end
        end
      end
    end

    if node.smokeTick >= 1 then
      if node.smokePoint and node.temperature > vaporCorrectedSmokePoint then
        local rootedIntensity = sqrt(node.intensity)
        --node emits smoke if close to flash point
        obj:addParticleByNodesRelative(hotcid, centreNode, rand * -2 * rootedIntensity * (1 + airSpeed * 0.1), 26, 0, 1)

        if node.temperature > node.flashPoint * 4 then
          obj:addParticleByNodesRelative(hotcid, centreNode, rand * -2 * rootedIntensity * (1 + airSpeed * 0.1), 28, 0, 1)
        end
      end
    end
  end
end

local function nodeCollision(p)
  --add energy to node
  local collisionNodeId = p.id1
  local node = flammableNodes[collisionNodeId]

  if not node or not node.heatEnergy then
    return
  end

  local normalEnergy = p.normalForce * p.perpendicularVel  * lastDt
  local slipEnergy = p.slipForce * p.slipVel * lastDt
  -- energy = work, sum up the normal and slip work for the time being, lastDt comes directly from main lua and is the dT from the last gfx frame
  local collisionEnergy = normalEnergy + slipEnergy
  if collisionEnergy <= 0 then
    return
  end

  node.heatEnergy = node.heatEnergy + (collisionEnergy * collisionEnergyMultiplier * node.selfIgnitionCoef)
  node.temperature = max(min(node.heatEnergy / node.weightSpecHeatCoef, maxNodeTemp), node.temperature)

  local vaporCorrectedSmokePoint = node.smokePoint - (node.smokePoint * node.isVapor * vaporFlashPointModifier)
  if node.canIgnite and node.temperature >= vaporCorrectedSmokePoint and not hotNodes[collisionNodeId] then
    hotNodes[collisionNodeId] = node --add it to the hot node list

    node.burnRate = node.burnRate or 0
    --same as main intensity calculation, just simplified for the ignition case
    node.intensity = node.burnRate * node.temperature / maxNodeTemp
    node.flameTick = 1
    node.smokeTick = 1
  end
end

local function init()
  M.updateGFX = nop

  flammableNodes = {}
  hotNodes = {}
  wheelNodes = {}
  currentNodeKey = nil
  centreNode = 0
  fireNodeCounter = 0
  fireballSoundTimer = 0
  tEnv = obj:getEnvTemperature() - 273.15

  local containerBeamCache = {}

  --create a cache of all available container beams for easy access
  if v.data.beams then
    for k,b in pairs(v.data.beams) do
      if b.containerBeam then
        containerBeamCache[b.containerBeam] = k
      end
    end
  end

  if v.data.nodes then
    local centreNodeDist = 100
    for _,node in pairs(v.data.nodes) do
      local nodeDist = sqrt((node.pos.x * node.pos.x) + (node.pos.y * node.pos.y) + (node.pos.z * node.pos.z))
      if  nodeDist < centreNodeDist then  --find the centre-most node and store it for particle reference
        centreNodeDist = nodeDist
        centreNode = node.cid
      end

      if node.flashPoint then
        --we can assume this node is part of the fire system
        local staticBaseTemp = (type(node.baseTemp) == "number") and node.baseTemp or tEnv
        flammableNodes[node.cid] =
        {
          name = node.name,
          flashPoint = node.flashPoint,
          smokePoint = node.smokePoint or node.flashPoint,
          burnRate = node.burnRate,
          staticBaseTemp = staticBaseTemp,
          useThermalsBaseTemp = node.baseTemp == "thermals",
          conductionRadius = node.conductionRadius or 0,
          selfIgnitionCoef = node.selfIgnitionCoef or 0,
          temperature = tEnv,
          intensity = 0,
          heatEnergy = (staticBaseTemp - tEnv) * (node.nodeWeight * (node.specHeat or 1)),
          chemEnergy = node.chemEnergy or 0,
          originalChemEnergy = node.chemEnergy or 0,
          weightSpecHeatCoef = node.nodeWeight * (node.specHeat or 1),
          maxHeatEnergy = (maxNodeTemp - tEnv) * node.nodeWeight * (node.specHeat or 1),
          lastUnderWaterValue = 0,
          flameTick = 0,
          smokeTick = 0,
          vaporState = 0,
          vaporPoint = node.vaporPoint,
          isVapor = 0,
          containerBeam = containerBeamCache[node.containerBeam],
          ignoreContainerBeamBreakMessage = node.ignoreContainerBeamBreakMessage or false,
          containerBeamBroken = false,
          canIgnite = containerBeamCache[node.containerBeam] == nil
        }

        fireNodeCounter = fireNodeCounter + 1
      end
    end
  end

  --cache wheelnodes for easy access from update
  if wheels.wheels then
    for id,wd in pairs(wheels.wheels) do
      wheelNodes[wd.node1] = { wheelID = id, node1 = wd.node1, node2 = wd.node2 }
      wheelNodes[wd.node2] = { wheelID = id, node1 = wd.node1, node2 = wd.node2 }
    end
  end

  math.randomseed(os.time())

  --activate fire sim if configured nodes are found
  if fireNodeCounter > 0 then
    M.updateGFX = updateGFX
    M.nodeCollision = nodeCollision
  end
end

local function igniteNode(cid)
  local node = flammableNodes[cid]
  if not node then
    return
  end
  node.heatEnergy = node.maxHeatEnergy
  node.temperature = maxNodeTemp
end

local function igniteRandomNode()
  local possibleNodes = {}
  for k,n in pairs(flammableNodes) do
    if n and n.canIgnite and not wheelNodes[k] and n.intensity <= 0 then
      table.insert(possibleNodes, k)
    end
  end

  if #possibleNodes <= 0 then
    return
  end

  local node = flammableNodes[possibleNodes[random(#possibleNodes)]]

  if not node then
    return
  end
  node.heatEnergy = node.maxHeatEnergy
  node.temperature = maxNodeTemp
end

local function igniteRandomNodeMinimal()
  local possibleNodes = {}
  for k,n in pairs(flammableNodes) do
    if n and n.canIgnite and not wheelNodes[k] and n.intensity <= 0 then
      table.insert(possibleNodes, k)
    end
  end

  if #possibleNodes <= 0 then
    return
  end

  local node = flammableNodes[possibleNodes[random(#possibleNodes)]]

  if not node then
    return
  end

  node.temperature = node.flashPoint + 10
  node.heatEnergy = node.temperature * node.weightSpecHeatCoef
end

local function igniteVehicle()
  for cid,_ in pairs(flammableNodes) do
    if not wheelNodes[cid] then --don't ignite wheelnodes right away to delay the tire popping a bit
      igniteNode(cid)
    end
  end
end

local function explodeVehicle()
  for cid,node in pairs(flammableNodes) do
    if node.containerBeam then
      node.vaporState = 100
      node.containerBeamBroken = true
      node.canIgnite = true
      node.isVapor = 1
    end

    igniteNode(cid)
  end
end

local function explodeNode(cid)
  local node = flammableNodes[cid]
  if not node then
    return
  end
  node.heatEnergy = node.maxHeatEnergy
  node.temperature = maxNodeTemp
  node.vaporState = 100
  node.containerBeamBroken = true
  node.canIgnite = true
  node.isVapor = 1
  hotNodes[cid] = node
end

local function extinguishVehicle()
  for cid,node in pairs(flammableNodes) do
    node.heatEnergy = 0
    node.temperature = tEnv
    node.intensity = 0
    obj:addParticleByNodes(cid, centreNode, -1, 48, 0, 15)
  end
end

local function extinguishVehicleSlowly()
  for _,node in pairs(flammableNodes) do
    node.chemEnergy = 0
  end
end

-- public interface
M.igniteNode = igniteNode
M.igniteRandomNodeMinimal = igniteRandomNodeMinimal
M.igniteRandomNode = igniteRandomNode
M.igniteVehicle = igniteVehicle
M.explodeVehicle = explodeVehicle
M.explodeNode = explodeNode
M.extinguishVehicle = extinguishVehicle
M.extinguishVehicleSlowly = extinguishVehicleSlowly
M.reset = init
M.init = init

--by default, fire sim is not active on an object
M.updateGFX = nop
M.nodeCollision = nop

return M