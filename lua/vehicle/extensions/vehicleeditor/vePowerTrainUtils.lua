local M = {}

local pw = require('powertrain')
local imguiUtils = require('ui/imguiUtils')
local im = extensions.ui_imgui

local function displayLivedataByType(devName,deviceType)
  im.BeginColumns("devicelivetable", 2, im.ColumnsFlags_NoResize)
  im.SetColumnWidth(0, 200)
  im.SetColumnWidth(1, 1000)
  for _,device in pairs(pw.getDevices()) do
    if device.type == deviceType and device.name == devName then
      if deviceType == 'combustionEngine' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("engineLoad", tostring(device.engineLoad))
          imguiUtils.cell("forcedInductionCoef", tostring(device.forcedInductionCoef))
          imguiUtils.cell("intakeAirDensityCoef", tostring(device.intakeAirDensityCoef))
          im.TreePop()
        end
      end
      if deviceType == 'differential' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("diffAngle", tostring(device.diffAngle))
          imguiUtils.cell("outputAV2", tostring(device.outputAV2))
          imguiUtils.cell("outputTorque2", tostring(device.outputTorque2))
          im.TreePop()
        end
      end
      if deviceType == 'shaft'then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then 
          im.Separator()
          imguiUtils.cell("primaryOutputAVName", tostring(device.primaryOutputAVName))
          imguiUtils.cell("secondaryOutputAVName", tostring(device.secondaryOutputAVName))
          imguiUtils.cell("primaryOutputTorqueName", tostring(device.primaryOutputTorqueName))
          imguiUtils.cell("secondaryOutputTorqueName", tostring(device.secondaryOutputTorqueName))
          im.TreePop()
        end
      end
      if device.type == 'manualGearbox' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then 
          im.Separator()
          for i=0,#device.gearDamages do
            imguiUtils.cell(tostring(i), tostring(device.gearDamages[i]))
          end
          im.TreePop()
        end
      end
      if deviceType == 'frictionClutch' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("clutchAngle", tostring(device.clutchAngle))
          imguiUtils.cell("torqueDiff", tostring(device.torqueDiff))
          imguiUtils.cell("lockSpring", tostring(device.lockSpring))
          imguiUtils.cell("lockDamp", tostring(device.lockDamp))
          imguiUtils.cell("thermalEfficiency", tostring(device.thermalEfficiency))
          im.TreePop()
        end
      end
      if deviceType == 'torqueConverter' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("lockupClutchAngle", tostring(device.lockupClutchAngle))
          imguiUtils.cell("torqueDiff", tostring(device.torqueDiff))
          imguiUtils.cell("lockupClutchSpring", tostring(device.lockupClutchSpring))
          imguiUtils.cell("lockupClutchDamp", tostring(device.lockupClutchDamp))
          im.TreePop()
        end
      end
      if deviceType == 'automaticGearbox' then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("parkClutchAngle", tostring(device.parkClutchAngle))
          imguiUtils.cell("oneWayTorqueSmoother", tostring(device.oneWayTorqueSmoother:value()))
          imguiUtils.cell("parkLockSpring", tostring(device.parkLockSpring))
          im.TreePop()
        end
      end
      if deviceType == "cvtGearbox"then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("parkLockSpring", tostring(device.parkLockSpring))
          imguiUtils.cell("oneWayTorqueSmoother", tostring(device.oneWayTorqueSmoother:value()))
          im.TreePop()
        end
      end
      if deviceType == "dctGearbox"then
        if im.TreeNodeEx1(device.name,im.TreeNodeFlags_DefaultOpen) then
          im.Separator()
          imguiUtils.cell("torqueDiff", tostring(device.torqueDiff))
          imguiUtils.cell("parkLockSpring", tostring(device.parkLockSpring))
          imguiUtils.cell("clutchAngle1", tostring(device.clutchAngle1))
          imguiUtils.cell("clutchAngle2", tostring(device.clutchAngle2))
          imguiUtils.cell("lockSpring1", tostring(device.lockSpring1))
          imguiUtils.cell("lockSpring2", tostring(device.lockSpring1))
          imguiUtils.cell("lockDamp1", tostring(device.lockDamp1))
          imguiUtils.cell("lockDamp2", tostring(device.lockDamp2))
          imguiUtils.cell("lockDamp2", tostring(device.lockDamp2))
          imguiUtils.cell("gearRatio1", tostring(device.gearRatio1))
          imguiUtils.cell("gearRatio2", tostring(device.gearRatio2))
          im.TreePop()
        end
      end
    end
  end
  im.EndColumns()
end
function M.displayLivedata()
  if im.TreeNodeEx1('All Devices',im.TreeNodeFlags_DefaultOpen) then
    for _, device in pairs(pw.getDevices()) do
      if im.TreeNodeEx1(device.name) then
        im.BeginColumns("nodelivetable", 2, im.ColumnsFlags_NoResize)
        im.SetColumnWidth(0, 200)
        im.SetColumnWidth(1, 1000)
        imguiUtils.cell("inputAV", tostring(device.inputAV))
        imguiUtils.cell("outputAV1", tostring(device.outputAV1))
        if device.outputAV2 then
          imguiUtils.cell("outputAV2", tostring(device.outputAV2))
        end
        imguiUtils.cell("outputTorque1", tostring(device.outputTorque1))
        if device.outputTorque2 then
          imguiUtils.cell("outputTorque2", tostring(device.outputTorque2))
        end
        imguiUtils.cell("isBroken", tostring(device.isBroken))
        imguiUtils.cell("mode", tostring(device.mode))
        imguiUtils.cell("virtualMassAV", tostring(device.virtualMassAV))
        imguiUtils.cell("isPhysicallyDisconnected", tostring(device.isPhysicallyDisconnected))
        imguiUtils.cell("gearRatio", tostring(device.gearRatio))
        imguiUtils.cell("cumulativeGearRatio", tostring(device.cumulativeGearRatio))
        im.EndColumns()
        im.TreePop()
      end
    end
    im.TreePop()
  end
end
function M.showLiveData(deviceID)
  im.Separator()
  displayLivedataByType(v.data.powertrain[deviceID].name,v.data.powertrain[deviceID].type) 
end
function M.showJbeamData(deviceID)
  if im.TreeNodeEx1("All jbeam data") then
    imguiUtils.addRecursiveTreeTable(v.data.powertrain[deviceID], '', false)
    im.TreePop()
  end

end

return M