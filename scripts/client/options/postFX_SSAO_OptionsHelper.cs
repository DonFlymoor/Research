//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_General_enabled
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_General_enabled_getValue()
{
    return SSAOPostFx.isEnabled();
}
function Settings_PostFX_SSAO_General_enabled_setValue( %value )
{
    if( %value $= "true" )
        %value = true;
    else if( %value $= "false")
        %value = false;

    $PostFXManager::PostFX::EnableSSAO = %value;
    if( $PostFXManager::PostFX::EnableSSAO )
        SSAOPostFx.enable();
    else
        SSAOPostFx.disable();
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_quality
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_General_quality_getValue()
{
    return $SSAOPostFx::quality;
}
function Settings_PostFX_SSAO_General_quality_setValue( %value )
{
    $PostFXManager::Settings::SSAO::quality = %value;
    $SSAOPostFx::quality = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_General_overall_strength
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_General_overall_strength_getValue()
{
    return $SSAOPostFx::overallStrength;
}
function Settings_PostFX_SSAO_General_overall_strength_setValue( %value )
{
    $PostFXManager::Settings::SSAO::overallStrength = %value;
    $SSAOPostFx::overallStrength  = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_General_blur_softness
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_General_blur_softness_getValue()
{
    return $SSAOPostFx::blurDepthTol;
}
function Settings_PostFX_SSAO_General_blur_softness_setValue( %value )
{
    $PostFXManager::Settings::SSAO::blurDepthTol = %value;
    $SSAOPostFx::blurDepthTol = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_General_blur_normalMaps
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_General_blur_normalMaps_getValue()
{
    return $SSAOPostFx::blurNormalTol;
}
function Settings_PostFX_SSAO_General_blur_normalMaps_setValue( %value )
{
    $PostFXManager::Settings::SSAO::blurNormalTol = %value;
    $SSAOPostFx::blurNormalTol = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_radius
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_radius_getValue()
{
    return $SSAOPostFx::sRadius;
}
function Settings_PostFX_SSAO_near_radius_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sRadius = %value;
    $SSAOPostFx::sRadius = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_strength
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_strength_getValue()
{
    return $SSAOPostFx::sStrength;
}
function Settings_PostFX_SSAO_near_strength_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sStrength = %value;
    $SSAOPostFx::sStrength = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_depth_min
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_depth_min_getValue()
{
    return $SSAOPostFx::sDepthMin;
}
function Settings_PostFX_SSAO_near_depth_min_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sDepthMin = %value;
    $SSAOPostFx::sDepthMin = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_depth_max
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_depth_max_getValue()
{
    return $SSAOPostFx::sDepthMax;
}
function Settings_PostFX_SSAO_near_depth_max_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sDepthMax = %value;
    $SSAOPostFx::sDepthMax = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_NM_tolerance
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_NM_tolerance_getValue()
{
    return $SSAOPostFx::sNormalTol;
}
function Settings_PostFX_SSAO_near_NM_tolerance_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sNormalTol = %value;
    $SSAOPostFx::sNormalTol = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_near_NM_power
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_near_NM_power_getValue()
{
    return $SSAOPostFx::sNormalPow;
}
function Settings_PostFX_SSAO_near_NM_power_setValue( %value )
{
    $PostFXManager::Settings::SSAO::sNormalPow = %value;
    $SSAOPostFx::sNormalPow = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_radius
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_radius_getValue()
{
    return $SSAOPostFx::lRadius;
}
function Settings_PostFX_SSAO_far_radius_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lRadius = %value;
    $SSAOPostFx::lRadius = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_strength
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_strength_getValue()
{
    return $SSAOPostFx::lStrength;
}
function Settings_PostFX_SSAO_far_strength_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lStrength = %value;
    $SSAOPostFx::lStrength = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_depth_min
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_depth_min_getValue()
{
    return $SSAOPostFx::lDepthMin;
}
function Settings_PostFX_SSAO_far_depth_min_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lDepthMin = %value;
    $SSAOPostFx::lDepthMin = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_depth_max
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_depth_max_getValue()
{
    return $SSAOPostFx::lDepthMax;
}
function Settings_PostFX_SSAO_far_depth_max_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lDepthMax = %value;
    $SSAOPostFx::lDepthMax = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_NM_tolerance
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_NM_tolerance_getValue()
{
    return $SSAOPostFx::lNormalTol;
}
function Settings_PostFX_SSAO_far_NM_tolerance_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lNormalTol = %value;
    $SSAOPostFx::lNormalTol = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_SSAO_far_NM_power
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_SSAO_far_NM_power_getValue()
{
    return $SSAOPostFx::lNormalPow;
}
function Settings_PostFX_SSAO_far_NM_power_setValue( %value )
{
    $PostFXManager::Settings::SSAO::lNormalPow = %value;
    $SSAOPostFx::lNormalPow = %value;
}
