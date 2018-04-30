-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local multiseat = false
local function buildOptionHelpers()
    local o = {}
    o.multiseat = {
        get = function ()
            return multiseat
        end,
        set = function ( value )
            if value ~= true and value ~= false then
              log("E", "settings_gameplay.lua", "Attempted to set multiseat to invalid value: "..dumps(value))
              return
            end
            local prev = multiseat
            multiseat = value
            if prev ~= value then
              bindings.onMultiseatChanged('multiseat setting changed')
              if multiseat then
                extensions.load("core_multiseatCamera")
              else
                extensions.unload("core_multiseatCamera")
              end
            end
        end
    }
    return o
end

M.buildOptionHelpers = buildOptionHelpers
return M
