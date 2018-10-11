-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local function applyOptions_Audio()
    --log( 'D', 'settings.audio', 'applyOptions_Audio' )
    -- validate options
    local devices = Engine.Audio.getInfo()
    local providerOK = false

    local audioProviderName = TorqueScript.getVar( '$pref::SFX::providerName' )
    for n, p in pairs(devices) do
        if n == audioProviderName then
            providerOK = true
        end
    end

    if not providerOK then
        log( 'E', 'settings.audio', 'incorrect audio provider: "' .. tostring(audioProviderName) .. '": ' .. dumps(devices) )

        local firstProviderName = ''
        for n, d in pairs(devices) do
            if n ~= 'Null' then
                firstProviderName = n
                break
            end
        end

        audioProviderName = firstProviderName
        if devices[firstProviderName] then
            TorqueScript.setVar( '$pref::SFX::providerName', audioProviderName )
            log( 'W', 'settings.audio', 'set provider to ' .. tostring(audioProviderName))
        end
    end

    if TorqueScript.eval( 'sfxCreateDevice($pref::SFX::providerName, $pref::SFX::useHardware, -1);' ) == '0' then
        local useHardware = TorqueScript.getVar( '$pref::SFX::useHardware' )
        audioProviderName = TorqueScript.getVar( '$pref::SFX::providerName' )
        log( 'E', 'applyOptions_Audio', 'Unable to create SFX device: '..audioProviderName..' '..useHardware );
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
