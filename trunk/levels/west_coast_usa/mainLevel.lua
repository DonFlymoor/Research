local M = {}

-- data = trigger event data, side = left(L) or right(R) start point
local function animateMainLights(data, side)
  local amberLight1 = scenetree.findObject("Amberlight1_" .. side)
  local amberLight2 = scenetree.findObject("Amberlight2_" .. side)
  local amberLight3 = scenetree.findObject("Amberlight3_" .. side)
  local greenLight = scenetree.findObject("Greenlight_" .. side)
  local stageLight = scenetree.findObject("Stagelight_" .. side)

  if amberLight1 then
    if data.event == 'enter' then
      amberLight1:playAnim('tree_start', false)
    elseif data.event == 'exit' then
      amberLight1:playAnim('tree_end', false)
    end
  end

  if amberLight2 then
    if data.event == 'enter' then
      amberLight2:playAnim('tree_start', false)
    elseif data.event == 'exit' then
      amberLight2:playAnim('tree_end', false)
    end
  end

  if amberLight3 then
    if data.event == 'enter' then
      amberLight3:playAnim('tree_start', false)
    elseif data.event == 'exit' then
      amberLight3:playAnim('tree_end', false)
    end
  end

  if greenLight then
    if data.event == 'enter' then
      greenLight:playAnim('tree_start', false)
    elseif data.event == 'exit' then
      greenLight:playAnim('tree_end', false)
    end
  end

  if stageLight then
    if data.event == 'enter' then
      stageLight:playAnim('prestage_start', false)
    elseif data.event == 'exit' then
      stageLight:playAnim('prestage_end', false)
    end
  end
end

-- data = trigger event data, side = left(L) or right(R) start point
local function animatePrestageLights(data, side)
  local prestageLight = scenetree.findObject("Prestagelight_" .. side)

  if prestageLight then
    if data.event == 'enter' then
      prestageLight:playAnim('prestage_start', false)
    elseif data.event == 'exit' then
      prestageLight:playAnim('prestage_end', false)
    end
  end
end

local function onBeamNGTrigger(data)
  if data.triggerName == "startTrigger_L" then
    animatePrestageLights(data, "L")
  end

  if data.triggerName == "startTrigger_R" then
    animatePrestageLights(data, "R")
  end

  if data.triggerName == "startTrigger_LR" then
    animateMainLights(data, "L")
    animateMainLights(data, "R")
  end

  -- if data.triggerName == "dragTrigger" then
  --   if data.event == "enter" then
  --     local buttonsTable = {}
  --     local DragRaceUI = scenetree.findObject("DragRaceActionMap")
  --     if DragRaceUI then
  --       DragRaceUI:push()
  --     end
  --     table.insert(buttonsTable, {action = 'start_drag', text = 'Accept', cmd = 'extensions.freeroam_dragRace.accept()'})
  --     guihooks.trigger('MissionInfoUpdate',{title = "Drag Strip", type="race", buttons = buttonsTable})
  --   end

  --   if data.event == "exit" then
  --     local DragRaceUI = scenetree.findObject("DragRaceActionMap")
  --     if DragRaceUI then
  --       DragRaceUI:pop()
  --     end
  --     guihooks.trigger('MenuHide', true)
  --     guihooks.trigger('MissionInfoUpdate', nil)
  --   end
  -- end
end

M.onBeamNGTrigger = onBeamNGTrigger

return M