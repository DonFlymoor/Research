-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

M.mode = 'disabled' -- this is the main mode
M.manualTargetName = nil
M.debugMode = 'off'
M.targetObjectID = -1
M.speedMode = nil
M.routeSpeed = nil
M.driveInLaneFlag = 'off'
M.extAggression = 1
M.cutOffDrivability = 0

-- [[ STORE FREQUENTLY USED FUNCTIONS IN UPVALUES ]] --
local max = math.max
local min = math.min
local sin = math.sin
local asin = math.asin
local pi = math.pi
local abs = math.abs
local sqrt = math.sqrt
local tableInsert = table.insert
local tableRemove = table.remove
local strFormat = string.format
---------------------------------

-- [[ ENVIRONMENT VARIABLES ]] --
local g = abs(obj:getGravity())
local gravityDir = vec3(0, 0, -1)
local gravityVec = gravityDir * g
----------------------------------

-- [[ PERFORMANCE RELATED ]] --
local maxExternalAggression = 2
local initialAggression = 1 / maxExternalAggression
local initialAggAccCoeff = 0.8
local maxAggAccCoeff = 1.3
local aggression = initialAggression

local accCoeffGrad = (maxAggAccCoeff - initialAggAccCoeff) / (1 - initialAggression)
local accCoeffYintercept = initialAggAccCoeff - accCoeffGrad * initialAggression

local aggressionMode

local baseTurnAccel = min(0.5, aggression) * g
local maxTottalAccel = g

local learned_turn_accel
-- local learned_brake_accel
local learned_total_accel = baseTurnAccel

local turnAccelSmoother = newTemporalSmoothing(0.05, 3, nil, baseTurnAccel)
-- local brakeAccelSmoother = newTemporalSmoothing(0.1, 2, nil, baseTurnAccel)
local totalAccelSmoother = newTemporalSmoothing(0.1, 2, nil, baseTurnAccel)
local targetSpeedSmoother = newTemporalSmoothingNonLinear(10, 7, 0)
--------------------------------------------------------------------------

-- [[ AI DATA: POSITION, CONTROL, STATE ]] --
local aiID = obj:getID()
local aiPos = vec3(obj:getFrontPosition())
local aiDirVec = vec3(obj:getDirectionVector())
local aiVel = vec3(obj:getVelocity())
local aiSpeed = aiVel:length()
local aiWidth -- this comes back zero at this point
local aiLength -- this comes back zero at this point

local forces = {}

local throttle = 1
local brake = 0
local threewayturn = 0
local lastCommand = {steering = 0, throttle = 0, brake = 0, parkingbrake = 0}

local targetPos = nil
local targetAiMidPos = nil
local targetstatus = nil

local driveInLaneFlag = false

local internalState = 'onroad'
local validateInput = nop
------------------------------

-- [[ CRASH DETECTION ]] --
local crashTime = 0
local crashManeuver = 0
local crashDir = nil
---------------------

-- [[ OPPONENT DATA ]] --
local player = nil
local plPrevVel = nil
----------------------

-- [[ SETTINGS, PARAMETERS, AUXILIARY DATA ]] --
local map = nil
local targetName = nil
local currentRoute = nil
local minPlanSize = 18

local wpList
local speedList
local routeSpeed = nil
local limitSpeed = nil
local race
local noOfLaps

local targetObjectSelectionMode = nil

local edgeDict = nil
local tau = nil
-----------------------

-- [[ HEAVY DEBUG MODE ]] --
local speedRecordings = {}
local trajectoryRec = {last = 0}
local routeRec = {last = 0}
local labelRenderDistance = 10
local targetSpeed
local targetSegIdx
local midTargetSegIdx
------------------------------

local function aistatus(status, category)
  guihooks.trigger("AIStatusChange", {status=status, category=category})
end

local function getState()
  return M
end

local function stateChanged()
  if playerInfo.anyPlayerSeated then
    guihooks.trigger("AIStateChange", getState())
  end
end

local function setAggressionInternal(v)
  aggression = min(max((v and v * M.extAggression) or initialAggression * M.extAggression, 0.15), 1)
  baseTurnAccel = min(0.5, aggression) * g
end

local function setAggressionExternal(v)
  M.extAggression = v or M.extAggression
  setAggressionInternal()
end

local function setAggressionMode(aggrmode)
  if aggrmode == 'rubberBand' then
    aggressionMode = 'rubberBand'
  else
    aggressionMode = nil
  end
end

local function resetAggression()
  setAggressionInternal()
end

local function setTargetObjectID(id)
  M.targetObjectID = M.targetObjectID ~= aiID and id or -1
  if M.targetObjectID ~= -1 then targetObjectSelectionMode = 'manual' end
end

local function updatePlayerData()
  if mapmgr.objects[M.targetObjectID] and targetObjectSelectionMode == 'manual' then
    player = mapmgr.objects[M.targetObjectID]
  elseif tableSize(mapmgr.objects) == 2 then
    if player ~= nil then
      player = mapmgr.objects[player.id]
    else
      for k, v in pairs(mapmgr.objects) do
        if k ~= aiID then
          M.targetObjectID = k
          player = v
          break
        end
      end
      targetObjectSelectionMode = 'auto'
    end
  else
    if player ~= nil and player.active == true then
      player = mapmgr.objects[player.id]
    else
      for k, v in pairs(mapmgr.objects) do
        if k ~= aiID and v.active == true then
          M.targetObjectID = k
          player = v
          break
        end
      end
      targetObjectSelectionMode = 'targetActive'
    end
  end
end

local function driveCar(steering, throttle, brake, parkingbrake)
  input.event("steering", -steering, 1)
  input.event("throttle", throttle, 2)
  input.event("brake", brake, 2)
  input.event("parkingbrake", parkingbrake, 2)

  lastCommand.steering = steering
  lastCommand.throttle = throttle
  lastCommand.brake = brake
  lastCommand.parkingbrake = parkingbrake
end

local function aimToTarget()
  if targetPos == nil then return end

  local targetVec = (targetPos - aiPos):normalized()
  local dirTarget = aiDirVec:dot(targetVec)
  local dirDiff = -math.asin(aiDirVec:cross(vec3(obj:getDirectionVectorUp())):dot(targetVec))

  if crashManeuver == 1 and dirTarget < aiDirVec:dot(crashDir) then
    driveCar(-fsign(dirDiff), brake, throttle, 0)
    return
  else
    crashManeuver = 0
  end

  if dirTarget < 0 and currentRoute ~= nil then
    local plan = currentRoute.plan
    local edgeDist = min((plan[2] or plan[1]).radiusOrig, plan[1].radiusOrig) -
    aiPos:z0():distanceToLine((plan[3] or plan[2]).posOrig:z0(), plan[2].posOrig:z0())
    if edgeDist > aiWidth and threewayturn == 0 then -- edgeDist > 0 and -> this is not needed aiWidth condition is stricter!!!
      driveCar(fsign(dirDiff), 0.5, 0, min(max(aiSpeed - 3, 0), 1))
    else
      threewayturn = 1
      driveCar(-fsign(dirDiff), 0, max(min(abs(dirTarget), 1), 0.6), 0)
    end
  else
    threewayturn = 0
    local pbrake
    if aiVel:dot(aiDirVec) * max(aiVel:squaredLength() - 1e-2, 0) < 0 then
      if aiSpeed < 0.15 and targetSpeed and targetSpeed <= 1e-5 then pbrake = 1 else pbrake = 0 end
      driveCar(dirDiff, 0.5, 0, pbrake)
    else
      if aiSpeed > 4 and aiSpeed < 30 and abs(dirDiff) > 0.8 and brake == 0 or (aiSpeed < 0.15 and targetSpeed and targetSpeed <= 1e-5) then pbrake = 1 else pbrake = 0 end
      driveCar(dirDiff, throttle, brake, pbrake)
    end
  end
end

-- http://cnx.org/contents/--TzKjCB@8/Projectile-motion-on-an-inclin
local function projectileSquareSpeedToRangeRatio(pos1, pos2, pos3)
  local sinTheta = (pos2.z - pos1.z) / pos1:distance(pos2)
  local sinAlpha = (pos3.z - pos2.z) / pos2:distance(pos3)
  local cosAlphaSquared = max(1 - sinAlpha * sinAlpha, 0)
  local cosTheta = sqrt(max(1 - sinTheta * sinTheta, 0)) -- in the interval theta = {-pi/2, pi/2} cosTheta is always positive
  return g * 0.5 * cosAlphaSquared / max(cosTheta * (sinTheta*sqrt(cosAlphaSquared) - cosTheta*sinAlpha), 0)
end

local function buildNextRoute(plan, planLen, path)
  local nextpathId, n1
  if planLen == 0 then -- TODO: maybe in this case it would be better to call findClosest road rather that just using a radius from the vehicle width
    nextpathId = 1
    if path[nextpathId] == nil then return end
    n1 = {pos = vec3(aiPos), radius = aiWidth * 0.5}
  else
    nextpathId = plan[planLen].pathidx + 1
    local prevpathId = nextpathId - 1
    if race == true and noOfLaps and noOfLaps > 1 and nextpathId > #path then
      local loopPathId
      local lastWayPoint = path[#path]
      for i, wayPoint in ipairs(path) do
        if lastWayPoint == wayPoint then
          loopPathId = i
          break
        end
      end
      nextpathId = 1 + loopPathId -- nextpathId % #path
      noOfLaps = noOfLaps - 1
    end
    if path[nextpathId] == nil then return end
    n1 = map.nodes[path[prevpathId]] -- this might be a bug, try this -> route.plan[planLen].posOrig
  end

  local n2 = map.nodes[path[nextpathId]]

  if n2 == nil then return end

  local nodeName = path[nextpathId]

  if driveInLaneFlag and n2.radius > 2.75 then -- TODO: (and n1.radius > 2.75) the second check might be problematic when n1.radius falls to the vehicle radius... i.e. planLen == 0 above
    local n2Pos = n2.pos
    local n1Pos = n1.pos

    local nVec1 = (n1Pos - n2Pos):z0():normalized():cross(gravityDir) -- vector normal to direction vector for current segment
    local n2HalfRadius = n2.radius * 0.5

    if path[nextpathId+1] ~= nil then -- if this is not the last segment in the path
      local n3Pos = map.nodes[path[nextpathId+1]].pos
      local nVec2 = (n2Pos - n3Pos):z0():normalized():cross(gravityDir) -- vector normal to direction vector of lookAhead segment
      n2 = {pos = n2Pos + n2HalfRadius * (1 - nVec1:dot(nVec2)*0.5) * (nVec1 + nVec2), radius = n2HalfRadius} -- the position calculation is p2 + r * ( v2 + (1 - v1.v2) * v1 )
    else
      n2 = {pos = n2Pos + n2HalfRadius * nVec1, radius = n2HalfRadius}
    end

    local n1HalfRadius = n1.radius * 0.5

    n1 = {pos = n1Pos + min(planLen, 1) * nVec1 * n1HalfRadius, radius = n1HalfRadius}
  end

  local vec = (n1.pos - n2.pos):z0()
  local manualSpeed = speedList and speedList[nodeName]

  return {pos = vec3(n2.pos), posOrig = vec3(n2.pos), radius = n2.radius, radiusOrig = n2.radius,
          posz0 = n2.pos:z0(), vec = vec, dirVec = vec:normalized(), turnDir = vec3(0,0,0), manualSpeed = manualSpeed, pathidx = nextpathId}
end

local function createPlan(route, planIdx)
  local i = planIdx or 2
  local newPlan = {{radius = 2, radiusOrig = 2, pos = vec3(aiPos), posz0 = aiPos:z0(), posOrig = vec3(aiPos), turnDir = vec3(0,0,0), speed = 0}} -- speed here is might not be need to be defined
  local midTargetSegIdx = route.midTargetSegIdx
  local path = route.path
  local plan = route.plan
  local planLen = #plan
  local n = plan[i] or buildNextRoute(plan, planLen, path)
  if n == nil then
    route.plan = newPlan
    return 1
  end
  newPlan[2] = n
  if n.pos:squaredDistance(newPlan[1].pos) > 1e+10 then route.plan = 0; return 0 end
  local newPlanLen = 2
  local dist = 0
  local j = 1
  local minDist = min(max(250, 0.5*aiSpeed*aiSpeed/g), 550)
  repeat
    local curDist = newPlan[j].pos:distance(newPlan[j+1].pos)
    local xSq = square(dist+curDist)
    if curDist > min(220, (0.00000001*xSq + 0.0013)*xSq + 4.5) and j >= midTargetSegIdx then
      local node1 = newPlan[j]
      local node2 = newPlan[j+1]
      local pos = (node1.pos + node2.pos)*0.5
      local vec = (node1.pos - node2.pos):z0()
      tableInsert(newPlan, j+1, {posOrig = (node1.posOrig + node2.posOrig)*0.5,
                                pos = pos,
                                radiusOrig = (node1.radiusOrig + node2.radiusOrig)*0.5,
                                radius = (node1.radius + node2.radius)*0.5,
                                posz0 = pos:z0(),
                                vec = vec,
                                dirVec = vec:normalized(),
                                turnDir = vec3(0,0,0),
                                pathidx = node2.pathidx})
      newPlanLen = newPlanLen + 1
    else
      j = j + 1
      if j >= newPlanLen then
        i = i + 1
        local n = plan[i] or buildNextRoute(newPlan, newPlanLen, path)
        if n == nil then break end
        newPlanLen = newPlanLen + 1
        newPlan[newPlanLen] = n
      end
      dist = dist + curDist
    end
    -- 'and i >= planLen' ensures all previous plan nodes have been processed
    -- and inserted into the newPlan. solves the issue of having one very long edge.
  until dist > minDist and newPlanLen >= minPlanSize and i >= planLen or newPlanLen > 100
  newPlan[1].pathidx = newPlan[2].pathidx
  route.plan = newPlan
  return newPlanLen
end

local function calculateTarget(plan, meanSegRadius)
  targetstatus = 1

  local targetLength = max(aiSpeed * 0.65, 6.5)

  local targetSegIdx = 1
  local midTargetSegIdx = 1

  local remainder = targetLength
  local halfRemainder = targetLength * 0.5

  for i = 1, #plan-1 do
    local segLen = (plan[i].pos - plan[i+1].pos):length()

    if segLen < halfRemainder then
      halfRemainder = halfRemainder - segLen
    else
      midTargetSegIdx = i
      local p1Pos = plan[i].pos
      local vec = plan[i+1].pos - p1Pos
      local vecLen = vec:length()

      targetAiMidPos = p1Pos + vec * min(halfRemainder, vecLen) / vecLen
      halfRemainder = math.huge
    end

    if segLen < remainder then
      remainder = remainder - segLen
    else
      targetSegIdx = i
      local p1Pos = plan[i].pos
      local vec = plan[i+1].pos - p1Pos
      local vecLen = vec:length()

      targetPos = p1Pos + vec * min(remainder, vecLen) / vecLen
      break
    end
  end

  return targetSegIdx, midTargetSegIdx
end

local function planAhead(route, baseRoute)
  if route == nil then return end
  if route.path == nil then
    route.path = {}
    route.midTargetSegIdx = 1
    for i = 1, #route do
      route.path[i] = route[i]
      route[i] = nil
    end
    route.plan = {}
  end

  local plan = route.plan
  local planCount = #plan

  if planCount == 0 then
    -- merge from base plan
    if baseRoute ~= nil and #baseRoute.plan > 1 and baseRoute ~= route then
      local commonpathend = -1
      local bp = baseRoute.plan[2].pathidx
      for i = 1, min(#route.path, baseRoute.plan[#baseRoute.plan].pathidx - bp) do
        if baseRoute.path[bp] ~= route.path[i] then break end
        commonpathend = bp
        bp = bp + 1
      end

      if commonpathend > 1 then
        local i = 1
        local refpathidx = baseRoute.plan[2].pathidx - 1
        while i <= #baseRoute.plan and baseRoute.plan[i].pathidx <= commonpathend do
          local n = baseRoute.plan[i]
          plan[i] = {pos = vec3(n.pos), posOrig = vec3(n.posOrig), radius = n.radius, radiusOrig = n.radiusOrig,
                    posz0 = vec3(n.posz0), vec = vec3(n.vec), dirVec = vec3(n.dirVec), turnDir = vec3(n.turnDir), pathidx = n.pathidx - refpathidx}
          i = i + 1
        end
        route.midTargetSegIdx = baseRoute.midTargetSegIdx
      end
    end

    planCount = createPlan(route)
    plan = route.plan
    if planCount == 0 then targetstatus = -1; return end
  end

  if planCount >= 3 then
    if route.midTargetSegIdx > 1 then
      planCount = createPlan(route, min(planCount, route.midTargetSegIdx))
      plan = route.plan
    end

    if planCount >= 3 then
      local n2 = plan[2]
      local xnorm, sqDistance = aiPos:xnormSquaredDistanceToLineSegment(n2.pos, plan[3].pos)

      if sqDistance <= square(n2.radius) or xnorm >= 0 then
        -- 'vehicle is close enough to node ahead' or 'vehicle has gone off-road'
        -- ('road' means the segment between current plan[2] node and previous plan[2] node if it exists)
        planCount = createPlan(route, 3)
        plan = route.plan
      end
    end
  end

  if planCount <= 2 and internalState ~= 'offroad' then
    planCount = createPlan(route)
    plan = route.plan
    if planCount == 2 then
      targetPos = plan[2].pos
      targetstatus = -1
      return
    else
      return
    end
  end

  -- optimize positions --
  plan[1].pos = aiPos
  plan[1].posOrig = aiPos
  plan[1].posz0 = aiPos:z0()
  local aiCompDir

  if aiSpeed > 1 then
    aiCompDir = -fsign(aiDirVec:dot(aiVel))*aiVel:normalized()
  else
    aiCompDir = -aiDirVec:normalized()
  end

  plan[1].dirVec = aiCompDir:z0():normalized()
  plan[1].vec = plan[1].dirVec * 10
  -- plan[1].curvature = 0

  for i = planCount, 0, -1 do
    if forces[i] then
      forces[i]:set(0,0,0)
    else
      forces[i] = vec3(0,0,0)
    end
  end

  for i = 1, planCount-1 do
    local n1 = plan[i]
    local n2 = plan[i+1]
    local v1 = n1.dirVec
    local v2 = -n2.dirVec
    local turnDir = (v1 + v2):normalized()

    local nforce = max(1 + v1:dot(v2), 0) * turnDir
    forces[i+1] = forces[i+1] - nforce
    forces[i-1] = forces[i-1] - nforce
    forces[i] = forces[i] + nforce + nforce

    n1.turnDir:set(turnDir)
  end

  local distFromEdge = aiWidth * min(1, 0.67 + 0.5*square(aggression-1))
  for i = 2, planCount do
    local n = plan[i]
    local k = n.turnDir:dot(forces[i])
    local nodeDisplVec = n.pos + fsign(k) * min(abs(k), 0.5) * n.turnDir - n.posOrig
    local nodeDisplLen = nodeDisplVec:length()
    local nodeDisplLenLim = min(nodeDisplLen, max(n.radiusOrig - distFromEdge, 0))
    n.radius = max(n.radiusOrig - nodeDisplLenLim, aiWidth * 0.7) -- max(n.radiusOrig - fsign(nodeDisplVec:dot(n.turnDir)) * nodeDisplLenLim - distFromEdge, distFromEdge)
    n.pos = n.posOrig + (nodeDisplLenLim / (nodeDisplLen + 1e-30)) * nodeDisplVec
    n.posz0:set(n.pos:z0())
    n.vec:set(plan[i-1].posz0 - n.posz0)
    n.dirVec:set(n.vec:normalized())
    n.speed = -1
  end

  targetSegIdx, midTargetSegIdx = calculateTarget(plan, meanSegRadius)
  route.midTargetSegIdx = midTargetSegIdx

  local coneIdx = min(math.floor(targetSegIdx), planCount)
  local lnP1 = aiPos
  local lnP2 = lnP1 - aiCompDir
  local xnormTarget, distTarget = plan[coneIdx].pos:xnormDistanceToLineSegment(lnP1, lnP2)

  for i = 2, coneIdx-1 do
    local n = plan[i]
    local xnormNode, distNode = n.pos:xnormDistanceToLineSegment(lnP1, lnP2)
    local distLimit = distTarget * xnormNode / (xnormTarget + 1e-30)
    if distNode > distLimit then
      local lineRefPnt = linePointFromXnorm(lnP1, lnP2, xnormNode)
      local nodeDisplVec = lineRefPnt + (n.pos - lineRefPnt):normalized() * distLimit - n.posOrig
      local nodeDisplLen = nodeDisplVec:length()
      local distFromEdge = aiWidth * max(min(0.675 / sqrt(aggression), (n.radiusOrig / aiWidth)*0.675), 0.55)
      local nodeDisplLenLim = min(nodeDisplLen, max(n.radiusOrig - distFromEdge, 0))
      n.radius = max(n.radiusOrig - nodeDisplLenLim, aiWidth * 0.7) -- max(n.radiusOrig - fsign(nodeDisplVec:dot(n.turnDir)) * nodeDisplLenLim - distFromEdge, distFromEdge)
      n.pos = n.posOrig + nodeDisplVec * (nodeDisplLenLim / (nodeDisplLen + 1e-30))
      n.posz0:set(n.pos:z0())
      n.vec:set(plan[i-1].posz0 - n.posz0)
      n.dirVec:set(n.vec:normalized())
    end
  end

  -- plan speeds
  local rLast = plan[planCount]

  if rLast.pathidx ~= #route.path or M.mode == 'chase' or (race and noOfLaps and noOfLaps > 1) then
    rLast.speed = rLast.manualSpeed or 200
  else
    rLast.speed = rLast.manualSpeed or 0
  end

  local traffic
  if false and driveInLaneFlag then
    traffic = {}
    for i = planCount-1, 1, -1 do
      local node1 = plan[i]
      local node2 = plan[i+1]
      if i == targetSegIdx then
        i = 1
        node1 = plan[i]
        node2 = plan[targetSegIdx+1]
      end
      traffic[i] = {}
      for plID, v in pairs(mapmgr.objects) do
        if plID ~= aiID then
          local plPosFront = vec3(obj:getObjectFrontPosition(plID))
          local plWidth = obj:getObjectInitialLength(plID)
          local plPosRear = plPosFront - v.dirVec * plWidth
          local plWidth = obj:getObjectInitialWidth(plID)
          local plWidthVec = v.dirVec:cross(gravityDir):normalized() * plWidth * 0.5
          local vehP1 = plPosRear-plWidthVec -- rear right
          local vehP2 = plPosFront-plWidthVec -- front right
          local vehP3 = plPosRear+plWidthVec -- rear left
          local vehP4 = plPosFront+plWidthVec -- front left

          local plXnormOnPlanLine1, distSq1 = plPosFront:xnormSquaredDistanceToLineSegment(node1.pos, node2.pos)
          local plXnormOnPlanLine2, distSq2 = plPosRear:xnormSquaredDistanceToLineSegment(node1.pos, node2.pos)
          local plXnormOnPlanLine3, xnormAlongPl1 = closestLinePoints(node1.pos, node2.pos, vehP1, vehP2)
          local plXnormOnPlanLine4, xnormAlongPl2 = closestLinePoints(node1.pos, node2.pos, vehP3, vehP4)
          local limitDistSq = square((aiWidth + plWidth) * 0.6)
          if plXnormOnPlanLine1 >= 0 and plXnormOnPlanLine1 <= 1 and distSq1 <= limitDistSq or
                plXnormOnPlanLine2 >= 0 and plXnormOnPlanLine2 <= 1 and distSq2 <= limitDistSq or
                min(plXnormOnPlanLine3, xnormAlongPl1) >= 0 and max(plXnormOnPlanLine3, xnormAlongPl1) <= 1 or
                min(plXnormOnPlanLine4, xnormAlongPl2) >= 0 and max(plXnormOnPlanLine4, xnormAlongPl2) <= 1 then
            -- if both are in each others way then rights of passage is to the one that has higher velocity
            -- get the smallest plan line xnorm which is between 0 and 1
            -- local plXnormOnPlanLine = min(abs(plXnormOnPlanLine1) / max(0, fsign(plXnormOnPlanLine1)),
            --                                   abs(plXnormOnPlanLine2) / max(0, fsign(plXnormOnPlanLine2)),
            --                                   abs(plXnormOnPlanLine3) / max(0, fsign(plXnormOnPlanLine3)),
            --                                   abs(plXnormOnPlanLine4) / max(0, fsign(plXnormOnPlanLine4)))
            local plXnormOnPlanLine = max(0, min(plXnormOnPlanLine1, plXnormOnPlanLine2, plXnormOnPlanLine3, plXnormOnPlanLine4))

            tableInsert(traffic[i], {plID, plXnormOnPlanLine, v.vel:dot((node2.pos-node1.pos):normalized())})
          elseif true then
            local plAIAngle = aiDirVec:dot((plPosFront-aiPos):normalized())
            if plAIAngle > -0.985 then
              local plVel = v.vel
              -- player trajectory does not go through ai vehicle bounds (i.e. player vehicle is not right behind ai vehicles)
              local plXnormOnPlanLine, xnorm2 = closestLinePoints(node1.pos, node2.pos, plPosFront, plPosFront+plVel)
              if min(xnorm2, plXnormOnPlanLine) > 0 and plXnormOnPlanLine <= 1 then
                -- player trajectory half-line intersects ai segment
                local segNormal = (node2.pos - node1.pos):cross(gravityDir)
                if segNormal:dot(plVel) > 0 then
                  -- player vehicle aproaching from the right. Give way.
                  segNormal = segNormal:normalized()
                  local dist = aiWidth * 0.6
                  local playerSpeed = plVel:length() + 1e-30

                  local xnorm_a = closestLinePoints(node1.pos-segNormal*dist, node2.pos-segNormal*dist, plPosFront, plPosFront+plVel)
                  local eta_p = (linePointFromXnorm(node1.pos-segNormal*dist, node2.pos-segNormal*dist, xnorm_a) - plPosFront):length() / playerSpeed

                  local xnorm_d = closestLinePoints(node1.pos+segNormal*dist, node2.pos+segNormal*dist, plPosRear, plPosRear+plVel)
                  local etd_p = (linePointFromXnorm(node1.pos+segNormal*dist, node2.pos+segNormal*dist, xnorm_d) - plPosRear):length() / playerSpeed

                  eta_p, etd_p = min(eta_p, etd_p), max(eta_p, etd_p)

                  local xnorm = min(1, max(0, min(xnorm_d, xnorm_a)))

                  local plAIColVec = linePointFromXnorm(node1.pos, node2.pos, xnorm) - aiPos
                  local plAIColDist = plAIColVec:length()
                  local eta_ai = (plAIColDist - max(node1.radius, node2.radius)*1.5) / (aiVel:dot(plAIColVec:normalized()) + 1e-30)
                  local etd_ai = (plAIColDist + max(node1.radius, node2.radius)*1.5) / (aiVel:dot(plAIColVec:normalized()) + 1e-30)
                  if not (etd_ai < eta_p or eta_ai > etd_p) then
                    tableInsert(traffic[i], {plID, xnorm, 0})
                  end
                end
              end
            end
          end
        end
      end
      if i == 1 then break end
    end
  end

  local nextCos = 1
  local totalAccel = learned_total_accel

  for i = planCount - 1, targetSegIdx+1, -1 do
    local node1 = plan[i]
    local node2 = plan[i+1]

    -- inclination calculation
    local v12d = node2.pos - node1.pos
    local dist = v12d:length() + 1e-30
    v12d = v12d / dist
    local Gf = gravityVec:dot(v12d) -- acceleration due to gravity parallel to raod segment, positive when downhill
    local Gt = (gravityVec - v12d * Gf):length() / g -- gravity vec normal to road segment

    local node2SpeedSq = square(node2.speed)

    local curvature = 2 * sqrt(node1.vec:cross(node2.vec):squaredLength() /
                               (node1.vec:squaredLength() * node2.vec:squaredLength() * (node1.vec + node2.vec):squaredLength())) + 1.6e-7

    local turnSpeedSq = totalAccel * Gt / curvature -- available centripetal acceleration * radius

    -- https://physics.stackexchange.com/questions/312569/non-uniform-circular-motion-velocity-optimization
    --local deltaPhi = 2 * asin(0.5 * node2.vec:length() * curvature) -- phi = phi2 - phi1 = 2 * asin(halfcord / radius)
    local node1SpeedSq = turnSpeedSq * sin(min(asin(min(node2SpeedSq/turnSpeedSq), 1) + 2*curvature*dist, pi*0.5))

    -- average tangential acceleration -- THIS IS PROBLEMATIC FOR VERY LOW TO ZERO CURVATURES
    local acct = max((node1SpeedSq - min(node2SpeedSq, turnSpeedSq)) * 0.5 / dist, 0) - Gf
    -- average centripetal acceleration
    local accn = square((sqrt(min(node2SpeedSq, turnSpeedSq)) + sqrt(node1SpeedSq)) * 0.5) * curvature
    local acc = sqrt(accn * accn + acct * acct)

    turnSpeedSq = acc / curvature
    node1SpeedSq = turnSpeedSq * sin(min(asin(min(node2SpeedSq/turnSpeedSq), 1) + 2*curvature*dist, pi*0.5))

    if i > 1 then
      local node0 = plan[i-1]
      local bumpSqSpeedToRangeRatio = projectileSquareSpeedToRangeRatio(node0.pos, node1.pos, node2.pos)
      if bumpSqSpeedToRangeRatio ~= math.huge then -- i.e. the projectile angle is greater than the incline angle so a jump is possible
        if node2.posz0:distanceToLine(node0.posz0, node1.posz0) < node2.radius then -- the next node is ~ alligned with the current segment
          -- the ratio times the range gives the square speed of the projectile lauch speed for which we will not ecceed the given range
          local bumpSpeedSq = bumpSqSpeedToRangeRatio * max(node2.vec:length(), node1.radiusOrig)
          if node1SpeedSq > bumpSpeedSq then
            if bumpSpeedSq > node2SpeedSq then
              node1SpeedSq = (node2SpeedSq + 2 * node2.vec:length() * acc ) / (1 + 2 * (1/bumpSqSpeedToRangeRatio) * acc)
            else
              if nextCos < -0.999 then
                -- segment starting at node3speed is almost aligned with segment ending at node3speed
                node1SpeedSq = node2SpeedSq
              else
                -- so as not to go beyond node3 and also reach there with less speed than node3.speed (no room to brake, no need to brake)
                node1SpeedSq = bumpSpeedSq
              end
            end
          else -- node1SpeedSq <= bumpSpeedSq (will jump but how far and how much distance will there be to brake)
            -- at this speed there will be some flight but it will not reach node3
            if node1SpeedSq > node2SpeedSq then
              -- some braking will be required and some traction is lost because of the distance we travel while in flight (how much?)
              -- find range of flight calculate distance that is available for braking and recalculate speed
              node1SpeedSq = (node2SpeedSq + 2 * node2.vec:length() * acc) / (1 + 2 * (1/bumpSqSpeedToRangeRatio) * acc)
            end
          end
        else -- do not take off
          node1SpeedSq = min(node1SpeedSq, bumpSqSpeedToRangeRatio * min(node2.vec:length(), node1.radiusOrig))
        end
      end
    end

    if traffic then
      for _, data in ipairs(traffic[i]) do
        local plPosOnPlan = linePointFromXnorm(node1.pos, node2.pos, data[2])
        local plAIColDist = (plPosOnPlan - aiPos):length()
        local plID = data[1]
        local v = mapmgr.objects[plID]
        node1SpeedSq = min(square(max(data[3], 0)) + 2 * acc * (plPosOnPlan - node1.pos):length() * max(plAIColDist - 5, 0) / (plAIColDist + 10), node1SpeedSq)
      end
    end

    nextCos = node1.dirVec:dot(-node2.dirVec)
    node1SpeedSq = sqrt(node1SpeedSq)

    -- if manualSpeed or routeSpeed are nil/false then fall back to the calculated node1SpeedSq.
    -- if routeSpeed is true (has a value) and limitSpeed == false then impose routeSpeed on entire route
    -- if routeSpeed is true (has a value) and limitSpeed == true then cap route speed (set max speed limit) to routeSpeed
    node1.speed = node1.manualSpeed or ((routeSpeed and limitSpeed) and min(routeSpeed, node1SpeedSq) ) or (limitSpeed ~= nil and routeSpeed) or node1SpeedSq
  end

  do
    -- Step 1
    local node2 = plan[targetSegIdx+1]

    -- Inclination calculation
    local v12d = node2.pos - targetAiMidPos
    local dist = v12d:length() + 1e-30
    v12d = v12d / dist
    local Gf = gravityVec:dot(v12d) -- Force per mass (acceleration) along the road, positive when downhill
    local Gt = (gravityVec - v12d * Gf):length() / g -- gravity vec normal to road segment

    local node2SpeedSq = square(node2.speed)

    local vec1 = (aiPos - targetAiMidPos):z0()
    local vec2 = (targetAiMidPos - node2.pos):z0()

    local curvature = 2 * sqrt(vec1:cross(vec2):squaredLength() /
                               (vec1:squaredLength() * vec2:squaredLength() * (vec1 + vec2):squaredLength())) + 1.6e-7
    local turnSpeedSq = totalAccel * Gt / curvature -- available centripetal acceleration * radius

    -- https://physics.stackexchange.com/questions/312569/non-uniform-circular-motion-velocity-optimization
    --local deltaPhi = 2 * asin(0.5 * vec2:length() * curvature) -- phi = phi2 - phi1 = 2 * asin(halfcord / radius)
    local targetAiMidPosSpeed = turnSpeedSq * sin(min(asin(min(node2SpeedSq/turnSpeedSq, 1)) + 2*curvature*dist, pi*0.5))

    -- average tangential acceleration -- THIS IS PROBLEMATIC FOR VERY LOW TO ZERO CURVATURES
    local acct = max((targetAiMidPosSpeed - min(node2SpeedSq, turnSpeedSq)) * 0.5 / dist, 0) - Gf
    -- average centripetal acceleration
    local accn = square((sqrt(min(node2SpeedSq, turnSpeedSq)) + sqrt(targetAiMidPosSpeed)) * 0.5) * curvature
    local acc = sqrt(accn * accn + acct * acct)

    turnSpeedSq = acc / curvature
    targetAiMidPosSpeed = turnSpeedSq * sin(min(asin(min(node2SpeedSq/turnSpeedSq), 1) + 2*curvature*dist, pi*0.5))

    -- Step 2
    local node1 = plan[1]
    node2SpeedSq = targetAiMidPosSpeed

    vec1:set(node1.vec)
    dist = aiPos - targetAiMidPos
    vec2:set(dist:z0())
    dist = dist:length()

    curvature = 2 * sqrt(vec1:cross(vec2):squaredLength() / (vec1:squaredLength() * vec2:squaredLength() * (vec1 + vec2):squaredLength())) + 1.6e-7
    turnSpeedSq = totalAccel * Gt / curvature -- available centripetal acceleration * radius

    -- https://physics.stackexchange.com/questions/312569/non-uniform-circular-motion-velocity-optimization
    --deltaPhi = 2 * asin(0.5 * vec2:length() * curvature) -- phi = phi2 - phi1 = 2 * asin(halfcord / radius)
    local node1SpeedSq = turnSpeedSq * sin(min(asin(min(node2SpeedSq/turnSpeedSq, 1)) + 2*curvature*dist, pi*0.5))

    if traffic then
      for _, data in ipairs(traffic[1]) do
        local plPosOnPlan = linePointFromXnorm(node1.pos, node2.pos, data[2])
        local plAIColDist = (plPosOnPlan - aiPos):length()
        local plID = data[1]
        local v = mapmgr.objects[plID]
        local playerPos = vec3(obj:getObjectFrontPosition(plID)) - v.dirVec * obj:getObjectInitialLength(plID)
        node1SpeedSq = min(square(max(data[3], 0)) + 2 * acc * (plPosOnPlan - node1.pos):length() * max(plAIColDist - 5, 0) / (plAIColDist + 10), node1SpeedSq)
      end
    end

    node1SpeedSq = sqrt(node1SpeedSq)

    node1.speed = node1.manualSpeed or ((routeSpeed and limitSpeed) and min(routeSpeed, node1SpeedSq)) or (limitSpeed ~= nil and routeSpeed) or node1SpeedSq
  end

  return plan
end

local function setSpeed(speed)
  -- both routeSpeed and limitSpeed have to be ~= nil for the set speed (either in limit mode or in set mode) to be effective
  if type(speed) ~= 'number' then routeSpeed = nil else routeSpeed = speed end
  M.routeSpeed = routeSpeed
end

local function setSpeedMode(speedMode)
  if speedMode == 'set' then
    limitSpeed = false
  elseif speedMode == 'limit' then
    limitSpeed = true
  else
    limitSpeed = nil
  end
  M.speedMode = speedMode
end

local function resetSpeedModeAndValue()
  routeSpeed = nil
  limitSpeed = nil
  M.speedMode = nil -- maybe this should be 'off'
  M.routeSpeed = nil
end

local function resetMapAndRoute()
  currentRoute = nil
  targetPos = nil
  race = nil
  noOfLaps = nil
  internalState = 'onroad'
  resetAggression()
end

local function fleePlan()
  local wp1, wp2 = mapmgr.findClosestRoad(aiPos)

  if wp1 == nil or wp2 == nil then
    internalState = 'offroad'
    return
  else
    internalState = 'onroad'
  end

  if aiDirVec:dot(map.nodes[wp2].pos - aiPos) > 0 then -- map.nodes[wp1].pos
    wp1, wp2 = wp2, wp1
  end

  local newRoute
  if targetName == nil then -- flee without target
    newRoute = mapmgr.getFleePath(wp1, mapmgr.objects[aiID], player) -- TODO: Why do i use mapmgr.objects here???
  else -- flee to target
    newRoute = mapmgr.getPathAwayFrom(wp1, targetName, aiPos, player.pos)
  end

  local newRouteLen = #newRoute

  if newRouteLen == 0 then
    internalState = 'offroad'
    return
  else
    internalState = 'onroad'
  end

  if newRouteLen == 1 and currentRoute ~= nil then
    planAhead(currentRoute)
    return
  end

  if newRouteLen >= 3 and newRoute[2] == wp2 then
    tableRemove(newRoute, 1)
    newRouteLen = newRouteLen - 1
  end

  if currentRoute == nil then
    if planAhead(newRoute) == nil then return end
    currentRoute = newRoute
    return
  end

  if newRouteLen == #currentRoute.path and newRoute[1] == currentRoute.path[1] and newRoute[newRouteLen] == currentRoute.path[#currentRoute.path] then
    planAhead(currentRoute)
    return
  end

  local tempPlan = planAhead(newRoute, currentRoute)

  if tempPlan == nil then
    planAhead(currentRoute)
    return
  else
    local ai2pl = player.pos - aiPos
    if (tempPlan[1].speed >= aiSpeed and (tempPlan[2].pos - aiPos):dot(aiDirVec) >= 0.4) or #currentRoute.plan < minPlanSize
    or (ai2pl:normalized():dot(aiDirVec) > 0.4 and ai2pl:squaredLength() < 3600) then
      currentRoute = newRoute
    else
      planAhead(currentRoute)
    end
  end
end

local function chasePlan()
  local mapNodes = map.nodes

  local wp1, wp2, dist1 = mapmgr.findClosestRoad(aiPos)

  if (wp1 == nil or wp2 == nil) then
    internalState = 'offroad'
    return
  end

  if aiDirVec:dot(mapNodes[wp2].pos - mapNodes[wp1].pos) > 0 then wp1, wp2 = wp2, wp1 end

  local plwp1, plwp2, dist2 = mapmgr.findClosestRoad(player.pos)

  if (plwp1 == nil or plwp2 == nil) then
    internalState = 'offroad'
    return
  end

  if dist1 > max(mapNodes[wp1].radius, mapNodes[wp2].radius) * 2 and dist2 > max(mapNodes[plwp1].radius, mapNodes[plwp2].radius) * 2 then
    internalState = 'offroad'
    return
  end

  internalState = 'onroad'

  if player.dirVec:dot(mapNodes[plwp2].pos - mapNodes[plwp1].pos) > 0 then plwp1, plwp2 = plwp2, plwp1 end

  if wp1 == plwp1 and plPrevVel ~= nil then
    local playerNodePos1 = mapNodes[plwp1].pos

    local segDir = (playerNodePos1 - mapNodes[plwp2].pos)
    local targetLineDir = vec3(-segDir.y, segDir.x, 0)
    local l1xn = closestLinePoints(playerNodePos1, playerNodePos1 + targetLineDir, player.pos, player.pos + player.dirVec)
    local tarPos = playerNodePos1 + targetLineDir * l1xn

    local p2Target = (tarPos - player.pos):normalized()
    local plVel2Target = player.vel:dot(p2Target)
    local plAccel = (plVel2Target - plPrevVel:dot(p2Target)) / tau
    local plTimeToTarget = (sqrt(max(plVel2Target * plVel2Target + 2 * plAccel * (tarPos - player.pos):length(), 0)) - plVel2Target) / (plAccel + 1e-30)

    local aiVel2Target = aiVel:dot((tarPos - aiPos):normalized())
    local aiTimeToTarget = (tarPos - aiPos):length() / (aiVel2Target + 1e-30)

    if aiTimeToTarget < plTimeToTarget then
      internalState = 'tail'
      return
    else
      local newRoute = {}

      newRoute.midTargetSegIdx = 1
      newRoute.path = {}

      local segRadius = mapNodes[plwp1].radius
      local playerPos = player.pos
      local playerDirVec = player.dirVec
      local vec1 = (aiPos - playerPos):z0()
      local vec2 = -playerDirVec:z0()

      newRoute.plan = { {radius = 2, radiusOrig = 2, pos = vec3(aiPos), posz0 = aiPos:z0(), posOrig = vec3(aiPos), turnDir = vec3(0,0,0), speed = 0, pathidx = 1},
        {radius = segRadius, radiusOrig = segRadius, pos = vec3(playerPos), posz0 = playerPos:z0(), posOrig = vec3(playerPos),
        vec = vec1, dirVec = vec1:normalized(), turnDir = vec3(0,0,0), pathidx = 1},
        {radius = segRadius, radiusOrig = segRadius, pos = playerPos + 15*playerDirVec, posz0 = (playerPos + 15*playerDirVec):z0(),
          posOrig = playerPos + 15 * playerDirVec, vec = vec2, dirVec = vec2:normalized(), turnDir = vec3(0,0,0), pathidx = 2} }

      if planAhead(newRoute) == nil then return end
      currentRoute = newRoute
      return
    end
  end

  if currentRoute ~= nil and currentRoute.path[1] == wp1 and currentRoute.path[#currentRoute.path] == plwp1 then
    planAhead(currentRoute)
    return
  end

  local newRoute = mapmgr.getPath(wp1, plwp1, driveInLaneFlag and 10e7 or 1)

  if #newRoute >= 3 and newRoute[2] == wp2 then
    tableRemove(newRoute, 1)
  end

  if currentRoute ~= nil then
    -- new plan same as old return
    if #currentRoute.path >= #newRoute and plwp1 == currentRoute.path[#currentRoute.path]
    and currentRoute.plan[2] ~= nil and wp1 == currentRoute.path[currentRoute.plan[2].pathidx] then
      local j = #currentRoute.path
      local curPathid = currentRoute.path[currentRoute.plan[#currentRoute.plan].pathidx]
      for i = #newRoute, 1, -1 do
        if newRoute[i] ~= currentRoute.path[j] then
          break
        end
        if currentRoute.path[j] == curPathid then
          planAhead(currentRoute)
          return
        end
        j = j - 1
      end
    end

    local tempplan = planAhead(newRoute, currentRoute)
    if tempplan == nil then return end

    if (tempplan[1].speed > aiSpeed and (tempplan[2].pos - aiPos):dot(aiDirVec) > 0) or #currentRoute.plan < minPlanSize then
      currentRoute = newRoute
    end
  else
    if planAhead(newRoute) == nil then return end
    currentRoute = newRoute
  end
end

local function getMapEdges(cutOffDrivability, node)
  -- creates a table (edgeDict) with map edges with drivability > cutOffDrivability
  if map.nodes ~= nil then
    local allSCC = mapmgr.getSCC(node) -- returns all scc's reachable from 'node'. an array of dicts
    local maxSccLen = 0
    local sccIdx
    for i, scc in ipairs(allSCC) do
      local sccLen = scc[0] -- position at which the number of nodes in currentSCC is stored
      if sccLen > maxSccLen then
        sccIdx = i
        maxSccLen = sccLen
      end
      scc[0] = nil
    end
    local currentSCC = allSCC[sccIdx]
    local keySet = {}
    local keySetLen = 0
    edgeDict = {}
    for nid, n in pairs(map.nodes) do
      if currentSCC[nid] or not driveInLaneFlag then
        for lid, data in pairs(n.links) do
          if (currentSCC[lid] or not driveInLaneFlag) and (data.drivability > cutOffDrivability) then
            local inNode = data.inNode
            local outNode = inNode == nid and lid or nid
            keySetLen = keySetLen + 1
            keySet[keySetLen] = {inNode, outNode}
            edgeDict[inNode..'\0'..outNode] = 1
            if not data.oneWay or not driveInLaneFlag then
              edgeDict[outNode..'\0'..inNode] = 1
            end
          end
        end
      end
    end
    if keySetLen == 0 then return end
    local edge = keySet[math.random(keySetLen)]
    return edge[1], edge[2]
  end
end

local function newManualPath()
  local newRoute, node1, node2, dist
  local offRoad = false
  if currentRoute ~= nil and currentRoute.path ~= nil then
    newRoute = {plan = currentRoute.plan, path = currentRoute.path, midTargetSegIdx = currentRoute.midTargetSegIdx}
  else
    node1, node2, dist = mapmgr.findClosestRoad(aiPos)
    if node1 == nil or node2 == nil then
      gui.message("Could not find a road network, or closest road is too far", 5, "AI debug")
      return
    end
    offRoad = dist > 2 * max(map.nodes[node1].radius, map.nodes[node2].radius)
    if offRoad then
      local vec1 = map.nodes[node1].pos - aiPos
      local vec2 = map.nodes[node2].pos - aiPos
      if aiDirVec:dot(vec1) > 0 and aiDirVec:dot(vec2) > 0 then
        if vec1:length() > vec2:length() then node1, node2 = node2, node1 end
      elseif aiDirVec:dot(map.nodes[node2].pos - map.nodes[node1].pos) > 0 then node1, node2 = node2, node1 end
    elseif aiDirVec:dot(map.nodes[node2].pos - map.nodes[node1].pos) > 0 then node1, node2 = node2, node1 end
    newRoute = {plan = {}, path = {node1}, midTargetSegIdx = 1}
  end
  for i = 0, #wpList-1 do
    local wp1 = wpList[i] or newRoute.path[#newRoute.path]
    local wp2 = wpList[i+1]
    local route = mapmgr.getPath(wp1, wp2, driveInLaneFlag and 10e7 or 1)
    local routeLen = #route
    if routeLen == 0 or (routeLen == 1 and wp2 ~= wp1) then
      gui.message("Path between waypoints '".. wp1 .."' - '".. wp2 .."' Not Found", 7, "AI debug")
      return
    end
    for j = 2, routeLen do
      tableInsert(newRoute.path, route[j])
    end
  end
  wpList = nil
  if not offRoad and #newRoute.path >= 3 and newRoute.path[2] == node2 then
    tableRemove(newRoute.path, 1)
  end
  currentRoute = newRoute
end

local function validateUserInput()
  validateInput = nop
  local wpListLen = #wpList
  local isValid = wpListLen >= 1
  for i = 1, wpListLen do
    if map.nodes[wpList[i]] == nil then
      local nodeAlias = map.nodeAliases[wpList[i]]
      if nodeAlias and map.nodes[nodeAlias] then
        wpList[i] = nodeAlias
      else
        if isValid then
          gui.message("One or more of the waypoints were not found on the map. Check the game console for more info.", 6, "AI debug")
          print('The waypoints with the following names could not be found on the Map: ')
          isValid = false
        end
        print(wpList[i])
      end
    end
  end
  return isValid
end

local function warningAIDisabled(message)
  gui.message(message, 5, "AI debug")
  M.mode = 'disabled'
  M.updateGFX = nop
  resetMapAndRoute()
  stateChanged()
end

M.updateGFX = nop
local function updateGFX(dt)
  if map == nil then
    if mapmgr.map == nil then return end
    map = mapmgr.map
  end

  local tmpPos = obj:getFrontPosition()
  aiPos:set(tmpPos)
  aiPos.z = max(aiPos.z - 1, obj:getSurfaceHeightBelow(tmpPos))
  aiDirVec:set(obj:getDirectionVector())
  aiVel:set(obj:getVelocity())
  aiSpeed = aiVel:length()
  aiWidth = aiWidth or obj:getObjectInitialWidth(aiID)
  aiLength = aiLength or obj:getObjectInitialLength(aiID)

  ------------------ RANDOM MODE ----------------
  if M.mode == 'random' then
    if currentRoute == nil or currentRoute.plan[2].pathidx > #currentRoute.path * 0.75 then
      local wp1, wp2 = mapmgr.findClosestRoad(aiPos)

      if wp1 == nil or wp2 == nil then
        warningAIDisabled("Could not find a road network, or closest road is too far")
        return
      end

      if offRoad then
        local vec1 = map.nodes[wp1].pos - aiPos
        local vec2 = map.nodes[wp2].pos - aiPos
        if aiDirVec:dot(vec1) > 0 and aiDirVec:dot(vec2) > 0 then
          if vec1:length() > vec2:length() then wp1, wp2 = wp2, wp1 end
        elseif aiDirVec:dot(map.nodes[wp2].pos - map.nodes[wp1].pos) > 0 then wp1, wp2 = wp2, wp1 end
      elseif aiDirVec:dot(map.nodes[wp2].pos - map.nodes[wp1].pos) > 0 then wp1, wp2 = wp2, wp1 end

      local newRoute = mapmgr.getRandomPath(wp1, wp2, driveInLaneFlag and 10e7 or 1) -- TODO: add check if this returns empty table!!
      if newRoute and #newRoute > 0 then
        local tempplan = planAhead(newRoute, currentRoute)

        if tempplan == nil then
          if currentRoute == nil then return end
          planAhead(currentRoute)
        else
          if currentRoute == nil or (tempplan[1].speed >= aiSpeed and (tempplan[2].pos - aiPos):dot(aiDirVec) >= 0) then
            currentRoute = newRoute
          else
            planAhead(currentRoute)
          end
        end
      end
    else
      planAhead(currentRoute)
    end
    if currentRoute == nil then return end

  ------------------ MANUAL MODE ----------------
  elseif M.mode == 'manual' then
    if validateInput() then newManualPath() end
    if aggressionMode == 'rubberBand' then
      updatePlayerData()
      if player ~= nil then
        if (aiPos - player.pos):dot(aiDirVec) > 0 then
          setAggressionInternal(max(min(0.1 + max((150 - (player.pos - aiPos):length())/150, 0), 1), 0.5))
        else
          setAggressionInternal(0.95)
        end
      end
    end
    planAhead(currentRoute)
    if currentRoute == nil then return end

  ------------------ SPAN MODE ----------------
  elseif M.mode == 'span' then
    if currentRoute == nil then
      local mapNodes = map.nodes
      local wpAft, wpFore = mapmgr.findClosestRoad(aiPos)
      if not (wpAft and wpFore) then
        warningAIDisabled("Could not find a road network, or closest road is too far")
        return
      end
      if aiDirVec:dot(mapNodes[wpFore].pos - mapNodes[wpAft].pos) < 0 then wpAft, wpFore = wpFore, wpAft end

      local target, targetLink

      if not edgeDict then
        -- creates the edgeDict and returns a random edge
        target, targetLink = getMapEdges(M.cutOffDrivability or 0, wpFore)
        if not target then
          warningAIDisabled("No available target with selected characteristics")
          return
        end
      end

      local newRoute = {}

      while true do
        if not target then
          local maxDist = -math.huge
          local lim = 1
          repeat
            -- get most distant non walked edge
            for k, v in pairs(edgeDict) do
              if v <= lim then
                if lim > 1 then edgeDict[k] = 1 end
                local i = string.find(k, '\0')
                local n1id = string.sub(k, 1, i-1)
                local sqDist = (mapNodes[n1id].pos - aiPos):squaredLength()
                if sqDist > maxDist then
                  maxDist = sqDist
                  target = n1id
                  targetLink = string.sub(k, i+1, #k)
                end
              end
            end
            lim = math.huge -- if the first iteration does not produce a target
          until target
        end -- of if not target

        local nodeDegree = 1
        for k, v in pairs(mapNodes[target].links) do
          -- we're looking for neihboor nodes other than the targetLink
          if v ~= targetLink then
            nodeDegree = nodeDegree + 1
          end
        end
        if nodeDegree == 1 then
          local key = target..'\0'..targetLink
          edgeDict[key] = edgeDict[key] + 1
        end

        newRoute = mapmgr.spanMap(wpFore, wpAft, target, edgeDict, driveInLaneFlag and 10e7 or 1)
        local newRouteLen = #newRoute

        if newRouteLen <= 1 and wpFore ~= target then
          -- remove edge from edgeDict list and get a new target (while loop will iterate again)
          edgeDict[target..'\0'..targetLink] = nil
          edgeDict[targetLink..'\0'..target] = nil
          target = nil
          if next(edgeDict) == nil then
            warningAIDisabled("Could not find a path to any of the possible targets")
            return
          end
        elseif newRouteLen == 0 then
          warningAIDisabled("No Route Found")
          return
        else
          -- insert the second edge node in newRoute if it is not already contained
          if newRoute[newRouteLen-1] ~= targetLink then newRoute[newRouteLen+1] = targetLink end
          break
        end
      end -- of while

      if planAhead(newRoute) == nil then return end
      currentRoute = newRoute
    else --> if currentRoute ~= nil
      planAhead(currentRoute)
    end -- of "if currentroute == nil"

  ------------------ FLEE MODE ----------------
  elseif M.mode == 'flee' then
    updatePlayerData()
    if player ~= nil then

      if validateInput() then
        targetName = wpList[1]
        wpList = nil
      end

      setAggressionInternal(max(min(0.9 - (player.pos - aiPos):length()/150, 1), 0.3))

      fleePlan()

      if internalState == 'offroad' then
        targetPos = aiPos + (aiPos - player.pos) * 100
        throttle = 1
        brake = 0
        targetSpeed = math.huge
        aimToTarget()
        return
      end
    else
      --gui.message("No vehicle to Flee from", 5, "AI debug") -- TODO: this freezes the up because it runs on the gfx step
      return
    end

    if currentRoute == nil then return end

  ------------------ CHASE MODE ----------------
  elseif M.mode == 'chase' then
    updatePlayerData()
    if player ~= nil then
      tau = dt

      setAggressionInternal(min(0.6 + (aiPos - player.pos):length() * 0.005, 1))

      chasePlan()

      plPrevVel = vec3(player.vel)

      if internalState == 'tail' then
        internalState = 'onroad'
        targetPos = player.pos
        throttle = 1
        brake = 0
        currentRoute = nil
        aimToTarget()
        return
      elseif internalState == 'offroad' then
        targetPos = player.pos
        throttle = 1
        brake = 0
        targetSpeed = math.huge
        aimToTarget()
        return
      end
    else
      --gui.message("No vehicle to Chase", 5, "AI debug")
      return
    end

    if currentRoute == nil then return end

  ------------------ STOP MODE ----------------
  elseif M.mode == 'stop' then
    if aiVel:dot(aiDirVec) > 0 then
      driveCar(0, 0, 1, 0)
    else
      driveCar(0, 1, 0, 0)
    end
    if aiSpeed < 0.08 then --  or aiVel:dot(aiDirVec) < 0
      driveCar(0, 0, 0, 0) -- only parkingbrake
      M.mode = 'disabled'
      M.manualTargetName = nil
      M.updateGFX = nop
      resetMapAndRoute()
      stateChanged()
    end
    targetSpeed = 0
    aimToTarget()
    return
  end

  throttle = 1
  brake = 0
  if currentRoute ~= nil then
    targetSpeed = targetSpeedSmoother:get(currentRoute.plan[1].speed, dt)
    if targetstatus < 0 then
      if M.mode ~= 'chase' then
        if targetSpeed <= 0.01 and aiSpeed <= 0.1 or (targetPos - aiPos):dot(aiDirVec) < 0 then
          driveCar(0, 0, 0, 1)
          aistatus("route done", 'route')
          if M.mode == 'span' then
            local path = currentRoute.path
            for i = 1, #path - 1 do
              local key = path[i]..'\0'..path[i+1]
              -- in case we have gone over an edge that is not in the edgeDict list
              edgeDict[key] = edgeDict[key] and (edgeDict[key] * 20)
            end
          end
          currentRoute = nil
          speedRecordings = {}
          return
        end
      else
        aistatus("route done", 'route')
        currentRoute = nil
        speedRecordings = {}
        return
      end
    end

    local curTurnAccel = abs(sensors.gx2)
    learned_turn_accel = turnAccelSmoother:getUncapped(max(curTurnAccel, baseTurnAccel), dt)

    --local curBrakeAccel = abs(sensors.gy2)
    --learned_brake_accel = brakeAccelSmoother:getUncapped(max(curBrakeAccel, baseTurnAccel), dt)

    local curTotalAccel = sqrt(curTurnAccel*curTurnAccel + square(sensors.gy2))

    local accelCoeff = accCoeffGrad * aggression + accCoeffYintercept --> y = ax + b

    local compTotalAccel = max(min(curTotalAccel * accelCoeff, maxTottalAccel), baseTurnAccel)

    -- https://www.desmos.com/calculator/flajtwbld5 for the functions calculating the in/out rate below
    if compTotalAccel < totalAccelSmoother:value() then
      learned_total_accel = totalAccelSmoother:getWithRateUncapped(compTotalAccel, dt, 0.45 - 0.4 * aggression) --> in rate
    else
      learned_total_accel = totalAccelSmoother:getWithRateUncapped(compTotalAccel, dt, 3 * aggression - 0.3) --> out rate
    end

    local wheelSpeed = electrics.values.wheelspeed
    local trnAccRatio = min(curTurnAccel, learned_turn_accel)/learned_turn_accel

    brake = max(0, min((aiSpeed - targetSpeed) * 3 * square(aggression), 1))
            * min(square(sqrt(aiSpeed/(targetSpeed + 1e-30)) - square(trnAccRatio)) , 1) -- TODO: I think this should be vehicle dependent
            * max(min(2 - (aiSpeed - wheelSpeed) * 0.2, 1), 0)

    throttle = max(0, min((targetSpeed - aiSpeed) * 2 * square(aggression), 1))

    -- see https://www.desmos.com/calculator/e24ebyxrbr for the second term in the calculation below
    throttle = ((throttle > 0.1 * (1 - aggression)) and throttle or 0)
                * min(square(1 - square(trnAccRatio)) , 1) -- TODO: I think this should be vehicle dependent
                * min(max((7 - (wheelSpeed - aiSpeed)) / 6.5, 0), 1)
  end

  -- TODO: this still runs if there is no currentPlan, but raises error if there is no targetSpeed
  if not controller.isFrozen and aiSpeed < 0.1 and targetSpeed and
      targetSpeed > 0.5 and (lastCommand.throttle ~= 0 or lastCommand.brake ~= 0) then
    crashTime = crashTime + dt
    if crashTime > 1 then
      crashDir = vec3(aiDirVec)
      crashManeuver = 1
    end
  else
    crashTime = 0
  end

  if targetPos == nil then
    driveCar(0, 0, 0, 1)
    throttle = 0
  else
    aimToTarget()
  end
end

local function debugDraw(focusPos)
  local debugDrawer = obj.debugDrawProxy

  if targetPos ~= nil and targetAiMidPos ~= nil then
    debugDrawer:drawSphere(0.25, (aiPos - aiDirVec*aiLength):toFloat3(), color(0,255,0,255))
    debugDrawer:drawSphere(0.5, targetPos:toFloat3(), color(255,0,0,255))
    debugDrawer:drawSphere(0.3, targetAiMidPos:toFloat3(), color(255,0,0,255))


    local xyz = math.sin(math.rad(170)*0.5)*vec3(obj:getDirectionVectorUp())
    local q = quat(xyz.x, xyz.y, xyz.z, math.cos(math.rad(170)*0.5))
    local vec = aiDirVec:rotated(q)
    debugDrawer:drawCylinder(aiPos:toFloat3(), (aiPos+vec*50):toFloat3(), 0.02, color(0,0,255,200))

    xyz = math.sin(math.rad(-170)*0.5)*vec3(obj:getDirectionVectorUp())
    q = quat(xyz.x, xyz.y, xyz.z, math.cos(math.rad(-170)*0.5))
    vec = aiDirVec:rotated(q)
    debugDrawer:drawCylinder(aiPos:toFloat3(), (aiPos+vec*50):toFloat3(), 0.02, color(0,0,255,200))

  end

  if currentRoute then
    if M.debugMode == 'target' then
      if map ~= nil and map.nodes ~= nil and currentRoute.path then
        debugDrawer:drawCylinder(aiPos:toFloat3(), (aiPos+aiDirVec*50):toFloat3(), 0.02, color(0,0,255,200))

        local p = map.nodes[currentRoute.path[#currentRoute.path]].pos:toFloat3()
        --debugDrawer:drawSphere(4, p, color(255,0,0,100))
        --debugDrawer:drawText(p + float3(0, 0, 4), color(0,0,0,255), 'Destination')
      end

    elseif M.debugMode == 'route' then
      if currentRoute.path ~= nil and next(map) ~= nil then
        local p = map.nodes[currentRoute.path[#currentRoute.path]].pos:toFloat3()
        debugDrawer:drawSphere(4, p, color(255,0,0,100))
        debugDrawer:drawText(p + float3(0, 0, 4), color(0,0,0,255), 'Destination')
      end

      local maxLen = 700
      local last = routeRec.last
      local len = min(#routeRec, maxLen)
      if len == 0 or (routeRec[last] - aiPos:toFloat3()):length() > 7 then
        last = 1 + last % maxLen
        routeRec[last] = aiPos:toFloat3()
        len = min(len+1, maxLen)
        routeRec.last = last
      end

      local param = float3(0.7, aiWidth, 0.7)
      for i = 1, len-1 do
        debugDrawer:drawSquarePrism(routeRec[1+(last+i-1)%len], routeRec[1+(last+i)%len], param, param, color(0,0,0,128))
      end

      if currentRoute.plan[1].pathidx then
        local mapNodes = map.nodes
        local path = currentRoute.path
        local param = param + float3(0, aiWidth, 0)
        for i = currentRoute.plan[1].pathidx, #path - 1 do
          debugDrawer:drawSquarePrism(mapNodes[path[i]].pos:toFloat3(), mapNodes[path[i+1]].pos:toFloat3(), param, param, color(255,0,0,120))
        end
      end

    elseif M.debugMode == 'speeds' then
      local plan = currentRoute.plan
      if plan and plan[1] then
        local col = getContrastColor(aiID)
        local prevPoint = plan[1].pos:toFloat3()
        local prevSpeed = -1
        for i = 1, #plan do
          local n = plan[i]
          local p = n.pos:toFloat3()
          if i == targetSegIdx+1 then
            debugDrawer:drawSphere(0.4, p, color(0,0,255,200))
          end
          local v = (n.speed >= 0 and n.speed) or prevSpeed
          local p1 = p + float3(0, 0, v*0.2)
          --debugDrawer:drawLine(p + float3(0, 0, v*0.2), (n.pos + n.turnDir):toFloat3() + float3(0, 0, v*0.2), col)
          debugDrawer:drawCylinder(p, p1, 0.03, col)
          debugDrawer:drawCylinder(prevPoint, p1, 0.05, col)
          debugDrawer:drawText(p1, color(0,0,0,255), strFormat("%2.0f", v*3.6) .. " kph")
          prevPoint = p1
          prevSpeed = v
        end

        local aiPosFloat = aiPos:toFloat3()
        local speedRecLen = #speedRecordings

        if speedRecLen == 0 or (speedRecordings[speedRecLen][1] - aiPosFloat):length() > 0.25 then
          tableInsert(speedRecordings, {aiPosFloat, aiSpeed, plan[1].speed, targetSpeed, brake, throttle})
          speedRecLen = speedRecLen + 1
        end

        local zOffSet = float3(0,0,0.5)
        local lastEntry
        for i = 1, speedRecLen do
          local v = speedRecordings[i]
          if lastEntry then
            debugDrawer:drawCylinder(lastEntry[1]+float3(0,0,lastEntry[2]*0.2), v[1]+float3(0, 0, v[2]*0.2), 0.02, color(255,255,0,200)) -- actuall speed
            debugDrawer:drawCylinder(lastEntry[1]+float3(0,0,lastEntry[3]*0.2), v[1]+float3(0, 0, v[3]*0.2), 0.02, color(0,0,255,200)) -- Non Smoothed target speed
            debugDrawer:drawCylinder(lastEntry[1]+float3(0,0,lastEntry[4]*0.2), v[1]+float3(0, 0, v[4]*0.2), 0.02, color(255,0,0,200)) -- smoothed target speed
          end
          debugDrawer:drawCylinder(v[1], v[1]+float3(0, 0, v[3]*0.2), 0.01, color(0,0,255,200))

          if (focusPos - v[1]):length() < labelRenderDistance then
            debugDrawer:drawText(v[1]+float3(0, 0, v[2]*0.2) + zOffSet, color(255,255,0,200), strFormat("%2.0f", v[2]*3.6) .. " kph")
            debugDrawer:drawText(v[1]+float3(0, 0, v[3]*0.2) + zOffSet, color(0,0,255,200), strFormat("%2.0f", v[3]*3.6) .. " kph")
            debugDrawer:drawText(v[1]+float3(0, 0, v[4]*0.2) + zOffSet, color(255,0,0,200), strFormat("%2.0f", v[4]*3.6) .. " kph")
          end
          lastEntry = v
        end

        if speedRecLen > 250 then
          tableRemove(speedRecordings, 1)
        end
      end

    elseif M.debugMode == 'trajectory' then
      -- Debug Curvatures
      -- local plan = currentRoute.plan
      -- if plan ~= nil then
      --   local prevPoint = plan[1].pos:toFloat3()
      --   for i = 1, #plan do
      --     local p = plan[i].pos:toFloat3()
      --     local v = plan[i].curvature or 1e-10
      --     local scaledV = abs(1000 * v)
      --     debugDrawer:drawCylinder(p, p + float3(0, 0, scaledV), 0.06, color(abs(min(fsign(v),0))*255,max(fsign(v),0)*255,0,200))
      --     debugDrawer:drawText(p + float3(0, 0, scaledV), color(0,0,0,255), strFormat("%5.4e", v))
      --     debugDrawer:drawCylinder(prevPoint, p + float3(0, 0, scaledV), 0.06, col)
      --     prevPoint = p + float3(0, 0, scaledV)
      --   end
      -- end

      -- Debug Planned Speeds
      local plan = currentRoute.plan
      if plan and plan[1] then
        local col = getContrastColor(aiID)
        local prevPoint = plan[1].pos:toFloat3()
        local prevSpeed = -1
        for i = 1, #plan do
          local n = plan[i]
          local p = n.pos:toFloat3()
          local v = (n.speed >= 0 and n.speed) or prevSpeed
          local p1 = p + float3(0, 0, v*0.2)
          --debugDrawer:drawLine(p + float3(0, 0, v*0.2), (n.pos + n.turnDir):toFloat3() + float3(0, 0, v*0.2), col)
          debugDrawer:drawCylinder(p, p1, 0.03, col)
          debugDrawer:drawCylinder(prevPoint, p1, 0.05, col)
          debugDrawer:drawText(p1, color(0,0,0,255), strFormat("%2.0f", v*3.6) .. " kph")
          prevPoint = p1
          prevSpeed = v
        end
      end

      -- Debug Throttle brake application
      local maxLen = 250
      local len = min(#trajectoryRec, maxLen)
      local last = trajectoryRec.last
      if len == 0 or (trajectoryRec[last][1] - aiPos:toFloat3()):length() > 0.25 then
        last = 1 + last % maxLen
        trajectoryRec[last] = {aiPos:toFloat3(), throttle, brake}
        len = min(len+1, maxLen)
        trajectoryRec.last = last
      end

      local param = float3(0.7, aiWidth, 0.7)
      for i = 1, len-1 do
        local rec = trajectoryRec[1+(last+i)%len]
        debugDrawer:drawSquarePrism(trajectoryRec[1+(last+i-1)%len][1], rec[1], param, param, color(255*sqrt(abs(rec[3])), 255*sqrt(rec[2]), 0, 100))
      end
    end
  end
end

local function init()
  map = {}
end

local function setMode(mode)
  local previousMode = M.mode
  M.mode = mode

  if M.mode ~= 'disabled' then
    resetMapAndRoute()
    --mapmgr.enableTracking()
  end

  if M.mode ~= 'disabled' and M.mode ~= 'stop' then -- TODO: this should be more explicit maybe?
    mapmgr.requestMap()
    M.updateGFX = updateGFX
  end

  if M.mode == 'disabled' then
    M.updateGFX = nop
    driveCar(0,0,0,0)
    currentRoute = nil
    targetPos = nil
    wheels.resetABSBehavior()
    --M.mode = 'stop'
    --mapmgr.disableTracking('AI')
  elseif M.mode ~= 'stop' then
    if controller.mainController then
      controller.mainController.setGearboxMode("arcade")
    end
    wheels.setABSBehavior("arcade")
  end

  if M.mode == 'stop' then
  end

  speedRecordings = {}
  trajectoryRec = {last = 0}
  routeRec = {last = 0}
end

local function reset() -- called when the user pressed I
  M.manualTargetName = nil
  resetMapAndRoute()
  driveCar(0, 0, 0, 0)
  setMode(M.mode) -- some scenarios don't work if this is changed to setMode('disabled')
  stateChanged()
end

local function resetLearning()
  turnAccelSmoother:reset()
  totalAccelSmoother:reset()
  targetSpeedSmoother:reset()

  learned_turn_accel = turnAccelSmoother:value()
  learned_total_accel = totalAccelSmoother:value()
end

local function setVehicleDebugMode(newMode)
  tableMerge(M, newMode)
  if M.debugMode ~= 'trajectory' then
    trajectoryRec = {last = 0}
  end
  if M.debugMode ~= 'route' then
    routeRec = {last = 0}
  end
  if M.debugMode ~= 'speed' then
    speedRecordings = {}
  end
  if M.debugMode ~= 'off' then
    M.debugDraw = debugDraw
  else
    M.debugDraw = nop
  end
end

local function setState(newState)
  tableMerge(M, newState)
  setAggressionExternal(M.extAggression)
  setMode(M.mode)
  setVehicleDebugMode(M)
  setTargetObjectID(M.targetObjectID)
end

local function setTarget(wp)
  M.manualTargetName = wp
  validateInput = validateUserInput
  wpList = {wp}
end

local function driveInLane(v)
  if v == 'on' then
    driveInLaneFlag = true
    M.driveInLaneFlag = 'on'
  else
    driveInLaneFlag = false
    M.driveInLaneFlag = 'off'
  end
end

-- e.g. ai.driveUsingPath{ wpTargetList = {'wp1', 'wp10'}, noOfLaps = 3, aggression = 0.9, wpSpeeds = {wp1 = 10, wp2 = 20} }
-- all arguments except wpTargetList are optional
local function driveUsingPath(arg)
  if arg.wpTargetList == nil or type(arg.wpTargetList) ~= 'table' or
  (arg.wpSpeeds ~= nil and type(arg.wpSpeeds) ~= 'table') or
  (arg.noOfLaps ~= nil and type(arg.noOfLaps) ~= 'number') or
  (arg.routeSpeed ~= nil and type(arg.routeSpeed) ~= 'number') or
  (arg.routeSpeedMode ~= nil and type(arg.routeSpeedMode) ~= 'string') or
  (arg.driveInLane ~= nil and type(arg.driveInLane) ~= 'string') or
  (arg.aggression ~= nil and type(arg.aggression) ~= 'number') then
    return
  end

  if arg.resetLearning then
    resetLearning()
  end

  if arg.mode == 'span' then
    spanMap(arg.drivability)
  else
    setState({mode = 'manual'})
    noOfLaps = arg.noOfLaps and max(arg.noOfLaps, 1) or 1
    wpList = arg.wpTargetList
    validateInput = validateUserInput
    if noOfLaps > 1 and #wpList > 1 and wpList[1] == wpList[#wpList] then race = true end
  end

  speedList = arg.wpSpeeds or {}
  setSpeed(arg.routeSpeed)
  setSpeedMode(arg.routeSpeedMode)
  driveInLane(arg.driveInLane)
  setAggressionMode(arg.aggressionMode)
  setAggressionExternal(arg.aggression)
  stateChanged()
end

local function spanMap(cutOffDrivability)
  M.cutOffDrivability = cutOffDrivability or 0
  setState({mode = 'span'})
  stateChanged()
end

local function setCutOffDrivability(drivability)
  M.cutOffDrivability = drivability or 0
  stateChanged()
end

local function onDeserialized(v)
  setState(v)
  stateChanged()
end

local function dumpCurrentRoute()
  dump(currentRoute)
end

-- public interface
M.driveInLane = driveInLane
M.stateChanged = stateChanged
M.reset = reset
M.init = init
M.setMode = setMode
M.setTarget = setTarget
M.setSpeed = setSpeed
M.setSpeedMode = setSpeedMode
M.setVehicleDebugMode = setVehicleDebugMode
M.setState = setState
M.getState = getState
M.debugDraw = nop
M.driveUsingPath = driveUsingPath
M.setAggressionMode = setAggressionMode
M.setAggression = setAggressionExternal
M.onDeserialized = onDeserialized
M.setTargetObjectID = setTargetObjectID
M.dumpCurrentRoute = dumpCurrentRoute
M.spanMap = spanMap
M.setCutOffDrivability = setCutOffDrivability
M.resetLearning = resetLearning

return M