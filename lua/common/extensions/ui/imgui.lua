-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = require('lua/common/extensions/ui/imgui_api')

local ffi = require('ffi')


M.FLT_MAX = FLT_MAX
M.BoolTrue = M.Bool(true)
M.BoolFalse = M.Bool(false)
M.IntZero = M.Int(0)
M.IntOne = M.Int(1)
M.IntNegOne = M.Int(-1)
M.FloatZero = M.Float(0.0)
M.FloatOne = M.Float(1.0)
M.FloatNegOne = M.Float(-1.0)
M.ImVec2Zero = M.ImVec2(0,0)
M.ImVec2One = M.ImVec2(1,1)
M.ImVec4Zero = M.ImVec4(0,0,0,0)
M.ImVec4One = M.ImVec4(1,1,1,1)

--TODO: Create event for initialization and when reloading lua
local function onImGuiReady()
  -- create new context
  if vmType == 'game' then
    -- get the 1st, initial c++ context that is managed by the game engine
    M.ctx = ffi.C.ImGui_GetMainContext()
  end
end

local function onExtensionLoaded()
  if vmType == 'game' then
    -- get the 1st, initial c++ context that is managed by the game engine
    M.ctx = ffi.C.ImGui_GetMainContext()
  else
    M.ctx = ffi.C.ImGui_CreateContext(obj:getID())
    ffi.C.ImGui_NewFrame(M.ctx, obj:getSafeLocalQueueNumber())
  end
end

-- only called from the vehicle lua
local function onDebugDraw()
  --if vmType ~= 'game' then
    ffi.C.ImGui_registerDrawData(M.ctx, obj:getSafeLocalQueueNumber())
    ffi.C.ImGui_NewFrame(M.ctx, obj:getSafeLocalQueueNumber())
  --end
end

M.flags = bit.bor
M.onImGuiReady = onImGuiReady
M.onExtensionLoaded = onExtensionLoaded
M.onDebugDraw = onDebugDraw -- only called from the vehicle lua

return M