-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = "util_thumbnailParts"
local camera = nil
local debugEnabled = false
local debug_data = {}
local veh_data = nil
local config = nil

local function LuaVec3Min(a,b)
    return vec3(math.min(a.x,b.x), math.min(a.y,b.y), math.min(a.z,b.z))
end

local function LuaVec3Max(a,b)
    return vec3(math.max(a.x,b.x), math.max(a.y,b.y), math.max(a.z,b.z))
end

local function yieldTime( sec , job)
    local start = os.clock()
    while os.clock() < (start+sec) do job.yield() end
end

local function init_camera()
    local game = commands.getGame()
	if not game then 
		log('E', logTag, "No game found")
		return 
	end

    camera = commands.getCamera(game)
	if not camera then 
		log('E', logTag, "No camera found")
		return 
	end
end

local function getView( partName, modelName )
    local dir = nil
    for nv,v in pairs(config.views) do
        for nk,k in ipairs(v.keywords) do
            if partName:find(k) then
                dir = v.cameraDirection
                break
            end
        end
    end
    if modelName and modelName~="" and config.models[modelName] then
        for nv,v in pairs(config.models[modelName]) do
            for nk,k in ipairs(v.keywords) do
                if partName:find(k) then
                    if v.cameraDirection then --if not overwritten by the current model then use generic one
                        dir = v.cameraDirection
                    else
                        dir = config.views[nv].cameraDirection
                    end
                    break
                end
            end
        end
    end
    if dir == nil then
        log("W", logTag, "part '"..partName.."' dosn't hit any filter!")
        dir = {0,0,-1} --top view by default
    end
    return vec3(dir)

end

local function test( part )
    -- body
    -- same thing for prop, just check if NOT "SPOTLIGHT" or "POINTLIGHT"
    -- vehicle->getTMesh()->getTSMeshByName(temp, isFlex);
    -- TSMesh::computeBounds()
    -- Box3F& getBounds()
    -- Point3F& getCenter()
    local veh = be:getPlayerVehicle(0)
    local t = veh:getBoundTSMesh(part, true)
    if t == nil or t.center == nil then
        log('E',"thumbnailParts.test", "invalid table : "..dumps(t))
        return
    end
    t.center = vec3(t.center)
    t.minExtents = vec3(t.minExtents)
    print( " minExtents = "..dumps(t.minExtents))
    t.maxExtents = vec3(t.maxExtents)
    print( " maxExtents = "..dumps(t.maxExtents))
    print( " offsetPos = "..dumps(vec3(t.offsetPos)))
    

    commands.setFreeCamera()

    -- Calculate rotation
    local topViewDirection = vec3(0,0,-1)
    local rot = quatFromDir(topViewDirection)
    local vehPos = vec3(veh:getPosition()) - vec3(t.offsetPos)
    print( "vehPos = "..dumps(vehPos))
    local refPos = vec3(veh:getNodePosition(veh:getRefNodeId()) )
    print( "ref = "..dumps(refPos))
    local pos = vehPos + t.center
    pos.z = pos.z + math.max(math.abs(t.minExtents.x), math.abs(t.minExtents.y), math.abs(t.maxExtents.x), math.abs(t.maxExtents.y) ) * 1 + t.maxExtents.z
	-- pos.z = 2.5
	-- Set position and rotation
	camera:setPosRot(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
    print("Starting position: ", camera:getPosition())
    
    --debug
    debugEnabled = true
    debug_data = {t.minExtents,t.maxExtents,pos,t.center, part, vec3(t.offsetPos)}
    print( " a = "..dumps(debug_data[1]))
    print( " b = "..dumps(debug_data[2]))

end

local function doPart( part ,dbg)
    if veh_data == nil then log("E", logTag, "veh_data is empty");return end
    if not veh_data[part] then log("E", logTag, "Part do not exists"); return end

    local veh = be:getPlayerVehicle(0)
    local minExtents = vec3(100,100,100)
    local maxExtents = vec3(-100,-100,-100)
    local center = vec3()
    local nbCenter = 0
    local offset = vec3()
    for _,pc in ipairs(veh_data[part]) do
        local t = veh:getBoundTSMesh(pc.mesh, true)
        if t.center == nil  then
            log('E',logTag..".test", "invalid table : "..dumps(t))
            goto continue
        end
        if pc.type == "flexbodies" then
            center = center+t.center
            nbCenter = nbCenter+1
        end
        if pc.pos then
            local tmppos = vec3(pc.pos)
            log('E',logTag..".test", "pc.pos : "..dumps(tmppos))
            if pc.type == "flexbodies" or #veh_data[part] ==1 then center = center+tmppos end
            maxExtents = LuaVec3Max(maxExtents, t.maxExtents+tmppos)
            minExtents = LuaVec3Min(minExtents, t.minExtents+tmppos)
        elseif vec3(t.transform.pos):length() > 0.01 then
            local tmppos = vec3(t.transform.pos)
            log('E',logTag..".test", "t.transform.pos : "..dumps(tmppos))
            if pc.type == "flexbodies" or #veh_data[part] ==1 then center = center+tmppos end
            maxExtents = LuaVec3Max(maxExtents, t.maxExtents+tmppos)
            minExtents = LuaVec3Min(minExtents, t.minExtents+tmppos)
        else
            maxExtents = LuaVec3Max(maxExtents, t.maxExtents)
            minExtents = LuaVec3Min(minExtents, t.minExtents)
        end
        offset = vec3(t.offsetPos)
        ::continue::
    end
    if nbCenter > 0 then center = center / nbCenter end
    center = (maxExtents+minExtents)*0.5
    local vehPos = vec3(veh:getPosition()) - vec3(offset)
    local pos = vehPos + center
    --pos.z = pos.z + math.max(math.abs(minExtents.x), math.abs(minExtents.y), math.abs(maxExtents.x), math.abs(maxExtents.y) ) * 1 + maxExtents.z
    local distance = math.max(math.abs(minExtents.x), math.abs(minExtents.y), math.abs(maxExtents.x), math.abs(maxExtents.y), math.abs(maxExtents.z), math.abs(maxExtents.z) ) * 1.25
    print("distance = "..tostring(distance))
    local dir = getView(part, veh:getJBeamFilename())
    pos = pos + distance * (-dir)
    local rot = quatFromDir(dir)
    -- dump(pos)
    --dump(rot)
    
    if dbg then
        debugEnabled = true
        debug_data = {minExtents,maxExtents,pos,center, part, offset}
    else
        camera:setPosRot(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
        debugEnabled = false
    end
    veh:queueLuaCommand( "partmgmt.selectPart( '"..part.."' , false)" )

    --return pos
    --dump(debug_data)
end

local function make( debug )
    local veh = be:getPlayerVehicle(0)
    if veh then veh:queueLuaCommand([[
local meshByParts = {}
local meshUsed = {}
if v.data.props then
    for _, o in ipairs (v.data.props) do
        if meshByParts[o.partOrigin] == nil then meshUsed[o.partOrigin]={}; meshByParts[o.partOrigin]={} end
        if o.mesh ~= "SPOTLIGHT" and o.mesh ~= "POINTLIGHT" and not tableContains(meshUsed[o.partOrigin], o.mesh) then table.insert(meshByParts[o.partOrigin], {mesh=o.mesh,type='props'}) end
    end
    for _, o in ipairs (v.data.flexbodies) do
        if meshByParts[o.partOrigin] == nil then meshUsed[o.partOrigin]={}; meshByParts[o.partOrigin]={} end
        if not tableContains(meshByParts[o.partOrigin], o.mesh) then table.insert(meshByParts[o.partOrigin], {mesh=o.mesh,type='flexbodies',pos=(o.pos or false)}) end
    end
end
--dump(meshByParts)
obj:queueGameEngineLua("util_thumbnailParts.output( "..serialize(meshByParts)..", ]]..tostring(debug)..[[ )")
    ]])
    end
end

local runJob = extensions.core_jobsystem.wrap(function(job)
    if veh_data == nil then log("E", logTag..'.job', "veh_data is empty");return end
    local veh = be:getPlayerVehicle(0)
    local model = veh:getJBeamFilename()
    yieldTime(5,job)
    veh:queueLuaCommand("partmgmt.selectReset()")
    commands.setFreeCamera()
    guihooks.trigger('hide_ui', true)
    for pName,_ in pairs(veh_data) do

        doPart(pName)

        yieldTime(0.5,job)

        TorqueScript.eval('screenShot("vehicles/' .. model .. '/'.. pName ..'", "PNG",0,0);')

        yieldTime(0.5,job)

    end
    veh:queueLuaCommand("partmgmt.selectReset()")
    guihooks.trigger('hide_ui', false)

end)

local function output( data , debug)
    dump(data)
    veh_data = data

    -- for pName,pMesh in pairs(veh_data) do
    --     getView(pName,"pickup")
    -- end
    if debug then return end
    runJob()
end

local function onExtensionLoaded()
    init_camera()
    config = readJsonFile("settings/thumbnailParts_config.json")
end

local function onPreRender(dt)
    if not debugEnabled then return end

    local veh = be:getPlayerVehicle(0)
    local vehPos = vec3(veh:getPosition()) -debug_data[6]
    debugDrawer:drawBox( (vehPos+debug_data[1]):toPoint3F(), (vehPos+debug_data[2]):toPoint3F(), ColorF(0.9,0.1,0.1,0.5) )
    debugDrawer:drawSphere((vehPos+debug_data[1]):toPoint3F(), 0.05, ColorF(0.6,0,0.0,1) )
    debugDrawer:drawSphere((vehPos+debug_data[2]):toPoint3F(), 0.05, ColorF(0.6,0,0.0,1) )
    -- debugDrawer:drawSphere(debug_data[3]:toPoint3F(), 0.05, ColorF(0,0,0.9,0.6) )
    --debugDrawer:drawText(debug_data[4]:toPoint3F(), String("hood"), ColorF(0,0.9,0,0.5))
    debugDrawer:drawTextAdvanced((vehPos+debug_data[4]):toPoint3F(), String(debug_data[5]), ColorF(0,0.9,0,1), true, false, ColorI(255,255,255,200))
    debugDrawer:drawTextAdvanced(debug_data[3]:toPoint3F(), String("camera"), ColorF(0,0,0.9,1), true, false, ColorI(255,255,255,200))
    --debugDrawer:setLastTTL(0)
    
end


M.onExtensionLoaded = onExtensionLoaded
M.test = test
M.make = make
M.doPart = doPart
M.output = output
M.onPreRender = onPreRender
M.getView = getView
M.runJob = runJob

return M