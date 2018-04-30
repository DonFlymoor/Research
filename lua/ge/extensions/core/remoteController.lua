-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Settings:

-- Settings END, please do not change anything below
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local qrencode = require "qrencode"

local M = {}

local logTag = 'remoteController'
local udpSocket = nil
local receive_sockets = {}

local ffi = require_optional('ffi')
if ffi then
  ffi.cdef[[
  typedef struct { float w, x, y, z; } ori_t;
  ]]
end

local listenPort = 4444 -- listening port for new conenctions and the port the apps listen on for UI packages
local appPort = listenPort + 1 -- port where the apps receive data on

local udpSocket = nil

-- Table of connected devices. The keys are a string of the IP address and the value is the virtual
-- devices id.
local virtualDevices = {}

-- The time of the last package received by each IP address
local lastPackageTimes = {}

-- The player number of each vDevice
local assignedPlayers = {}

local prevX = -1
local prevY = -1
local code = math.random(10000, 99999)
--local iosCode = 232664


local function getQRCode()
  if udpSocket == nil then
    udpSocket = socket.udp()
    if udpSocket:setsockname('*', listenPort) == nil then
      log('W', logTag, "Unable to open UDP Socket")
      udpSocket = nil
      return false
    end
    --ip, port = udpSocket:getsockname()
    udpSocket:settimeout(0)
    receive_sockets[0] = udpSocket
    log('I', logTag, "started with code "..code)
  end
  local ok, table_or_message = qrencode.qrcode(
    "https://play.google.com/store/apps/details?id=com.beamng.remotecontrol#"..code
  )
  if ok then
    return table_or_message
  end
  log('E', logTag, table_or_message)
end

local function getQRCodeIOS()
  if udpSocket == nil then
    udpSocket = socket.udp()
    if udpSocket:setsockname('*', listenPort) == nil then
      log('W', logTag, "Unable to open UDP Socket")
      udpSocket = nil
      return false
    end
    --ip, port = udpSocket:getsockname()
    udpSocket:settimeout(0)
    receive_sockets[0] = udpSocket
    log('I', logTag, "started with code "..code)
  end
  local ok, table_or_message = qrencode.qrcode(
    "https://itunes.apple.com/ca/app/beamng.drive-remote-control/id1163096150#"..code
  )
  if ok then
    return table_or_message
  end
  log('E', logTag, table_or_message)
end

local function onUpdate()
  -- TODO: move to 1 fps
  if not udpSocket then return end

  local currentTime = Engine.Platform.getRealMilliseconds()

  for ip, lastPackageTime in pairs(lastPackageTimes) do
    -- Unplug controller after a 10 seconds timeout
    if virtualDevices[ip] ~= nil and currentTime - lastPackageTime > 10000 then
      virtualinput.deleteDevice(virtualDevices[ip])
      virtualDevices[ip] = nil
    end
  end

  while true do
    --log('D', logTag, "getting data from ".. tostring(listenPort))
    local data, ip, listenPort = udpSocket:receivefrom(128)

    if not data then
      --log('D', logTag, "No data")
      return
    end
    lastPackageTimes[ip] = currentTime

    --udpSocket:setpeername(ip, port)
    --log('D', logTag, "got '" .. tostring(data) .. "' from "..tostring(ip) .. ":" .. tostring(listenPort))
    if(data:sub(0, 6) == 'beamng') then -- new device trying to connect
      local args = split(data, '|')
      --log('D', logTag, "data: " .. args[1] .. " : " .. args[2] .. " : " .. args[3])
      local deviceName = args[2]
      if deviceName == "" then
        deviceName = "Unknown"
      end
      log('D', logTag, "Got discovery package from device " .. deviceName ..
                     " with code " .. args[3])
      if not (args[3] == tostring(code)) then
        log('D', logTag, "Code doesn't match "..code..", ignoring package.")
      else
        if not virtualDevices[ip] then
          local nAxes = 1
          local nButtons = 2
          local nPovs = 0
          local vDevice = virtualinput.createDevice(
            deviceName, "bngremotectrlv1", nAxes, nButtons, nPovs
          )
          if not vDevice or vDevice < 0 then
            log('E', logTag, 'unable to create remote controller input')
          else
            virtualDevices[ip] = vDevice
          end
        end
        if virtualDevices[ip] ~= nil then
          log('D', logTag, 'sending hello back to: ' .. ip .. ':' .. appPort)
          local response = "beamng|" .. args[3]
          udpSocket:sendto(response, ip, appPort)
        end
      end
    elseif virtualDevices[ip] ~= nil then
      local orientation = ffi.new("ori_t")
      -- notice the reverse - for the network endian byte order
      ffi.copy(orientation, data:reverse(), ffi.sizeof(orientation))


      --log('D', logTag, 'got data: ' .. orientation.x .. ', ' .. orientation.y .. ', ' .. orientation.z.. ', ' .. orientation.w)

      --log('D', logTag, "Got input package")
      --log('D', logTag, "Orientation: "..math.floor(orientation.x * 100)..", "..math.floor(orientation.y*100)..", "..math.floor(orientation.z*100))
      --log('D', logTag, string.format("Orientation: %0.2f, %0.2f, %0.2f", orientation.x, orientation.y, orientation.z))

      local vDevice = virtualDevices[ip]

      -- ask the vehicle to send the UI data to the target
      local vehicle = assignedPlayers[vDevice] and be:getPlayerVehicle(assignedPlayers[vDevice]) or nil
      if vehicle then
        -- we reuse the outgauge extension for updating the user interface of the app
        -- this is incompatible with the outgauge settings. You cannot use outgauge and this at the same time for now
        vehicle:queueLuaCommand('extensions.outgauge.sendPackage("' .. ip .. '", ' .. appPort .. ', ' .. orientation.w .. ')')
      end

      -- normalize data
      orientation.x = math.min(1, math.max(0, orientation.x))
      orientation.y = math.min(1, math.max(0, orientation.y))
      orientation.z = math.min(1, math.max(0, orientation.z))

      -- send the received input events to the vehicle
      virtualinput.emit(
        vDevice, "button", 0, (orientation.x > 0.5) and "make" or "break", orientation.x
      )
      virtualinput.emit(
        vDevice, "button", 1, (orientation.y > 0.5) and "make" or "break", orientation.y
      )
      virtualinput.emit(vDevice, "axis", 0, "move",  orientation.z)
    end
  end
end

local function onExtensionLoaded()
  if not ffi then
    log('E', logTag, 'remote controller requires FFi to work')
    return false
  end
  return true
end

local function onInputBindingsChanged(players)
  for device, player in pairs(players) do
    for _, vDevice in pairs(virtualDevices) do
      if "vinput"..vDevice == device then
        assignedPlayers[vDevice] = player
      end
    end
  end
end

local function devicesConnected () 
  return tableSize(virtualDevices) > 0
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onFirstUpdate = onFirstUpdate
M.onInputBindingsChanged = onInputBindingsChanged
M.getQRCode = getQRCode
M.getQRCodeIOS = getQRCodeIOS
M.devicesConnected = devicesConnected

return M
