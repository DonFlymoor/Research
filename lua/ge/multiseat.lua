-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

require("utils")
local M = {}

-- returns how many players can be using cars at the same time
local function getMaxPlayersAmount(multiseat)
    if multiseat then return 16 -- TODO hardcoded, should be same as steering fastpath limit in t3d side
    else return 1 end
end

-- returns a list of which player is controlling each input device
-- e.g. { "keyboard": 0, "xinput0": 1, "mouse": 0 }
local function getAssignedPlayers(devices, logEnabled)
    local maxPlayers = getMaxPlayersAmount(settings.getValue("multiseat"))
    local nVehicles = tableSize(getAllVehicles())
    local nControllers = tableSize(devices) - 1 -- assume mouse goes together with keyboard
    local players = math.max(1,math.min(maxPlayers, nVehicles, nControllers))
    if logEnabled and players > 1 then log("D", "multiseat", "Settled for "..players.." players:  supported="..maxPlayers..", vehicles="..nVehicles..", devices="..nControllers.." (& mouse)") end
    local assignedPlayers = {}
    local lastPlayer = 0
    for devname,info in pairs(devices) do
        local devicetype = string.split(devname, "%D+")[1] -- strip trailing number, if it exists (xinput0 -> xinput)
        if devicetype == "keyboard" or devicetype == "mouse" then
            --keyboard/mouse > always player 0 if available
            assignedPlayers[devname] = 0
        else
            lastPlayer = (lastPlayer + 1) % players
            assignedPlayers[devname] = lastPlayer
        end
    end
    if logEnabled and players > 1 then log((players>1) and "I" or "D", "", "Assigned players: "..dumps(assignedPlayers):gsub("\n", ""):gsub("  ", " ")) end
    return assignedPlayers
end

M.getAssignedPlayers = getAssignedPlayers

return M
