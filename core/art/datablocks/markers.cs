
datablock MissionMarkerData(WayPointMarker)
{
    category = "Misc";
    shapeFile = "core/art/shapes/octahedron.dts";
};

datablock MissionMarkerData(SpawnSphereMarker)
{
    category = "Misc";
    shapeFile = "core/art/shapes/spawn_arrow.DAE";
};

datablock MissionMarkerData(CameraBookmarkMarker)
{
    category = "Misc";
    shapeFile = "core/art/shapes/camera.dts";
};

function Marker::setCameraAtMarker(%this)
{
    if(!isObject( Game ) || !isObject( Game.camera )) {
        return;
    }

    Game.camera.setTransformF(%this.getTransformF());
}

function Marker::setMarkerAtCamera(%this)
{
    if(!isObject( Game ) || !isObject( Game.camera )) {
        return;
    }

    %this.setTransformF(Game.camera.getTransformF());
}
