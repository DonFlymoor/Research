-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'createThumbnails'

local workerCoroutine = nil

local config = jsonReadFile('settings/createThumbnails_config.json')
local options = config.options
local views = config.views

local function isBatch()
    local cmdArgs = Engine.getStartingArgs()
    local probability = 0
    for i = 1, #cmdArgs do
        local arg = cmdArgs[i]
        arg = arg:stripchars('"')
        if arg == "-onLevelLoad_ext" or arg == "'util/createThumbnails'" then
            probability = probability +1
        end
    end
    return probability > 1
end

local function yieldSec(yieldfn,sec)
    local start  = os.clock()
    while (start+sec)>os.clock() do
        yieldfn()
    end
end

local function onPreRender(dt)
    if workerCoroutine ~= nil then
        local errorfree, value = coroutine.resume(workerCoroutine)
        if not errorfree then
            log('I', logTag, "workerCoroutine: "..value)
        end
        if coroutine.status(workerCoroutine) == "dead" then
            workerCoroutine = nil
            settings.setValue('GraphicBorderless', false)
            guihooks.trigger('hide_ui', false)
            if isBatch() then
                shutdown(0)
            end
        end
    end
end

local function findVal (model, config)
    return function (view)
        return function (val)
            if view.models ~= nil and view.models[model] ~= nil then
                local temp = view.models[model]

                if temp.configs ~= nil and temp.configs[config] ~= nil and temp.configs[config][val] ~= nil then
                    return temp.configs[config][val]
                end

                if temp[val] ~= nil then
                    return temp[val]
                end
            end
            return view[val]
        end
    end
end

-- called when the module is loaded. Note: not all system may be up and running at this point
local function onInit()
    log('I', logTag, "initialized")
end

local function setDimHelper (useView)
    local canvas = scenetree.findObject("Canvas")
    if not canvas then
        return
    end

    log('I', logTag, "requesting new video mode")
    local vm = canvas:getVideoMode()
    vm.width = useView.width
    vm.height = useView.height
    vm.fullscreen = false
    canvas:setMinExtent(vm.width, vm.height)
    canvas:setVideoMode(vm)
end

-- executed when a level was loaded
local function onClientStartMission(mission)
   setDimHelper({width = 1600, height = 900})
end

-- executed when a level was unloaded
local function onClientEndMission(mission)
end

-- executed on the first update where the engine is up and running
local function onFirstUpdate()
end

local function onExtensionLoaded()
    log('I', logTag, "module loaded")

    -- set GraphicBorderless to true, to make sure the view dimensions actually are the ones the picture is taken in
    settings.setValue('GraphicBorderless', true)

    -- set correct level
    --core_levels.startLevel(levelFullPath)


    -- main thing

    -- todo: since we need to load the whole vehicle for each config anyway we should cycle each view for each vehicle so that we don't need to set the window dimensions that often

    workerCoroutine = coroutine.create(function()

        if core_camera == nil then
            extensions.load("core_camera")
        end

        yieldSec(coroutine.yield, 0.1)

        log('I', logTag, 'Getting config list')
        local configs = core_vehicles.getConfigList(true).configs
        local models = core_vehicles.getModelList().models --because

        local configCount = tableSize(configs)
        log('I', logTag, table.maxn(configs).." configs")
        local modelInfo = nil

        yieldSec(coroutine.yield, 0.1)

        local counter = 0
        for _, v in pairs(configs) do
            counter = counter + 1
            local findValConf = findVal(v.model_key, v.key)
            -- if v.model_key == 'bigramp' or v.model_key == 'ramptest' or v.model_key == 'roadsigns' then goto continue end

            -- skip props
            -- if v.aggregates.Type.Prop then goto skipConfig end
            if options.models ~= nil and not tableContains(options.models, v.model_key) then goto skipConfig end

            if models == nil or models[v.model_key] == nil then
                log("E", logTag, "Model Info  not found for model ='"..v.model_key .."'")
                break
            end
            modelInfo = models[v.model_key]

            -- Replace the vehicle
            log('I', logTag, string.format("Spawning vehicle %05d / %05d", counter, configCount) .. ' : ' .. ' name: ' .. tostring(v.model_key) .. ', config: ' .. tostring(v.key))
            yieldSec(coroutine.yield, 0.1)
            local oldVehicle = be:getPlayerVehicle(0)
            core_vehicles.replaceVehicle(v.model_key, { config = v.key, licenseText = options.plate or ' '})
            yieldSec(coroutine.yield, 1)

            guihooks.trigger('hide_ui', true)

            for viewName, useView in pairs(views) do
                if useView.allow == nil then
                    useView.allow = {}
                end
                -- dump(v.key)
                -- dump(v.aggregates)
                -- print("TYPE ======"..tostring(modelInfo.Type))
                if modelInfo.Type == "Prop" and not tableContains(useView.allow, "Prop") then goto skipView end
                if modelInfo.Type == "Trailer" and not tableContains(useView.allow, "Trailer") then goto skipView end
                if not v.is_default_config and tableContains(useView.allow, "onlyDefault") then goto skipView end
                if options.views ~= nil and not tableContains(options.views, viewName) then goto skipView end
                local findValView = findValConf(useView)

                yieldSec(coroutine.yield, 0.1)
                setDimHelper(useView)
                yieldSec(coroutine.yield, 0.1)

                local newVehicle = oldVehicle
                while newVehicle == oldVehicle do
                    yieldSec(coroutine.yield, 0.1)
                    newVehicle = be:getPlayerVehicle(0)
                end

                newVehicle:setPositionRotation(0,0,0.5,0,0,0,1)
                newVehicle:queueLuaCommand("input.event('parkingbrake', 1, 1)")

                -- scenetree.hemisphere:setPosition(Point3F(pos.x, pos.y, 0))
                -- scenetree.light:setPosition(Point3F(pos.x, pos.y, 15))

                local vehicleId = newVehicle:getID()

                core_camera.resetCameraByID(vehicleId)
                core_camera.setFOV(vehicleId, 20)

                yieldSec(coroutine.yield, 0.4)

                core_camera.resetCameraByID(vehicleId)
                core_camera.setFOV(vehicleId, 20)

                yieldSec(coroutine.yield, 0.4)


                -- newVehicle:setCamModeByType("orbit")
                --newVehicle:setCamRotation(Point3F(-135, 1.3, 0))
                --newVehicle:setCamFOV(20)
                -- newVehicle:setCamModeByType("onboard.driver")

                core_camera.setRotation(vehicleId, vec3(findValView('rotation'), 0, 0))


                if findValView('dist') == nil then
                    useView.dist = 1
                end

                local idealDistance = newVehicle:getViewportFillingCameraDistance() * findValView('dist')
                core_camera.setDistance(vehicleId, idealDistance)
                if findValView('fov') then
                    core_camera.setFOV(vehicleId, findValView('fov'))
                end
                if findValView('offset') then
                    core_camera.setOffset(vehicleId, vec3(findValView('offset')[1] / idealDistance, findValView('offset')[2] / idealDistance, findValView('offset')[3] / idealDistance))
                end
                --MoveManager.zoomInSpeed = idealDistance
                --print("* new distance: " .. tostring(idealDistance))

                yieldSec(coroutine.yield, 2)

                if findValView('freeOffset') then
                    commands.setFreeCamera()
                    local game = commands.getGame()
                    local camera = commands.getCamera(game)
                    local pos = camera:getPosition()
                    pos.x = pos.x + findValView('freeOffset')[1] / idealDistance
                    pos.y = pos.y + findValView('freeOffset')[2] / idealDistance
                    pos.z = pos.z + findValView('freeOffset')[3] / idealDistance
                    camera:setPosition(vec3(pos):toPoint3F())
                    TorqueScript.eval('setFov('.. findValView('fov') ..');') --cannot be replaced atm because of anonymous namespace in c++
                    yieldSec(coroutine.yield, 0.5)
                end


                --newVehicle:queueLuaCommand("input.event('steering', 0.0, 1); input.event('parkingbrake', 1, 1); electrics.toggle_lights() ; electrics.toggle_lightbar_signal() ; electrics.toggle_fog_lights()")
                newVehicle:queueLuaCommand("input.event('parkingbrake', 1, 1)")

                -- Take screenshot
                local screenShotName = "vehicles/" .. v.model_key .. "/" .. (findValView('prefix') or '') .. v.key .. (findValView('suffix') or '')
                log('I', logTag, "saved screenshot:" .. screenShotName  ..'.png')
                TorqueScript.eval('screenShot("' .. screenShotName ..'", "PNG", 1);')
                if viewName == "default" and v.is_default_config then
                    -- t3d apparently does not like to take two pictures in one frame...
                    yieldSec(coroutine.yield, 0.2)
                    log('I', logTag, "saved default:" .. v.model_key  ..'.png')
                    TorqueScript.eval('screenShot("vehicles/' .. v.model_key .. '/default", "PNG", 1);')
                end
                yieldSec(coroutine.yield, 0.2)

                if findValView("annotation") == "true" then
                    yieldSec(coroutine.yield, 0.2)
                    TorqueScript.eval('toggleAnnotationVisualize(true);')
                    screenShotName = "vehicles/" .. v.model_key .. "/" .. (findValView('prefix') or '') .. v.key .. (findValView('suffix') or '')
                    yieldSec(coroutine.yield, 0.2)
                    log('I', logTag, "saved screenshot:" .. screenShotName  ..'_ann.png')
                    TorqueScript.eval('screenShot("' .. screenShotName ..'_ann", "PNG", 1);')
                    yieldSec(coroutine.yield, 0.2)
                    TorqueScript.eval('toggleAnnotationVisualize(false);')
                end

                if findValView("annotation") == "true" then
                    yieldSec(coroutine.yield, 0.2)
                    TorqueScript.eval('toggleLightColorViz(true);')
                    screenShotName = "vehicles/" .. v.model_key .. "/" .. (findValView('prefix') or '') .. v.key .. (findValView('suffix') or '')
                    yieldSec(coroutine.yield, 0.2)
                    log('I', logTag, "saved screenshot:" .. screenShotName  ..'_li.png')
                    TorqueScript.eval('screenShot("' .. screenShotName ..'_li", "PNG", 1);')
                    yieldSec(coroutine.yield, 0.2)
                    TorqueScript.eval('toggleLightColorViz(false);')
                end



                 if findValView('freeOffset') then
                    commands.setGameCamera()
                end
                ::skipView::
            end

            ::skipConfig::
        end
    end)
end

local function onExtensionUnloaded()
    log('I', logTag, "module unloaded")
    settings.setValue('GraphicBorderless', false)
end

M.onPreRender = onPreRender
M.onInit = onInit
M.onClientStartMission = onClientStartMission
M.onClientEndMission = onClientEndMission
M.onFirstUpdate = onFirstUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
