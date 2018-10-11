local M = {}

local mp = require('MessagePack')
local socket = require('socket/socket')
local json = require('json')

M.receive = function(skt)
  local length, err = skt:receive(16)
  local data, err = skt:receive(tonumber(length))

  if err then
    log('E', 'ResearchCom', 'Error reading from socket: '..tostring(error))
    return nil
  end

  return data
end

M.readMessage = function(clients)
  local read, write, _ = socket.select(clients, clients, 0)
  local message

  for _, skt in ipairs(read) do
    if write[skt] == nil then
      goto continue
    end

    skt:settimeout(0.1, 't')

    message = M.receive(skt)

    ::continue::
  end

  if message ~= nil then
    message = mp.unpack(message)
  end

  return message
end

M.sendMessage = function(skt, message)
  local length
  if skt == nil then
    return
  end

  message = mp.pack(message)
  length = #message
  length = string.format('%016d', length)
  skt:send(length)
  skt:send(message)
end

M.sendACK = function(skt, type)
  local message = {type = type}
  M.sendMessage(skt, message)
end

return M
