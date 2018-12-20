-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local json = require('json')


local reruns = 6 -- how often to reparse the json
local debug = false -- true

local hp = HighPerfTimer()

-- finding files
local filenames = FS:findFilesByPattern('/vehicles', '*.jbeam', -1, false, false)
print(' * Finding all ' .. tostring(#filenames) .. ' json files took ' ..  string.format('%0.3f', hp:stopAndReset()) .. 's')

-- reading into memory
local fileContent = {}
local totalSize = 0
for _, filename in pairs(filenames) do
  fileContent[filename] = readFile(filename)
  totalSize = totalSize + string.len(fileContent[filename])
  --print(' * ' ..tostring(filename))
end

local t = hp:stopAndReset()
print(' * Reading into memory took ' .. string.format('%0.3f', t) .. 's. Size: ' .. string.format('%0.3f', (totalSize) /1000/1000 ) .. ' MB. Performance: ' .. string.format('%0.3f', (totalSize / t) /1000/1000 ) .. ' MB/s')

-- parsing
local function test()
  for i= 1, reruns do
    for filename, content in pairs(fileContent) do
      --print(' * ' ..tostring(filename))
      local state, data = pcall(json.decode, content)
    end
  end
  local totalSizeReruns = totalSize * reruns
  t = hp:stop()
  print(' * Parsing (' .. tostring(reruns) .. 'x = '.. string.format('%0.3f', totalSizeReruns /1000000 ) .. ' MB) took ' .. string.format('%0.3f', t) .. 's. Performance: ' .. string.format('%0.3f', (totalSizeReruns/1000000) / t  ) .. ' MB/s')
end

test()
require('jit').off()
print(" == JIT off ==")
test()