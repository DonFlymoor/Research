-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.menuEntry = 'PowerTrain'
local imguiUtils = require('ui/imguiUtils')
local pwUtils =extensions.vehicleEditor_vePowerTrainUtils
local im = extensions.ui_imgui
local initialWindowSize = im.ImVec2(800, 800)
local nextWindowPos = im.ImVec2(100, 100)
--local pw = require('powertrain')
local curState = {}
curState.toggleButton = ffi.new("bool[1]", false)
curState.selectedDeviceId = 0

local windowOpen = im.BoolPtr(false)
local deviceFilter = ffi.new('ImGuiTextFilter[1]')

local function findPowertrain()
  local deviceId = curState.selectedDeviceId
  if im.TreeNodeEx1("find device by name##devicenamefilter",im.TreeNodeFlags_DefaultOpen) then
    local filterchanged = false
    if im.ImGuiTextFilter_Draw(deviceFilter, "filter") then
      filterchanged = true
      deviceId = nil
    end
    im.BeginChild1("##nodefilterresults1", im.ImVec2(0, 200))
    im.BeginColumns("nodefiltertable1", 3, im.ColumnsFlags_NoResize)
    im.SetColumnWidth(0, 200)
    im.SetColumnWidth(1, 50)
    im.SetColumnWidth(2, 50)
    im.Separator()
    im.Text('Name')
    im.NextColumn()
    im.Text('Id')
    im.NextColumn()
    -- button column
    im.NextColumn()
    im.Separator()
    im.Separator()

    for lpid = 0, #v.data.powertrain - 1 do
      local device = v.data.powertrain[lpid]
      if device.name and im.ImGuiTextFilter_PassFilter(deviceFilter, device.name) then
        if (filterchanged and not deviceId) or deviceId == device.cid then
          deviceId = device.cid
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
        else
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.6, 0.6, 0.6, 1))
        end
        im.Text(tostring(device.name))
        im.NextColumn()
        im.Text(tostring(device.cid))
        im.NextColumn()
        if im.SmallButton('sel##nodeselect'..tostring(device.cid)) then
          deviceId = device.cid
        end
        im.PopStyleColor()
        im.NextColumn()
      end
    end
    im.EndColumns()
    im.EndChild()

    if (deviceId and deviceId >= 0 and deviceId < #v.data.powertrain) then
      curState.selectedDeviceId = deviceId
      im.Separator()
      pwUtils.showJbeamData(curState.selectedDeviceId)
      pwUtils.showLiveData(curState.selectedDeviceId)
      im.Text('                                            ')
      if im.Button("Live data(All Devices)") then
        curState.toggleButton[0] = not curState.toggleButton[0]
        im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)
        im.SetNextWindowPos(nextWindowPos, im.Cond_FirstUseEver)
      end
      if curState.toggleButton[0] then
        if im.Begin("Powertrain Live Data##powertrain",ffi.new("bool[1]", false),0) then
          pwUtils.displayLivedata()
        end
        im.End()
      end
    end
    im.TreePop()
  end
end
local function onDebugDraw(dt)
  if windowOpen[0] ~= true then return end
  if im.Begin("PowerTrain", windowOpen) then
    --[[for _,d in pairs(pw.getDevices()) do
      if im.CollapsingHeader1(d.name) then
        imguiUtils.addRecursiveTreeTable(d, '', false)
      end
    end--]]
    findPowertrain()
  end
  im.End()
end

local function onSerialize()
  return {
    windowOpen = windowOpen[0],
    toggleButton = curState.toggleButton[0],
    selectedDeviceId = curState.selectedDeviceId
  }
end

local function onDeserialized(data)
  windowOpen[0] = data.windowOpen
  curState.toggleButton[0] = data.toggleButton
  curState.selectedDeviceId = data.selectedDeviceId
end

local function open()
  windowOpen[0] = true
end

local function onExtensionLoaded()
end

local function onExtensionUnloaded()
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.onDebugDraw = onDebugDraw

M.open = open

return M