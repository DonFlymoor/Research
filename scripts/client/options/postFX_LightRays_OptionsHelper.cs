//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_LightRays_General_enabled
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_LightRays_enabled_getValue()
{
    return LightRayPostFX.isEnabled();
}
function Settings_PostFX_LightRays_enabled_setValue( %value )
{
    if( %value $= "true" )
        %value = true;
    else if( %value $= "false")
        %value = false;

    $PostFXManager::PostFX::EnableLightRays = %value;
    if( $PostFXManager::PostFX::EnableLightRay )
        LightRayPostFX.enable();
    else
        LightRayPostFX.disable();
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_LightRays_brightness
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_LightRays_brightness_getValue()
{
    return $LightRayPostFX::brightScalar;
}
function Settings_PostFX_LightRays_brightness_setValue( %value )
{
    $PostFXManager::Settings::LightRays::brightScalar = %value;
    $LightRayPostFX::brightScalar = %value;
}
