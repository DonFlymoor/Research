
local M = {}
M.whiteList = {}
M.blackList = {}
local actionGroups = {}

M.addAction = function( filter, actionName, filtered )
    if type(actionGroups[actionName]) == 'table' then
        for i, a in ipairs(actionGroups[actionName]) do
            ActionMap.addToFilter( filter, a, filtered )
        end
    else
        ActionMap.addToFilter( filter, actionName, filtered )
    end
end

M.clear = function( filter )
    ActionMap.clearFilters( filter )
    end

M.setGroup = function( name, arrayValues )
    actionGroups[name] = arrayValues
    end

M.getGroup = function( name )
    return actionGroups[name]
    end

return M
