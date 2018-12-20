-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

--local jsonEncodeFull = require('libs/lunajson/lunajson').encode() -- slow but conform encoder

local replicationURL = 'ws://replicator/s1/v1/ws'

local ws_client

local copas = require('libs/copas/copas')

local function receive_data_job(job)
  while true do
    local data_raw = ws_client:receive()
    if not data_raw then
      return
    end
    --print('< ' .. tostring(data_raw))
    local data = json.decode(data_raw)
    if not data or #data < 3 then
      log('E', 'replication', 'replication data error: ' .. dumps(data))
      goto continue
    end
    --dump(data)

    if data[1] == 'f' then
      local obj = Sim.findObjectByPersistID(data[2])
      if obj then
        SimObject.replicating = true
        obj:setField(data[3], "", data[4])
        SimObject.replicating = false
      end

    end
    ::continue::
  end
  print('coroutine done')
end

local function connect()
  extensions.core_jobsystem.create(function ()
    ws_client = require('libs/lua-websockets/websocket').client.copas()
    print(' connecting to ' .. tostring(replicationURL))
    ws_client:connect(replicationURL)
    print(' .. done!')

    extensions.core_jobsystem.create(receive_data_job)

    local d = {'join'}
    ws_client:send(jsonEncode(d))

    SimObject.replicationEnabled = true
  end)
end

-- called by C++
local function onChange(action, objName, objPID, arg1, arg2)
  if objName == 'thePlayer' then return end
  --print('onChange: ' .. tostring(action) .. ', ' .. tostring(objName) .. ', ' .. tostring(objPID) .. ', ' .. tostring(arg1) .. ' = ' .. tostring(arg2))
  coroutine.resume(coroutine.create(function ()
    local d = {action, objPID, arg1, arg2 }
    ws_client:send(jsonEncode(d))
  end))
end

local function onUpdate()
  copas.step(0) -- pump data
end

M.onUpdate = onUpdate
M.connect = connect
M.onChange = onChange

return M
