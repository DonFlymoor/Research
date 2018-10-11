-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local players = {}

local function getRewardValue(player, typeArray)
    players[player] = players[player] or {}
    local inv = players[player]
    local totalValue = 0
    for _, type in ipairs(typeArray) do
        totalValue = totalValue + (inv[type] or 0)
    end
    return totalValue
end

local function addReward(player, value, type)
    players[player] = players[player] or {}
    local inv = players[player]
    inv[type] = (inv[type] or 0) + value
end

local function delReward(player, value, typeArray)
    if getRewardValue(player, typeArray) < value then
        return false
    end
    players[player] = players[player] or {}
    local inv = players[player]
    for _, type in ipairs(typeArray) do    
        local forDel = math.min(value, (inv[type] or 0))
        if forDel > 0 then
            value = value - forDel
            inv[type] = inv[type] - forDel
            if inv[type] == 0 then inv[type] = nil end
            if value == 0 then return end
        end
    end
    return true
end

local function iterateRewardsConst(player, callback)
    local inv = players[player] or {}
    for k, v in pairs(inv) do
        callback(k, v)
    end
end

local function reset()
    players = {}
end

local function processCampaignReward(player, scenarioResult, scenarioData)
    local data = (not scenarioResult.failed and scenarioData.onEvent.onSucceed) or scenarioData.onEvent.onFail
    if not data or not data.rewards then return end
    for _, v in ipairs(data.rewards) do
        addReward(player, v.value, v.type)
    end
end

local function getScenarioReward(scenarioData, eventName)
  if scenarioData and scenarioData.onEvent and scenarioData.onEvent[eventName] then
    local eventData = scenarioData.onEvent[eventName]   
    if eventData.rewards and type(eventData.rewards) == 'table' then
      local result = {}
     for _,v in ipairs(eventData.rewards) do
       table.insert(result, v)
     end
     return result
    end
  end

  return nil
end

M.reset = reset
M.getRewardValue = getRewardValue
M.addReward = addReward
M.delReward = delReward
M.iterateRewardsConst = iterateRewardsConst
M.processCampaignReward = processCampaignReward
M.getScenarioReward = getScenarioReward

return M
