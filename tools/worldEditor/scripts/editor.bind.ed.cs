//------------------------------------------------------------------------------
// Mission Editor Manager
new ActionMap(EditorMap);

function editorWheelFadeScroll( %val ) {
    EWorldEditor.fadeIconsDist += 0.1 * %val;
    if (EWorldEditor.fadeIconsDist < 0) EWorldEditor.fadeIconsDist = 0;
}

EditorMap.bind( mouse, zaxis, "E", "$mvAbsYAxis = VALUE/100" );
EditorMap.bind( mouse, "alt zaxis", "E", "editorWheelFadeScroll(VALUE)" );
