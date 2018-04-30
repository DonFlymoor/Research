-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Settings:

-- the IP Address of the OutSim Device
local OutSim_IP    = '192.168.1.100'
-- the port to use
local OutSim_Port  = 4444
-- delay in 100 ms
local OutSim_Delay = 1

-- Settings END, please do not change anything below
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local M = {}

local lastTime = 100000
local timer = 0

local ffi = require("ffi")
--local socket = require("socket.socket")
local udpSocket = nil

-- teh documentation can be found at LFS/docs/InSim.txt
ffi.cdef[[
typedef struct outsim_t {   // note: X and Y axes are on the ground, Z is up.
  unsigned    time;       // time in milliseconds (to check order)
  float       angVelX;    // 3 floats, angular velocity vector
  float       angVelY;
  float       angVelZ;
  float       heading;    // anticlockwise from above (Z)
  float       pitch;      // anticlockwise from right (X)
  float       roll;       // anticlockwise from front (Y)
  float       accelX;     // 3 floats X, Y, Z
  float       accelY;
  float       accelZ;
  float       velX;       // 3 floats X, Y, Z
  float       velY;
  float       velZ;
  int         posX;       // 3 ints   X, Y, Z (1m = 65536)
  int         posY;
  int         posZ;
  int         id;         // optional - only if OutSim ID is specified
} outsim_t;
]]

local function updateGFX(dt)
  -- only send when the 1st player is seated in this vehicle
  if not playerInfo.firstPlayerSeated then return end
  
  lastTime = lastTime + dt
  if lastTime < OutSim_Delay / 10 then
    return
  end
  lastTime = lastTime - OutSim_Delay / 10
  timer    = timer + dt
  if timer > 36000 then
    timer = 0
  end

  local o = ffi.new("outsim_t")
  -- set the values
  o.time = math.floor(timer*1000)

  -- TODO: struct needs to be filled

  -- convert the struct into a string
  local packet = ffi.string(o, ffi.sizeof(o))

  -- replace with your ip here
  udpSocket:sendto(packet, OutSim_IP, OutSim_Port)
end

local function onInit()
  udpSocket = socket.udp()
end

-- public interface
M.updateGFX = updateGFX
M.onInit    = onInit

return M
