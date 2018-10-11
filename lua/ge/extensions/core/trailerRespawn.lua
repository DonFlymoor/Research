-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local disabled = false
local trailerReg = {}
local couplerOffset = {}

local function onSerialize()
    local data = {}
    data.trailerReg = trailerReg
    data.couplerOffset = couplerOffset
    data.disabled = disabled
    return data
end

local function onDeserialized(data)
    trailerReg = data.trailerReg
    couplerOffset = data.couplerOffset
    disabled = data.disabled
    M.onWorldReadyState()
end

local function resetData()
    trailerReg = {}
    couplerOffset = {}
    disabled = false
    M.onWorldReadyState()
end

--return true if create a loop
local function checkRedondancy(trailerId, forbiddenId)
    if trailerReg[trailerId] and trailerReg[trailerId]~= -1 then
        if trailerReg[trailerId].trailerId == forbiddenId then
            return true
        else
            return checkRedondancy(trailerReg[trailerId].trailerId, forbiddenId)
        end
    end
    return false
end

local function onCouplerAttached(objId1, objId2, nodeId, obj2nodeId)
    if objId1 == objId2 then --[[log("E","trailerRespawn.register", "same vehicle ID");]] return end
    if couplerOffset[objId1] == nil or couplerOffset[objId1][nodeId] == nil or couplerOffset[objId2] == nil or couplerOffset[objId2][obj2nodeId] == nil then
        -- log("I","trailerRespawn.register", "Coupler Id not found, probably nodegrabber")
        --log("I","trailerRespawn.register", dumps(couplerOffset[objId1]) .. " | ".. dumps(couplerOffset[objId1][nodeId]) .. " | ".. dumps(couplerOffset[objId2]) .. " | ".. dumps(couplerOffset[objId2][obj2nodeId] ) )
        return
    end

    local trailer = be:getObjectByID(objId2)
    local trailerModel = core_vehicles.getModel(trailer:getField('JBeam','0')).model

    if trailerModel.Type == "Trailer" then
        if be:getPlayerVehicle(0):getId() == objId1 then
            log("D","trailerRespawn.register", tostring(objId1).." owns trailer "..tostring(objId2).."   node="..tostring(nodeId).."  trailernode="..tostring(obj2nodeId))
            if checkRedondancy(objId2, objId1) then 
                log("E","trailerRespawn.register", "tried to register a loop")
                return
            end
            trailerReg[objId1] = {trailerId=objId2, trailerNode=obj2nodeId, node=nodeId}
        else
            log("D","trailerRespawn.register INV", tostring(objId2).." owns trailer "..tostring(objId1).."   node="..tostring(obj2nodeId).."  trailernode="..tostring(nodeId))
            if checkRedondancy(objId1,objId2) then 
                log("E","trailerRespawn.register", "tried to register a loop")
                return
            end
            trailerReg[objId2] = {trailerId=objId1, trailerNode=nodeId, node=obj2nodeId}
        end
    end
end

local function onCouplerDetach(objId1, nodeId)
    log("D","trailerRespawn.onCouplerDetach", tostring(objId1).." onCouplerDetached "..tostring(nodeId))

    if trailerReg[objId1] and trailerReg[objId1] ~= -1 then
        log("D","trailerRespawn.onCouplerDetach", "unreg1 "..tostring(objId1))
        trailerReg[objId1] = -1
        return
    end

    for vId,tId in pairs(trailerReg) do
        if tId.trailerId == objId1 then
            log("D","trailerRespawn.onCouplerDetach", "unreg2 "..tostring(objId1))
            trailerReg[vId] = -1
            return
        end
    end
end

local function onVehicleSpawned(vehid)
    --log("I","trailerRespawn.onVehicleSpawned", tostring(vehid))
    local veh = be:getObjectByID(vehid)
    veh:queueLuaCommand('beamstate.getCouplerOffset()')
end

local function onVehicleResetted(vehId)
    -- log("D","trailerRespawn.onVehicleResetted", tostring(vehId).."   "..dumps(trailerReg[vehId]) )
    if trailerReg[vehId] and trailerReg[vehId] ~= -1 then
        -- log("I","trailerRespawn.onVehicleResetted", "veh COUPLER "..tostring(trailerReg[vehId].node).."   "..tostring(couplerOffset[vehId][trailerReg[vehId].node]) )
        local tmp = couplerOffset[trailerReg[vehId].trailerId][trailerReg[vehId].trailerNode]
        --if tmp.y > 0 then tmp.y = -tmp.y end
        -- log("I","trailerRespawn.onVehicleResetted", "trailer coupler "..tostring(trailerReg[vehId].trailerId).."   "..tostring(tmp) )
        spawn.placeTrailer(vehId, couplerOffset[vehId][trailerReg[vehId].node]:toPoint3F(), trailerReg[vehId].trailerId, tmp:toPoint3F())
    end
end

local function onVehicleDestroyed(vehId)
    -- log("I","trailerRespawn.onVehicleDestroyed", tostring(vehId))

    if couplerOffset[vehId] then
        couplerOffset[vehId] = nil
    end

    if trailerReg[vehId] then
        log("D","trailerRespawn.onVehicleDestroyed", "Unregister Vehicle "..tostring(vehId).." Trailer was"..tostring(trailerReg[vehId]))
        trailerReg[vehId] = nil
        return
    end

    for vId,tId in pairs(trailerReg) do
        if tId.trailerId == vehId then
            log("D","trailerRespawn.onVehicleDestroyed", "Unregister trailer "..tostring(vehId).." Vehicle was"..tostring(vId))
            trailerReg[vId] = -1
            return
        end
    end
end

local function addCouplerOffset(vId, data)
    --log("E","trailerRespawn.addCouplerOffset", "Vehicle "..tostring(vId).." couplers data"..dumps(data))
    for _,d in pairs(data) do
        data[_] = vec3(d)
    end
    --dump(data)
    couplerOffset[vId] = data
end

local function debugUpdate(dt, dtSim)
    if debugEnabled == false then return end

  -- highlight all coupling nodes

  for vID,c in pairs(couplerOffset) do
    local veh = be:getObjectByID(vID)
    if veh then
        local pos = vec3(veh:getPosition())
        for ci,cpos in pairs(c) do
            debugDrawer:drawSphere( (pos+cpos):toPoint3F(), 0.05, ColorF(1, 0, 0, 1)) 
            debugDrawer:drawTextAdvanced( (pos+cpos):toPoint3F(), String(tostring(vID.."@"..ci)), ColorF(0.2, 0, 0, 1), true, false, ColorI(255,255,255,255) )
            -- print(tostring(vID).." = "..tostring((pos+cpos)))
        end
    else
        --log("E","trailerRespawn.debugUpdate", "Vehicle "..tostring(vID).." invalid !!!!")
    end
  end
end

local function onWorldReadyState()
    disabled = (scenario_scenarios and scenario_scenarios.getScenario() and not scenario_scenarios.getScenario().useTrailerRespawn) ~= nil 
    -- log("I","trailerRespawn.onWorldReadyState", "disabled = "..tostring(disabled))
    if disabled then
        M.onCouplerAttached = nop
        M.onCouplerDetach = nop
        M.onVehicleResetted = nop
    else
        M.onCouplerAttached = onCouplerAttached
        M.onCouplerDetach = onCouplerDetach
        M.onVehicleResetted = onVehicleResetted
    end
end

M.onWorldReadyState = onWorldReadyState

M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.onCouplerAttached = onCouplerAttached
M.onCouplerDetach = onCouplerDetach
M.addCouplerOffset = addCouplerOffset

M.onVehicleSpawned = onVehicleSpawned
M.onVehicleResetted = onVehicleResetted
M.onVehicleDestroyed = onVehicleDestroyed

M.debugEnabled = false
-- M.onPreRender = debugUpdate
M.resetData = resetData

return M