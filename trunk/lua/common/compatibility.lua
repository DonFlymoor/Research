-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this file provides a very thing compatibility layer depending on if it is run
-- in plain Lua 5.1 - 5.3 or LuaJIT


loadstring = loadstring or load
unpack = unpack or table.unpack


-- notes for developers:
-- string.gfind = string.gmatch
-- table.getn = #
