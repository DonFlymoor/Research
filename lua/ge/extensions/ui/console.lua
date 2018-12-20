-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local im = ui_imgui
local ffi = require('ffi')

local windowOpen = im.BoolPtr(false)
local console_log_buffer = {}
local consoleInputField = ffi.new("char[4096]", "")
local initialWindowSize = im.ImVec2(800, 600)

local inputCallbackC = nil
local comboCurrentItem = im.IntPtr(0)

local historyFilename = cachepath .. 'ConsoleEntryHistory.json'
local history = {}
local historyPos = 1

local function inputCallback(data)
  --log('E', 'console', '>>> inputCallback 1 - ' .. dumps(data) .. ' / ' .. tostring(#history))
  if data.EventFlag == im.ImGuiInputTextFlags('ImGuiInputTextFlags_CallbackHistory') then
    local prevHistoryPos = historyPos
    if data.EventKey == im.ImGuiKey('ImGuiKey_UpArrow') then
      --print("UP")
      historyPos = historyPos - 1
      if historyPos == 0 then historyPos = #history end
    elseif data.EventKey == im.ImGuiKey('ImGuiKey_DownArrow') then
      --print("DOWN")
      historyPos = historyPos + 1
      if historyPos > #history then historyPos = 1 end
    end

    if #history > 0 and prevHistoryPos ~= historyPos then
      local t = history[historyPos]
      local inplen = string.len(t)
      local inplenInt = im.Int(inplen)
      print("new text: " .. tostring(t) .. ', len = ' .. tostring(inplen))
      ffi.copy(data.Buf, t, math.max(data.BufSize, inplen))
      --data.Buf = ffi.string(t, math.max(data.BufSize, inplen))
      data.CursorPos = inplenInt
      data.SelectionStart = inplenInt
      data.SelectionEnd = inplenInt
      data.BufTextLen = inplenInt
      data.BufDirty = im.Bool(true);
    end

  end
  return im.Int(0)
end

local function shiftTableEntry(t, old, new)
  local value = t[old]
  if new < old then
     table.move(t, new, old - 1, new + 1)
  else
     table.move(t, old + 1, new, old)
  end
  t[new] = value
end

local function onUpdate()
  if windowOpen[0] ~= true then return end

  im.SetNextWindowSize(initialWindowSize, im.Cond_FirstUseEver)

  if im.Begin("Console", windowOpen, 0) then
    im.BeginChild1("result", im.ImVec2(0, -im.GetTextLineHeight() * 2))
      for _, le in ipairs(console_log_buffer) do
        if le[1] == 'i' then
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.8, 0.8, 0.8, 1))
        elseif le[1] == 'r' then
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 1, 0.5, 1))
        elseif le[1] == 'o' then
          im.PushStyleColor2(im.Col_Text, im.ImVec4(0.5, 0.5, 1, 1))
        else
          im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 1, 1, 1))
        end
        im.TextUnformatted(le[2])
        im.PopStyleColor()
      end
      im.SetScrollHere(1) -- scroll to the bottom always
    im.EndChild()
    local flags = 0
    flags = im.flags(flags, im.ImGuiInputTextFlags('ImGuiInputTextFlags_EnterReturnsTrue'))
    -- FIXME:
    flags = im.flags(flags, im.ImGuiInputTextFlags('ImGuiInputTextFlags_CallbackCompletion'))
    flags = im.flags(flags, im.ImGuiInputTextFlags('ImGuiInputTextFlags_CallbackHistory'))

    im.PushItemWidth(100)
    if im.Combo2("", comboCurrentItem, "GE - Lua\0GE - TorqueScript\0CEF/UI - JS\0BeamNG - Vehicle Lua\0\0") then
      print("context changed")
    end
    im.SameLine()

    im.PushItemWidth(im.GetContentRegionAvailWidth() - 70)
    local exec = im.InputText("", consoleInputField, ffi.sizeof(consoleInputField), flags, inputCallbackC)


    im.SameLine()
    im.PushItemWidth(40)
    exec = exec or im.SmallButton("execute")
    if exec then
      local cmd = ffi.string(consoleInputField)
      if string.len(cmd) > 0 then

        print("> history 1 = " .. dumps(history))
        if history[historyPos] ~= cmd then
          table.insert(history, cmd)
        else
          -- move element to the end
          shiftTableEntry(history, historyPos, #history)
        end
        print("> history 2 = " .. dumps(history))
        historyPos = 1

        --print(" CMD = " .. tostring(cmd))
        table.insert(console_log_buffer, {'i', "> " .. tostring(cmd)})
        local res, out = executeLuaSandboxed(cmd, 'VEConsole')
        --print(" RES = " .. tostring(res))
        --print(" OUT = " .. dumps(out))
        if res then
          table.insert(console_log_buffer, {'r', tostring(res)})
        end
        if out and #out > 0 then
          for _, le in ipairs(out) do
            table.insert(console_log_buffer, {'o', tostring(le)})
          end
        end
        ffi.fill(consoleInputField, ffi.sizeof(consoleInputField))

        jsonWriteFile(historyFilename, history, true)

        --im.SetItemDefaultFocus()
        --im.SetKeyboardFocusHere(-1)
      end
    end
  end

  im.End()
end




local function onSerialize()
  return {
    windowOpen = windowOpen[0],
  }
end

local function onDeserialized(data)
  windowOpen[0] = data.windowOpen
end

local function open()
  windowOpen[0] = true
end


local function onExtensionLoaded()
  log('E', 'console', 'onExtensionLoaded')
  -- see http://luajit.org/ext_ffi_semantics.html#callback
  inputCallbackC = ffi.cast("ImGuiTextEditCallback", inputCallback)
  log('E', 'console', 'inputCallbackC = ' .. tostring(inputCallbackC))
  history = jsonReadFile(historyFilename) or {}
  log('E', 'console', 'history = ' .. dumps(history))
end

local function onExtensionUnloaded()
  if inputCallbackC then
    inputCallbackC:free()
  end
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onUpdate = onUpdate
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized

M.open = open
return M