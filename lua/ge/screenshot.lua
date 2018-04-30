-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local uploadQueue = nil

local screenshotPath = 'screenshots/'
local media_url = 'http://media.beamng.com/'
local format = 'jpg' -- case sensitive, look at the c++ source
local uploadCounter = 0

local function nop()
end

local function uploadScreenshot(filename, batchTag)
  local filepath = screenshotPath .. filename
  local f = io.open(filepath, "rb")
  if f == nil then
    -- screenshot will not exist for some frames when it is created
    --log('E', 'screenshot', "screenshot not existing: " .. tostring(filepath));
    return false
  end
  log('D', 'screenshot', "uploading screenshot: " .. tostring(filename));
  local file_contents = f:read("*all")
  f:close()

  local http = require "socket.http"
  local ltn12 = require "ltn12"
  local boundary = "----LuaSocketFormBoundary1n0Akh2QVfS8vm6B9U"
  local reqbody =
      '--'..boundary..'\r\n'..
      'Content-Disposition: form-data; name="source"\r\n\r\n'..
      'ingame\r\n'

  if batchTag then
    reqbody = reqbody ..
      '--'..boundary..'\r\n'..
      'Content-Disposition: form-data; name="t"\r\n\r\n'..
      batchTag ..'\r\n'
  end

  reqbody = reqbody ..
      '--'..boundary..'\r\n'..
      'Content-Disposition: form-data; name="file"; filename='..filename..'\r\n'..
      'Content-type: image/png\r\n\r\n'..
      file_contents..'\r\n'..
      '--'..boundary..'--\r\n'

  local respbody = {}

  local body_exist, code, headers, status = http.request {
    method = "POST",
    url = media_url .. "/s4/u/",
    source = ltn12.source.string(reqbody),
    headers = {
      ["Content-Type"] = "multipart/form-data; boundary="..boundary,
      ["Content-Length"] = #reqbody,
    },
    sink = ltn12.sink.table(respbody)
  }

  if tonumber(code) ~= 200 then
    log('E', 'screenshot', "error uploading screenshot: " .. tostring(filename));
    log('E', 'screenshot', 'body:' .. dumps(respbody))
    log('E', 'screenshot', 'code:' .. tostring(code))
    log('E', 'screenshot', 'headers:' .. dumps(headers))
    log('E', 'screenshot', 'status:' .. tostring(status))
    return true
  end

  if tonumber(body_exist) == 1 and tonumber(code) == 200 and #respbody > 0 then
    log('D', 'screenshot', "screenshot uploaded successfully: " .. tostring(filename));
    local state, response = pcall(json.decode, respbody[1])
    if state and response.ok == 1 then
      local uri = media_url..response.tag..'/'..filename
      openWebBrowser(uri)
      setClipboard(uri)
      return true
    end
  end
  return true
end

M.updateGFX = nop
local function updateGFX()
  if uploadQueue == nil then return end
  uploadCounter = uploadCounter - 1

  if uploadScreenshot(uploadQueue[1], uploadQueue[2]) or uploadCounter <= 0 then
    uploadQueue = nil
    M.updateGFX = nop
  end
end

local function doScreenshot(batchTag)
  -- find the next available screenshot filename
  if uploadQueue ~= nil then return end
  local counter = 0
  local filename = ''
  local filename_without_ext = ''
  local filepath = ''
  repeat
    filename_without_ext = string.format('screenshot_%05d', counter)
    filename = filename_without_ext .. '.' ..format
    filepath = screenshotPath .. filename
    counter = counter + 1
  until not FS:fileExists(filepath)
  createScreenshot(screenshotPath .. filename_without_ext, format, 1, 0)
  uploadQueue = {filename, batchTag}
  M.updateGFX = updateGFX
  uploadCounter = 50
end

local function publish(batchTag)
  if settings.getValue('onlineFeatures') ~= 'enable' then
    log('E', 'screenshot.publish', 'screenshot publishing disabled because online features are disabled')
    return
  end
  doScreenshot(batchTag)
end

local function doSteamScreenshot()
  if settings.getValue('onlineFeatures') ~= 'enable' then
    log('E', 'screenshot.publish', 'screenshot publishing disabled because online features are disabled')
    return
  end
  Steam.triggerScreenshot()
end

-- public interface
M.publish = publish
M.doSteamScreenshot = doSteamScreenshot

return M