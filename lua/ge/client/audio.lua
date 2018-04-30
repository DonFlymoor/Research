local M = {}

local logTag = "audio"
local AudioChannels = {"AudioChannelDefault", "AudioChannelGui", "AudioChannelEffects", "AudioChannelMessages", "AudioChannelMusic", "AudioChannelAmbience"}

--[[
This function tests whether the current sfxSource object equals to the AudioChannelDefault object.
--------
@param sfxSource: C++ object of type SFXSource
@return: sfxId if it equals to one of the AudioChannels, else -1
]]
local function sfxGroupToOldChannel(sfxSource)
  local sfxId = sfxSource:getID()

  for i, channelName in pairs(AudioChannels) do 
    local channel = scenetree.findObject(channelName)
    if not channel then 
      return -1
    elseif channel:getID() == sfxId then
      return i-1 --this is because Lua starts counting at 1 and TS at 0
    end
  end
  return -1
end

M.sfxGroupToOldChannel = sfxGroupToOldChannel
return M