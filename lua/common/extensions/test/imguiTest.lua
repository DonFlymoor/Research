-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local ffi = require('ffi')

local M = {}

local logTag = "imguiTest"

local window_open = ffi.new("bool[1]", false)

local imgui_size_t = ffi.new("size_t")

local imgui_true = ffi.new("bool", true)
local imgui_false = ffi.new("bool", false)

local imgui_true_ptr = ffi.new("bool[1]", true)

local buf = ffi.new("char[256]", "Hello World")
local buf_size = ffi.new("uint64_t", 64)

local inputField = ffi.new("char[256]", "Hello World")
local checkbox = ffi.new("bool[1]", false)

local fl = ffi.new("float[1]", 5.0)

local debug = 1

-- test
local c = ffi.new("int", 1)
local d = ffi.new("int", 2)
local e = 0

local imgui_scrollbarLayoutVertical = core_imgui.ImGuiLayoutType("ImGuiLayoutType_Vertical")
local imgui_scrollbarLayoutHorizontal = core_imgui.ImGuiLayoutType("ImGuiLayoutType_Horizontal")

local imgui_windowFlag_MenuBar = core_imgui.ImGuiWindowFlags("ImGuiWindowFlags_MenuBar")
local imgui_inputTextFlag_CharsDecimal = core_imgui.ImGuiInputTextFlags("ImGuiInputTextFlags_CharsDecimal")
local btnSize = core_imgui.ImVec2Ptr(60, 20)

local function onUpdate()

  if debug == 1 then
    print("imgui.lua:onUpdate()")
    debug = 0
  end

  --MAIN MENU
  if core_imgui.BeginMainMenuBar() then
    if core_imgui.BeginMenu("File", imgui_true) then
      if core_imgui.MenuItem("Open", nil, imgui_false, imgui_true) then
        log('I', logTag, "MainMenuBar->File->Open")
      end
      core_imgui.EndMenu()
    end

    if core_imgui.BeginMenu("Edit", imgui_true) then
      if core_imgui.MenuItem("Undo", "Ctrl+Z", imgui_false, imgui_true) then
        log('I', logTag, "MainMenuBar->Edit->Undo")
      end
      core_imgui.EndMenu()
    end

    core_imgui.EndMainMenuBar()
  end

  --TEST WINDOW
  core_imgui.Begin("test-window", window_open, imgui_windowFlag_MenuBar)

  if core_imgui.BeginMenuBar() then

    if core_imgui.BeginMenu("Menu", imgui_true) then
      if core_imgui.MenuItem("Item", nil, imgui_false, imgui_true) then
        log('I', logTag, "Window->Menu->Item")
      end
      core_imgui.EndMenu()
    end

    core_imgui.EndMenuBar()
  end

  core_imgui.InputText("Input Text", inputField, ffi.sizeof(inputField), imgui_inputTextFlag_CharsDecimal)

  core_imgui.Checkbox("Checkbox", checkbox)

  core_imgui.SameLine(0.0, -1.0)

  core_imgui.RadioButton("Radio", imgui_true)



  core_imgui.SliderFloat("Slider Float", fl, 0.0, 10.0, "%.3f", 1.0)

  if core_imgui.Button("Button", btnSize) then
    print("button clicked!")
    print(inputField)
    print(checkbox)
    c = c + 1
  end

  core_imgui.Scrollbar(imgui_scrollbarLayoutVertical)

  core_imgui.Text("Hello world: %s", inputField)
  core_imgui.Text("Hello world: %d - %d, %g", c, d, e)

  for i = 1, 20 do
    core_imgui.Text("Hello world")
  end

  core_imgui.End()

end

M.onUpdate = onUpdate

return M