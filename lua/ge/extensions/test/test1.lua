-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require('mathlib')

local M = {}
local logTag = 'ci-test1' -- please change to sth more meaningful

--local maxRunMinutes = nil -- run forever
local maxRunMinutes = 3600 -- run for an hour

local levelFolder = 'levels/'
local levelWhiteList = {
    --hirochi_raceway = 1,
    east_coast_usa = 1,
    small_island = 1,
    --jungle_rock_island = 1,
    --Utah = 1,
}
local levelChangeTime = 10 * 60 -- exchange every 10 minutes
local levelChangeTimer = 0

local currentLevel = nil
local terrainPosition = nil

local vehicleFolder = 'vehicles/'
local vehicleWhiteList = {
    pickup = 1,
    pigeon = 1,
    semi = 1,
    super = 1,
    sunburst = 1,
    van = 1,
    hatch = 1,
    fullsize = 1,
--    coupe = 1,
    moonhawk = 1,
}
local wasSet = {}

local viewTime = 10
local viewTimer = 0

local updateTime = 1
local updateTimer = 0

local exchangeTime = 120 -- exchange vehicles every 2 minutes
local exchangeTimer = 0 -- change after 5 seconds for the first time

local crashTimeout = 10
local time = 0
local vehicleCount = 3
local vehicles = {}
local lastPos = {}
local aimap = nil

local heatBitmap = nil

local function deleteVehicles()
    log('D', logTag, "deleteVehicles")

    local objSize = 1
    repeat
        objSize = be:getObjectCount()
        if objSize == 0 then break end
        local bo = be:getObject(0) -- always remove first vehicle
        if bo then
            bo:delete()
        end
    until objSize == 0
end

local function spawnVehicles(vehicles)
    log('D', logTag, "spawnVehicles")
    for _,ve in pairs(vehicles) do
        spawnVehicle(ve[1], ve[2], ve[3].x, ve[3].y, ve[3].z)
    end
end


local function getAvailableVehicles()
    log('D', logTag, "getAvailableVehicles")
    local dir = FS:openDirectory(vehicleFolder)
    local dirs = {}
    if dir then
        repeat
            entry = dir:getNextFilename()
            if not entry then break end
            if vehicleWhiteList[entry] and FS:directoryExists(vehicleFolder.."/"..entry) then
                table.insert(dirs, entry)
            end
        until not entry
        FS:closeDirectory(dir)
    end

    local vehicleConfigs = {}
    for _, vn in pairs(dirs) do
        vehicleConfigs[vn] = FS:findFilesByPattern('game:vehicles/'..vn, '*.pc', 0, true, false)
    end

    return vehicleConfigs
end

local function exchangeVehicles()
    log('D', logTag, "exchangeVehicles")
    deleteVehicles()

    vehicles = {}
    wasSet = {}

    --map.debugMode = 'graph'

    local vehiclesMap = getAvailableVehicles()

    for i = 1, vehicleCount do
        local pos = aimap.nodes[tableChooseRandomKey(aimap.nodes)].pos
        local vehicle = tableChooseRandomKey(vehiclesMap)
        local vehicleConfig = vehiclesMap[vehicle][tableChooseRandomKey(vehiclesMap[vehicle])]
        if not vehicleConfig then vehicleConfig = "" end

        --print("vehicle: " ..tostring(vehicle))
        --print("vehicleConfig: " ..tostring(vehicleConfig))
        --print("pos: " ..tostring(pos))
        local d = {vehicle, vehicleConfig, vec3(pos)}
        table.insert(vehicles, d)


    end

    spawnVehicles(vehicles)
    be:enterNextVehicle(0, 0)
    commands.setGameCamera()
end


local function exchangeLevel()
    local levelPathMap = {}

    for k,v in pairs(levelWhiteList) do
        local levelPath = levelFolder .. k .. '/' .. k .. '.mis'
        --log('I', logTag, levelPath)
        if FS:fileExists(levelPath) then
            table.insert(levelPathMap, levelPath)
        end
    end

    -- get random level
    local newLevel = levelPathMap[ tableChooseRandomKey(levelPathMap) ]
    TorqueScript.eval('schedule( 1000, 0, \"startLevel\", \"' .. newLevel .. '\" );') --TODO deprecated, should use the line below
    --beamng_cef.startLevel(newLevel) --TODO this should be used instead
end

--

-- executed when a level was loaded
M.onClientStartMission = function(mission)
    currentLevel = split(mission, '/')
    currentLevel = currentLevel[#currentLevel - 1]

    aimap = map.getMap()
    exchangeVehicles()
    initHeatMap()
end

-- executed when a level was unloaded
M.onClientEndMission = function(mission)
  destroyHeatMap()
  currentLevel = nil
end

-- executed on the first update where the engine is up and running
M.onFirstUpdate = function()
end

-- executed every frame, also when not rendering 3d in the menu
M.onPreRender = function(dt)
    time = time + dt

    aimap = map.getMap()
    if not aimap then return end

    if time - viewTimer > viewTime then
        viewTimer = time
        be:enterNextVehicle(0, 1)
        commands.setGameCamera()

        if heatBitmap then
          saveHeatMap()
        end
    end

    if time - updateTimer > updateTime then
        updateTimer = time

        local objSize = be:getObjectCount()
        for i = 0, objSize do
            local bo = be:getObject(i)
            if bo then
                if not wasSet[i] then
                    bo:queueLuaCommand('ai.setState({mode = "random", debugMode = "off"})')
                    wasSet[i] = true
                end

                local pos = bo:getPosition()

                if not lastPos[i] or (lastPos[i][1] - pos):len() > 1 then
                    lastPos[i] = {pos, time}
                end

                if lastPos[i] and time - lastPos[i][2] > crashTimeout then
                    if heatBitmap then
                      heatBitmap:drawIcon(pos - terrainPosition, 'x', ColorI(255, 0, 0, 255))
                    end
                    ui_message("vehicle " .. (i + 1) .. " (" .. vehicles[i + 1][1] .. ") got stuck: reset")
                    bo:queueLuaCommand('obj:requestReset(RESET_PHYSICS)')
                    lastPos[i] = {pos, time}
                end
            end
        end
    end

    -- draw heatmap?
    if heatBitmap and terrainPosition then
      for mk, mv in pairs(map.objects) do
        -- {active = isactive, pos = pos, vel = vel, dirVec = dirVec, damage = damage}
        -- TODO: fix coordinate system
        local x = mv.pos.x - terrainPosition.x
        local y = mv.pos.y - terrainPosition.y
        local velo = math.min(254, mv.vel:length() * 20)
        --local existingVelo = heatBitmap:getPixel(x, y)
        --if not existingVelo or existingVelo.r == 255 or existingVelo.r < velo then
        --print("drawPoint("..tostring(x) .. ","..tostring(y)..","..tostring(velo) .. ")")
        heatBitmap:drawPoint(x, y, ColorI(velo, 0, 0, 255), 2)
        --end
      end
    end

    if time - exchangeTimer > exchangeTime then
        exchangeTimer = time
        exchangeVehicles()
    end

    -- level
    if time - levelChangeTimer > levelChangeTime then
        levelChangeTimer = time
        exchangeLevel()
    end

    -- Run for some time, then quit normally
    if maxRunMinutes and time > maxRunMinutes then
        shutdown(0)
    end
end

M.onExtensionLoaded = function()
    log('D', logTag, "module loaded, muting logs ...")
    -- disable Debug, Info, Always and Warnigns to keep the log size small
    --Lua:blacklistLogLevel("DI") --AW
end

M.onUnload = function()
    log('D', logTag, "module unloaded")
end

return M
