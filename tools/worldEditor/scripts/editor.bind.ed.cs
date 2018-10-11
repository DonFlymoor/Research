//------------------------------------------------------------------------------
// Mission Editor Manager
new ActionMap(EditorMap);

function editorYaw(%val) {
    %yawAdj = getMouseAdjustAmount(%val);
    if((isObject(Game.camera) && Game.camera.newtonRotation) || EWorldEditor.isMiddleMouseDown()) {
        // Clamp and scale
        %yawAdj = mClamp(%yawAdj, -m2Pi()+0.01, m2Pi()-0.01);
        %yawAdj *= 0.5;
    }
    if(EditorSettings.value( "Camera/invertXAxis" )) %yawAdj *= -1;
    $mvYaw += %yawAdj;
}

function editorPitch(%val) {
    %pitchAdj = getMouseAdjustAmount(%val);
    if((isObject(Game.camera) && Game.camera.newtonRotation) || EWorldEditor.isMiddleMouseDown()) {
        // Clamp and scale
        %pitchAdj = mClamp(%pitchAdj, -m2Pi()+0.01, m2Pi()-0.01);
        %pitchAdj *= 0.5;
    }
    if( EditorSettings.value( "Camera/invertYAxis" ) ) %pitchAdj *= -1;
    $mvPitch += %pitchAdj;
}

function editorWheelFadeScroll( %val ) {
    EWorldEditor.fadeIconsDist += %val * 0.1;
    if( EWorldEditor.fadeIconsDist < 0 ) EWorldEditor.fadeIconsDist = 0;
}

EditorMap.bind( mouse, xaxis, "E", "editorYaw(VALUE)" );
EditorMap.bind( mouse, yaxis, "E", "editorPitch(VALUE)" );
EditorMap.bind( mouse, zaxis, "E", "$mvAbsYAxis = VALUE/100" );
EditorMap.bind( mouse, "alt zaxis", "E", "editorWheelFadeScroll(VALUE)" );
