-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local function applyOptions_Audio()
    log( 'D', 'settings.audio', 'applyOptions_Audio' )
    -- validate options
    local devices = Engine.Audio.getInfo()
    local providerOK = false
    local deviceOK = false

    local audioProviderName = TorqueScript.getVar( '$pref::SFX::providerName' )
    local audioDeviceName = TorqueScript.getVar( '$pref::SFX::deviceName' )
    for n, p in pairs(devices) do
        if n == audioProviderName then
            for i, d in ipairs(p) do
                if d.name == audioDeviceName then
                    deviceOK = true
                end
            end
            providerOK = true
        end
    end

    if not providerOK then
        log( 'E', 'settings.audio', 'incorrect audio provider: provider: "' .. tostring(audioProviderName) .. '", device: "' .. tostring(audioDeviceName) .. '" : ' .. dumps(devices) )

        local firstProviderName = ''
        for n, d in pairs(devices) do
            if n ~= 'Null' then
                firstProviderName = n
                break
            end
        end

        audioProviderName = firstProviderName
        audioDeviceName = "default"
        if devices[firstProviderName] then
            TorqueScript.setVar( '$pref::SFX::providerName', audioProviderName )
            TorqueScript.setVar( '$pref::SFX::deviceName', audioDeviceName )
            log( 'W', 'settings.audio', 'set provider to ' .. tostring(audioProviderName) .. ' and device to ' .. tostring(audioDeviceName) )
            deviceOK = true
        end
    end

    if audioDeviceName == "default" then
      deviceOK = true
    end

    if not deviceOK then
        log( 'E', 'settings.audio', 'incorrect audio device: provider: "' .. tostring(audioProviderName) .. '", device: "' .. tostring(audioDeviceName) .. '" : ' ..  dumps(devices))
        for providerName, deviceArray in pairs(devices) do
            if providerName == audioProviderName then
                audioDeviceName = "default"
                TorqueScript.setVar( '$pref::SFX::deviceName', audioDeviceName )
                log( 'W', 'settings.audio', 'set device to ' .. tostring(audioDeviceName) )
                break
            end
        end
    end

    if TorqueScript.eval( 'sfxCreateDevice($pref::SFX::providerName, $pref::SFX::deviceName, $pref::SFX::useHardware, -1);' ) == '0' then
        local useHardware = TorqueScript.getVar( '$pref::SFX::useHardware' )
        audioProviderName = TorqueScript.getVar( '$pref::SFX::providerName' )
        audioDeviceName = TorqueScript.getVar( '$pref::SFX::deviceName' )
        log( 'E', 'applyOptions_Audio', 'Unable to create SFX device: '..audioProviderName..' '..audioDeviceName..' '..useHardware );
    end
end

local function buildOptionHelpers()

    local o = {}

    -- SettingsAudioProvider
    o.AudioProvider = {
        get = function() return TorqueScript.getVar('$pref::SFX::providerName') end,
        set = function ( value )
            TorqueScript.setVar( '$pref::SFX::providerName', value )
            applyOptions_Audio()
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local added = {}

            local deviceList = be:sfxGetAvailableDevices()
            local entries = string.match( deviceList, '(.*)\n')
            entries = split( entries, '\n' )
            for k, v in ipairs(entries) do
                local record = split( v, '\t')
                --dump(record)
                local provider = record[1]
                if provider ~= '' and not provider:upper():find('NULL') and not added[provider] then
                    table.insert(keys, provider)
                    table.insert(values, provider)
                    added[provider] = true
                end
            end
            return {keys=keys, values=values}
        end
    }

    -- SettingsAudioDevice
    o.AudioDevice = {
        get = function() return TorqueScript.getVar('$pref::SFX::deviceName') end,
        set = function(value)
            TorqueScript.setVar( '$pref::SFX::deviceName', value )
            applyOptions_Audio()
        end,
        getModes = function()
            local keys = {}
            local values = {}
            local usedKeys = {}
            local deviceList = be:sfxGetAvailableDevices()
            local entries = string.match( deviceList, '(.*)\n' )
            entries = split( entries, '\n' )
            local defaultDeviceName = "None"
            local previousDeviceName = TorqueScript.getVar('$pref::SFX::deviceName')
            local foundPreviousDeviceName = previousDeviceName == "default"
            for k, v in ipairs(entries) do
                if v ~= '\n' then
                    v = v:match( '(.*)\t' )
                    local record = split( v, '\t')
                    local device = record[2]
                    if usedKeys[device] then
                        log( 'D', 'settings.audio', ' Duplicated device name: '..device )
                    elseif device ~= '' and not device:upper():find('NULL') then
                        if defaultDeviceName == "None" then
                          defaultDeviceName = device
                        end
                        if device == previousDeviceName then
                          foundPreviousDeviceName = true
                        end
                        table.insert(keys, device)
                        table.insert(values, device)
                        usedKeys[device] = true
                    end
                end
            end
            table.insert(keys, "default")
            table.insert(values, "Windows Default | Detected: "..defaultDeviceName..")")
            if not foundPreviousDeviceName then
              table.insert(keys, previousDeviceName)
              table.insert(values, "Disconnected: "..previousDeviceName..")")
            end
            return {keys=keys, values=values}
        end
    }

    -- SettingsAudioMasterVol
    o.AudioMasterVol = {
        get = function()
            local v = tonumber(TorqueScript.getVar('$pref::SFX::masterVolume'))
            --log("D", "settings_audio", "AudioMasterVol.get() == "..dumps(v))
            return v
        end,
        set = function(value)
            --log("D", "settings_audio", "AudioMasterVol.set("..dumps(value)..")")
            TorqueScript.call('OptAudioUpdateMasterVolume', value)
        end
    }

    -- SettingsAudioInterfaceVol
    o.AudioInterfaceVol = {
        get = function()
            local audioGui = scenetree.findObject("AudioGui")
            if not audioGui then
                log('E', "AudioGui not found")
                return
            end
            local channel = audio_client.sfxGroupToOldChannel(audioGui.sourceGroup)
            return tonumber( TorqueScript.getVar( '$pref::SFX::channelVolume'..channel ) ) -- TS array is only a string merge varname + index
        end,
        set = function ( value )
            TorqueScript.call( 'OptAudioUpdateChannelVolume', 'AudioGui', value)
        end
    }

    -- SettingsAudioEffectsVol
    o.AudioEffectsVol = {
        get = function ()
            local audioEffect = scenetree.findObject("AudioEffect")
            if not audioEffect then
                log('E', "AudioEffect not found")
                return
            end
            local channel = audio_client.sfxGroupToOldChannel(audioEffect.sourceGroup)
            return tonumber( TorqueScript.getVar( '$pref::SFX::channelVolume'..channel ) )
        end,
        set = function ( value )
            TorqueScript.call( 'OptAudioUpdateChannelVolume', 'AudioEffect', value)
        end
    }

    -- AudioAmbienceVol
    o.AudioAmbienceVol = {
        get = function ()
            local AudioAmbience = scenetree.findObject("AudioAmbience")
            if not AudioAmbience then
                log('E', "AudioAmbience not found")
                return
            end
            local channel = audio_client.sfxGroupToOldChannel(AudioAmbience.sourceGroup)
            return tonumber( TorqueScript.getVar( '$pref::SFX::channelVolume'..channel ) )
        end,
        set = function ( value )
            TorqueScript.call( 'OptAudioUpdateChannelVolume', 'AudioAmbience', value)
        end
    }

    -- AudioMaxChannels
    o.AudioMaxChannels = {
        get = function ()
            return TorqueScript.getVar( '$pref::SFX::Device::maxVoices' )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::SFX::Device::maxVoices', value )
        end,
        getModes = function()
            return {keys={'128', '64', '48'}, values={'High', 'Normal', 'Low'}}
        end
    }

    -- useFmodLiveUpdate
    o.useFmodLiveUpdate = {
        get = function ()
            return TorqueScript.getVar( '$pref::SFX::useFmodLiveUpdate' )
        end,
        set = function ( value )
            TorqueScript.setVar( '$pref::SFX::useFmodLiveUpdate', value )
        end,
    }

    return o
end

local function onFirstUpdate(data)
    applyOptions_Audio()
end

M.buildOptionHelpers = buildOptionHelpers
M.onFirstUpdate = onFirstUpdate
return M
