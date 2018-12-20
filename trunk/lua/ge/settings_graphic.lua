-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local logTag = "settings_graphic"

-- local/default variables for settings
local CEF_UI_maxSizeHeight = "1080"
local mainMenuBackgroundMode = "VideoScaled"

local desiredwindowPlacement = nil

local function getSceneObj(objectName)
    local sceneObj = scenetree.findObject(objectName)
    if not sceneObj then
        log("E", logTag, "could  not find "..objectName)
        return
    end
    return sceneObj
end

local function videoModeFromString( videoModeStr )
    local vm = { width = 0, height = 0, fullScreen = 0, bitDepth = 0, refreshRate = 0, antialiasLevel = 0}
    local entries = split( videoModeStr, ' ')
    local count = tableSize(entries)
    if count == 6 then
        if tonumber( entries[1] ) then vm.width = tonumber( entries[1] ) end
        if tonumber( entries[2] ) then vm.height = tonumber( entries[2] ) end
        if tonumber( entries[4] ) then vm.bitDepth = tonumber( entries[4] ) end
        if tonumber( entries[5] ) then vm.refreshRate = tonumber( entries[5] ) end
        if tonumber( entries[6] ) then vm.antialiasLevel = tonumber( entries[6] ) end

        if entries[3] == "false" then
            vm.fullScreen = false
        else
            vm.fullScreen = true
        end
    end

    return vm
end

local function getDefault()
    local data = {}
    local vm = videoModeFromString(TorqueScript.call('getDesktopVideoMode'))
    data.GraphicResolutions = vm.width .. ' ' .. vm.height..' '..vm.refreshRate
    return data
end

local restartDialogShowed = false
local function openNeedRestartDialog()
    if not restartDialogShowed then
        restartDialogShowed = true
        TorqueScript.call( 'MessageBoxOK', 'This change requires that the game be restarted', 'This change requires that the game be restarted' )
    end
end

local function getAspectRatio( w, h )
  if tonumber(w) and tonumber(h) then
    local ratio = w /h
    if math.abs( ratio - 4/3) < 0.1 then return '(4:3)' end
    if math.abs( ratio - 16/9) < 0.1 then return '(16:9)' end
  end

  return ''
end

local function videoModeToString( vm )
    local str = tostring(vm.width)..' '..tostring(vm.height)..' '..tostring(vm.fullScreen)..' '..tostring(vm.bitDepth)..' '..tostring(vm.refreshRate)..' '..tostring(vm.antialiasLevel)
    return str
end

local function applyOptions_Graphic()
    log("D", logTag, "    >>>> applyOptions_Graphic <<<<<")
    local canvas = scenetree.findObject("Canvas")
    if( not canvas ) then
        return
    end

    local vm = videoModeFromString( TorqueScript.getVar( '$pref::Video::mode' ) )
    canvas:setVideoMode( vm )
end

local function getGPU()
  local gpu = TorqueScript.getVar( '$pref::Video::gpu' )
  local adapters = GFXInit.getAdapters()
  for k, a in ipairs(adapters) do
    if gpu ~= '' and a.gpu == gpu then return gpu end
    if gpu == '' and a.gpu ~= '' then return a.gpu end
  end

  gpu = adapters[1].gpu
  TorqueScript.setVar( '$pref::Video::gpu', gpu )
  return gpu
end

local function getGFX()
    local gfx = TorqueScript.getVar( '$pref::Video::displayDevice' )
    local adapters = GFXInit.getAdapters()
    for k, a in ipairs(adapters) do
        if gfx ~= '' and a.gfx == gfx then return gfx end
        if gfx == '' and a.gfx ~= '' then  return a.gfx end
    end

    gfx = adapters[1].gfx
    TorqueScript.setVar( '$pref::Video::displayDevice', gfx )
    return gfx
end

local function buildOptionHelpers()

    local o = {}
    local canvas = scenetree.findObject("Canvas")

    if( not canvas ) then
        return
    end

    -- SettingsGraphicDisplayDriver
    o.GraphicDisplayDriver = {
        get = function ()
            local value = TorqueScript.getVar( '$pref::Video::displayOutputDevice' )
            local adapters = GFXInit.getAdapters()
            for i, a in ipairs(adapters) do
                if a.output == value then
                    value = value:gsub("\\","/") -- TODO remove when fixed problem with JS and backlashes
                    return value
                end
            end
            return adapters[1].output:gsub("\\","/")
        end,
        set = function ( value )
            value = value:gsub("/","\\")  -- TODO remove when fixed problem with JS and backlashes
            local adapters = GFXInit.getAdapters()
            for i, a in ipairs(adapters) do
                if a.output == value then
                    TorqueScript.setVar( '$pref::Video::displayOutputDevice', value )
                    openNeedRestartDialog()
                    return
                end
            end
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local currentGPU = getGPU()
            local currentGFX = getGFX()
            local adapters = GFXInit.getAdapters()
            for k, a in ipairs(adapters) do
              if a.gpu == currentGPU and a.gfx == currentGFX then
                a.output = a.output:gsub("\\","/") -- TODO remove when fixed problem with JS and backlashes
                table.insert(keys, a.output)
                table.insert(values, a.monitor)
              end
            end
            return {keys=keys, values=values}
        end
    }


    o.GraphicGPU = {
        get = function ()
            return getGPU()
        end,
        set = function ( value )
            local currentGPU = getGPU()
            TorqueScript.setVar( '$pref::Video::gpu', value )
            local newGPU = getGPU()

            if currentGPU ~= newGPU then
              local adapters = GFXInit.getAdapters()
              for k, a in ipairs(adapters) do
                if a.gpu == newGPU then
                  a.output = a.output:gsub("/","\\")
                  TorqueScript.setVar( '$pref::Video::displayOutputDevice', a.output )
                  return
                end
              end
              openNeedRestartDialog()
            end
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local gpus = {}
            local adapters = GFXInit.getAdapters()
            for k, a in ipairs(adapters) do
              if not gpus[a.gpu] then
                table.insert(keys, a.gpu)
                table.insert(values, a.gpu)
                gpus[a.gpu] = true
              end
            end
            return {keys=keys, values=values}
        end
    }

    -- SettingsGraphicResolutions
    o.GraphicResolutions = {
        get = function ()
            local videoMode = canvas:getVideoMode()
            return videoMode.width .. ' ' .. videoMode.height..' '..videoMode.refreshRate
        end,
        set = function ( value )
            local videoMode = canvas:getVideoMode()
            videoMode.width, videoMode.height, videoMode.refreshRate = value:match(' *(.*) +(.*) +(.*)')
            canvas:setVideoMode( videoMode )
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local addedRes = {}

            local getKey = function(vm)
                return vm.width ..' '.. vm.height..' '..vm.refreshRate
            end

            local getValue = function(vm)
                return vm.width..' x '..vm.height..' '..getAspectRatio(vm.width, vm.height)..' '..vm.refreshRate..'Hz'
            end

            local videoMode = canvas:getVideoMode()
            table.insert(keys, getKey(videoMode) )
            table.insert(values, getValue(videoMode) )
            addedRes[getKey(videoMode)] = 1

            local videoModeList = canvas:getAllVideoModes()
            for k, videoModeStr in ipairs(videoModeList) do
                local vm = videoModeStr
                local key = getKey(vm)
                if addedRes[key] == nil and vm.height > 400 then
                    addedRes[key] = 1
                    table.insert(keys, key)
                    table.insert(values, getValue(vm) )
                end
            end
            return {keys=keys, values=values}
        end
    }

    -- SettingsGraphicResolutions
    o.WindowPlacement = {
        get = function ()
            return canvas:getPlacement()
        end,
        set = function ( value )
        end,
    }

    o.uiUpscaling = {
        get = function()
            return CEF_UI_maxSizeHeight
        end,

        set = function(value)
            CEF_UI_maxSizeHeight = value
            if value ~= TorqueScript.getVar('$CEF_UI::maxSizeHeight') then
                TorqueScript.setVar('$CEF_UI::maxSizeHeight', value)
            end
        end,
        getModes = function()
            return {keys={'1440', '1080', '720', '0'}, values={'2560 x 1440', '1920 x 1080', '1280 x 720', 'Disabled'}}
        end
    }

    o.FPSLimiter = {
        get = function ()
            return SimpleSettings.fpslimiter
        end,
        set = function ( value )
            SimpleSettings.fpslimiter = value
        end
    }
    o.FPSLimiterEnabled = {
        get = function ()
            return SimpleSettings.fpslimiterEnabled
        end,
        set = function ( value )
            SimpleSettings.fpslimiterEnabled = value
        end
    }
    o.SleepInBackground = {
        get = function ()
            return getSleepInBackground()
        end,
        set = function ( value )
            setSleepInBackground(value)
        end
    }
    -- SettingsGraphicFullscreen
    o.GraphicFullscreen = {
        get = function ()
            local videoMode = canvas:getVideoMode()
            return videoMode.fullScreen
        end,
        set = function ( value )
            local videoMode = canvas:getVideoMode()
            videoMode.fullScreen = value
            canvas:setVideoMode( videoMode )
        end
    }

    -- SettingsGraphicBorderless
    o.GraphicBorderless = {
        get = function ()
            return TorqueScript.getVar('$pref::Video::borderless' ) ~= "0"
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::Video::borderless', value )
            applyOptions_Graphic()
        end
    }

    -- SettingsGraphicSync
    o.vsync = {
        get = function ()
            local v = tonumber( TorqueScript.getVar('$video::vsync') )
            return v == true or (type(v)=="number" and v > 0)
        end,
        set = function ( value )
            local boolValue = value == true or (type(value)=="number" and value > 0)
            TorqueScript.setVar( '$video::vsync', boolValue )
            applyOptions_Graphic()
        end,
        getModes = function()
            return {keys={false, true}, values={'Off', 'On'}}
        end
    }

    -- SettingsGraphicRefreshRate
    o.GraphicRefreshRate = {
        get = function ()
            local videoMode = canvas:getVideoMode()
            return videoMode.refreshRate
        end,
        set = function ( value )
            local videoMode = canvas:getVideoMode()
            videoMode.refreshRate = value
            --canvas:setVideoMode( videoMode )
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local temp = {}
            local videoMode = canvas:getVideoMode()
            if not videoMode.fullScreen then
                return nil
            end

            local videoModeList = canvas:getAllVideoModes()
            for k, v in ipairs(videoModeList) do
                local vm = v
                temp[vm.refreshRate] = vm.refreshRate
            end
            for k, v in pairs(temp) do
                table.insert(keys, tostring(k))
                table.insert(values, tostring(v))
            end
            return {keys=keys, values=values}
        end
    }

    o.GraphicAntialiasType = {
        get = function ()
            local SMAA_PostEffect = getSceneObj("SMAA_PostEffect")
            if not SMAA_PostEffect then return end
            local FXAA_PostEffect = getSceneObj("FXAA_PostEffect")
            if not FXAA_PostEffect then return end
            if not settings.getValue('GraphicAntialiasType') then
                if settings.getValue('GraphicPostfxQuality') == '3' then
                    SMAA_PostEffect:enable()
                else
                    FXAA_PostEffect:enable()
                end
            end

            if SMAA_PostEffect:isEnabled() ~= false then
                return 'smaa'
            elseif FXAA_PostEffect:isEnabled() ~= false then
                return 'fxaa'
            else
                return settings.getValue('GraphicAntialiasType')
            end
        end,
        set = function ( value )
            local enabledAA =  settings.getValue('GraphicAntialias')
            settings.setValue('GraphicAntialias', 0)
            settings.setValue('GraphicAntialias', enabledAA)
        end,
        getModes = function ()
            return {keys={'smaa', 'fxaa'}, values={'SMAA', 'FXAA'}}
        end
    }

    -- SettingsGraphicAntialias
    o.GraphicAntialias = {
        get = function ()
            local SMAA_PostEffect = getSceneObj("SMAA_PostEffect")
            if not SMAA_PostEffect then return end
            local FXAA_PostEffect = getSceneObj("FXAA_PostEffect")
            if not FXAA_PostEffect then return end
            if SMAA_PostEffect:isEnabled() ~= false or FXAA_PostEffect:isEnabled() ~= false then
                return 4
            end
            return 0
        end,
        set = function ( value )
            local SMAA_PostEffect = getSceneObj("SMAA_PostEffect")
            if not SMAA_PostEffect then return end
            local FXAA_PostEffect = getSceneObj("FXAA_PostEffect")
            if not FXAA_PostEffect then return end
            if tonumber(value) == 0 then
              SMAA_PostEffect:disable()
              FXAA_PostEffect:disable()
              return
            end

            local AA = settings.getValue('GraphicAntialiasType')
            if AA == 'fxaa' then
                FXAA_PostEffect:enable()
            else
                SMAA_PostEffect:enable()
            end
        end,
        getModes = function()
            return {keys={"0", "1", "2", "4"}, values={"Off", "x1", "x2", "x4"}}
        end
    }

    -- SettingsGraphicAnisotropic
    o.GraphicAnisotropic = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::Video::defaultAnisotropy' ) )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::Video::defaultAnisotropy', value )
            applyOptions_Graphic()
        end,
        getModes = function()
            return {keys={"0", "4", "8", "16"}, values={"Off", "x4", "x8", "x16"}}
        end
    }

    -- SettingsGraphicGamma
    o.GraphicGamma = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::Video::Gamma' ) )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::Video::Gamma', value )
        end
    }

    -- SettingsGraphicOverallQuality
    o.GraphicOverallQuality = {
        get = function ()
            local value = TorqueScript.getVar( '$pref::Video::GraphicOverallQuality' )
            if not value or value == '' then value = 0 end
            return value
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::Video::GraphicOverallQuality', value )
        end,
        getModes = function()
            return {keys={'4','3', '2', '1', '0'}, values={'High', 'Normal', 'Low', 'Lowest', 'Custom'}}
        end
    }

    -- SettingsGraphicMeshQuality
    o.GraphicMeshQuality = {
        get = function ()
            return ( TorqueScript.call( 'MeshQualityGroup.getCurrentLevelId' ) )
        end,
        set = function ( value )
            TorqueScript.call( 'MeshQualityGroup.applyLevelId', value )
        end,
        getModes = function()
            return {keys={'3', '2', '1', '0'}, values={'High', 'Normal', 'Low', 'Lowest'}}
        end
    }

    -- SettingsGraphicTextureQuality
    o.GraphicTextureQuality = {
        get = function ()
            return ( TorqueScript.call( 'TextureQualityGroup.getCurrentLevelId' ) )
        end,
        set = function ( value )
            TorqueScript.call( 'TextureQualityGroup.applyLevelId', value )
        end,
        getModes = function()
            return {keys={'3', '2', '1', '0'}, values={'High', 'Normal', 'Low', 'Lowest'}}
        end
    }

    -- SettingsGraphicLightingQuality
    o.GraphicLightingQuality = {
        get = function ()
            return ( TorqueScript.call( 'LightingQualityGroup.getCurrentLevelId' ) )
        end,
        set = function ( value )
            TorqueScript.call( 'LightingQualityGroup.applyLevelId', value )
        end,
        getModes = function()
            return {keys={'3', '2', '1', '0'}, values={'High', 'Normal', 'Low', 'Lowest'}}
        end
    }

    -- SettingsGraphicShaderQuality
    o.GraphicShaderQuality = {
        get = function ()
            return ( TorqueScript.call( 'ShaderQualityGroup.getCurrentLevelId' ) )
        end,
        set = function ( value )
            TorqueScript.call( 'ShaderQualityGroup.applyLevelId', value )
        end,
        getModes = function()
            return {keys={'3', '2', '1', '0'}, values={'High', 'Normal', 'Low', 'Lowest'}}
        end
    }

    -- SettingsGraphicPostfxQuality
    o.GraphicPostfxQuality = {
        get = function ()
            local levelStr = getTSVar( '$PostFXManager::Settings::quality' )
            if levelStr == "" then
                levelStr = "2"
            end
            return (levelStr)
        end,
        set = function ( value )
            value = tostring(value)
            TorqueScript.setVar( '$PostFXManager::Settings::quality', value )
            local preset = '$PostFXManager::normalPreset'
            if value == '3' then
                preset = '$PostFXManager::highPreset'
            elseif value == '2' then
                preset = '$PostFXManager::normalPreset'
            elseif value == '1' then
                preset = '$PostFXManager::lowPreset'
            elseif value == '0' then
                preset = '$PostFXManager::lowestPreset'
            else
                return
            end

            TorqueScript.call('PostFXManager::loadPresetHandler', preset)
            settings.setState( { GraphicAntialiasType = false} )
        end,
        getModes = function()
            return {keys={'3', '2', '1', '0', '-1'}, values={'High', 'Normal', 'Low', 'Lowest', 'Custom'}}
        end
    }

    -- GraphicDynReflectionEnabled
    o.GraphicDynReflectionEnabled = {
        get = function ()
            return TorqueScript.getVar( '$pref::BeamNGVehicle::dynamicReflection::enabled' ) ~= "0"
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::BeamNGVehicle::dynamicReflection::enabled', value )
        end
    }

    -- GraphicDynReflectionFacesPerupdate
    o.GraphicDynReflectionFacesPerupdate = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::BeamNGVehicle::dynamicReflection::facesPerUpdate' ) )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::BeamNGVehicle::dynamicReflection::facesPerUpdate', value )
        end
    }

    -- GraphicDynReflectionDetail
    o.GraphicDynReflectionDetail = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::BeamNGVehicle::dynamicReflection::detail' ) )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::BeamNGVehicle::dynamicReflection::detail', value )
        end
    }

    -- GraphicDynReflectionDistance
    o.GraphicDynReflectionDistance = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::BeamNGVehicle::dynamicReflection::distance' ) )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::BeamNGVehicle::dynamicReflection::distance', value )
        end
    }

    -- GraphicDynReflectionTexsize
    o.GraphicDynReflectionTexsize = {
        get = function ()
            local value = math.log(tonumber( TorqueScript.getVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize' ) ) )/math.log( 2 )
            return value - 7
        end,
        set = function ( value )
            value = math.pow(2, value + 7)
            TorqueScript.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', value )
        end
    }

    -- SettingsPostFXDOFGeneralEnabled
    o.PostFXDOFGeneralEnabled = {
        get = function ()
            local DOFPostEffect = getSceneObj("DOFPostEffect")
            if not DOFPostEffect then return end
            return DOFPostEffect:isEnabled() ~= false
        end,
        set = function ( value )
            TorqueScript.setVar( '$PostFXManager::Settings::quality', -1 )
            TorqueScript.setVar( '$PostFXManager::PostFX::EnableDOF', value )
            local DOFPostEffect = getSceneObj("DOFPostEffect")
            if not DOFPostEffect then return end
            if value then
                DOFPostEffect:enable()
            else
                DOFPostEffect:disable()
            end
        end
    }

    -- SettingsPostFXLightRaysEnabled
    o.PostFXLightRaysEnabled = {
        get = function ()
            local LightRayPostFX = getSceneObj("LightRayPostFX")
            if not LightRayPostFX then return end
            return LightRayPostFX:isEnabled() ~= false
        end,
        set = function ( value )
            print("*************LightRayPostFX 2 set")
            local LightRayPostFX = getSceneObj("LightRayPostFX")
            if not LightRayPostFX then return end
            TorqueScript.setVar( '$PostFXManager::Settings::quality', -1 )
            TorqueScript.setVar( '$PostFXManager::PostFX::EnableLightRays', value )
            if value then
                LightRayPostFX:enable()
            else
                LightRayPostFX:disable()
            end
        end
    }

    -- SettingsPostFXSSAOGeneralEnabled
    o.PostFXSSAOGeneralEnabled = {
        get = function ()
            local SSAOPostFx = getSceneObj("SSAOPostFx")
            if not SSAOPostFx then return end
            return SSAOPostFx:isEnabled() ~= false
        end,
        set = function ( value )
            print("********PostFXSSAOGeneralEnabled 2 set") --not tested
            TorqueScript.setVar( '$PostFXManager::Settings::quality', -1 )
            TorqueScript.setVar( '$PostFXManager::PostFX::EnableSSAO', value )
            local SSAOPostFx = getSceneObj("SSAOPostFx")
            if not SSAOPostFx then return end
            if value then
                SSAOPostFx:enable()
            else
                SSAOPostFx:disable()
            end
        end
    }

    -- SettingsGraphicGrassDensity
    o.GraphicGrassDensity = {
        get = function ()
            return tonumber( TorqueScript.getVar( '$pref::GroundCover::densityScale' ))
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::GroundCover::densityScale', value )
        end
    }

    -- SettingsGraphicDisableShadows
    o.GraphicDisableShadows = {
        get = function ()
            local levelStr = getTSVar( '$pref::Shadows::disable' )
            if levelStr == "" then
                levelStr = "0"
            end
            return (levelStr)
        end,
        set = function ( value )
            value = tostring(value)
            setTSVar( '$pref::Shadows::disable', value)
        end,
        getModes = function()
            return {keys={'2', '1', '0'}, values={'None', 'Partial', 'All'}}
        end
    }

    -- MainMenuBackgroundMode
    o.MainMenuBackgroundMode = {
        get = function ()
            return mainMenuBackgroundMode
        end,
        set = function ( value )
            mainMenuBackgroundMode = value
        end,
        getModes = function()
            return {keys={'Video', 'VideoScaled', 'Images', 'ImagesScaled'}, values={'Video', 'Video scaled', 'Images', 'Images scaled'}}
        end
    }


    return o
end

local function onInit(data)
    desiredwindowPlacement = data.WindowPlacement
end

local function onFirstUpdate()
    local canvas = scenetree.findObject("Canvas")
    if TorqueScript.getVar( '$forceFullscreen' ) == "1" then
        desiredwindowPlacement = false
        local data = getDefault()
        data.GraphicFullscreen = true
        for k, v in pairs(data) do
            settings.setValue(k, v)
        end
    end

    if desiredwindowPlacement then
        if not canvas then return end
        canvas:restorePlacement(desiredwindowPlacement)
    end
    canvas:showWindow()
end

M.buildOptionHelpers = buildOptionHelpers
M.onInit = onInit
M.onFirstUpdate = onFirstUpdate

return M
