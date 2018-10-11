-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
require('mathlib')

local M = {}

M.dependencies = {'scenario_scenarios'}
local helper = require('scenario/scenariohelper')

local logTag = "dderby2.0"

--TODO clean up Variable names for better understandability
local lastPosition      = {}
local vehiclesStopTicks = {} --the time a vehicle has stood still consecutively
local scenarioVehicles  = {}
local activePlayers     = 0
local maxStopTicks      = 10 --MaxTime not moving until disqualified
local tickCounter       = 0

local playersMoving  = {} --players currently moving
local playersStopped = {} --disqualified Players

local retargetCD = {}
local retargetCDLength = 5 --minimum Time a car needs to follow a car before looking for a new target
local targets = {}    --The vehicle an AI vehicle is currently targeting

local playerV --the Player Vehicle Object
local pName   --the Players name
local aiVehicles = {} --All the AIVehicles
local vehicleData = {}--telemetry of the vehicles
--local cog = {}        --The vehicles center of gravity
--local cogNode = {}    --The ID of the node closest to the CoG
local vehPreCrash = {}--Telemetry of a vehicle at the moment of the last crash
local lastVelocity = {}--Velocity at last frame

local placement = {}
local score     = {}  --the point score a vehicle/player has accumulated
local baseValue = 1 --the Base worth of a vehicle

local tracked = {}     --Whether a crash is currently tracked
local crashCD          = {}
local crashCDLength    = 2
local crashTrackLength = 0.4
local crashPairs       = {}
local crashInitiator   = {}
local crashKind        = {}
local crashOwner       = {}

local gotPushed          = {}
local pushTimeout        = {}
local lastCollision      = {}
local lastCollisionTimer = {}
--local gear = {}
local broken = {}

--multiplier values for crashkind
local angleMultiplier = {f = 1, b = 1.5, d = 2}

local messageText        = {}
local messageTimer       = {}
local messageLength      = 2
local popUpMessages      = {}
local popUpMessageLength = 3
local vehColor = {}

--statistics
local frontalcrashes   = {}
local backwardscrashes = {}
local driftcrashes     = {}
local chaincrashes     = {}
local totalDmgVS = {} --totalDmgVS[v1][v2] tracks damage done by v1 to v2

--DEBUG
local AIactive = true
local debug = false

--DEFAULTS used if no specifics given in scenario json customData
local defaultMaxStopTicks = 10
local defaultAIactive = true
local defaultDebug = false
--TODO: Add more default colors if demo derby should support more than 4 cars
local defaultColors  = {
    {0.5, 0.5,   1}, --blue
    {  0,   1,   0}, --green
    {  1, 0.6,   0}, --orange
    {  1,   1,   1}  --white
}

local function reset()
    scenarioVehicles = {}
    playersStopped = {}
    activePlayers = 0
    lastPosition = {}
    vehiclesStopTicks = {}
    popUpMessages = {}
end

local function onScenarioChange()
    local scenario = scenario_scenarios.getScenario()
    if not scenario then reset() return end

    if scenario.state == 'running' and scenario.vehicles then
        reset()

        --Load Variables defined in JSON if available

            if scenario.customData.AIactive ~= nil then
                AIactive = scenario.customData.AIactive
            else
                AIactive = defaultAIactive
            end
            if scenario.customData.maxStopTicks ~= nil then
                maxStopTicks = scenario.customData.maxStopTicks
            else
                maxStopTicks = defaultMaxStopTicks
            end
            if scenario.customData.debug ~= nil then
                debug = scenario.customData.debug
            else
                debug = defaultDebug
            end

        playerV = be:getPlayerVehicle(0)
        pName   = playerV:getName()

        log('I', logTag, pName .. " is a player")
        local i = 1
        for vName,_ in pairs(scenario.vehicles) do

            local vObj = scenetree.findObject(vName)

            if vObj then
                --Initialise values for vehicle
                messageText[vName]        = ""
                scenarioVehicles[vName]   = vObj
                vehicleData[vName]        = map.objects[map.objectNames[vName]]
                activePlayers             = activePlayers + 1
                lastPosition[vName]       = vehicleData[vName].pos
                lastVelocity[vName]       = vehicleData[vName].vel
                vehiclesStopTicks[vName]  = 0
                pushTimeout[vName]        = 0
                lastCollisionTimer[vName] = 0
                placement[vName]          = 0
                score[vName]              = 0
                broken[vName]             = false
                frontalcrashes[vName]     = 0
                backwardscrashes[vName]   = 0
                driftcrashes[vName]       = 0
                chaincrashes[vName]       = 0
                totalDmgVS[vName]         = {}

                --Sets custom color if defined in scenario json, otherwise picks a default color
                if scenario.customData.colors[vName] ~= nil then
                    local c = scenario.customData.colors[vName]
                    vehColor[vName] = { c.r, c.g, c.b }
                else
                    log("W", logTag, "No color found for "..vName..". Assigning default color")
                    vehColor[vName] = defaultColors[i]
                end

                i = i+1

                scenario_scenarios.trackVehicleMovementAfterDamage(vName)

                --Give every vehicle pair an id, initialise individual damage tracking
                for vName2,_ in pairs(scenario.vehicles) do
                    if vName ~= vName2 then
                        totalDmgVS[vName][vName2] = 0
                        if tracked[vName..vName2] == nil and tracked[vName2..vName] == nil then
                            tracked[vName..vName2] = false
                            crashCD[vName..vName2] = 0
                        end
                    end
                end

                if playerV and vName ~= pName then
                    aiVehicles[vName] = vObj
                    if AIactive then helper.setAiMode(vName,"chase", pName) end
                    log('I', logTag,vName .. " is AI")
                end
            end
        end
    end
end

local function dumpStats(name)
    log('I', logTag, " ")
    log('I', logTag, name.." Stats:")
    log('I', logTag, "Frontalcrashes: "..frontalcrashes[name])
    log('I', logTag, "Reversecrashes: "..backwardscrashes[name])
    log('I', logTag, "Driftcrashes:   "..driftcrashes[name])
    log('I', logTag, "Chaincrashes:   "..chaincrashes[name])
    log('I', logTag, " ")
    log('I', logTag, "Total damage against: ")

    local tDMG = 0
    for vName, dmg in pairs(totalDmgVS[name]) do
        tDMG = tDMG + dmg
        log('I', logTag, vName..": "..dmg)
    end

    log('I', logTag, " ")
    log('I', logTag, "Total: "..tDMG)
    log('I', logTag, " ")
end


--AI Code
--chooses the closest other moving vehicle as the vehs target
local function findClosestMoving(name)
    if name then
        local minDist
        local target

        for i=1, #playersMoving do
            local vName = playersMoving[i]
            if vName ~= name then
                local distance = (vehicleData[vName].pos - vehicleData[name].pos):length()

                if not minDist or minDist > distance then
                    minDist = distance
                    target  = scenarioVehicles[vName]
                end
            end
        end
        return target
    end
end

local function findFurthestMoving(name)
    if name then
        local maxDist
        local target

        for i=1, #playersMoving do
            local vName = playersMoving[i]
            if vName ~= name then
                local distance = (vehicleData[vName].pos - vehicleData[name].pos):length()

                if not maxDist or maxDist < distance then
                    maxDist = distance
                    target = scenarioVehicles[vName]
                end
            end
        end
        return target
    end
end

local function vehStopped(name)
    local stopped = false
    for i = 1, #playersStopped do
        if playersStopped[i] == name then
            stopped = true
            break
        end
    end
    return stopped
end

local function targetMoving(name)
    local moving = false

    if not targets[name] then return false end

    for i = 1, #playersMoving do
        if playersMoving[i] == targets[name]:getName() then
            moving = true
            break
        end
    end

    return moving
end

local function changeAI(name)
    if (not retargetCD[name] or retargetCD[name] <= 0) then
        if not targetMoving(name) then
            local newTarget

            if math.random() < 0.5 then
                --log('I', logTag, "Changed "..name.." behaviour to closest.")
                newTarget = findClosestMoving(name)
            else
                --log('I', logTag, "Changed "..name.." behaviour to furthest.")
                newTarget = findFurthestMoving(name)
            end

            if newTarget then
                targets[name] = newTarget
                --log('I', logTag, "Set " .. name .. " target to " .. newTarget:getName())
                helper.setAiMode(name,"chase", newTarget:getName())
            end
            --log('I',logTag,"Cooldown reset to full length")
            retargetCD[name] = retargetCDLength
        end
    end
end


--UI CODE
local function setCrashMsg(crashID, name, sc, customCrash)
    local msg = ""

    local kind = crashKind[crashID][name]

    if sc > 2500 then
        msg = "Amazing "
    elseif sc > 1800 then
        msg = "Awesome "
    elseif sc > 1000 then
        msg = "Nice "
    elseif sc < 100 then
        msg = "Boring "
    end

    if not customCrash then
        if kind == 'f' then
            msg = msg.."Frontal Crash!"
        elseif kind == 'd' then
            msg = msg.."Drift Crash!!!"
        elseif kind == 'b' then
            msg = msg.."Reverse Crash!!"
        end
    else
        msg = msg..customCrash
    end

    messageTimer[pName] = messageLength
    helper.realTimeUiDisplay(msg)
end

--returns string of given integer with english counting suffix (i.e. 1st, 2nd, 3rd, 11th, 1000th,...)
local function getPlacementString(n)
    local m10 = n % 10

    if  m10==0 or (4<=m10 and m10<=9) or (11<=n and n<=13) then
        return n.."th"
    elseif m10 == 1 then
        return n.."st"
    elseif m10 == 2 then
        return n.."nd"
    else
        return n.."rd"
    end
end

local function getNameByPlacement(p)
    for name, place in pairs(placement) do
        if place == p then return name end
    end

    return nil
end

local function setCountdownMsg(time)
    local msg

    if not vehStopped(pName) then
        msg = "Move! You're out in "..time
        if time ~= 1 then
            msg = msg.." seconds."
        else
            msg = msg.." second."
        end

        messageTimer[pName] = 1
    else
        msg = "You're out! You came in "..getPlacementString(placement[pName]).." place!"
        messageTimer[pName] = 5
    end

    helper.realTimeUiDisplay(msg)
end

--[[local function clearMsg()
    messageTimer[pName] = 0
end]]

local function createPopup(msg, veh, color, time)
    --[ [1]Timer, [2]ogTime, [3]message, [4]vehicle, [5]color]
    local popup = {time, time, msg, veh, color}
    table.insert( popUpMessages, popup )
end

--This is unreadable
--[ [1]Timer, [2]ogTime, [3]message, [4]vehicle, [5]color]
local function drawPopups(dt)
    local i = 1
    local j = #popUpMessages
    while i <= j do
        local color = popUpMessages[i][5]

        --Makes popup fade out
        local alpha
        if popUpMessages[i][1] > popUpMessages[i][2]/2 then
            alpha = 1
        else
            alpha = (popUpMessages[i][1]*2/popUpMessages[i][2])
        end

        --Makes popup rise
        local hOffset = (popUpMessages[i][2]-popUpMessages[i][1]/popUpMessages[i][2])/1.7

        debugDrawer:drawTextAdvanced((vehicleData[popUpMessages[i][4]].pos+vec3(0,0,0.3+hOffset)):toPoint3F(), String(popUpMessages[i][3]), ColorF(color[1],color[2],color[3],alpha),true, false, ColorI(0, 0, 0, alpha*200))
        popUpMessages[i][1] = popUpMessages[i][1] - dt

        if popUpMessages[i][1] <= 0 then
            table.remove( popUpMessages, i )
            j = j-1
        else
            i = i+1
        end
    end
end

--return two vec3 (start and end) and two numbers (height, width)
--[[local function getBB(veh) --TODO: Currently unused, delete at some point if not neccessary
    local bbStart = (vec3(veh:getSpawnWorldOOBB():getPoint(0))+vec3(veh:getSpawnWorldOOBB():getPoint(1))+vec3(veh:getSpawnWorldOOBB():getPoint(2))+vec3(veh:getSpawnWorldOOBB():getPoint(3)))/4
    local bbEnd   = (vec3(veh:getSpawnWorldOOBB():getPoint(4))+vec3(veh:getSpawnWorldOOBB():getPoint(5))+vec3(veh:getSpawnWorldOOBB():getPoint(6))+vec3(veh:getSpawnWorldOOBB():getPoint(7)))/4
    local height  = (vec3(veh:getSpawnWorldOOBB():getPoint(1))-vec3(veh:getSpawnWorldOOBB():getPoint(0))):length()
    local width   = (vec3(veh:getSpawnWorldOOBB():getPoint(3))-vec3(veh:getSpawnWorldOOBB():getPoint(0))):length()

    return bbStart, bbEnd, height, width
end]]

local function debugger()
    for vName,_ in pairs(scenarioVehicles) do
        --local bbStart,bbEnd,extZ,extX = getBB(vObj)
        if vName ~= playerV:getName() then
            debugDrawer:drawLine((vehicleData[pName].pos+vec3(0,0,1.2)):toPoint3F(),(vehicleData[pName].pos+(vehicleData[vName].pos-vehicleData[pName].pos):normalized()+vec3(0,0,1.2)):toPoint3F(), ColorF(1,0,0,1))
        end

        debugDrawer:drawLine((vehicleData[vName].pos+vec3(0,0,1.2)):toPoint3F(),(vehicleData[vName].pos+vehicleData[vName].vel+vec3(0,0,1.2)):toPoint3F(), ColorF(0,0,1,1))
        debugDrawer:drawLine((vehicleData[vName].pos+vec3(0,0,1.2)):toPoint3F(),(vehicleData[vName].dirVec+vehicleData[vName].pos+vec3(0,0,1.2)):toPoint3F(), ColorF(0,0,1,1))

        --BoundingBox drawn in the smartest way ever probably
        --debugDrawer:drawSquarePrism(bbStart:toPoint3F(),bbEnd:toPoint3F(),Point2F(extZ,extX),Point2F(extZ,extX),ColorF(0,1,0,0.15))
    end
end


--GAMEPLAY CODE

--crashtype returns descriptive char
local function crashType(nameA, nameB)
    local dPos  = (vehicleData[nameB].pos-vehicleData[nameA].pos):normalized()
    local angle = vehicleData[nameA].dirVec:dot(dPos)

    --Ranges [0,1] The higher this number, the likelier a Driftcrash
    local step = 0.72

    if debug then log('I', logTag, "Angle = "..angle) end

    if step <= angle then
        --log('I', logTag, nameA..": Frontalcrash!")
        return 'f'
    elseif -step >= angle then
        --log('I', logTag, nameA..": Backwardscrash!")
        return 'b'
    else
        --log('I', logTag, nameA..": Driftcrash!")
        return 'd'
    end
end

--TODO: erase this function change gotPushed[name] = nil -> gotPushed[name] = name (also rename gotPushed to pusher or something)
local function getPusher(name)
    local pusher = name

    if gotPushed[name] ~= nil then
        pusher = gotPushed[name]
    end

    return pusher
end

local function crashedInto(nameA,nameB)
    local vel = vehicleData[nameA].vel

    if vel:length() < 3 then
        --log('I',logTag,nameA.." Vel too low - no crash")
        return false
    end

    --Minimum allowed angle between Velocity and deltaPos of Objectts for crash to be legal, Gets smaller if the car is drifting
    local cutoff   = 0.25+0.25*math.abs(vehicleData[nameA].vel:normalized():dot(vehicleData[nameA].dirVec))
    local posDelta = (vehicleData[nameB].pos - vehicleData[nameA].pos):normalized()

    --divide Dot product by Maximum Dot product to get the normalized dot product [-1,1]
    local cos = posDelta:dot(vel:normalized())

    if debug then
      local roundFactor = 100000
        if cos > cutoff then
            log('I',logTag,nameA.." successfully crashed into "..nameB.." | Cos: "..(round(cos*roundFactor)/roundFactor).."  Vel: "..(round(vel:length()*roundFactor)/roundFactor).."  Cut: "..round(cutoff*roundFactor)/roundFactor)
        else
            log('I',logTag,nameA.." didn't crash into "..nameB.." | Cos: "..(round(cos*roundFactor)/roundFactor).."  Vel: "..(round(vel:length()*roundFactor)/roundFactor).."  Cut: "..round(cutoff*roundFactor)/roundFactor)
        end
    end

    return cos > cutoff
end

local function trackCrash(nameA, nameB)
    local names = {nameA, nameB}
    local id

    if crashCD[names[1]..names[2]] then id = names[1]..names[2] else id = names[2]..names[1] end

    local dDmg = {}     --Delta Damage
    --local dDir = {}     --Delta Direction
    local dVel = {}     --Delta Velocity
    --local dPos = {}     --Delta Position
    local initVelL = {} --Initial Velocity (length)

    --Get all the Values for both cars
    for i=1,2,1 do
        dDmg[i] = vehicleData[names[i]].damage - vehPreCrash[id][names[i]].damage
        --dDir[i] = vehicleData[names[i]].dirVec - vehPreCrash[id][names[i]].dirVec
        dVel[i] = vehicleData[names[i]].vel    - vehPreCrash[id][names[i]].vel
        --dPos[i] = vehicleData[names[i]].pos    - vehPreCrash[id][names[i]].pos
        initVelL[i] = vehPreCrash[id][names[i]].vel:length()
    end

    for i=1,2,1 do
        local j = i%2+1

        if crashOwner[id][names[i]] ~= names[j] then
            totalDmgVS[crashOwner[id][names[i]]][names[j]] = totalDmgVS[crashOwner[id][names[i]]][names[j]] + dDmg[j]
        end

        if crashInitiator[id][names[i]] then
        --if crashInitiator[id][names[i]] and not vehStopped(names[j]) then
            local sc --Score

            local jValue = baseValue - baseValue*vehiclesStopTicks[names[j]]/maxStopTicks --Value of other car determined by its time idling

            --return value between 0 and 2
            local initVelMP = (initVelL[i] - initVelL[j]) / math.max(initVelL[i],initVelL[j]) + 1
            local angleMP = angleMultiplier[crashKind[id][names[i]]]
            local dmgMP = 1
            if math.max(dDmg[i],dDmg[j]) > 0 then
                dmgMP = (dDmg[j] - dDmg[i]) / math.max(dDmg[i],dDmg[j]) + 1
            end


            --sc = jValue
            local score1 = round(((angleMP * dmgMP * initVelMP * dDmg[j] * jValue)/dVel[i]:length()))

            local highDmgMP = 1
            if dDmg[j] > 10000 then
                highDmgMP = 3
            elseif dDmg[j] > 5000 then
                highDmgMP = 1.5
            elseif dDmg[j] < 1000 then
                highDmgMP = 0.5
            end

            local dmgBlock = dmgMP * dDmg[j] / 1000
            local velBlock = initVelMP*initVelL[i]

            local score2 = round((angleMP * dmgMP * initVelMP * highDmgMP * jValue)/dVel[i]:length())
            local score3 = round((angleMP * dmgMP * initVelMP * highDmgMP * jValue))
            local score4 = round((dmgBlock + velBlock)*jValue)

            if names[i] == pName or names[j] == pName then
                log('I', logTag, names[i].." scores:")
                dump(score1)
                dump(score2)
                dump(score3)
                dump(score4)
            end

            sc = score1
            sc = round(sc)

            if sc > 150 then
                log('I', names[i].."->"..names[j]," jValue:"..jValue.." AngleMP:"..angleMultiplier[crashKind[id][names[i]]].." DmgMP:"..dmgMP.." IVelMP:"..initVelMP.." dDMGj:"..dDmg[j].." dVel:"..dVel[i]:length())
                log('I', names[i].."->"..names[j], "Score:  "..sc)

                if names[i] == pName then
                    setCrashMsg(id, names[i], sc)
                elseif crashOwner[id][names[i]] == pName then
                    setCrashMsg(id, names[i], sc, "Chain Crash!")
                end

                createPopup("+"..sc,crashOwner[id][names[i]],vehColor[names[j]],popUpMessageLength)

                --The crashowner gets the Points
                if crashOwner[id][names[i]] ~= names[i] then
                    --log('I', logTag, crashOwner[id][names[i]].." got Pushapoints!! "..sc)
                    chaincrashes[crashOwner[id][names[i]]] = chaincrashes[crashOwner[id][names[i]]] + 1
                else
                    if crashKind[id][names[i]] == 'f' then
                        frontalcrashes[names[i]] = frontalcrashes[names[i]] + 1
                    elseif crashKind[id][names[i]] == 'b' then
                        backwardscrashes[names[i]] = backwardscrashes[names[i]] + 1
                    elseif crashKind[id][names[i]] == 'd' then
                        driftcrashes[names[i]] = driftcrashes[names[i]] + 1
                    end
                end

                if crashOwner[id][names[i]] == pName then
                    dumpStats(pName)
                end

                score[crashOwner[id][names[i]]] = score[crashOwner[id][names[i]]] + sc
            end
        end
        tracked[id] = false
    end
end

local function onObjectCollision(idA, idB)
    local id
    local pushTime = 0.2
    local names = {be:getObjectByID(idA):getName(), be:getObjectByID(idB):getName()}

    if (vehicleData[names[1]].vel - vehicleData[names[2]].vel):length() > 1 then

        --Find the proper order of names for crashCD
        if crashCD[names[1]..names[2]] then
            id = names[1]..names[2]
        else
            id = names[2]..names[1]
        end

        --If the crash between the objects isn't on cooldown
        if crashCD[id] <= 0 then
            crashCD[id]        = crashCDLength
            vehPreCrash[id]    = {}
            crashInitiator[id] = {}
            crashKind[id]      = {}
            crashOwner[id]     = {}
            crashPairs[id]     = names

            crashInitiator[id][names[1]] = crashedInto(names[1],names[2])
            crashInitiator[id][names[2]] = crashedInto(names[2],names[1])

            tracked[id] = true

            --Save Vehicle Telemetry at time of crash to get Deltas afterwards
            vehPreCrash[id][names[1]] = map.objects[map.objectNames[names[1]]]
            vehPreCrash[id][names[2]] = map.objects[map.objectNames[names[2]]]
            for i=1,2,1 do
                local j = i%2+1

                crashKind[id][names[i]]   = crashType(names[i],names[j])
                --crashOwner[id][names[i]]  = names[i]
                crashOwner[id][names[i]]  = getPusher(names[i])

                if crashInitiator[id][names[j]] then
                    lastCollision[names[i]] = names[j]
                    lastCollisionTimer[names[i]] = pushTime
                end
            end
        end
    end
end

--[[TODO: Delete this
local function setGearName(vID, g)
    gear[be:getObjectByID(vID):getName()] = g
end

local function requestGearName(name)
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setGearName(\'.. obj:getID() ..\',\'.. tostring(electrics.values.gear) ..\')\')')
    --helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setGearName(\'.. obj:getID() ..\',\'.. vec3toString(vec3(obj:calcCenterOfGravity(true))) ..\')\')')
end]]

--[[local function findCogNode(name, cog)
    local veh = scenarioVehicles[name]
    local closestNode
    local minDist

    for i = 0, veh:getNodeCount()-1, 1 do
        local dist = ((vehicleData[name].pos+vec3(veh:getNodePosition(i)))-cog):length()
        if not minDist or minDist > dist then
            minDist = dist
            closestNode = i
        end
    end

    cogNode[name] = closestNode

    log('I', logTag, name.." closest node set to: ".. closestNode)
end

local function setCog(vID, c)
    cog[be:getObjectByID(vID):getName()] = c
end

local function requestCog(name)
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setCog(\'.. obj:getID() ..\',\'.. vec3toString(vec3(obj:calcCenterOfGravity(true))) ..\')\')')
end]]


--If any checked part of the vehicle is damaged the broken tag gets set
local function setBroken(vID, value)
    if value == true then
        broken[be:getObjectByID(vID):getName()] = true
    end
end


local function requestBroken(name)
    --ENGINE
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setBroken(\'.. obj:getID() ..\',\'.. tostring(damageTracker.getDamage("engine", "blockMelted"))..\')\')')
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setBroken(\'.. obj:getID() ..\',\'.. tostring(damageTracker.getDamage("engine", "engineDisabled"))..\')\')')
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setBroken(\'.. obj:getID() ..\',\'.. tostring(damageTracker.getDamage("engine", "engineLockepUp"))..\')\')')
    --POWERTRAIN
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setBroken(\'.. obj:getID() ..\',\'.. tostring(damageTracker.getDamage("powertrain","wheelaxleFL" ))..\')\')')
    helper.queueLuaCommandByName(name, 'obj:queueGameEngineLua(\'scenario_demolitionDerby2.setBroken(\'.. obj:getID() ..\',\'.. tostring(damageTracker.getDamage("powertrain","wheelaxleFR" ))..\')\')')
end

-- Returns array of names ordered by their associated score
local function getScoreOrder()
    local scoreOrder = {}
    for name, scr in pairs(score) do
        for i=1, #scoreOrder+1, 1 do
            if not scoreOrder[i] or scr > score[scoreOrder[i]] then
                table.insert(scoreOrder,i,name)
                break
            end
        end
    end
    return scoreOrder
end

--[[Used for Scoreboard UI App
local function requestState()
    --log('I', logTag, "requestState() called!")
    local order = getScoreOrder()
    --local bsList = {}
    local tmp = {}

    --for i=1, #currentLine.tasklist, 1 do table.insert(bsList, currentLine.tasklist[i]) end
    tmp.tasklist = order
    guihooks.trigger('ddScoreUpdate', tmp)
end]]

local minC = 1
local maxDV = 0
-- called before rendering a graphics frame
local function onPreRender(dt)

--This happens every graphics frame
    local scenario = scenario_scenarios.getScenario()

    if not scenario or scenario.state ~= 'running' then return end

    --[[for vName, vData in pairs(scenario.vehicles) do
        if not cog[vName] then
            requestCog(vName)
        end
    end]]

    for vName,_ in pairs(scenario.vehicles) do

        --[[if not cogNode[vName] then
            if cog[vName] then
                findCogNode(vName, cog[vName])
            else
                return
            end
        end]]


        vehicleData[vName] = map.objects[map.objectNames[vName]]

        --detect whether the car was significantly pushed in the last time
        if lastCollision[vName] then
            if lastCollisionTimer[vName] > 0 then
                -- dV > 0 if Vehicle got faster
                local dV    = (vehicleData[vName].vel:length() - lastVelocity[vName]:length())
                local dVCos = (lastVelocity[vName]:normalized():dot(vehicleData[vName].vel:normalized()))
                if lastVelocity[vName]:length() < 1 then
                    dVCos = 1
                end

                --TODO: Tweak those numbers
                local dVMax    = 1.5 -- The larger this number, the larger the neeeded accleration to trigger pushed status
                local dVCosMin = 0.7 --The smaller this number, the larger the needed angle to trigger pushed status [-1,1]
                if dV > dVMax or dVCos < dVCosMin then
                    if dV > dVMax then       log('I', logTag, vName.." - dV:    "..dV) end
                    if dVCos < dVCosMin then log('I', logTag, vName.." - dVCos: "..dVCos) end

                    local pusher = lastCollision[vName]
                    if gotPushed[pusher] then pusher = gotPushed[pusher] end

                    if not gotPushed[vName] or gotPushed[vName] ~= pusher then
                        gotPushed[vName]  = pusher
                        pushTimeout[vName] = 2
                        log('I', logTag, gotPushed[vName] .. " pushed " .. vName)
                    end
                end
            else
                --log('I', logTag, vName.." pusher reset")
                lastCollision[vName]      = nil
                lastCollisionTimer[vName] = 0
            end
        end

        --If the vehicle was pushed check whether it moved on its own again or if the push timed out, if so change gotPushed
        if lastCollisionTimer[vName] <= 0 and gotPushed[vName] then
            local moved = false

            local dV    = (vehicleData[vName].vel:length() - lastVelocity[vName]:length())
            --local dVCos = (lastVelocity[vName]:normalized():dot(vehicleData[vName].vel:normalized()))
            --if lastVelocity[vName]:length() < 1 then
            --    dVCos = 1
            --end

            --TODO: Tweak those numbers
            local dVMax    = 0.6
            if dV > dVMax then moved = true end--or dVCos < dVCosMin then

            if pushTimeout[vName] < 0 or moved then
                pushTimeout[vName] = 0
                gotPushed[vName] = nil
            end

            pushTimeout[vName] = pushTimeout[vName] - dt
        end
    end

--Adjust timers and cooldowns
    tickCounter = tickCounter + dt

    for vName,_ in pairs(retargetCD) do
        --time = time - dt somehow doesn't stick, dunno why
        retargetCD[vName] = retargetCD[vName] - dt
    end

    for vName,_ in pairs(lastCollisionTimer) do
        --time = time - dt somehow doesn't stick, dunno why
        if lastCollisionTimer[vName] > 0 then
            lastCollisionTimer[vName] = lastCollisionTimer[vName] - dt
        end
    end

    for id, time in pairs(crashCD) do
        if time > 0 then
            if time <= crashCDLength - crashTrackLength and tracked[id]  then
                trackCrash(crashPairs[id][1], crashPairs[id][2])
            end
            crashCD[id] = time - dt
        end

        if time < 0 then
            crashCD[id] = 0
        end
    end

    for name,_ in pairs(messageTimer) do
        if messageTimer[name] > 0 then
            messageTimer[name] = messageTimer[name] - dt
        else
            messageText[name] = ""
            helper.realTimeUiDisplay(messageText[name])
        end
    end

    drawPopups(dt)

    if debug then debugger() end

    if debug then
        if vehicleData[pName].vel:length() > 3 then
            --log('I', logTag, (lastVelocity[pName]:normalized():dot(vehicleData[pName].vel:normalized())))
            if (lastVelocity[pName]:normalized():dot(vehicleData[pName].vel:normalized())) < minC then
                minC = (lastVelocity[pName]:normalized():dot(vehicleData[pName].vel:normalized()))
            end

            if (vehicleData[pName].vel:length() - lastVelocity[pName]:length()) > maxDV then
                maxDV = (vehicleData[pName].vel:length() - lastVelocity[pName]:length())
            end

        elseif minC ~= 1 then
            log('I', logTag, "----MIN Cos---- = "..minC)
            log('I', logTag, "----MAX DV----- = "..maxDV)
            minC = 1
            maxDV= 0
        end
    end

    for vName,_ in pairs(scenario.vehicles) do
        lastVelocity[vName] = vehicleData[vName].vel
    end

    if tickCounter < 1 then return end

--This happens every second
    tickCounter    = 0
    playersMoving  = {}
    --playersStopped = {}

    --determine which vehicles are moving and which are stopped
    for vName, data in pairs(vehicleData) do
        if not vehStopped(vName) then
            requestBroken(vName)
            if not lastPosition[vName] then lastPosition[vName] = data.pos end

            local distance = (data.pos - lastPosition[vName]):length()
            if distance > 1 and getPusher(vName) == vName and not broken[vName] then
                lastPosition[vName] = data.pos
                vehiclesStopTicks[vName] = 0
                table.insert( playersMoving, vName )
            else
                if vehiclesStopTicks[vName] < maxStopTicks then
                    vehiclesStopTicks[vName] = vehiclesStopTicks[vName] + 1
                else
                    table.insert( playersStopped, vName )
                    placement[vName] = activePlayers - #playersStopped + 1
                    --TODO Add message that a tribute has been eliminated
                    --Disabling the engine would be more elegant but this does the job for now
                    helper.queueLuaCommandByName(vName, 'beamstate.breakBreakGroup("wheel_FL")')
                    helper.queueLuaCommandByName(vName, 'beamstate.breakBreakGroup("wheel_FR")')
                    --Subtle visual cue
                    helper.queueLuaCommandByName(vName, 'fire.explodeVehicle()')
                end
                local outTime = maxStopTicks-vehiclesStopTicks[vName]+1
                if vName == pName and outTime <= 5 then
                    setCountdownMsg(outTime)
                end
            end
        end
    end

    --Adjust AI behaviour to moving/stopped vehicles
    if AIactive then
        for vName,_ in pairs(aiVehicles) do
            changeAI(vName)
        end
    end

    local scoreBoard = {}
    local order = getScoreOrder()
    for i, name in ipairs (order) do
        local line = i..". "..name..":  "..score[name].." pts"
        table.insert(scoreBoard, {line})
    end
    guihooks.trigger('appJsonDump', scoreBoard)

    if #playersStopped >= activePlayers - 1 then
        local message = ""

        for vName,_ in pairs(scenario.vehicles) do
            if not vehStopped(vName) then placement[vName] = 1 end
        end
        for i=1, activePlayers do
            dump(getPlacementString(i))
            dump(getNameByPlacement(i))
            message = message..getPlacementString(i).." Place: "..getNameByPlacement(i).."<br>"
        end

        local result = {msg = message}

        scenario_scenarios.finish(result)
    end


    --[[if #playersStopped == activePlayers then
        local result = {msg = "NOBODY WINS!!"}
        --ALSO "NOBODY WINS!!"
        scenario_scenarios.finish(result)
    end]]
end

local function onRaceResult()
  if playerV then
    playerInstance = 'scenario_player0'

    local distData = {
      value = frontalcrashes[pName],
      points= frontalcrashes[pName],
      maxPoints= frontalcrashes[pName]
    }
    statistics_statistics.initialiseArbitraryStat("frontalcrashes", "Frontalcrashes", playerV, playerInstance, frontalcrashes[pName], frontalcrashes[pName])
    statistics_statistics.setStatProgress(playerV:getID(), "frontalcrashes", playerInstance, distData)

    distData = {
      value = backwardscrashes[pName],
      points= backwardscrashes[pName],
      maxPoints= backwardscrashes[pName]
    }
    statistics_statistics.initialiseArbitraryStat("backwardscrashes", "Reversecrashes", playerV, playerInstance, backwardscrashes[pName], backwardscrashes[pName])
    statistics_statistics.setStatProgress(playerV:getID(), "backwardscrashes", playerInstance, distData)

    distData = {
      value = driftcrashes[pName],
      points= driftcrashes[pName],
      maxPoints= driftcrashes[pName]
    }
    statistics_statistics.initialiseArbitraryStat("driftcrashes", "Driftcrashes", playerV, playerInstance, driftcrashes[pName], driftcrashes[pName])
    statistics_statistics.setStatProgress(playerV:getID(), "driftcrashes", playerInstance, distData)

    distData = {
      value = chaincrashes[pName],
      points= chaincrashes[pName],
      maxPoints= chaincrashes[pName]
    }
    statistics_statistics.initialiseArbitraryStat("chaincrashes", "Chaincrashes", playerV, playerInstance, chaincrashes[pName], chaincrashes[pName])
    statistics_statistics.setStatProgress(playerV:getID(), "chaincrashes", playerInstance, distData)
 end
end

M.onObjectCollision = onObjectCollision
M.onScenarioChange = onScenarioChange
M.onPreRender = onPreRender
M.onRaceResult = onRaceResult
--M.setCog = setCog
M.setBroken = setBroken
--M.requestState = requestState

return M
