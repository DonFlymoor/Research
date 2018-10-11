
function initBaseClient()
{
    // Base client functionality
    exec( "./mission.cs" );
    exec("~/scripts/client/postFx.cs");
    exec( "./renderManager.cs" );
    exec( "./lighting.cs" );

    initRenderManager();
    initLightingSystems();

    // Initialize all core post effects.
    initPostEffects();

    // Initialize the post effect manager.
    exec("~/scripts/client/postFx/postFXManager.gui");
    exec("~/scripts/client/postFx/postFXManager.gui.cs");
    exec("~/scripts/client/postFx/postFXManager.gui.settings.cs");
    exec("~/scripts/client/postFx/postFXManager.persistance.cs");
    exec("tools/gui/saveFileDialog.ed.cs");
    exec("tools/gui/openFileDialog.ed.cs");

    PostFXManager.settingsApplyDefaultPreset();  // Get the default preset settings
}
