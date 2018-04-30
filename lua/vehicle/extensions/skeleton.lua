-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this module is always loaded and then unloaded if not required.
-- it draws the basic skeleton of everything in case no flexbody is found
-- this is supposed to help people get quickstarted in working with jbeam

local M = {}

local function onExtensionLoaded()
    -- decide if we want this module to be loaded or not:
    -- if it has flexbodies, unload again
    if v.data.flexbodies ~= nil and tableSize(v.data.flexbodies) ~= 0 then
        -- unload again
        return false
    end
    -- keep module loaded
    return true
end

local function onDebugDraw(focusPos)
    -- this is disabled once debug mode is enabled, so it does not conflict
    if bdebug.state.debugEnabled then return end

    -- simply draw all beams in pink
    for _, beam in pairs (v.data.beams) do
        obj.debugDrawProxy:drawBeam3d(beam.cid, 0.01, color(44, 71, 112,230))
    end

    -- draw node balls
    for _, node in pairs (v.data.nodes) do
        obj.debugDrawProxy:drawNodeSphere(node.cid, 0.03, color(170, 57, 57,230))
    end

    -- and the collision triangles if there are any
    obj.debugDrawProxy:drawColTris(0, color(0,0,0,150), color(0,100,0,50), color(100,0,0,50), 1, color(0,0,255,255))
end

-- public interface
M.onDebugDraw = onDebugDraw
M.onExtensionLoaded = onExtensionLoaded

return M