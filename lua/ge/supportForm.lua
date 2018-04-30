-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local function collect(data)
    local help = data.info
    
    if data.add.hws then
        help.hws = core_hardwareinfo.getInfo()
    end
    if data.add.steam then
       
    end
    if data.add.log then
       
    end
    if data.add.bench then
        help.bench = core_hardwareinfo.latestBananbench()
    end

    return help
end

local function recieve(d) 
    local data = collect(d)
    guihooks.trigger("SupportPreviewChanged", data)
end

local function send(d)
    local data = collect(d)
    print('send this to the server somehow:')
    dump(data)
    -- send the form to the server / whatever
end

-- public interface
M.recieve = recieve
M.send = send

return M