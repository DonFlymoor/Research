-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt


-- do not use this file/extensions directly, use ui_imgui instead

-- this file needs to be in sync with imgui_api.h

local M = { ctx = nil }

local ffi = require('ffi')
ffi.cdef(readFile('lua/common/extensions/ui/imgui_api.h'))
local C = ffi.C -- shortcut to prevent lookups all the time

function M.Bool(x) return ffi.new("bool", x) end
function M.BoolPtr(x) return ffi.new("bool[1]", x) end
function M.CharPtr(x) return ffi.new("char[1]", x) end
function M.Int(x) return ffi.new("int", x) end
function M.IntPtr(x) return ffi.new("int[1]", x) end
function M.Float(x) return ffi.new("float", x) end
function M.FloatPtr(x) return ffi.new("float[1]", x) end
function M.Double(x) return ffi.new("double", x) end
function M.DoublePtr(x) return ffi.new("double[1]", x) end
function M.ArrayChar(x) return ffi.new("char[?]", x) end
function M.ArrayInt(size) return ffi.new("int[?]", size) end
function M.ArrayFloat(size) return ffi.new("float[?]", size) end
function M.ArrayImVec4(size) return ffi.new("ImVec4[?]", size) end

function M.ImVec4ToFloatPtr(imVec4) return ffi.cast("float*", imVec4) end

function M.ArrayBoolByTbl(tbl)
  local arr = ffi.new("bool[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("bool", tbl[i+1])
  end
  return arr
end

function M.ArrayBoolPtrByTbl(tbl)
  local arr = ffi.new("bool*[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("bool[1]", tbl[i+1])
  end
  return arr
end

function M.ArrayIntPtrByTbl(tbl)
  local arr = ffi.new("int*[" .. #tbl .. "]")
  for i = 0, #tbl - 1 do
    arr[i] = ffi.new("int[1]", tbl[i+1])
  end
  return arr
end

function M.ArrayFloatByTbl(tbl)
  local arr = ffi.new("float[?]", #tbl)
  for i = 1, #tbl do
    arr[i - 1] = tbl[i]
  end
  return arr
end

function M.ArrayFloatPtrByTbl(tbl)
  local arr = ffi.new("float*[" .. #tbl .. "]")
  for i = 1, #tbl do
    arr[i - 1] = ffi.new("float[1]", tbl[i])
  end
  return arr
end

function M.ImVec2(x, y)
  local res = ffi.new("ImVec2")
  res.x = x
  res.y = y
  return res
end

function M.ImVec2Ptr(x, y)
  local res = ffi.new("ImVec2[1]")
  res[0].x = x or 0
  res[0].y = y or 0
  return res
end

function M.ImVec3(x, y, z)
  local res = ffi.new("ImVec3")
  res.x = x
  res.y = y
  res.z = z
  return res
end

function M.ImVec3Ptr(x, y, z)
  local res = ffi.new("ImVec3[1]")
  res[0].x = x
  res[0].y = y
  res[0].z = z
  return res
end

function M.ImVec4(x, y, z, w)
  local res = ffi.new("ImVec4")
  res.x = x
  res.y = y
  res.z = z
  res.w = w
  return res
end

function M.ImVec4Ptr(x, y, z, w)
  local res = ffi.new("ImVec4[1]")
  res[0].x = x
  res[0].y = y
  res[0].z = z
  res[0].w = w
  return res
end

function M.ImColorByRGB(r, g, b, a)
  local res = ffi.new("ImColor")
  local sc = 1/255
  res.Value = M.ImVec4(r * sc, g * sc, b * sc, a * sc or 1)
  return res
end

-- ImTextureHandler helper code for constructor
local ImTextureHandler_mt = {
  __gc = function(hnd) C.ImTextureHandler_set(hnd, '') end,
  getID = function(hnd) return C.ImTextureHandler_get(hnd) end,
  setID = function(hnd, path) return C.ImTextureHandler_set(hnd, path) end,
  getSize = function(hnd) local vec2 = M.ImVec2(0, 0) C.ImTextureHandler_size(hnd, vec2) return vec2 end,
}
ImTextureHandler_mt.__index = ImTextureHandler_mt

local ImTextureHandler_constructor = ffi.metatype("ImTextureHandler", ImTextureHandler_mt)

function M.ImTextureHandler(path)
  local res = ImTextureHandler_constructor()
  C.ImTextureHandler_set(res, path)
  return res
end

-- HELPER
function M.ArraySize(arr) return ffi.sizeof(arr) / ffi.sizeof(arr[0]) end
function M.GetLengthArrayBool(array) return ffi.sizeof(array) / ffi.sizeof("bool") end
function M.GetLengthArrayFloat(array) return ffi.sizeof(array) / ffi.sizeof("float") end
function M.GetLengthArrayInt(array) return ffi.sizeof(array) / ffi.sizeof("int") end
function M.GetLengthArrayCharPtr(array) return (ffi.sizeof(array) / ffi.sizeof("char*")) - 1 end
function M.GetLengthArrayImVec4(array) return ffi.sizeof(array) / ffi.sizeof("ImVec4") end
function M.ArrayCharPtrByTbl(tbl) return ffi.new("const char*[".. #tbl + 1 .."]", tbl) end

-- WRAPPER
-- Context creation and access
function M.GetMainContext() return C.ImGui_GetMainContext() end
-- Main
function M.CreateIO() return C.imgui_CreateIO(M.ctx) end
function M.GetIO(p_open) C.imgui_GetIO(M.ctx, p_open or nil) end
function M.SetStyle(style) C.imgui_SetStyle(M.ctx, style) end
function M.GetStyle(p_open) C.imgui_GetStyle(M.ctx, p_open or nil) end

-- Demo, Debug, Information
function M.ShowDemoWindow(p_open) C.imgui_ShowDemoWindow(M.ctx, p_open or nil) end
function M.ShowMetricsWindow(p_open) C.imgui_ShowMetricsWindow(M.ctx, p_open or nil) end
function M.ShowStyleEditor(ref) C.imgui_ShowStyleEditor(M.ctx, ref or nil) end
function M.ShowStyleSelector(label) return C.imgui_ShowStyleSelector(M.ctx, label) end
function M.ShowFontSelector(label) C.imgui_ShowFontSelector(M.ctx, label) end
function M.ShowUserGuide() C.imgui_ShowUserGuide(M.ctx) end
function M.GetVersion() return C.imgui_GetVersion() end

-- Style
function M.StyleColorsDark(dst) C.imgui_StyleColorsDark(M.ctx, dst) end
function M.StyleColorsClassic(dst) C.imgui_StyleColorsClassic(M.ctx, dst) end
function M.StyleColorsLight(dst) C.imgui_StyleColorsLight(M.ctx, dst) end

-- Windows
function M.Begin(name, p_open, flags) return C.imgui_Begin(M.ctx, name, p_open, flags or 0) end
function M.End() return C.imgui_End(M.ctx) end
function M.BeginChild1(str_id, size, border, flags) return C.imgui_BeginChild1(M.ctx, str_id, size or M.ImVec2(0,0), border or false, flags or 0) end
function M.BeginChild2(id, size, border, flags) return C.imgui_BeginChild2(M.ctx, id, size or M.ImVec2(0,0), border or false, flags or 0) end
function M.EndChild() C.imgui_EndChild(M.ctx) end

-- Windows: Utilities
function M.IsWindowAppearing() return C.imgui_IsWindowAppearing(M.ctx) end
function M.IsWindowCollapsed() return C.imgui_IsWindowCollapsed(M.ctx) end
function M.IsWindowFocused(flags) return C.imgui_IsWindowFocused(M.ctx, flags or 0) end
function M.IsWindowHovered(flags) return C.imgui_IsWindowHovered(M.ctx, flags or 0) end
function M.GetWindowDrawList() return C.imgui_GetWindowDrawList(M.ctx) end
function M.GetWindowPos(res) C.imgui_GetWindowPos(M.ctx, res) end
function M.GetWindowSize(res) C.imgui_GetWindowSize(M.ctx, res) end
function M.GetWindowWidth() return C.imgui_GetWindowWidth(M.ctx) end
function M.GetWindowHeight() return C.imgui_GetWindowHeight(M.ctx) end
function M.GetContentRegionMax(res) C.imgui_GetContentRegionMax(M.ctx, res) end
function M.GetContentRegionAvail(res) C.imgui_GetContentRegionAvail(M.ctx, res) end
function M.GetContentRegionAvailWidth() return C.imgui_GetContentRegionAvailWidth(M.ctx) end
function M.GetWindowContentRegionMin(res) C.imgui_GetWindowContentRegionMin(M.ctx, res) end
function M.GetWindowContentRegionMax() C.imgui_GetWindowContentRegionMax(M.ctx, res) end
function M.GetWindowContentRegionWidth() return C.imgui_GetWindowContentRegionWidth(M.ctx) end

function M.SetNextWindowPos(pos, cond, pivot) C.imgui_SetNextWindowPos(M.ctx, pos, cond or 0, pivot or M.ImVec2(0,0)) end
function M.SetNextWindowSize(pos, cond) C.imgui_SetNextWindowSize(M.ctx, pos, cond or 0) end
function M.SetNextWindowSizeConstraints(size_min, size_max, custom_callback, custom_callback_data) C.imgui_SetNextWindowSizeConstraints(M.ctx, size_min, size_max, custom_callback or nil, custom_callback_data or nil) end
function M.SetNextWindowContentSize(size) C.imgui_SetNextWindowContentSize(M.ctx, size) end

function M.SetNextWindowCollapsed(collapsed, cond) C.imgui_SetNextWindowCollapsed(M.ctx, collapsed, cond or 0) end
function M.SetNextWindowFocus() C.imgui_SetNextWindowFocus(M.ctx) end
function M.SetNextWindowBgAlpha(alpha) C.imgui_SetNextWindowBgAlpha(M.ctx, alpha) end
function M.SetWindowPos1(pos, cond) C.imgui_SetWindowPos1(M.ctx, pos, cond or 0) end
function M.SetWindowSize1(size, cond) C.imgui_SetWindowSize1(M.ctx, size, cond or 0) end
function M.SetWindowCollapsed1(collapsed, cond) C.imgui_SetWindowCollapsed1(M.ctx, collapsed, cond or 0) end
function M.SetWindowFocus1() C.imgui_SetWindowFocus1(M.ctx) end
function M.SetWindowFontScale(scale) C.imgui_SetWindowFontScale(M.ctx, scale) end
function M.SetWindowPos2(name, pos, cond ) C.imgui_SetWindowPos2(M.ctx, name, pos, cond or 0) end
function M.SetWindowSize2(name, size, cond) C.imgui_SetWindowSize2(M.ctx, name, size, cond or 0) end
function M.SetWindowCollapsed2(name, collapsed, cond) C.imgui_SetWindowCollapsed2(M.ctx, name, collapsed, cond or 0) end
function M.SetWindowFocus2(name) C.imgui_SetWindowFocus2(M.ctx, name) end

-- Windows Scrolling
function M.GetScrollX() return C.imgui_GetScrollX(M.ctx) end
function M.GetScrollY() return C.imgui_GetScrollY(M.ctx) end
function M.GetScrollMaxX() return C.imgui_GetScrollMaxX(M.ctx) end
function M.GetScrollMaxY() return C.imgui_GetScrollMaxY(M.ctx) end
function M.SetScrollX(scroll_x) C.imgui_SetScrollX(M.ctx, scroll_x) end
function M.SetScrollY(scroll_y) C.imgui_SetScrollY(M.ctx, scroll_y) end
function M.SetScrollHere(center_y_ratio) C.imgui_SetScrollHere(M.ctx, center_y_ratio or 0.5) end
function M.SetScrollFromPosY(pos_y, center_y_ratio) C.imgui_SetScrollFromPosY(M.ctx, pos_y, center_y_ratio or 0.5) end

-- Parameters stacks (shared)
function M.PushFont(font) C.imgui_PushFont(M.ctx, font) end
function M.PopFont() C.imgui_PopFont(M.ctx) end
function M.PushStyleColor1(idx, col) C.imgui_PushStyleColor1(M.ctx, idx, col) end
function M.PushStyleColor2(idx, col) C.imgui_PushStyleColor2(M.ctx, idx, col) end
function M.PopStyleColor(count) C.imgui_PopStyleColor(M.ctx, count or 1) end
function M.PushStyleVar1(idx, val) C.imgui_PushStyleVar1(M.ctx, idx, val) end
function M.PushStyleVar2(idx, val) C.imgui_PushStyleVar2(M.ctx, idx, val) end
function M.PopStyleVar(count) C.imgui_PopStyleVar(M.ctx, count or 1) end
function M.GetStyleColorVec4(idx) return C.imgui_GetStyleColorVec4(M.ctx, idx) end
function M.GetFont() return C.imgui_GetFont(M.ctx) end
function M.GetFontSize() return C.imgui_GetFontSize(M.ctx) end
function M.GetFontTexUvWhitePixel(res) C.imgui_GetFontTexUvWhitePixel(M.ctx, res) end
function M.GetColorU321(idx, alpha_mul) return C.imgui_GetColorU321(M.ctx, idx, alpha_mul or 1) end
function M.GetColorU322(col) return C.imgui_GetColorU322(M.ctx, col) end
function M.GetColorU323(col) return C.imgui_GetColorU323(M.ctx, col) end

-- Parameters stacks (current window)
function M.PushItemWidth(item_width) C.imgui_PushItemWidth(M.ctx, item_width) end
function M.PopItemWidth() C.imgui_PopItemWidth(M.ctx) end
function M.CalcItemWidth() return C.imgui_CalcItemWidth(M.ctx) end
function M.PushTextWrapPos(wrap_pos_x) C.imgui_PushTextWrapPos(M.ctx, wrap_pos_x or 0) end
function M.PopTextWrapPos() C.imgui_PopTextWrapPos(M.ctx) end
function M.PushAllowKeyboardFocus(allow_keyboard_focus) C.imgui_PushAllowKeyboardFocus(M.ctx, allow_keyboard_focus) end
function M.PopAllowKeyboardFocus() C.imgui_PopAllowKeyboardFocus(M.ctx) end
function M.PushButtonRepeat(repeated) C.imgui_PushButtonRepeat(M.ctx, repeated) end
function M.PopButtonRepeat() C.imgui_PopButtonRepeat(M.ctx) end

-- Cursor / Layout
function M.Separator() C.imgui_Separator(M.ctx) end
function M.SameLine(pos_x, spacing_w) C.imgui_SameLine(M.ctx, pos_x or 0, spacing_w or -1) end
function M.NewLine() C.imgui_NewLine(M.ctx) end
function M.Spacing() C.imgui_Spacing(M.ctx) end
function M.Dummy(size) C.imgui_Dummy(M.ctx, size) end
function M.Indent(indent_w) C.imgui_Indent(M.ctx, indent_w or 0) end
function M.Unindent(indent_w) C.imgui_Unindent(M.ctx, indent_w or 0) end
function M.BeginGroup() C.imgui_BeginGroup(M.ctx) end
function M.EndGroup() C.imgui_EndGroup(M.ctx) end
function M.GetCursorPos(res) C.imgui_GetCursorPos(M.ctx, res) end
function M.GetCursorPosX() return C.imgui_GetCursorPosX(M.ctx) end
function M.GetCursorPosY() return C.imgui_GetCursorPosY(M.ctx) end
function M.SetCursorPos(local_pos) C.imgui_SetCursorPos(M.ctx, local_pos) end
function M.SetCursorPosX(x) C.imgui_SetCursorPosX(M.ctx, x) end
function M.SetCursorPosY(y) C.imgui_SetCursorPosY(M.ctx, y) end
function M.GetCursorStartPos(res) C.imgui_GetCursorStartPos(M.ctx, res) end
function M.GetCursorScreenPos(res) C.imgui_GetCursorScreenPos(M.ctx, res) end
function M.SetCursorScreenPos(screen_pos) return C.imgui_SetCursorScreenPos(M.ctx, screen_pos) end
function M.AlignTextToFramePadding() return C.imgui_AlignTextToFramePadding(M.ctx) end
function M.GetTextLineHeight() return C.imgui_GetTextLineHeight(M.ctx) end
function M.GetTextLineHeightWithSpacing() return C.imgui_GetTextLineHeightWithSpacing(M.ctx) end
function M.GetFrameHeight() return C.imgui_GetFrameHeight(M.ctx) end
function M.GetFrameHeightWithSpacing() return C.imgui_GetFrameHeightWithSpacing(M.ctx) end

-- ID stack/scopes
function M.PushID1(str_id) return C.imgui_PushID1(M.ctx, str_id) end
function M.PushID2(str_id_begin, str_id_end) return C.imgui_PushID2(M.ctx, str_id_begin, str_id_end) end
function M.PushID3(ptr_id) return C.imgui_PushID3(M.ctx, ptr_id) end
function M.PushID4(int_id) return C.imgui_PushID4(M.ctx, int_id) end
function M.PopID() return C.imgui_PopID(M.ctx) end
function M.GetID1(str_id) return C.imgui_GetID1(M.ctx, str_id) end
function M.GetID2(str_id_begin, str_id_end) return C.imgui_GetID2(M.ctx, str_id_begin, str_id_end) end
function M.GetID3(ptr_id) return C.imgui_GetID3(M.ctx, ptr_id) end

-- Widgets: Text
function M.TextUnformatted(text, text_end) C.imgui_TextUnformatted(M.ctx, text, text_end or nil) end
function M.Text(fmt, ...) C.imgui_Text(M.ctx, fmt, ...) end
function M.TextColored(col, fmt, ...) C.imgui_TextColored(M.ctx, col, fmt, ...) end
function M.TextDisabled(fmt, ...) C.imgui_TextDisabled(M.ctx, fmt, ...) end
function M.TextWrapped(fmt, ...) C.imgui_TextWrapped(M.ctx, fmt, ...) end
function M.LabelText(label, fmt, ...) C.imgui_LabelText(M.ctx, label, fmt, ...) end
function M.BulletText(fmt, ...) C.imgui_BulletText(M.ctx, fmt, ...) end

-- Widgets: Main
function M.Button(label, size) return C.imgui_Button(M.ctx, label, size or M.ImVec2(0,0)) end
function M.SmallButton(label) return C.imgui_SmallButton(M.ctx, label) end
function M.ArrowButton(str_id, dir) return C.imgui_ArrowButton(M.ctx, str_id, dir) end
function M.InvisibleButton(str_id, size) return C.imgui_InvisibleButton(M.ctx, str_id, size) end
function M.Image(user_texture_id, size, uv0, uv1, tint_col, border_col)
  if user_texture_id == nil then
    log('E', 'imgui', 'Wrong texture format')
    return
  end
  C.imgui_Image(M.ctx, user_texture_id, size, uv0 or M.ImVec2(0,0), uv1 or M.ImVec2(1, 1), tint_col or M.ImVec4(1,1,1,1), border_col or M.ImVec4(0,0,0,0))
end
function M.ImageButton(user_texture_id, size, uv0, uv1, frame_padding, bg_col, tint_col) return C.imgui_ImageButton(M.ctx, user_texture_id, size, uv0 or M.ImVec2(0,0), uv1 or M.ImVec2(1, 1), frame_padding or -1, bg_col or M.ImVec4(0,0,0,0), tint_col or M.ImVec4(1,1,1,1)) end
function M.Checkbox(label, v) return C.imgui_Checkbox(M.ctx, label, v) end
function M.CheckboxFlags(label, flags, flags_value) return C.imgui_CheckboxFlags(M.ctx, label, flags, flags_value) end
function M.RadioButton1(label, active) return C.imgui_RadioButton1(M.ctx, label, active) end
function M.RadioButton2(label, v, v_button) return C.imgui_RadioButton2(M.ctx, label, v, v_button) end
function M.PlotLines1(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) C.imgui_PlotLines1(M.ctx, label, values, values_count, values_offset or 0, overlay_text or nil, scale_min or FLT_MAX, scale_max or FLT_MAX, graph_size or M.ImVec2(0,0)) end
function M.PlotLines2(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) C.imgui_PlotLines2(M.ctx, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) end
function M.PlotHistogram1(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) C.imgui_PlotHistogram1(M.ctx, label, values, values_count, values_offset or 0, overlay_text or nil, scale_min or FLT_MAX, scale_max or FLT_MAX, graph_size or M.ImVec2(0,0)) end
function M.PlotHistogram2(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) C.imgui_PlotHistogram2(M.ctx, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size) end
function M.ProgressBar(fraction, size_arg, overlay) C.imgui_ProgressBar(M.ctx, fraction, size_arg or M.ImVec2(-1.0, 0.0), overlay or nil) end
function M.Bullet() C.imgui_Bullet(M.ctx) end

-- Widgets: Combo Box
function M.BeginCombo(label, preview_value, flags) return C.imgui_BeginCombo(M.ctx, label, preview_value, flags or 0) end
function M.EndCombo() return C.imgui_EndCombo(M.ctx) end
function M.Combo1(label, current_item, items, items_count, popup_max_height_in_items) return C.imgui_Combo1(M.ctx, label, current_item, items, items_count or M.GetLengthArrayCharPtr(items), popup_max_height_in_items or -1) end
function M.Combo2(label, current_item, items_separated_by_zeros, popup_max_height_in_items) return C.imgui_Combo2(M.ctx, label, current_item, items_separated_by_zeros, popup_max_height_in_items or -1) end

-- Widgets: Drags
function M.DragFloat(label, v, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragFloat(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragFloat2(label, v, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragFloat2(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragFloat3(label, v, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragFloat3(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragFloat4(label, v, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragFloat4(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragFloatRange2(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max, power, editEnded)
  local res = C.imgui_DragFloatRange2(M.ctx, label, v_current_min, v_current_max, v_speed or 1, v_min or 0, v_max or 0, format or "%.3f", format_max or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragInt(label, v, v_speed, v_min, v_max, format, editEnded)
  local res = C.imgui_DragInt(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragInt2(label, v, v_speed, v_min, v_max, format, editEnded)
  local res = C.imgui_DragInt2(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragInt3(label, v, v_speed, v_min, v_max, format, editEnded)
  local res = C.imgui_DragInt3(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragInt4(label, v, v_speed, v_min, v_max, format, editEnded)
  local res = C.imgui_DragInt4(M.ctx, label, v, v_speed or 1, v_min or 0, v_max or 0, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragIntRange2(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max, editEnded)
  local res = C.imgui_DragIntRange2(M.ctx, label, v_current_min, v_current_max, v_speed or 1, v_min or 0, v_max or 0, format or "%d", format_max or nil)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragScalar(label, data_type, v, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragScalar(M.ctx, label, data_type, v, v_speed, v_min or nil, v_max or nil, format or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.DragScalarN(label, data_type, v, components, v_speed, v_min, v_max, format, power, editEnded)
  local res = C.imgui_DragScalarN(M.ctx, label, data_type, v, components, v_speed, v_min or nil, v_max or nil, format or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end

-- Widgets: Input with Keyboard
function M.InputText(label, buf, buf_size, flags, callback, user_data, editEnded)
  local res =  C.imgui_InputText(M.ctx, label, buf, buf_size or ffi.sizeof(buf), flags or 0, callback or nil, user_data or nil )
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputTextMultiline(label, buf, buf_size, size, flags, callback, user_data, editEnded)
  local res =  C.imgui_InputTextMultiline(M.ctx, label, buf, buf_size or ffi.sizeof(buf), size or M.ImVec2(0,0), flags or 0, callback or nil, user_data or nil)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputTextMultilineReadOnly(label, buf, size, flags, callback, user_data, editEnded)
  local res =  C.imgui_InputTextMultilineReadOnly(M.ctx, label, buf, size or M.ImVec2(0,0), flags or 0, callback or nil, user_data or nil)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputFloat(label, v, step, step_fast, format, extra_flags, editEnded)
  local res =  C.imgui_InputFloat(M.ctx, label, v, step or 0, step_fast or 0, format or "%.3f", extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputFloat2(label, v, format, extra_flags, editEnded)
  local res =  C.imgui_InputFloat2(M.ctx, label, v, format or "%.3f", extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputFloat3(label, v, format, extra_flags, editEnded)
  local res =  C.imgui_InputFloat3(M.ctx, label, v, format or "%.3f", extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputFloat4(label, v, format, extra_flags, editEnded)
  local res =  C.imgui_InputFloat4(M.ctx, label, v, format or "%.3f", extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputInt(label, v, step, step_fast, extra_flags, editEnded)
  local res =  C.imgui_InputInt(M.ctx, label, v, step or 1, step_fast or 100, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputInt2(label, v, extra_flags, editEnded)
  local res =  C.imgui_InputInt2(M.ctx, label, v, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputInt3(label, v, extra_flags, editEnded)
  local res =  C.imgui_InputInt3(M.ctx, label, v, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputInt4(label, v, extra_flags, editEnded)
  local res =  C.imgui_InputInt4(M.ctx, label, v, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputDouble(label, v, step, step_fast, format, extra_flags, editEnded)
  local res =  C.imgui_InputDouble(M.ctx, label, v, step or 0, step_fast or 0, format or "%.6f", extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputScalar(label, data_type, v, step, step_fast, format, extra_flags, editEnded)
  local res =  C.imgui_InputScalar(M.ctx, label, data_type, v, step or nil, step_fast or nil, format or nil, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.InputScalarN(label, data_type, v, components, step, step_fast, format, extra_flags, editEnded)
  local res =  C.imgui_InputScalarN(M.ctx, label, data_type, v, components, step or nil, step_fast or nil, format or nil, extra_flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end

-- Widgets: Sliders
function M.SliderFloat(label, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderFloat(M.ctx, label, v, v_min, v_max, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderFloat2(label, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderFloat2(M.ctx, label, v, v_min, v_max, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderFloat3(label, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderFloat3(M.ctx, label, v, v_min, v_max, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderFloat4(label, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderFloat4(M.ctx, label, v, v_min, v_max, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderAngle(label, v_rad, v_degrees_min, v_degrees_max, editEnded)
  local res = C.imgui_SliderAngle(M.ctx, label, v_rad, v_degrees_min or -360.0, v_degrees_max or 360.0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderInt(label, v, v_min, v_max, format, editEnded)
  local res =  C.imgui_SliderInt(M.ctx, label, v, v_min, v_max, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderInt2(label, v, v_min, v_max, format, editEnded)
  local res =  C.imgui_SliderInt2(M.ctx, label, v, v_min, v_max, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderInt3(label, v, v_min, v_max, format, editEnded)
  local res =  C.imgui_SliderInt3(M.ctx, label, v, v_min, v_max, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderInt4(label, v, v_min, v_max, format, editEnded)
  local res =  C.imgui_SliderInt4(M.ctx, label, v, v_min, v_max, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderScalar(label, data_type, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderScalar(M.ctx, label, data_type, v, v_min, v_max, format or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SliderScalarN(label, data_type, v, components, v_min, v_max, format, power, editEnded)
  local res = C.imgui_SliderScalarN(M.ctx, label, data_type, v, components, v_min, v_max, format or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.VSliderFloat(label, size, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_VSliderFloat(M.ctx, label, size, v, v_min, v_max, format or "%.3f", power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.VSliderInt(label, size, v, v_min, v_max, format, editEnded)
  local res = C.imgui_VSliderInt(M.ctx, label, size, v, v_min, v_max, format or "%d")
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.VSliderScalar(label, size, data_type, v, v_min, v_max, format, power, editEnded)
  local res = C.imgui_VSliderScalar(M.ctx, label, size, data_type, v, v_min, v_max, format or nil, power or 1)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end

-- Widgets: Color Editor/Picker
function M.ColorEdit3(label, col, flags, editEnded)
  local res = C.imgui_ColorEdit3(M.ctx, label, col, flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.ColorEdit4(label, col, flags, editEnded)
  local res = C.imgui_ColorEdit4(M.ctx, label, col, flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.ColorPicker3(label, col, flags, editEnded)
  local res = C.imgui_ColorPicker3(M.ctx, label, col, flags or 0)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.ColorPicker4(label, col, flags, ref_col, editEnded)
  local res = C.imgui_ColorPicker4(M.ctx, label, col, flags or 0, ref_col or nil)
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.ColorButton(desc_id, col, flags, size, editEnded)
  local res = C.imgui_ColorButton(M.ctx, desc_id, col, flags or 0, size or M.ImVec2(0,0))
  if editEnded then
    editEnded[0] = C.imgui_IsItemDeactivatedAfterChange(M.ctx)
  end
  return res
end
function M.SetColorEditOptions(flags) C.imgui_SetColorEditOptions(M.ctx, flags) end

-- Widgets: Trees
function M.TreeNode1(label) return C.imgui_TreeNode1(M.ctx, label) end
function M.TreeNode2(str_id, fmt, ...) return C.imgui_TreeNode2(M.ctx, str_id, fmt, ...) end
function M.TreeNode3(ptr_id, fmt, ...) return C.imgui_TreeNode3(M.ctx, ptr_id, fmt, ...) end
function M.TreeNodeV1(str_id, fmt, ...) return C.imgui_TreeNodeV1(M.ctx, str_id, fmt, ...) end
function M.TreeNodeV2(ptr_id, fmt, ...) return C.imgui_TreeNodeV2(M.ctx, ptr_id, fmt, ...) end
function M.TreeNodeEx1(label, flags) return C.imgui_TreeNodeEx1(M.ctx, label, flags or 0) end
function M.TreeNodeEx2(str_id, flags, fmt, ...) return C.imgui_TreeNodeEx2(M.ctx, str_id, flags, fmt, ...) end
function M.TreeNodeEx3(ptr_id, flags, fmt, ...) return C.imgui_TreeNodeEx3(M.ctx, ptr_id, flags, fmt, ...) end
function M.TreeNodeExV1(str_id, flags, fmt, ...) return C.imgui_TreeNodeExV1(M.ctx, str_id, flags, fmt, ...) end
function M.TreeNodeExV2(ptr_id, flags, fmt, ...) return C.imgui_TreeNodeExV2(M.ctx, ptr_id, flags, fmt, ...) end
function M.TreePush1(str_id) C.imgui_TreePush1(M.ctx, str_id) end
function M.TreePush2(ptr_id) C.imgui_TreePush2(M.ctx, ptr_id or nil) end
function M.TreePop() C.imgui_TreePop(M.ctx) end
function M.TreeAdvanceToLabelPos() C.imgui_TreeAdvanceToLabelPos(M.ctx) end
function M.GetTreeNodeToLabelSpacing() return C.imgui_GetTreeNodeToLabelSpacing(M.ctx) end
function M.SetNextTreeNodeOpen(is_open, cond) C.imgui_SetNextTreeNodeOpen(M.ctx, is_open, cond) end
function M.CollapsingHeader1(label, flags) return C.imgui_CollapsingHeader1(M.ctx, label, flags or 0) end
function M.CollapsingHeader2(label, p_open, flags) return C.imgui_CollapsingHeader2(M.ctx, label, p_open, flags or 0) end

-- Widgets: Selectable / Lists
function M.Selectable1(label, selected, flags, size) return C.imgui_Selectable1(M.ctx, label, selected or false, flags or 0, size or M.ImVec2(0,0)) end
function M.Selectable2(label, p_selected, flags, size) return C.imgui_Selectable2(M.ctx, label, p_selected, flags or 0, size or M.ImVec2(0,0)) end
function M.ListBox(label, current_item, items, items_count, height_in_items) return C.imgui_ListBox(M.ctx, label, current_item, items, items_count or M.GetLengthArrayInt(items) - 1, height_in_items or -1) end
function M.ListBoxHeader1(label, size) return C.imgui_ListBoxHeader1(M.ctx, label, size or M.ImVec2(0,0)) end
function M.ListBoxHeader2(label, items_count, height_in_items) return C.imgui_ListBoxHeader2(M.ctx, label, items_count, height_in_items or -1) end
function M.ListBoxFooter() return C.imgui_ListBoxFooter(M.ctx) end

-- Widgets: Value() Helpers
function M.Value1(prefix, b) C.imgui_imgui_Value1(M.ctx, prefix, b) end
function M.Value2(prefix, v) C.imgui_imgui_Value2(M.ctx, prefix, v) end
function M.Value3(prefix, v) C.imgui_imgui_Value3(M.ctx, prefix, v) end
function M.Value4(prefix, v, float_format) C.imgui_imgui_Value4(M.ctx, prefix, v, float_format or nil) end

-- Tooltips
function M.SetTooltip(fmt, ...) C.imgui_SetTooltip(M.ctx, fmt, ...) end
function M.BeginTooltip() C.imgui_BeginTooltip(M.ctx) end
function M.EndTooltip() C.imgui_EndTooltip(M.ctx) end

-- Menus
function M.BeginMainMenuBar() return C.imgui_BeginMainMenuBar(M.ctx) end
function M.EndMainMenuBar() C.imgui_EndMainMenuBar(M.ctx) end
function M.BeginMenuBar() return C.imgui_BeginMenuBar(M.ctx) end
function M.EndMenuBar() C.imgui_EndMenuBar(M.ctx) end
function M.BeginMenu(label, enabled) return C.imgui_BeginMenu(M.ctx, label, enabled or true) end
function M.EndMenu() C.imgui_EndMenu(M.ctx) end
function M.MenuItem1(label, shortcut, selected, enabled) return C.imgui_MenuItem1(M.ctx, label, shortcut or nil, selected or false, enabled or true) end
function M.MenuItem2(label, shortcut, p_selected, enabled) return C.imgui_MenuItem2(M.ctx, label, shortcut, p_selected, enabled or true) end

-- Popups
function M.OpenPopup(str_id) C.imgui_OpenPopup(M.ctx, str_id) end
function M.BeginPopup(str_id, flags) return C.imgui_BeginPopup(M.ctx, str_id, flags or 0) end
function M.BeginPopupContextItem(str_id, mouse_button) return C.imgui_BeginPopupContextItem(M.ctx, str_id or nil, mouse_button or 1) end
function M.BeginPopupContextWindow(str_id, mouse_button, also_over_items) return C.imgui_BeginPopupContextWindow(M.ctx, str_id or nil, mouse_button or 1, also_over_items or true) end
function M.BeginPopupContextVoid(str_id, mouse_button) return C.imgui_BeginPopupContextVoid(M.ctx, str_id or nil, mouse_button or 1) end
function M.BeginPopupModal(name, p_open, flags) return C.imgui_BeginPopupModal(M.ctx, name, p_open or nil, flags or 0) end
function M.EndPopup() C.imgui_EndPopup(M.ctx) end
function M.OpenPopupOnItemClick(str_id, mouse_button) return C.imgui_OpenPopupOnItemClick(M.ctx, str_id or nil, mouse_button or 1) end
function M.IsPopupOpen(str_id) return C.imgui_IsPopupOpen(M.ctx, str_id) end
function M.CloseCurrentPopup() C.imgui_CloseCurrentPopup(M.ctx) end

-- Columns
function M.Columns(count, id, border) C.imgui_Columns(M.ctx, count or 1, id or nil, border or true) end
function M.NextColumn() C.imgui_NextColumn(M.ctx) end
function M.GetColumnIndex() return C.imgui_GetColumnIndex(M.ctx) end
function M.GetColumnWidth(column_index) return C.imgui_GetColumnWidth(M.ctx, column_index or -1) end
function M.SetColumnWidth(column_index, width) C.imgui_SetColumnWidth(M.ctx, column_index, width) end
function M.GetColumnOffset(column_index) return C.imgui_GetColumnOffset(M.ctx, column_index or -1) end
function M.SetColumnOffset(column_index, offset_x) C.imgui_SetColumnOffset(M.ctx, column_index, offset_x) end
function M.GetColumnsCount() return C.imgui_GetColumnsCount(M.ctx) end
function M.BeginColumns(id, count, flags) C.imgui_BeginColumns(M.ctx, id or "", count or 2, flags or 0) end
function M.EndColumns() C.imgui_EndColumns(M.ctx) end

-- Logging/Capture
function M.LogToTTY(max_depth) C.imgui_LogToTTY(M.ctx, max_depth or -1) end
function M.LogToFile(max_depth, filename) C.imgui_LogToFile(M.ctx, max_depth or -1, filename or nil) end
function M.LogToClipboard(max_depth) C.imgui_LogToClipboard(M.ctx, max_depth or -1) end
function M.LogFinish() C.imgui_LogFinish(M.ctx) end
function M.LogButtons() C.imgui_LogButtons(M.ctx) end
function M.LogText(fmt, ...) C.imgui_LogText(M.ctx, fmt, ...) end

-- Drag and Drop
function M.BeginDragDropSource(flags) return C.imgui_BeginDragDropSource(M.ctx, flags or 0) end
function M.SetDragDropPayload(type, data, size, cond) return C.imgui_SetDragDropPayload(M.ctx, type, data, size, cond or 0) end
function M.EndDragDropSource() C.imgui_EndDragDropSource(M.ctx) end
function M.BeginDragDropTarget() return C.imgui_BeginDragDropTarget(M.ctx) end
function M.AcceptDragDropPayload(type, flags) return C.imgui_AcceptDragDropPayload(M.ctx, type, flags or 0) end
function M.EndDragDropTarget() C.imgui_EndDragDropTarget(M.ctx) end

-- Clipping
function M.PushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect) C.imgui_PushClipRect(M.ctx, clip_rect_min, clip_rect_max, intersect_with_current_clip_rect) end
function M.PopClipRect() C.imgui_PopClipRect(M.ctx) end

-- Focus, Activation
function M.SetItemDefaultFocus() C.imgui_SetItemDefaultFocus(M.ctx) end
function M.SetKeyboardFocusHere(offset) C.imgui_SetKeyboardFocusHere(M.ctx, offset or 0) end

-- Utilities
function M.IsItemHovered(flags) return C.imgui_IsItemHovered(M.ctx, flags or 0) end
function M.IsItemActive() return C.imgui_IsItemActive(M.ctx) end
function M.IsItemFocused() return C.imgui_IsItemFocused(M.ctx) end
function M.IsItemClicked(mouse_button) return C.imgui_IsItemClicked(M.ctx, mouse_button or 0) end
function M.IsItemVisible() return C.imgui_IsItemVisible(M.ctx) end
function M.IsItemDeactivated() return C.imgui_IsItemDeactivated(M.ctx) end
function M.IsItemDeactivatedAfterChange() return C.imgui_IsItemDeactivatedAfterChange(M.ctx) end
function M.IsAnyItemHovered() return C.imgui_IsAnyItemHovered(M.ctx) end
function M.IsAnyItemActive() return C.imgui_IsAnyItemActive(M.ctx) end
function M.IsAnyItemFocused() return C.imgui_IsAnyItemFocused(M.ctx) end
function M.GetItemRectMin(res) C.imgui_GetItemRectMin(M.ctx, res) end
function M.GetItemRectMax(res) C.imgui_GetItemRectMax(M.ctx, res) end
function M.GetItemRectSize(v) C.imgui_GetItemRectSize(M.ctx, v) end
function M.SetItemAllowOverlap() C.imgui_SetItemAllowOverlap(M.ctx) end
function M.IsRectVisible1(size) return C.imgui_IsRectVisible1(M.ctx, size) end
function M.IsRectVisible2(rect_min, rect_max) return C.imgui_IsRectVisible2(M.ctx, rect_min, rect_max) end
function M.GetTime() return C.imgui_GetTime(M.ctx) end
function M.GetFrameCount() return C.imgui_GetFrameCount(M.ctx) end
function M.GetOverlayDrawList() return C.imgui_GetOverlayDrawList(M.ctx) end
function M.GetDrawListSharedData() return C.imgui_GetDrawListSharedData(M.ctx) end
function M.SetStateStorage(storage) C.imgui_SetStateStorage(M.ctx, storage) end
function M.GetStateStorage() return C.imgui_GetStateStorage(M.ctx) end
function M.CalcTextSize(res, text, text_end, hide_text_after_double_hash, wrap_width) C.imgui_CalcTextSize(M.ctx, text, text_end or nil, hide_text_after_double_hash or false, wrap_width or -1) end
function M.CalcListClipping(items_count, items_height, out_items_display_start, out_items_display_end) C.imgui_CalcListClipping(M.ctx, items_count, items_height, out_items_display_start, out_items_display_end) end

function M.BeginChildFrame(id, size, flags) return C.imgui_BeginChildFrame(M.ctx, id, size, flags) end
function M.EndChildFrame() C.imgui_EndChildFrame(M.ctx) end

function M.ColorConvertU32ToFloat4(res, inU32) C.imgui_ColorConvertU32ToFloat4(res, inU32) end
function M.ColorConvertFloat4ToU32(inU32) return C.imgui_ColorConvertFloat4ToU32(inU32) end
function M.ColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v) C.imgui_ColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v) end
function M.ColorConvertHSVtoRGB(h ,s ,v, a )
  local col = M.ImVec4(0,0,0, a or 1)
  C.imgui_ColorConvertHSVtoRGB(h,s,v, col)
  return col
end

-- Inputs
function M.GetKeyIndex(imgui_key) return C.imgui_GetKeyIndex(M.ctx, imgui_key) end
function M.IsKeyDown(user_key_index) return C.imgui_IsKeyDown(M.ctx, user_key_index) end
function M.IsKeyPressed(user_key_index, repeated) return C.imgui_IsKeyPressed(M.ctx, user_key_index, repeated and true or false) end
function M.IsKeyReleased(user_key_index) return C.imgui_IsKeyReleased(M.ctx, user_key_index) end
function M.GetKeyPressedAmount(key_index, repeat_delay, rate) return C.imgui_GetKeyPressedAmount(M.ctx, key_index, repeat_delay, rate) end
function M.IsMouseDown(button) return C.imgui_IsMouseDown(M.ctx, button) end
function M.IsAnyMouseDown() return C.imgui_IsAnyMouseDown(M.ctx) end
function M.IsMouseClicked(button, repeated) return C.imgui_IsMouseClicked(M.ctx, button, repeated or false) end
function M.IsMouseDoubleClicked(button) return C.imgui_IsMouseDoubleClicked(M.ctx, button) end
function M.IsMouseReleased(button) return C.imgui_IsMouseReleased(M.ctx, button) end
function M.IsMouseDragging(button, lock_threshold) return C.imgui_IsMouseDragging(M.ctx, button or 0, lock_threshold or -1.0) end
function M.IsMouseHoveringRect(r_min, r_max, clip) return C.imgui_IsMouseHoveringRect(M.ctx, r_min, r_max, clip or true) end
function M.IsMousePosValid(mouse_pos) return C.imgui_IsMousePosValid(M.ctx, mouse_pos or nil) end
function M.GetMousePos(res) C.imgui_GetMousePos(M.ctx, res) end
function M.GetMousePosOnOpeningCurrentPopup(res) C.imgui_GetMousePosOnOpeningCurrentPopup(M.ctx, res) end
function M.GetMouseDragDelta(res, button, lock_threshold) C.imgui_GetMouseDragDelta(M.ctx, res, button, lock_threshold) end
function M.ResetMouseDragDelta(button) C.imgui_ResetMouseDragDelta(M.ctx, button) end
function M.GetMouseCursor(res) C.imgui_GetMouseCursor(M.ctx, res) end
function M.SetMouseCursor(type) C.imgui_SetMouseCursor(M.ctx, type) end
function M.CaptureKeyboardFromApp(capture) C.imgui_CaptureKeyboardFromApp(M.ctx, capture) end
function M.CaptureMouseFromApp(capture) C.imgui_CaptureMouseFromApp(M.ctx, capture) end

-- Clipboard Utilities
function M.GetClipboardText() return C.imgui_GetClipboardText(M.ctx) end
function M.SetClipboardText(text) C.imgui_SetClipboardText(M.ctx, text) end

-- Settings/.Ini Utilities
function M.LoadIniSettingsFromDisk(ini_filename) C.imgui_LoadIniSettingsFromDisk(M.ctx, ini_filename) end
function M.LoadIniSettingsFromMemory(ini_data, ini_size) C.imgui_LoadIniSettingsFromMemory(M.ctx, ini_data, ini_size) end
function M.SaveIniSettingsToDisk(ini_filename) C.imgui_SaveIniSettingsToDisk(M.ctx, ini_filename) end
function M.SaveIniSettingsToMemory(out_ini_size) return C.imgui_SaveIniSettingsToMemory(M.ctx, out_ini_size) end

--
function M.Scrollbar(direction) C.imgui_Scrollbar(M.ctx, direction) end

-- Member functions
function M.ImDrawList_AddRect(drawList, vec2A, vec2B, col, rounding, rounding_corners_flags, thickness) C.imgui_ImDrawList_AddRect(drawList, vec2A, vec2B, col, rounding or 0.0, rounding_corners_flags or M.DrawCornerFlags_All, thickness or 1.0) end
function M.ImDrawList_AddRectFilled(drawList, vec2A, vec2B, col, rounding, rounding_corners_flags) C.imgui_ImDrawList_AddRectFilled(drawList, vec2A, vec2B, col, rounding or 0.0, rounding_corners_flags or M.DrawCornerFlags_All) end
function M.ImDrawList_AddTriangleFilled(drawList, a, b, c, col) C.imgui_ImDrawList_AddTriangleFilled(drawList, a, b, c, col) end
function M.ImDrawList_AddText1(drawList, pos, col, text_begin, text_end) C.imgui_ImDrawList_AddText1(drawList, pos, col, text_begin, text_end or nil) end
function M.ImDrawList_AddText2(drawList, font, font_size, pos, col, text_begin, text_end, wrap_width, cpu_fine_clip_rect) C.imgui_ImDrawList_AddText2(drawList, font, font_size, pos, col, text_begin, text_end or nil, wrap_width or 0, cpu_fine_clip_rect or nil) end
function M.ImDrawList_AddImage(drawList, user_texture_id, a, b, uv_a, uv_b, col) C.imgui_ImDrawList_AddImage(drawList, user_texture_id, a, b, uv_a or M.ImVec2(0,0), uv_b or M.ImVec2(1, 1), col or ffi.new('ImU32', 0xFFFFFFFF)) end
function M.ImGuiTextFilter_Draw(textFilter, label, width) return C.imgui_ImGuiTextFilter_Draw(textFilter, M.ctx, label or "Filter (inc,-exc)", width or 0) end
function M.ImGuiTextFilter_PassFilter(textFilter, text) return C.imgui_ImGuiTextFilter_PassFilter(textFilter, M.ctx, text) end
function M.ImGuiTextFilter_Clear(textFilter) return C.imgui_ImGuiTextFilter_Clear(textFilter, M.ctx) end

-- Helper functions
  -- Imgui Helper
function M.GetImGuiIO_FontAllowUserScaling() return C.imgui_GetImGuiIO_FontAllowUserScaling(M.ctx) end
function M.ImGuiIO_KeyCtrl() return C.imgui_ImGuiIO_KeyCtrl(M.ctx) end
function M.ImGuiIO_KeyShift() return C.imgui_ImGuiIO_KeyShift(M.ctx) end
function M.ImGuiIO_KeyAlt() return C.imgui_ImGuiIO_KeyAlt(M.ctx) end
function M.ImGuiIO_DeltaTime() return C.imgui_ImGuiIO_DeltaTime(M.ctx) end
function M.ImGuiStyle_ItemSpacing(res) C.imgui_ImGuiStyle_ItemSpacing(M.ctx, res) end
function M.ImGuiStyle_ItemInnerSpacing(res) C.imgui_ImGuiStyle_ItemInnerSpacing(M.ctx, res) end
  -- Font
function M.ImGuiIO_Fonts_AddFontDefault(imGuiIO, res, font_cfg) C.imgui_ImGuiIO_Fonts_AddFontDefault(imGuiIO, res, font_cfg or nil) end
function M.ImGuiIO_Fonts_AddFontFromFileTTF(imGuiIO, res, filename, size_pixels, font_cfg, glyph_ranges) C.imgui_ImGuiIO_Fonts_AddFontFromFileTTF(imGuiIO, res, filename, size_pixels, font_cfg or nil, glyph_ranges or nil) end

function M.ImGuiIO_MouseWheel() return C.imgui_ImGuiIO_MouseWheel(M.ctx) end
function M.ImGuiIO_WantCaptureMouse() return C.imgui_ImGuiIO_WantCaptureMouse(M.ctx) end

function M.GetWindow(index) return C.imgui_GetWindow(M.ctx, index) end
function M.MinimizeAllWindows() C.imgui_MinimizeAllWindows(M.ctx) end
function M.MaximizeAllWindows() C.imgui_MaximizeAllWindows(M.ctx) end

  --
function M.ShowHelpMarker(desc, sameLine)
  if sameLine == true then M.SameLine() end
  M.TextDisabled("(?)")
  if M.IsItemHovered() then
    M.BeginTooltip()
    M.PushTextWrapPos(M.GetFontSize() * 35.0)
    M.TextUnformatted(desc)
    M.PopTextWrapPos()
    M.EndTooltip();
  end
end

function M.tooltip(message)
  if M.IsItemHovered() then
    M.SetTooltip(message)
  end
end

  --PlotLines helper
function M.GetTableLength(tbl)
  local count = 0
  for _ in pairs(tbl) do count = count + 1 end
  return count
end

function M.TableToArrayFloat( tbl )
  local array = ffi.new("float[?]", M.GetTableLength(tbl))
  for k,v in pairs(tbl) do
    array[k - 1] = v
  end
  return array
end

function M.PlotLinesTbl( label, tbl, value, values_offset, overlay_text, scale_min, scale_max, graph_size )
  table.remove(tbl, 1)
  table.insert( tbl, value )
  local arr = M.TableToArrayFloat( tbl )
  M.PlotLines1(label, arr , M.GetLengthArrayFloat(arr), values_offset, overlay_text, scale_min, scale_max, graph_size )
end

function M.PlotLines( label, arr, value, values_offset, overlay_text, scale_min, scale_max, graph_size )
  local size = ffi.sizeof(arr) / ffi.sizeof('float[1]')
  for i = 0, size - 2 do
    arr[i] = arr[i+1]
  end
  arr[size-1] = value
  M.PlotLines1(label, arr , M.GetLengthArrayFloat(arr), values_offset, overlay_text, scale_min, scale_max, graph_size )
end

function M.CreateTable(size)
  local tbl = {}
  for i = 1, size, 1 do
    tbl[i] = 0
  end
  return tbl
end

-- direct pointers, no wrappers needed
M.CreateContext                              = C.ImGui_CreateContext
M.GetStyleColorName                          = C.imgui_GetStyleColorName
M.ImGuiIO_Fonts_TexWidth                     = C.imgui_ImGuiIO_Fonts_TexWidth
M.ImGuiIO_Fonts_TexHeight                    = C.imgui_ImGuiIO_Fonts_TexHeight
M.ImGuiIO_Fonts_TexID                        = C.imgui_ImGuiIO_Fonts_TexID
M.ImGuiIO_MousePos                           = C.imgui_ImGuiIO_MousePos

-- ImGuiLayoutType
M.LayoutType_Vertical                        = C.ImGuiLayoutType_Vertical
M.LayoutType_Horizontal                      = C.ImGuiLayoutType_Horizontal

-- ImGuiWindowFlags
M.WindowFlags_None                           = C.ImGuiWindowFlags_None
M.WindowFlags_NoTitleBar                     = C.ImGuiWindowFlags_NoTitleBar
M.WindowFlags_NoResize                       = C.ImGuiWindowFlags_NoResize
M.WindowFlags_NoMove                         = C.ImGuiWindowFlags_NoMove
M.WindowFlags_NoScrollbar                    = C.ImGuiWindowFlags_NoScrollbar
M.WindowFlags_NoScrollWithMouse              = C.ImGuiWindowFlags_NoScrollWithMouse
M.WindowFlags_NoCollapse                     = C.ImGuiWindowFlags_NoCollapse
M.WindowFlags_AlwaysAutoResize               = C.ImGuiWindowFlags_AlwaysAutoResize
M.WindowFlags_NoSavedSettings                = C.ImGuiWindowFlags_NoSavedSettings
M.WindowFlags_NoInputs                       = C.ImGuiWindowFlags_NoInputs
M.WindowFlags_MenuBar                        = C.ImGuiWindowFlags_MenuBar
M.WindowFlags_HorizontalScrollbar            = C.ImGuiWindowFlags_HorizontalScrollbar
M.WindowFlags_NoFocusOnAppearing             = C.ImGuiWindowFlags_NoFocusOnAppearing
M.WindowFlags_NoBringToFrontOnFocus          = C.ImGuiWindowFlags_NoBringToFrontOnFocus
M.WindowFlags_AlwaysVerticalScrollbar        = C.ImGuiWindowFlags_AlwaysVerticalScrollbar
M.WindowFlags_AlwaysHorizontalScrollbar      = C.ImGuiWindowFlags_AlwaysHorizontalScrollbar
M.WindowFlags_AlwaysUseWindowPadding         = C.ImGuiWindowFlags_AlwaysUseWindowPadding
M.WindowFlags_ResizeFromAnySide              = C.ImGuiWindowFlags_ResizeFromAnySide
M.WindowFlags_ChildWindow                    = C.ImGuiWindowFlags_ChildWindow
M.WindowFlags_Tooltip                        = C.ImGuiWindowFlags_Tooltip
M.WindowFlags_Popup                          = C.ImGuiWindowFlags_Popup
M.WindowFlags_Modal                          = C.ImGuiWindowFlags_Modal
M.WindowFlags_ChildMenu                      = C.ImGuiWindowFlags_ChildMenu

-- ImGuiInputTextFlags
M.InputTextFlags_CharsDecimal                = C.ImGuiInputTextFlags_CharsDecimal
M.InputTextFlags_CharsHexadecimal            = C.ImGuiInputTextFlags_CharsHexadecimal
M.InputTextFlags_CharsUppercase              = C.ImGuiInputTextFlags_CharsUppercase
M.InputTextFlags_CharsNoBlank                = C.ImGuiInputTextFlags_CharsNoBlank
M.InputTextFlags_AutoSelectAll               = C.ImGuiInputTextFlags_AutoSelectAll
M.InputTextFlags_EnterReturnsTrue            = C.ImGuiInputTextFlags_EnterReturnsTrue
M.InputTextFlags_CallbackCompletion          = C.ImGuiInputTextFlags_CallbackCompletion
M.InputTextFlags_CallbackHistory             = C.ImGuiInputTextFlags_CallbackHistory
M.InputTextFlags_CallbackAlways              = C.ImGuiInputTextFlags_CallbackAlways
M.InputTextFlags_CallbackCharFilter          = C.ImGuiInputTextFlags_CallbackCharFilter
M.InputTextFlags_AllowTabInput               = C.ImGuiInputTextFlags_AllowTabInput
M.InputTextFlags_CtrlEnterForNewLine         = C.ImGuiInputTextFlags_CtrlEnterForNewLine
M.InputTextFlags_NoHorizontalScroll          = C.ImGuiInputTextFlags_NoHorizontalScroll
M.InputTextFlags_AlwaysInsertMode            = C.ImGuiInputTextFlags_AlwaysInsertMode
M.InputTextFlags_ReadOnly                    = C.ImGuiInputTextFlags_ReadOnly
M.InputTextFlags_Password                    = C.ImGuiInputTextFlags_Password
M.InputTextFlags_NoUndoRedo                  = C.ImGuiInputTextFlags_NoUndoRedo
M.InputTextFlags_CharsScientific             = C.ImGuiInputTextFlags_CharsScientific
M.InputTextFlags_Multiline                   = C.ImGuiInputTextFlags_Multiline

-- ImGuiComboFlags
M.ComboFlags_PopupAlignLeft                  = C.ImGuiComboFlags_PopupAlignLeft
M.ComboFlags_HeightSmall                     = C.ImGuiComboFlags_HeightSmall
M.ComboFlags_HeightRegular                   = C.ImGuiComboFlags_HeightRegular
M.ComboFlags_HeightLarge                     = C.ImGuiComboFlags_HeightLarge
M.ComboFlags_HeightLargest                   = C.ImGuiComboFlags_HeightLargest
M.ComboFlags_NoArrowButton                   = C.ImGuiComboFlags_NoArrowButton
M.ComboFlags_NoPreview                       = C.ImGuiComboFlags_NoPreview
M.ComboFlags_HeightMask_                     = C.ImGuiComboFlags_HeightMask_

-- ImGuiCol
M.Col_Text                                = C.ImGuiCol_Text
M.Col_TextDisabled                        = C.ImGuiCol_TextDisabled
M.Col_WindowBg                            = C.ImGuiCol_WindowBg
M.Col_ChildBg                             = C.ImGuiCol_ChildBg
M.Col_PopupBg                             = C.ImGuiCol_PopupBg
M.Col_Border                              = C.ImGuiCol_Border
M.Col_BorderShadow                        = C.ImGuiCol_BorderShadow
M.Col_FrameBg                             = C.ImGuiCol_FrameBg
M.Col_FrameBgHovered                      = C.ImGuiCol_FrameBgHovered
M.Col_FrameBgActive                       = C.ImGuiCol_FrameBgActive
M.Col_TitleBg                             = C.ImGuiCol_TitleBg
M.Col_TitleBgActive                       = C.ImGuiCol_TitleBgActive
M.Col_TitleBgCollapsed                    = C.ImGuiCol_TitleBgCollapsed
M.Col_MenuBarBg                           = C.ImGuiCol_MenuBarBg
M.Col_ScrollbarBg                         = C.ImGuiCol_ScrollbarBg
M.Col_ScrollbarGrab                       = C.ImGuiCol_ScrollbarGrab
M.Col_ScrollbarGrabHovered                = C.ImGuiCol_ScrollbarGrabHovered
M.Col_ScrollbarGrabActive                 = C.ImGuiCol_ScrollbarGrabActive
M.Col_CheckMark                           = C.ImGuiCol_CheckMark
M.Col_SliderGrab                          = C.ImGuiCol_SliderGrab
M.Col_SliderGrabActive                    = C.ImGuiCol_SliderGrabActive
M.Col_Button                              = C.ImGuiCol_Button
M.Col_ButtonHovered                       = C.ImGuiCol_ButtonHovered
M.Col_ButtonActive                        = C.ImGuiCol_ButtonActive
M.Col_Header                              = C.ImGuiCol_Header
M.Col_HeaderHovered                       = C.ImGuiCol_HeaderHovered
M.Col_HeaderActive                        = C.ImGuiCol_HeaderActive
M.Col_Separator                           = C.ImGuiCol_Separator
M.Col_SeparatorHovered                    = C.ImGuiCol_SeparatorHovered
M.Col_SeparatorActive                     = C.ImGuiCol_SeparatorActive
M.Col_ResizeGrip                          = C.ImGuiCol_ResizeGrip
M.Col_ResizeGripHovered                   = C.ImGuiCol_ResizeGripHovered
M.Col_ResizeGripActive                    = C.ImGuiCol_ResizeGripActive
M.Col_PlotLines                           = C.ImGuiCol_PlotLines
M.Col_PlotLinesHovered                    = C.ImGuiCol_PlotLinesHovered
M.Col_PlotHistogram                       = C.ImGuiCol_PlotHistogram
M.Col_PlotHistogramHovered                = C.ImGuiCol_PlotHistogramHovered
M.Col_TextSelectedBg                      = C.ImGuiCol_TextSelectedBg
M.Col_ModalWindowDarkening                = C.ImGuiCol_ModalWindowDarkening
M.Col_DragDropTarget                      = C.ImGuiCol_DragDropTarget
M.Col_NavHighlight                        = C.ImGuiCol_NavHighlight
M.Col_NavWindowingHighlight               = C.ImGuiCol_NavWindowingHighlight
M.Col_COUNT                               = C.ImGuiCol_COUNT

-- ImDrawCornerFlags
M.DrawCornerFlags_TopLeft                    = C.ImDrawCornerFlags_TopLeft
M.DrawCornerFlags_TopRight                   = C.ImDrawCornerFlags_TopRight
M.DrawCornerFlags_BotLeft                    = C.ImDrawCornerFlags_BotLeft
M.DrawCornerFlags_BotRight                   = C.ImDrawCornerFlags_BotRight
M.DrawCornerFlags_Top                        = C.ImDrawCornerFlags_Top
M.DrawCornerFlags_Bot                        = C.ImDrawCornerFlags_Bot
M.DrawCornerFlags_Left                       = C.ImDrawCornerFlags_Left
M.DrawCornerFlags_Right                      = C.ImDrawCornerFlags_Right
M.DrawCornerFlags_All                        = C.ImDrawCornerFlags_All

-- ImGuiCond
M.GuiCond_Always                             = C.ImGuiCond_Always
M.GuiCond_Once                               = C.ImGuiCond_Once
M.GuiCond_FirstUseEver                       = C.ImGuiCond_FirstUseEver
M.GuiCond_Appearing                          = C.ImGuiCond_Appearing

-- ImGuiSelectableFlags
M.ImGuiSelectableFlags_DontClosePopups       = C.ImGuiSelectableFlags_DontClosePopups
M.ImGuiSelectableFlags_SpanAllColumns        = C.ImGuiSelectableFlags_SpanAllColumns
M.ImGuiSelectableFlags_AllowDoubleClick      = C.ImGuiSelectableFlags_AllowDoubleClick

-- ImGuiTreeNodeFlags
M.TreeNodeFlags_Selected                     = C.ImGuiTreeNodeFlags_Selected
M.TreeNodeFlags_Framed                       = C.ImGuiTreeNodeFlags_Framed
M.TreeNodeFlags_AllowItemOverlap             = C.ImGuiTreeNodeFlags_AllowItemOverlap
M.TreeNodeFlags_NoTreePushOnOpen             = C.ImGuiTreeNodeFlags_NoTreePushOnOpen
M.TreeNodeFlags_NoAutoOpenOnLog              = C.ImGuiTreeNodeFlags_NoAutoOpenOnLog
M.TreeNodeFlags_DefaultOpen                  = C.ImGuiTreeNodeFlags_DefaultOpen
M.TreeNodeFlags_OpenOnDoubleClick            = C.ImGuiTreeNodeFlags_OpenOnDoubleClick
M.TreeNodeFlags_OpenOnArrow                  = C.ImGuiTreeNodeFlags_OpenOnArrow
M.TreeNodeFlags_Leaf                         = C.ImGuiTreeNodeFlags_Leaf
M.TreeNodeFlags_Bullet                       = C.ImGuiTreeNodeFlags_Bullet
M.TreeNodeFlags_FramePadding                 = C.ImGuiTreeNodeFlags_FramePadding
M.TreeNodeFlags_NavLeftJumpsBackHere         = C.ImGuiTreeNodeFlags_NavLeftJumpsBackHere
M.TreeNodeFlags_CollapsingHeader             = C.ImGuiTreeNodeFlags_CollapsingHeader

-- ImGuiHoveredFlags
M.HoveredFlags_Default                       = C.ImGuiHoveredFlags_Default
M.HoveredFlags_ChildWindows                  = C.ImGuiHoveredFlags_ChildWindows
M.HoveredFlags_RootWindow                    = C.ImGuiHoveredFlags_RootWindow
M.HoveredFlags_AnyWindow                     = C.ImGuiHoveredFlags_AnyWindow
M.HoveredFlags_AllowWhenBlockedByPopup       = C.ImGuiHoveredFlags_AllowWhenBlockedByPopup
-- M.HoveredFlags_AllowWhenBlockedByModal     = C.ImGuiHoveredFlags_AllowWhenBlockedByModal
M.HoveredFlags_AllowWhenBlockedByActiveItem  = C.ImGuiHoveredFlags_AllowWhenBlockedByActiveItem
M.HoveredFlags_AllowWhenOverlapped           = C.ImGuiHoveredFlags_AllowWhenOverlapped
M.HoveredFlags_RectOnly                      = C.ImGuiHoveredFlags_RectOnly
M.HoveredFlags_RootAndChildWindows           = C.ImGuiHoveredFlags_RootAndChildWindows

-- ImGuiColorEditFlags
M.ColorEditFlags_None                        = C.ImGuiColorEditFlags_None
M.ColorEditFlags_NoAlpha                     = C.ImGuiColorEditFlags_NoAlpha
M.ColorEditFlags_NoPicker                    = C.ImGuiColorEditFlags_NoPicker
M.ColorEditFlags_NoOptions                   = C.ImGuiColorEditFlags_NoOptions
M.ColorEditFlags_NoSmallPreview              = C.ImGuiColorEditFlags_NoSmallPreview
M.ColorEditFlags_NoInputs                    = C.ImGuiColorEditFlags_NoInputs
M.ColorEditFlags_NoTooltip                   = C.ImGuiColorEditFlags_NoTooltip
M.ColorEditFlags_NoLabel                     = C.ImGuiColorEditFlags_NoLabel
M.ColorEditFlags_NoSidePreview               = C.ImGuiColorEditFlags_NoSidePreview
M.ColorEditFlags_NoDragDrop                  = C.ImGuiColorEditFlags_NoDragDrop
M.ColorEditFlags_AlphaBar                    = C.ImGuiColorEditFlags_AlphaBar
M.ColorEditFlags_AlphaPreview                = C.ImGuiColorEditFlags_AlphaPreview
M.ColorEditFlags_AlphaPreviewHalf            = C.ImGuiColorEditFlags_AlphaPreviewHalf
M.ColorEditFlags_HDR                         = C.ImGuiColorEditFlags_HDR
M.ColorEditFlags_RGB                         = C.ImGuiColorEditFlags_RGB
M.ColorEditFlags_HSV                         = C.ImGuiColorEditFlags_HSV
M.ColorEditFlags_HEX                         = C.ImGuiColorEditFlags_HEX
M.ColorEditFlags_Uint8                       = C.ImGuiColorEditFlags_Uint8
M.ColorEditFlags_Float                       = C.ImGuiColorEditFlags_Float
M.ColorEditFlags_PickerHueBar                = C.ImGuiColorEditFlags_PickerHueBar
M.ColorEditFlags_PickerHueWheel              = C.ImGuiColorEditFlags_PickerHueWheel
M.ColorEditFlags__InputsMask                 = C.ImGuiColorEditFlags__InputsMask
M.ColorEditFlags__DataTypeMask               = C.ImGuiColorEditFlags__DataTypeMask
M.ColorEditFlags__PickerMask                 = C.ImGuiColorEditFlags__PickerMask
M.ColorEditFlags__OptionsDefault             = C.ImGuiColorEditFlags__OptionsDefault

-- ImGuiKey
M.Key_Tab                                    = C.ImGuiKey_Tab
M.Key_LeftArrow                              = C.ImGuiKey_LeftArrow
M.Key_RightArrow                             = C.ImGuiKey_RightArrow
M.Key_UpArrow                                = C.ImGuiKey_UpArrow
M.Key_DownArrow                              = C.ImGuiKey_DownArrow
M.Key_PageUp                                 = C.ImGuiKey_PageUp
M.Key_PageDown                               = C.ImGuiKey_PageDown
M.Key_Home                                   = C.ImGuiKey_Home
M.Key_End                                    = C.ImGuiKey_End
M.Key_Insert                                 = C.ImGuiKey_Insert
M.Key_Delete                                 = C.ImGuiKey_Delete
M.Key_Backspace                              = C.ImGuiKey_Backspace
M.Key_Space                                  = C.ImGuiKey_Space
M.Key_Enter                                  = C.ImGuiKey_Enter
M.Key_Escape                                 = C.ImGuiKey_Escape
M.Key_A                                      = C.ImGuiKey_A
M.Key_C                                      = C.ImGuiKey_C
M.Key_V                                      = C.ImGuiKey_V
M.Key_X                                      = C.ImGuiKey_X
M.Key_Y                                      = C.ImGuiKey_Y
M.Key_Z                                      = C.ImGuiKey_Z
M.Key_COUNT                                  = C.ImGuiKey_COUNT

-- ImGuiDataType
M.DataType_S32                               = C.ImGuiDataType_S32
M.DataType_U32                               = C.ImGuiDataType_U32
M.DataType_S64                               = C.ImGuiDataType_S64
M.DataType_U64                               = C.ImGuiDataType_U64
M.DataType_Float                             = C.ImGuiDataType_Float
M.DataType_Double                            = C.ImGuiDataType_Double
M.DataType_COUNT                             = C.ImGuiDataType_COUNT

-- ImGuiDir
M.Dir_None                                   = C.ImGuiDir_None
M.Dir_Left                                   = C.ImGuiDir_Left
M.Dir_Right                                  = C.ImGuiDir_Right
M.Dir_Up                                     = C.ImGuiDir_Up
M.Dir_Down                                   = C.ImGuiDir_Down
M.Dir_COUNT                                  = C.ImGuiDir_COUNT

-- ImGuiStyleVar
M.StyleVar_Alpha                             = C.ImGuiStyleVar_Alpha
M.StyleVar_WindowPadding                     = C.ImGuiStyleVar_WindowPadding
M.StyleVar_WindowRounding                    = C.ImGuiStyleVar_WindowRounding
M.StyleVar_WindowBorderSize                  = C.ImGuiStyleVar_WindowBorderSize
M.StyleVar_WindowMinSize                     = C.ImGuiStyleVar_WindowMinSize
M.StyleVar_WindowTitleAlign                  = C.ImGuiStyleVar_WindowTitleAlign
M.StyleVar_ChildRounding                     = C.ImGuiStyleVar_ChildRounding
M.StyleVar_ChildBorderSize                   = C.ImGuiStyleVar_ChildBorderSize
M.StyleVar_PopupRounding                     = C.ImGuiStyleVar_PopupRounding
M.StyleVar_PopupBorderSize                   = C.ImGuiStyleVar_PopupBorderSize
M.StyleVar_FramePadding                      = C.ImGuiStyleVar_FramePadding
M.StyleVar_FrameRounding                     = C.ImGuiStyleVar_FrameRounding
M.StyleVar_FrameBorderSize                   = C.ImGuiStyleVar_FrameBorderSize
M.StyleVar_ItemSpacing                       = C.ImGuiStyleVar_ItemSpacing
M.StyleVar_ItemInnerSpacing                  = C.ImGuiStyleVar_ItemInnerSpacing
M.StyleVar_IndentSpacing                     = C.ImGuiStyleVar_IndentSpacing
M.StyleVar_ScrollbarSize                     = C.ImGuiStyleVar_ScrollbarSize
M.StyleVar_ScrollbarRounding                 = C.ImGuiStyleVar_ScrollbarRounding
M.StyleVar_GrabMinSize                       = C.ImGuiStyleVar_GrabMinSize
M.StyleVar_GrabRounding                      = C.ImGuiStyleVar_GrabRounding
M.StyleVar_ButtonTextAlign                   = C.ImGuiStyleVar_ButtonTextAlign
M.StyleVar_COUNT                             = C.ImGuiStyleVar_COUNT

-- ImGuiColumnsFlags
M.ColumnsFlags_NoBorder                      = C.ImGuiColumnsFlags_NoBorder
M.ColumnsFlags_NoResize                      = C.ImGuiColumnsFlags_NoResize
M.ColumnsFlags_NoPreserveWidths              = C.ImGuiColumnsFlags_NoPreserveWidths
M.ColumnsFlags_NoForceWithinWindow           = C.ImGuiColumnsFlags_NoForceWithinWindow
M.ColumnsFlags_GrowParentContentsSize        = C.ImGuiColumnsFlags_GrowParentContentsSize

-- ImGuiDragDropFlags
M.DragDropFlags_SourceNoPreviewTooltip       = C.ImGuiDragDropFlags_SourceNoPreviewTooltip
M.DragDropFlags_SourceNoDisableHover         = C.ImGuiDragDropFlags_SourceNoDisableHover
M.DragDropFlags_SourceNoHoldToOpenOthers     = C.ImGuiDragDropFlags_SourceNoHoldToOpenOthers
M.DragDropFlags_SourceAllowNullID            = C.ImGuiDragDropFlags_SourceAllowNullID
M.DragDropFlags_SourceExtern                 = C.ImGuiDragDropFlags_SourceExtern
M.DragDropFlags_AcceptBeforeDelivery         = C.ImGuiDragDropFlags_AcceptBeforeDelivery
M.DragDropFlags_AcceptNoDrawDefaultRect      = C.ImGuiDragDropFlags_AcceptNoDrawDefaultRect
M.DragDropFlags_AcceptPeekOnly               = C.ImGuiDragDropFlags_AcceptPeekOnly

-- ImFontAtlasFlags
M.FontAtlasFlags_NoPowerOfTwoHeight          = C.ImFontAtlasFlags_NoPowerOfTwoHeight
M.FontAtlasFlags_NoMouseCursors              = C.ImFontAtlasFlags_NoMouseCursors

-- ImDrawListFlags
M.DrawListFlags_AntiAliasedLines             = C.ImDrawListFlags_AntiAliasedLines
M.DrawListFlags_AntiAliasedFill              = C.ImDrawListFlags_AntiAliasedFill

-- ImGuiConfigFlags
M.ConfigFlags_NavEnableKeyboard              = C.ImGuiConfigFlags_NavEnableKeyboard
M.ConfigFlags_NavEnableGamepad               = C.ImGuiConfigFlags_NavEnableGamepad
M.ConfigFlags_NavEnableSetMousePos           = C.ImGuiConfigFlags_NavEnableSetMousePos
M.ConfigFlags_NavNoCaptureKeyboard           = C.ImGuiConfigFlags_NavNoCaptureKeyboard
M.ConfigFlags_NoMouse                        = C.ImGuiConfigFlags_NoMouse
M.ConfigFlags_NoMouseCursorChange            = C.ImGuiConfigFlags_NoMouseCursorChange
M.ConfigFlags_IsSRGB                         = C.ImGuiConfigFlags_IsSRGB
M.ConfigFlags_IsTouchScreen                  = C.ImGuiConfigFlags_IsTouchScreen

-- ImGuiBackendFlags
M.BackendFlags_HasGamepad                    = C.ImGuiBackendFlags_HasGamepad
M.BackendFlags_HasMouseCursors               = C.ImGuiBackendFlags_HasMouseCursors
M.BackendFlags_HasSetMousePos                = C.ImGuiBackendFlags_HasSetMousePos

-- ImGuiNavInput
M.NavInput_Activate                          = C.ImGuiNavInput_Activate
M.NavInput_Cancel                            = C.ImGuiNavInput_Cancel
M.NavInput_Input                             = C.ImGuiNavInput_Input
M.NavInput_Menu                              = C.ImGuiNavInput_Menu
M.NavInput_DpadLeft                          = C.ImGuiNavInput_DpadLeft
M.NavInput_DpadRight                         = C.ImGuiNavInput_DpadRight
M.NavInput_DpadUp                            = C.ImGuiNavInput_DpadUp
M.NavInput_DpadDown                          = C.ImGuiNavInput_DpadDown
M.NavInput_LStickLeft                        = C.ImGuiNavInput_LStickLeft
M.NavInput_LStickRight                       = C.ImGuiNavInput_LStickRight
M.NavInput_LStickUp                          = C.ImGuiNavInput_LStickUp
M.NavInput_LStickDown                        = C.ImGuiNavInput_LStickDown
M.NavInput_FocusPrev                         = C.ImGuiNavInput_FocusPrev
M.NavInput_FocusNext                         = C.ImGuiNavInput_FocusNext
M.NavInput_TweakSlow                         = C.ImGuiNavInput_TweakSlow
M.NavInput_TweakFast                         = C.ImGuiNavInput_TweakFast
M.NavInput_KeyMenu_                          = C.ImGuiNavInput_KeyMenu_
M.NavInput_KeyLeft_                          = C.ImGuiNavInput_KeyLeft_
M.NavInput_KeyRight_                         = C.ImGuiNavInput_KeyRight_
M.NavInput_KeyUp_                            = C.ImGuiNavInput_KeyUp_
M.NavInput_KeyDown_                          = C.ImGuiNavInput_KeyDown_
M.NavInput_COUNT                             = C.ImGuiNavInput_COUNT
M.NavInput_InternalStart_                    = C.ImGuiNavInput_InternalStart_

-- ImGuiFocusedFlags
M.FocusedFlags_None                          = C.ImGuiFocusedFlags_None
M.FocusedFlags_ChildWindows                  = C.ImGuiFocusedFlags_ChildWindows
M.FocusedFlags_RootWindow                    = C.ImGuiFocusedFlags_RootWindow
M.FocusedFlags_AnyWindow                     = C.ImGuiFocusedFlags_AnyWindow
M.FocusedFlags_RootAndChildWindows           = C.ImGuiFocusedFlags_RootAndChildWindows

-- ImGuiInputSource
M.InputSource_None                           = C.ImGuiInputSource_None
M.InputSource_Mouse                          = C.ImGuiInputSource_Mouse
M.InputSource_Nav                            = C.ImGuiInputSource_Nav
M.InputSource_NavKeyboard                    = C.ImGuiInputSource_NavKeyboard
M.InputSource_NavGamepad                     = C.ImGuiInputSource_NavGamepad
M.InputSource_COUNT                          = C.ImGuiInputSource_COUNT

-- ImGuiNavForward
M.NavForward_None                            = C.ImGuiNavForward_None
M.NavForward_ForwardQueued                   = C.ImGuiNavForward_ForwardQueued
M.NavForward_ForwardActive                   = C.ImGuiNavForward_ForwardActive

return M