-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- nil values are equal last values
function setPlateText(txt, vehId, designPath)
  log('E', "License Plate", "setPlateText() in main.lua is deprecated. Please use core_vehicles.setPlateText() instead.")
  -- fallback
  core_vehicles.setPlateText(txt, vehId, designPath)
end

function getVehicleLicenseName(veh)
  log('E', "License Plate", "getVehicleLicenseName() in main.lua is deprecated. Please use core_vehicles.getVehicleLicenseName() instead.")
  -- fallback
  core_vehicles.getVehicleLicenseName(veh)
end

encodeJson = jsonEncode
jsonEncodePretty = jsonEncodePretty
serializeJsonToFile = jsonWriteFile
writeJsonFile = jsonWriteFile
readJsonFile = jsonReadFile
