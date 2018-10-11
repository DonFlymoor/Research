// this file is the interface for CEF <--> T3D

function changeVehicleColor(%color) {
    %obj = getPlayerVehicle(0);
    if (!isObject(%obj))
        return;

    %obj.color = %color;
}

function getVehicleColorPalette(%index) {
    %obj = getPlayerVehicle(0);
    if (!isObject(%obj))
    return;

    return %obj.getFieldValue("colorPalette" @ %index);
}

function setVehicleColorPalette(%index, %color) {
    %obj = getPlayerVehicle(0);
    if (!isObject(%obj))
        return;

    %obj.setFieldValue("colorPalette" @ %index, %color);
}