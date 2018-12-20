local M = {}

local mp = require('libs/lua-MessagePack/MessagePack')
local socket = require('libs/luasocket/socket.socket')
local json = require('json')

M.receive = function(skt)
  local length, err = skt:receive(16)

  if err then
    log('E', 'ResearchCom', 'Error reading from socket: '..tostring(err))
    return nil, err
  end

  local data, err = skt:receive(tonumber(length))

  if err then
    log('E', 'ResearchCom', 'Error reading from socket: '..tostring(err))
    return nil, err
  end

  return data, nil
end

M.readMessage = function(clients)
  local read, write, _ = socket.select(clients, clients, 0)
  local message, err

  for _, skt in ipairs(read) do
    if write[skt] == nil then
      goto continue
    end

    skt:settimeout(0.1, 't')

    message, err = M.receive(skt)

    ::continue::
  end

  if err ~= nil then
    return nil, err
  end

  if message ~= nil then
    message = mp.unpack(message)
  end

  return message, nil
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
