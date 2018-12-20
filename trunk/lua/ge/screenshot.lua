-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local uploadQueue = nil

local screenshotPath = 'screenshots/'
local media_url = 'http://media.beamng.com/'
local defaultFormat = 'jpg' -- case sensitive, look at the c++ source
local uploadCounter = 0

local function nop()
end

local function uploadScreenshot(filename, filepath, batchTag)
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
      file_contents..'\r\n'

  -- add metaData to the POST
  local metaData = {
    versionb = beamng_versionb,
    versiond = beamng_versiond,
    windowtitle = beamng_windowtitle,
    buildtype = beamng_buildtype,
    buildinfo = beamng_buildinfo,
    arch = beamng_arch,
    buildnumber = beamng_buildnumber,
    shipping_build = shipping_build,
  }
  metaData.level = getMissionFilename()
  if extensions.core_gamestate.state.state then
    metaData.gameState = extensions.core_gamestate.state.state
  end

  if Steam and Steam.isWorking and Steam.accountID ~= 0 then
    metaData.steamIDHash = tostring(hashStringSHA1(Steam.getAccountIDStr()))
    metaData.steamPlayerName = Steam.playerName
  end

  local pos = getCameraPosition()
  local rot = getCameraQuat()
  if pos.x ~= 0 or pos.y ~=0 or pos.z ~= 0 then
    metaData.cameraPos = {pos.x, pos.y, pos.z}
    metaData.cameraRot = {rot.x, rot.y, rot.z, rot.w}
  end

  extensions.hook('onUploadScreenshot', metaData)

  reqbody = reqbody ..
  '--'..boundary..'\r\n'..
  'Content-Disposition: form-data; name="metaData"\r\n\r\n'..
  jsonEncode(metaData) ..'\r\n'
  -- metaData done

  -- any shared account present?
  --local adminTag = nil
  --if Steam and Steam.isWorking and Steam.accountID ~= 0 then
  --  adminTag = tostring(hashStringSHA1(Steam.getAccountIDStr()))
  --end
  --if adminTag then
  --  reqbody = reqbody ..
  --    '--'..boundary..'\r\n'..
  --    'Content-Disposition: form-data; name="a"\r\n\r\n'..
  --    adminTag ..'\r\n'
  --end

  -- complete the message
  reqbody = reqbody ..  '--'..boundary..'--\r\n'

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
      --dump(response)
      --local uri = media_url..response.tag..'/'..filename
      local url = response.adminURLQuick
      openWebBrowser(url)
      setClipboard(response.url)
      return true
    end
  end
  return true
end

M.updateGFX = nop
local function updateGFX()
  if uploadQueue == nil then return end
  uploadCounter = uploadCounter - 1

  if uploadScreenshot(uploadQueue[1], uploadQueue[2], uploadQueue[3]) or uploadCounter <= 0 then
    uploadQueue = nil
    M.updateGFX = nop
  end
end

local function doScreenshot(batchTag)
  -- find the next available screenshot filename
  if uploadQueue ~= nil then return end
  local counter = 0

  local format = defaultFormat
  if tonumber(TorqueScript.eval('return ConsoleDlg.isAwake();')) == 1 then
    -- with jpeg, the console is not readable ...
    format = 'png'
  end

  local filename = ''
  local filename_without_ext = ''
  local filepath = ''
  local screenPath = screenshotPath .. tostring(getScreenShotFolderString())
  if not FS:directoryExists(screenPath) then
    FS:directoryCreate(screenPath)
  end
  repeat
    filename_without_ext = 'screenshot_' .. tostring(getScreenShotDateTimeString())
    if counter > 0 then
      filename_without_ext = filename_without_ext .. '_' .. tostring(counter)
    end
    filename = filename_without_ext .. '.' ..format
    filepath = screenPath .. '/' .. filename
    counter = counter + 1
  until not FS:fileExists(filepath)
  createScreenshot(screenPath .. '/' .. filename_without_ext, format, 1, 0)
  uploadQueue = {filename, filepath, batchTag}
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