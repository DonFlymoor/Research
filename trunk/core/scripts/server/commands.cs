function editorOrbitCameraSelectChange( %size, %center) {
    if(%size > 0) {
        Game.camera.setValidEditOrbitPoint(true);
        Game.camera.setEditOrbitPoint(%center);
    } else {
        Game.camera.setValidEditOrbitPoint(false);
    }
}

function editorCameraAutoFit(%radius) {
    Game.camera.autoFitRadius(%radius);
    Game.setCameraHandler(Game.camera);
}
