-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
local logTag = 'editor_groundmodel_debug'

local im = ui_imgui

local windowOpen = im.BoolPtr(false)

local groundModels = {}
local groundDebug = im.BoolPtr(false)
local staticDebug = im.BoolPtr(false)
local depthDebug = im.BoolPtr(false)
local mouseFocus = im.BoolPtr(true)
local distance = im.FloatPtr(20)
local tileSize = im.FloatPtr(1)
local depthScale = im.FloatPtr(1)
local active = {}

local groundModelPath = "/art/groundmodels.json"

local gms
local vgmk -- visible ground model keys

local collisiontype = im.IntPtr(0)

local function setup()
  local i = 1
  local groundModelSize = tableSize(core_environment.groundModels)

  gms = tableKeys(core_environment.groundModels)
  table.sort(gms)

  for _, k in ipairs(gms) do
    local v = core_environment.groundModels[k]
    -- groundModels[k] = {data = v, active = im.BoolPtr(true), color = im.ArrayFloatByTbl({i/45 ,1 - i/45,0})}
    groundModels[k] = {data = v, active = im.BoolPtr(true), color = im.ArrayFloatByTbl(rainbowColor(groundModelSize, i, 1))}
    groundModels[k].cdata = {}
    groundModels[k].cdata.collisiontype = im.IntPtr(v.collisiontype)
    groundModels[k].cdata.defaultDepth = im.FloatPtr(v.defaultDepth)
    groundModels[k].cdata.dragAnisotropy = im.FloatPtr(v.dragAnisotropy)
    groundModels[k].cdata.flowBehaviorIndex = im.FloatPtr(v.flowBehaviorIndex)
    groundModels[k].cdata.flowConsistencyIndex = im.FloatPtr(v.flowConsistencyIndex)
    groundModels[k].cdata.fluidDensity = im.FloatPtr(v.fluidDensity)
    groundModels[k].cdata.hydrodynamicFriction = im.FloatPtr(v.hydrodynamicFriction)
    --groundModels[k].cdata.name = "Test"
    groundModels[k].cdata.roughnessCoefficient = im.FloatPtr(v.roughnessCoefficient)
    groundModels[k].cdata.shearStrength = im.FloatPtr(v.shearStrength)
    groundModels[k].cdata.skidMarks = im.BoolPtr(v.skidMarks)
    groundModels[k].cdata.slidingFrictionCoefficient = im.FloatPtr(v.slidingFrictionCoefficient)
    groundModels[k].cdata.staticFrictionCoefficient = im.FloatPtr(v.staticFrictionCoefficient)
    groundModels[k].cdata.strength = im.FloatPtr(v.strength)
    groundModels[k].cdata.stribeckVelocity = im.FloatPtr(v.stribeckVelocity)

    i = i + 1
    -- dump(groundModels[k].data:as_table())
  end
end

local function setValue(name, gm, type, val)
  gm.data[type] = val
  be:setGroundModel(name, gm.data)
end

local function saveGroundmodels()
  local data = {}
  for k,v in pairs(groundModels) do
    data[k] = {}
    for propertyName, propertyVal in pairs(v.cdata) do
      data[k][propertyName] = propertyVal[0]
    end
  end
  dump(data)
  jsonWriteFile(groundModelPath, data, true)
end

local function drawGroundModel(visibleGroundModels, debugtype, focusPos, gmName, gm)
  local col = ColorF(gm.color[0], gm.color[1], gm.color[2], 1)
  local drawn = 0
  if debugtype >= 0 then
    drawn = drawn + debugDrawer:renderGroundModelDebug(debugtype, gmName, col, distance[0], tileSize[0], focusPos:toPoint3F(), depthScale[0])
  end
  if staticDebug[0] then
    drawn = drawn + debugDrawer:renderStaticColDebug(debugtype, gmName, col, distance[0], tileSize[0], focusPos:toPoint3F(), depthScale[0])
  end
  if drawn > 0 then
    if not visibleGroundModels[gmName] then visibleGroundModels[gmName] = 0 end
    visibleGroundModels[gmName] = visibleGroundModels[gmName] + drawn
  end
end

local function openWindow()
  windowOpen[0] = true
end

local function onEditorGui()
  if windowOpen[0] ~= true then return end

  -- mouse
  local focusPos = vec3(Lua.lastDebugFocusPos)
  if mouseFocus[0] then
    local res = cameraMouseRayCast()
    if res and res.pos then
      -- debugDrawer:drawSphere(res.pos, 0.1, ColorF(0,1,0,1))
      --debugDrawer:drawLine(res.pos, res.pos + res.normal, ColorF(0,1,0,1))
      --print(" hit object: " .. tostring(res.object:getId() .. ' in ' .. res.distance .. ' m distance'))
      -- removes the object - fun minigame ;)
      --if res.object then res.object:delete() end
      focusPos = vec3(res.pos)
      debugDrawer:drawSphere(focusPos:toPoint3F(), 0.03, ColorF(0,1,0,1))

      local data = {}
      data.texture = 'art/circle'
      data.position = focusPos:toPoint3F()
      data.color = ColorF(1, 0, 0, 0.75)
      data.forwardVec = Point3F(0, 1, 0)
      data.scale = (vec3(1,1,1) * distance[0]):toPoint3F()
      Engine.Render.DynamicDecalMgr.addDecal(data)
    end
  end

  local visibleGroundModels = {}

  im.Begin("GroundModel Debug Window", windowOpen, im.WindowFlags_MenuBar)
    if im.BeginMenuBar() then
      if im.BeginMenu("Menu") then
        if im.MenuItem1("Save groundmodels") then saveGroundmodels() end
        if im.MenuItem1("Restore default") then core_environment.reloadGroundModels() setup() end
        im.EndMenu()
      end
      im.EndMenuBar()
    end
    local debugtype = -1
    if groundDebug[0] and depthDebug[0] then debugtype = 2
    elseif groundDebug[0] and not depthDebug[0] then debugtype = 0
    elseif not groundDebug[0] and depthDebug[0] then debugtype = 1 end

    im.Checkbox("Ground", groundDebug) im.SameLine()
    im.Checkbox("Depth", depthDebug) im.SameLine()
    if im.Checkbox("Static", staticDebug) then
      Engine.setStaticColDebugEnabled(staticDebug[0])
    end
    if im.TreeNode1("Options") then
      im.SameLine()
      im.Dummy(im.ImVec2(30,0)) im.SameLine()
      im.Checkbox("Mouse Focues", mouseFocus)
      im.PushItemWidth(60)
      im.SliderFloat("Distance", distance, 0, 250, "%.1f") im.SameLine()
      im.SliderFloat("Tile Size", tileSize, 0.25, 1, "%.2f") im.SameLine()
      im.SliderFloat("Depth Scale", depthScale, 0.1, 10, "%.2f")
      im.PopItemWidth()
      im.TreePop()
    end

    im.Dummy(im.ImVec2(0,10))



    im.Separator()

    -- TODO: use ImGuiListClipper
    if im.TreeNode1("Groundmodels") then
      if im.SmallButton("Enable All") then
        for _,k in pairs(gms) do
          groundModels[k].active[0] = true
        end
      end
      im.SameLine()
      if im.SmallButton("Disable All") then
        for _,k in pairs(gms) do
          groundModels[k].active[0] = false
        end
      end
      im.BeginChild1("GroundModelScroll")
      im.BeginColumns("GroundModelColumnsBegin", 3, im.ColumnsFlags_NoResize)

      im.SetColumnWidth(0, 60)
      im.SetColumnWidth(1, 45)
      im.SetColumnWidth(2, 1000)

      -- table header
      im.Separator()
      im.Text("Visible")
      im.NextColumn()
      im.Text("Color")
      im.NextColumn()
      im.Text("GroundModel")
      im.NextColumn()
      im.Separator()

      for _,k in pairs(gms) do
        local v = groundModels[k]
        im.PushID1(k..'_active')
        im.SetCursorPosX(15)
        im.Checkbox('', groundModels[k].active)
        im.NextColumn()
        im.PopID()
        im.SameLine()
        im.PushID1(k..'_color')
        im.SetCursorPosX(65)
        im.ColorEdit3("", groundModels[k].color, im.ColorEditFlags_NoInputs)
        im.PopID()
        im.NextColumn()

        -- im.SetCursorPosX(55)
        if im.TreeNode1(k) then
          im.PushItemWidth(100)
          if im.SliderInt("collisiontype", v.cdata.collisiontype, 0, 30) then
            setValue(k, v, 'collisiontype', v.cdata.collisiontype[0])
          end
          if im.SliderFloat("defaultDepth", v.cdata.defaultDepth, 0.0, 5) then
            setValue(k, v, 'defaultDepth', v.cdata.defaultDepth[0])
          end
          im.ShowHelpMarker('This parameter sets the depth of the surface fluid in meters.', true)
          if im.SliderFloat("dragAnisotropy", v.cdata.dragAnisotropy, 0, 1, "%.2f") then
            setValue(k, v, 'dragAnisotropy', v.cdata.dragAnisotropy[0])
          end
          im.ShowHelpMarker('Upwards/Downwards drag anisotropy. This creates a lifting or sinking effect on the node when it slides through the surface fluid.', true)
          if im.SliderFloat("flowBehaviorIndex", v.cdata.flowBehaviorIndex, 0, 5.0, "%.2f") then
            setValue(k, v, 'flowBehaviorIndex', v.cdata.flowBehaviorIndex[0])
          end
          if im.SliderFloat("flowConsistencyIndex", v.cdata.flowConsistencyIndex, 0, 15000, "%.0f") then
            setValue(k, v, 'flowConsistencyIndex', v.cdata.flowConsistencyIndex[0])
          end
          im.ShowHelpMarker('Determines the speed sensitive drag effect. If <1 then fluid is Pseudoplastic (ketchup, whipped cream, paint) and has less drag coefficient at high speeds. If =1 then fluid is Newtonian, having equal drag coefficient at any speed. If >1 then fluid is Dilatant, having higher drag coefficient at high speeds.', true)
          if im.SliderFloat("fluidDensity", v.cdata.fluidDensity, 0, 50000, "%.0f") then
            setValue(k, v, 'fluidDensity', v.cdata.fluidDensity[0])
          end
          im.ShowHelpMarker('Density of the surface fluid (kg/m^3).', true)
          if im.SliderFloat("hydrodynamicFriction", v.cdata.hydrodynamicFriction, 0, 0.01, "%.4f") then
            setValue(k, v, 'hydrodynamicFriction', v.cdata.hydrodynamicFriction[0])
          end
          im.ShowHelpMarker("This friction coefficient is used to add some extra friction as sliding velocity increases. This is useful for replicating fluid viscosity or speed sensitive friction effects of somewhat fluid-like ground types (soft dirt, sand, mud). If you decide that you'll simulate the fluid like behavior with the more complex fluid physics below, then just set this to 0.", true)
          -- if im.InputText("name", v.cdata.name) then
          --   setValue(k, v, 'name', v.cdata.name[0])
          -- end
          if im.SliderFloat("roughnessCoefficient", v.cdata.roughnessCoefficient, 0, 1, "%.2f") then
            setValue(k, v, 'roughnessCoefficient', v.cdata.roughnessCoefficient[0])
          end
          if im.SliderFloat("shearStrength", v.cdata.shearStrength, 0, 25000, "%.0f") then
            setValue(k, v, 'shearStrength', v.cdata.shearStrength[0])
          end
          if im.Checkbox("skidMarks", v.cdata.skidMarks) then
            setValue(k, v, 'skidMarks', v.cdata.skidMarks[0])
          end
          im.ShowHelpMarker('False = No skidmarks, True = Skidmarks.', true)
          if im.SliderFloat("slidingFrictionCoefficient", v.cdata.slidingFrictionCoefficient, 0.1, 1.5, "%.2f") then
            setValue(k, v, 'slidingFrictionCoefficient', v.cdata.slidingFrictionCoefficient[0])
          end
          if im.SliderFloat("staticFrictionCoefficient", v.cdata.staticFrictionCoefficient, 0.1, 2.0, "%.2f") then
            setValue(k, v, 'staticFrictionCoefficient', v.cdata.staticFrictionCoefficient[0])
          end
          im.ShowHelpMarker('Static friction keeps you in the same place when you are stopped on a hill. This friction coefficient is usually higher than sliding friction.', true)
          if im.SliderFloat("strength", v.cdata.strength, 0, 2, "%.2f") then
            setValue(k, v, 'strength', v.cdata.strength[0])
          end
          im.ShowHelpMarker('This parameter raises or diminishes surface friction in a generic way. It is here so as to be able to do quick calibrations of friction. Start with having this to 1.0 and after tuning the rest of the surface variables, come back and play with this.', true)
          if im.SliderFloat("stribeckVelocity", v.cdata.stribeckVelocity, 0, 7.5, "%.2f") then
            setValue(k, v, 'stribeckVelocity', v.cdata.stribeckVelocity[0])
          end
          im.ShowHelpMarker('The stribeck velocity defines the shape of the static-sliding friction curve. A small stribeck velocity will cause an abrupt change from static to sliding friction, a large stribek velocity will make a slower transition that will feel more "sticky". The inverse (1 / stribeck velocity) is often described as "stribeck coefficient". Reference values can be found in either form, so make sure not to confuse them when looking up reference data.', true)
          im.TreePop()
        end
        im.NextColumn()

        -- debug draw
        if v.active[0] then
          drawGroundModel(visibleGroundModels, debugtype, focusPos, k, v)
        end
      end
      im.EndColumns()
      im.EndChild()
      im.TreePop()
    else
      -- no groundtype filtering: draw them all!
      for _,k in pairs(gms) do
        drawGroundModel(visibleGroundModels, debugtype, focusPos, k, groundModels[k])
      end
    end

    local textLineHeight = im.GetTextLineHeight()

    if im.TreeNode1("visible Groundmodels") then
      im.BeginChild1("GroundModelVisScroll")
      im.BeginColumns("GroundModelColumnsBegin", 3, im.ColumnsFlags_NoResize)

      im.SetColumnWidth(0, 50)
      im.SetColumnWidth(1, 50)
      im.SetColumnWidth(2, 1000)

      -- table header
      im.Separator()
      im.Text("Color")
      im.NextColumn()
      im.Text("Tris")
      im.NextColumn()
      im.Text("GroundModel")
      im.NextColumn()
      im.Separator()

      vgmk = tableKeys(visibleGroundModels)
      table.sort(vgmk, function(a, b) return visibleGroundModels[a] > visibleGroundModels[b] end)


      for _, k in ipairs(vgmk) do
        local v = visibleGroundModels[k]
        local p1 = im.ImVec2Ptr(0,0)
        im.GetCursorScreenPos(p1)
        local p2 = im.ImVec2(p1[0].x + 20, p1[0].y + textLineHeight)
        local cf = groundModels[k].color
        local col = im.GetColorU322(im.ImVec4(cf[0], cf[1], cf[2], cf[3]))
        im.ImDrawList_AddRectFilled(im.GetWindowDrawList(), p1[0], p2, col)
        im.NextColumn()

        im.Text(tostring(v))

        im.NextColumn()
        im.Text(tostring(k))
        im.NextColumn()
      end
      im.EndColumns()
      im.EndChild()

      im.TreePop()
    end

    -- ## commented out following stuff for the time being cause it caused a huuuge framedrop and made the tool unuseable ##

    -- if staticDebug[0] then
    --   local c = Engine.getCollisionDebugData()
    --   if c then
    --     -- postprocessing: sort, do some global stats, etc
    --     c.worlds[1].tris = 0
    --     for kb, body in ipairs(c.worlds[1].bodies) do
    --       body.tris = 0
    --       for kc, col in ipairs(body.cols) do
    --         body.tris = body.tris + col.triCount
    --       end
    --       c.worlds[1].tris = c.worlds[1].tris + body.tris
    --     end
    --     table.sort(c.worlds[1].bodies, function(a, b) return a.tris > b.tris end)
    --   end

      -- display
      -- if im.TreeNode1("Static Collision data: " .. tostring(c.worlds[1].tris) .. " tris") then

        -- im.BeginChild1("StaticColDetailScroll")
        -- im.BeginColumns("StaticColDetailColumnsBegin", 2, im.ColumnsFlags_NoResize)
        -- local firstColumnSize = 150
        -- im.SetColumnWidth(0, firstColumnSize)
        -- im.SetColumnWidth(1, 1000)

        -- -- table header
        -- im.Separator()
        -- im.Text("Triangles")
        -- im.NextColumn()
        -- im.Text("Object")
        -- im.NextColumn()
        -- im.Separator()

        -- for kb, body in ipairs(c.worlds[1].bodies) do
        --   local weight = ((body.tris * 50) / c.worlds[1].tris) * firstColumnSize
        --   -- draw bar in the firs column
        --   local p1 = im.ImVec2Ptr(0,0)
        --   im.GetCursorScreenPos(p1)
        --   local p2 = im.ImVec2(p1[0].x + weight, p1[0].y + textLineHeight)
        --   local col = im.GetColorU322( im.ImVec4(0.65, 0.2, 0.2, 1))
        --   im.ImDrawList_AddRectFilled(im.GetWindowDrawList(), p1[0], p2, col)
        --   -- then the text on top and the other columns
        --   im.Text(string.format("%d (%0.2f%%%%)", body.tris, (body.tris / c.worlds[1].tris) * 100))
        --   im.NextColumn()
        --   im.Text(body.objName .. ' [' .. body.objId .. ']')
        --   im.SameLine()
        --   if ui_imgui.SmallButton("select") then
        --     TorqueScript.eval('EWorldEditor.clearSelection();EWorldEditor.selectObject(' .. tostring(body.objId) .. ');EWorldEditor.dropCameraToSelection();')
        --   end
        --   im.NextColumn()
        -- end
        -- im.EndColumns()
        -- im.EndChild()

        -- im.TreePop()
      -- end
    -- end
  im.End()
end

local function onEditorGuiToolsMenu()
  if ui_imgui.MenuItem1("Groundmodel Debug", nil, imgui_false, imgui_true) then
    windowOpen[0] = true
  end
end

local function onExtensionLoaded()
  setup()
end

local function onSerialize()
  return {
    windowOpen = windowOpen[0],
    staticDebug = staticDebug[0],
  }
end

local function onDeserialized(data)
  windowOpen[0] = data.windowOpen
  staticDebug[0] = data.staticDebug

  Engine.setStaticColDebugEnabled(staticDebug[0])
end

M.openWindow = openWindow
M.onSerialize = onSerialize
M.onDeserialized = onDeserialized
-- M.onEditorGui = onEditorGui
M.onUpdate = onEditorGui
M.onEditorGuiToolsMenu = onEditorGuiToolsMenu
M.onExtensionLoaded = onExtensionLoaded

return M