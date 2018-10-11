-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- extensions.load('test_mouseRayTest')

local M = {}

-- testing to just get the mouse ray: getCameraMouseRay
local function test1()
  local res = getCameraMouseRay()
  if res and res.pos then
    res.pos = vec3(res.pos)
    res.dir = vec3(res.dir)
    local startPos = res.pos
    local endPos = res.pos + res.dir * 0.1
    --debugDrawer:drawSphere(startPos:toPoint3F(), 0.01, ColorF(0,1,0,1))
    debugDrawer:drawSphere(endPos:toPoint3F(), 0.01, ColorF(1,1,0,1))
    debugDrawer:drawLine(startPos:toPoint3F(), endPos:toPoint3F(), ColorF(1,0,0,1))
  end
end

-- testing the raycasting
local function test2()
  local res = cameraMouseRayCast()
  if res and res.pos then
    debugDrawer:drawSphere(res.pos, 0.1, ColorF(0,1,0,1))
    --debugDrawer:drawLine(res.pos, res.pos + res.normal, ColorF(0,1,0,1))
    print(" hit object: " .. tostring(res.object:getId() .. ' in ' .. res.distance .. ' m distance'))
    -- removes the object - fun minigame ;)
    --if res.object then res.object:delete() end
  end
end

local function onPreRender()

  --test1()
  test2()

end

M.onPreRender = onPreRender

return M