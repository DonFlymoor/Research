-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local multiplayerEnabled = false
local remoteIP = '127.0.0.1'
local listenPort = 13317

-- why we need two sockets: they have different proerties (i.e. timeout)
local listenUdpSocket = nil
local sendingUdpSocket = nil

function hex_dump_file(buf, filename)
  local f = io.open(filename, "w")
  for i=1,math.ceil(#buf/16) * 16 do
    if (i-1) % 16 == 0 then f:write(string.format('%08X  ', i-1)) end
    f:write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
    if i %  8 == 0 then f:write(' ') end
    if i % 16 == 0 then f:write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
  end
  f:close()
end

local function onExtensionLoaded()
  log('D', 'nodeStream.onExtensionLoaded', "nodeStream module loaded")

  if multiplayerEnabled then
    sendingUdpSocket = socket.udp()

    listenUdpSocket = socket.udp()
    if listenUdpSocket:setsockname('*', listenPort) == nil then
      log('W', 'nodestream.onExtensionLoaded', 'Unable to open listening UDP Socket')
      listenUdpSocket = nil
    end
    --ip, port = listenUdpSocket:getsockname()
    listenUdpSocket:settimeout(0)
  end
end

local function onUpdate()
  if not listenUdpSocket then return end

  local data, ip, port = listenUdpSocket:receivefrom(32768)
  if not data then return end
  --log('D', 'nodeStream.onUpdate', 'got packet with size ' .. string.len(data) .. ' from ' .. tostring(ip) .. ':' .. tostring(port))
  --hex_dump_file(data, 'nsd_received.txt')

  --local v = be:getObject(1)
  --if v then
  --  v:injectDataPackage(data, string.len(data))
  --end
end

local function onUnload()
  log('D', 'nodeStream.onUnload', "nodeStream module unloaded")
end

local function send(data)
  if not sendingUdpSocket then return end
  --log('D', 'nodeStream.send', 'send packet with size ' .. string.len(data) .. ' to ' .. tostring(remoteIP) .. ':' .. tostring(listenPort))
  --hex_dump_file(data, 'nsd_sent.txt')
  sendingUdpSocket:sendto(data, remoteIP, listenPort)
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onUnload = onUnload
M.onUpdate = onUpdate

M.send = send

return M
