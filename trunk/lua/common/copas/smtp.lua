--[[
Copas is free software: it can be used for both academic and commercial purposes at absolutely no 
cost. There are no royalties or GNU-like "copyleft" restrictions. Copas qualifies as Open Source 
software. Its licenses are compatible with GPL. Copas is not in the public domain and the Kepler 
Project keep its copyright. The legal details are below.

The spirit of the license is that you are free to use Copas for any purpose at no cost without having 
to ask us. The only requirement is that if you do use Copas, then you should give us credit by 
including the appropriate copyright notice somewhere in your product or its documentation.

Copas was designed and implemented by André Carregal and Javier Guerra. The implementation is not 
derived from licensed software.

Copyright © 2005-2010 Kepler Project.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
-------------------------------------------------------------------
-- identical to the socket.smtp module except that it uses
-- async wrapped Copas sockets

local copas = require("copas")
local smtp = require("socket.smtp")

local create = function() return copas.wrap(socket.tcp()) end
local forwards = { -- setting these will be forwarded to the original smtp module
  PORT = true,
  SERVER = true,
  TIMEOUT = true,
  DOMAIN = true,
  TIMEZONE = true
}

copas.smtp = setmetatable({}, { 
    -- use original module as metatable, to lookup constants like socket.SERVER, etc.
    __index = smtp,
    -- Setting constants is forwarded to the luasocket.smtp module.
    __newindex = function(self, key, value)
        if forwards[key] then smtp[key] = value return end
        return rawset(self, key, value)
      end,
    })
local _M = copas.smtp

_M.send = function(mailt)
  mailt.create = mailt.create or create
  return smtp.send(mailt)
end

return _M