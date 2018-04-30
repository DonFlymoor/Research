-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require('mathlib')

local M = {}

local function deleteVehicles()
    local objSize = be:getObjectCount()
    if objSize == 0 then return end
    for i = 0, objSize do
        local bo = be:getObject(0) -- always remove first vehicle
        if bo then
            bo:delete()
        end
    end
end

local function spawnVehicles(vehicles)
    for _,ve in pairs(vehicles) do
        spawnVehicle(ve[1], ve[2], ve[3].x, ve[3].y, ve[3].z)
    end
end

local function enterVehicleByNumber(n)
    local bo = be:getObject(n)
    if bo then
        local player = 0
        be:enterVehicle(player, vehicle)
        commands.setGameCamera()
    end
    return bo
end

-- executed on the first update where the engine is up and running
local wasInitialized = false
M.onPreRender = function(dt)
    if not wasInitialized then
        local aimap = map.getMap()
        if not aimap then return end

        map.debugMode = 'graph'

        deleteVehicles()
        local pos = aimap.nodes[tableChooseRandomKey(aimap.nodes)].pos
        spawnVehicles({{'super', 'vehicles/super/stripped_insane.pc', pos}})
        local bo = enterVehicleByNumber(0)
        if not bo then return end
        
        bo:queueLuaCommand('ai.setState({mode = "random", debugMode = "route"})')

        wasInitialized = true
    end
end

M.onLoad = function()
    log('D', 'simpleDrivearound.onLoad', "simpleDrivearound module loaded")
end

M.onUnload = function()
    log('D', 'simpleDrivearound.onUnload', "simpleDrivearound module unloaded")
end

return M