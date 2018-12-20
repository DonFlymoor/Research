--[[
 SJSON Parser for Lua 5.1

 Copyright (c) 2013-2018 BeamNG GmbH.
 All Rights Reserved.

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 It decodes SJON format:
  https://github.com/Autodesk/sjson

 Usage:

 -- Lua script:
 local t = Json.Decode(json)

 Notes:
 1) Encodable Lua types: string, number, boolean, table, nil
 2) All control chars are encoded to \uXXXX format eg "\021" encodes to "\u0015"
 3) All Json \uXXXX chars are decoded to chars (0-255 byte range only)
 4) Json single line // and /* */ block comments are discarded during decoding
 5) Numerically indexed Lua arrays are encoded to Json Lists eg [1,2,3]
 6) Lua dictionary tables are converted to Json objects eg {"one":1,"two":2}
 7) Json nulls are decoded to Lua nil and treated by Lua in the normal way

--]]

local M = {}

if not pcall(require, "table.new") then
  table.new = function() return {} end
end

local error = error
local tonumber = tonumber
local byte, sub, tconcat, tablenew = string.byte, string.sub, table.concat, table.new

local escapes = {
  [116] = '\t',
  [110] = '\n',
  [102] = '\f',
  [114] = '\r',
  [98] = '\b',
  [34] = '"',
  [92] = '\\'
}

local peekTable = tablenew(256,0)

local function jsonError(msg, s, i)
  local curlen = 0
  local n = 1
  for w in s:gmatch("([^\n]*)") do
    curlen = curlen + #w
    if curlen >= i then
      error(string.format("%s near line %d, '%s'",msg, n, w:match'^%s*(.*%S)' or ''))
    end
    if w == '' then
      n = n + 1
      curlen = curlen + 1
    end
  end
end

local function parseNumber(self, s)
  -- Read Number
  local i = self[1]
  local c = byte(s, i)
  local coef = 1

  if c == 45 then -- -
    coef = -1
    i = i + 1
  elseif c == 43 then i = i + 1 end -- +

  local r = 0
  c = byte(s, i)
  while (c >= 48 and c <= 57) do -- \d
    i = i + 1
    r = r * 10 + (c - 48)
    c = byte(s, i)
  end
  if c == 46 then -- .
    i = i + 1
    c = byte(s, i)
    local f = 0
    local scale = 0.1
    while (c >= 48 and c <= 57) do -- \d
      i = i + 1
      f = f + (c - 48) * scale
      c = byte(s, i)
      scale = scale * 0.1
    end
    r = r + f
  elseif c == 35 then -- #
    local infend = self[1] + 6
    if sub(s, self[1], infend) == "1#INF00" then
      self[1] = infend
      return math.huge
    else
      jsonError(string.format("Invalid number: '%s'", sub(s, self[1], infend)), s, self[1])
    end
  end
  if c == 101 or c == 69 then -- e E
    i = i + 1
    c = byte(s, i)
    while (c >= 45 and c <= 57) or c == 43 do -- \d-+
      i = i + 1
      c = byte(s, i)
    end
    r = tonumber(sub(s, self[1], i - 1))
    if r == nil then
      jsonError(string.format("Invalid number: '%s'", sub(s, self[1], i-1)), s, self[1])
    end
  else
    r = r * coef
  end
  self[1] = i - 1
  return r
end

local function error_input(self, s)
  jsonError('Invalid input', s, self[1])
end

local function SkipWhiteSpace(self, s)
  local i = self[1] + 1

::restart::
  local p = byte(s, i)
  while p ~= nil and (p <= 32 or p == 44) do -- matches space tab comma newline
    i = i + 1
    p = byte(s, i)
  end

  if p == 47 then -- / -- read comment
    i = i + 1
    p = byte(s, i)
    if p == 47 then -- / -- single line comment "//"
      repeat
        i = i + 1
        p = byte(s, i)
      until p == 10 or p == 13 or p == nil
      i = i + 1
    elseif p == 42 then -- * -- block comment "/*  xxxxxxx */"
      while true do
        i = i + 1
        p = byte(s, i)
        if (p == 42 and byte(s, i+1) == 47) or p == nil then -- */
          break
        elseif p == 47 and byte(s, i+1) == 42 then -- /*
          jsonError("'/*' inside another '/*' comment is not permitted", s, i)
        end
      end
      i = i + 2
    else
      jsonError('Invalid comment', s, i)
    end
    goto restart
  end

  self[1] = i
  return p
end

local function readString(self, s)
  -- parse string
  -- fast path
  local i = self[1] + 1
  local si = i -- "
  local ch = byte(s, i)
  while ch ~= 34 and ch ~= 92 and ch ~= nil do  -- " \
    i = i + 1
    ch = byte(s, i)
  end

  if ch == 34 then -- "
    self[1] = i
    return sub(s, si, i - 1)
  end

  -- slow path for strings with escape chars
  if ch ~= 92 then -- \
    self[1] = si
    jsonError("String not having an end-quote", s, self[1])
    return
  end

  i = si
  local result = {}
  local resultidx = 1
  ch = byte(s, i)
  while ch ~= 34 do -- "
    ch = s:match('^[^"\\]*', i)
    i = i + (ch and ch:len() or 0)
    result[resultidx] = ch
    resultidx = resultidx + 1
    ch = byte(s, i)
    if ch == 92 then -- \
      local ch1 = escapes[byte(s, i+1)]
      if ch1 then
        result[resultidx] = ch1
        resultidx = resultidx + 1
        i = i + 1
      else
        result[resultidx] = '\\'
        resultidx = resultidx + 1
      end
      i = i + 1 -- "
    end
  end

  self[1] = i
  return tconcat(result)
end

local function readKey(self, s, c)
  local key
  local starti = self[1]
  if c == 34 then -- '"'
    key = readString(self, s)
  else
    local i = starti
    local ch = byte(s, i)
    while (ch >= 97 and ch <= 122) or (ch >= 65 and ch <= 90) or (ch >= 48 and ch <= 57) or ch == 95 do -- [a z] [A Z] or [0 9] or _
      i = i + 1
      ch = byte(s, i)
    end

    local i_1 = i - 1
    key = sub(s, starti, i_1)
    self[1] = i_1
  end
  if self[1] < starti then
    jsonError(string.format("Expected dictionary key"), s, self[1])
  end
  local delim = SkipWhiteSpace(self, s)
  if delim ~= 58 and delim ~= 61 then -- : =
    jsonError(string.format("Expected dictionary separator ':' or '=' instead of: '%s'", string.char(delim)), s, self[1])
  end
  return key
end

local function decode(s)
  if s == nil then return nil end
  local self = {0}
  local c = SkipWhiteSpace(self,s)
  if c == 123 or c == 91 then
      return peekTable[c](self, s)
  else
    local result = {}
    while c do
      result[readKey(self, s, c)] = peekTable[SkipWhiteSpace(self, s)](self, s)
      c = SkipWhiteSpace(self, s)
    end
    return result
  end
end

-- build dispatch table
do
  for i = 0, 255 do
    peekTable[i] = error_input
  end

  peekTable[123] = function(self, s) -- {
      -- parse object
      local result = tablenew(0, 2)
      local c = SkipWhiteSpace(self, s)
      while c ~= 125 do -- }
        result[readKey(self, s, c)] = peekTable[SkipWhiteSpace(self, s)](self, s)
        c = SkipWhiteSpace(self, s)
      end
      return result
    end
  peekTable[116] = function(self, s) -- t
      local i = self[1]
      if byte(s, i+1) == 114 and byte(s, i+2) == 117 and byte(s, i+3) == 101 then -- rue
        self[1] = i + 3
        return true
      else
        jsonError('Error reading value: true', s, self[1])
      end
    end
  peekTable[110] = function(self, s) -- n
      local i = self[1]
      if byte(s, i+1) == 117 and byte(s, i+2) == 108 and byte(s, i+3) == 108 then -- ull
        self[1] = i + 3
        return nil
      else
        jsonError('Error reading value: null', s, self[1])
      end
    end
  peekTable[102] = function(self, s) -- f
      local i = self[1]
      if byte(s, i+1) == 97 and byte(s, i+2) == 108 and byte(s, i+3) == 115 and byte(s, i+4) == 101 then -- alse
        self[1] = i + 4
        return false
      else
        jsonError('Error reading value: false', s, self[1])
      end
    end
  peekTable[91] = function(self, s) -- [
      -- Read Array
      local result = tablenew(2, 0)
      local tidx = 1
      local c = SkipWhiteSpace(self, s)
      while c ~= 93 do -- ]
        result[tidx] = peekTable[c](self, s)
        tidx = tidx + 1
        c = SkipWhiteSpace(self, s)
      end
      return result
    end
  peekTable[48] = parseNumber -- 0
  peekTable[49] = parseNumber -- 1
  peekTable[50] = parseNumber -- 2
  peekTable[51] = parseNumber -- 3
  peekTable[52] = parseNumber -- 4
  peekTable[53] = parseNumber -- 5
  peekTable[54] = parseNumber -- 6
  peekTable[55] = parseNumber -- 7
  peekTable[56] = parseNumber -- 8
  peekTable[57] = parseNumber -- 9
  peekTable[43] = parseNumber -- +
  peekTable[45] = parseNumber -- -
  peekTable[34] = readString  -- "
end

-- public interface
M.decode = decode
return M
