//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_General_enabled
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_General_enabled_getValue()
{
    return DOFPostEffect.isEnabled();
}
function Settings_PostFX_DOF_General_enabled_setValue( %value )
{
    if( %value $= "true" )
        %value = true;
    else if( %value $= "false")
        %value = false;

    $PostFXManager::PostFX::EnableDOF = %value;
    if( $PostFXManager::PostFX::EnableDOF )
        DOFPostEffect.enable();
    else
        DOFPostEffect.disable();
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_general_enable_auto_focus
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_General_enable_auto_focus_getValue()
{
    return $DOFPostFx::EnableAutoFocus;
}
function Settings_PostFX_DOF_General_enable_auto_focus_setValue( %value )
{
    $PostFXManager::Settings::DOF::EnableAutoFocus = %value;
    $DOFPostFx::EnableAutoFocus = %value;
    DOFPostEffect.setAutoFocus( %value );
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_near_blur_max
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_near_blur_max_getValue()
{
    return $DOFPostFx::BlurMin;
}
function Settings_PostFX_DOF_autoFocus_near_blur_max_setValue( %value )
{
    $PostFXManager::Settings::DOF::BlurMin = %value;
    $DOFPostFx::BlurMin = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_far_blur_max
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_far_blur_max_getValue()
{
    return $DOFPostFx::BlurMax;
}
function Settings_PostFX_DOF_autoFocus_far_blur_max_setValue( %value )
{
    $PostFXManager::Settings::DOF::BlurMax = %value;
    $DOFPostFx::BlurMax = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_focus_range_min
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_focus_range_min_getValue()
{
    return $DOFPostFx::FocusRangeMin;
}
function Settings_PostFX_DOF_autoFocus_focus_range_min_setValue( %value )
{
    $PostFXManager::Settings::DOF::FocusRangeMin = %value;
    $DOFPostFx::FocusRangeMin = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_focus_range_max
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_focus_range_max_getValue()
{
    return $DOFPostFx::FocusRangeMax;
}
function Settings_PostFX_DOF_autoFocus_focus_range_max_setValue( %value )
{
    $PostFXManager::Settings::DOF::FocusRangeMax = %value;
    $DOFPostFx::FocusRangeMax = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_blur_curve_near
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_blur_curve_near_getValue()
{
    return $DOFPostFx::BlurCurveNear;
}
function Settings_PostFX_DOF_autoFocus_blur_curve_near_setValue( %value )
{
    $PostFXManager::Settings::DOF::BlurCurveNear = %value;
    $DOFPostFx::BlurCurveNear = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_DOF_autoFocus_blur_curve_far
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_DOF_autoFocus_blur_curve_far_getValue()
{
    return $DOFPostFx::BlurCurveFar;
}
function Settings_PostFX_DOF_autoFocus_blur_curve_far_setValue( %value )
{
    $PostFXManager::Settings::DOF::BlurCurveFar = %value;
    $DOFPostFx::BlurCurveFar = %value;
    DOFPostEffect.setFocusParams( $DOFPostFx::BlurMin, $DOFPostFx::BlurMax, $DOFPostFx::FocusRangeMin, $DOFPostFx::FocusRangeMax, -($DOFPostFx::BlurCurveNear), $DOFPostFx::BlurCurveFar );
}

