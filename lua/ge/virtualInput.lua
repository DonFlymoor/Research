-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local devices = {}

-- VirtualInputManager API:

-- getVirtualInputManager()
-- void emitEvent(const char* deviceType, int deviceInstance, const char* objType, int objectInstance, const char* action, float fValue);
-- int registerDevice(const char* productName, int axes, int buttons, int povs);
-- void resetDevices();

M.update = function()
end

M.enable = function(state)
 -- state = true or false
end

M.init = function()
    getVirtualInputManager():resetDevices()
end

-- consumer API

M.createDevice = function(productName, vidpid, axes, buttons, povs)
    local mgr = getVirtualInputManager()
    print("MANAGER?")
    if not mgr then return nil end
    print(tostring(mgr))

    local deviceInstance = mgr:registerDevice(productName, vidpid, axes, buttons, povs)
    if deviceInstance < 0 then
        print("IS NULL")
        return nil
    end
    log('D', 'lua.virtualinput', 'registered device "' .. productName .. '" to vinput' .. tostring(deviceInstance))

    return deviceInstance
end

M.deleteDevice = function(deviceInstance)
    local mgr = getVirtualInputManager()
    if not mgr then return nil end
    mgr:unregisterDevice('vinput' .. tostring(deviceInstance))
end

M.emit = function(deviceInstance, objType, objectInstance, action, val)
    local mgr = getVirtualInputManager()
    if not mgr then return nil end
    mgr:emitEvent('vinput', deviceInstance, objType, objectInstance, action, val)
end

M.emitAxis = function(deviceInstance, objectInstance, val)
    local mgr = getVirtualInputManager()
    if not mgr then return nil end

    log('D', 'lua.virtualinput', 'moving axis ' .. tostring(objectInstance) .. ' of device ' .. tostring(deviceInstance) .. ' to ' .. val)
    mgr:emitEvent('vinput', deviceInstance, 'axis', objectInstance, 'move', val)
end

return M
