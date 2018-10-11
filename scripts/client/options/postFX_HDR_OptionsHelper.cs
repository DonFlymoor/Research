
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Brightness_tone_mapping_contrast
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Brightness_tone_mapping_contrast_getValue()
{
    return $HDRPostFX::enableToneMapping;
}
function Settings_PostFX_HDR_Brightness_tone_mapping_contrast_setValue( %value )
{
    $PostFXManager::Settings::HDR::enableToneMapping = %value;
    $HDRPostFX::enableToneMapping = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Brightness_key_value
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Brightness_key_value_getValue()
{
    return $HDRPostFX::keyValue;
}
function Settings_PostFX_HDR_Brightness_key_value_setValue( %value )
{
    $PostFXManager::Settings::HDR::keyValue = %value;
    $HDRPostFX::keyValue = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Brightness_minimum_luminance
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Brightness_minimum_luminance_getValue()
{
    return $HDRPostFX::minLuminace;
}
function Settings_PostFX_HDR_Brightness_minimum_luminance_setValue( %value )
{
    $PostFXManager::Settings::HDR::minLuminace = %value;
    $HDRPostFX::minLuminace = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Brightness_white_cutoff
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Brightness_white_cutoff_getValue()
{
    return $HDRPostFX::whiteCutoff;
}
function Settings_PostFX_HDR_Brightness_white_cutoff_setValue( %value )
{
    $PostFXManager::Settings::HDR::whiteCutoff = %value;
    $HDRPostFX::whiteCutoff = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Brightness_adapt_rate
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Brightness_adapt_rate_getValue()
{
    return $HDRPostFX::adaptRate;
}
function Settings_PostFX_HDR_Brightness_adapt_rate_setValue( %value )
{
    $PostFXManager::Settings::HDR::adaptRate = %value;
    $HDRPostFX::adaptRate = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Bloom_enable
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Bloom_enable_getValue()
{
    return $HDRPostFX::enableBloom;
}
function Settings_PostFX_HDR_Bloom_enable_setValue( %value )
{
    $PostFXManager::Settings::HDR::enableBloom = %value;
    $HDRPostFX::enableBloom = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Bloom_bright_pass_treshold
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Bloom_bright_pass_treshold_getValue()
{
    return $HDRPostFX::brightPassThreshold;
}
function Settings_PostFX_HDR_Bloom_bright_pass_treshold_setValue( %value )
{
    $PostFXManager::Settings::HDR::brightPassThreshold = %value;
    $HDRPostFX::brightPassThreshold = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Bloom_blur_multiplier
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Bloom_blur_multiplier_getValue()
{
    return $HDRPostFX::gaussMultiplier;
}
function Settings_PostFX_HDR_Bloom_blur_multiplier_setValue( %value )
{
    $PostFXManager::Settings::HDR::gaussMultiplier = %value;
    $HDRPostFX::gaussMultiplier = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Bloom_blur_mean_value
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Bloom_blur_mean_value_getValue()
{
    return $HDRPostFX::gaussMean;
}
function Settings_PostFX_HDR_Bloom_blur_mean_value_setValue( %value )
{
    $PostFXManager::Settings::HDR::gaussMean = %value;
    $HDRPostFX::gaussMean = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Bloom_blur_std_dev_value
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Bloom_blur_std_dev_value_getValue()
{
    return $HDRPostFX::gaussStdDev;
}
function Settings_PostFX_HDR_Bloom_blur_std_dev_value_setValue( %value )
{
    $PostFXManager::Settings::HDR::gaussStdDev = %value;
    $HDRPostFX::gaussStdDev = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Effects_enable_color_shift
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Effects_enable_color_shift_getValue()
{
    return $HDRPostFX::enableBlueShift;
}
function Settings_PostFX_HDR_Effects_enable_color_shift_setValue( %value )
{
    $PostFXManager::Settings::HDR::enableBlueShift = %value;
    $HDRPostFX::enableBlueShift = %value;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Settings_PostFX_HDR_Effects_color_shift
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Settings_PostFX_HDR_Effects_color_shift_getValue()
{
    %color = $HDRPostFX::blueShiftColor;

    %rgb = "rgb(" SPC (getWord(%color, 0)*255) SPC (getWord(%color, 1)*255) SPC (getWord(%color, 2)*255) SPC "1 )";
    debug( "    Settings_PostFX_HDR_Effects_color_shift_getValue" SPC %rgb SPC " - " SPC $HDRPostFX::blueShiftColor);
    return %rgb;
}
function Settings_PostFX_HDR_Effects_color_shift_setValue( %value )
{
    //clean value string
    %value = cleanRGB(%value);

    //we need values as float, alpha allways 1.0f
    %rgbFloat = (getWord(%value, 0)/255) SPC (getWord(%value, 1)/255) SPC (getWord(%value, 2)/255) SPC 1;
    debug( "    Settings_PostFX_HDR_Effects_color_shift_setValue" SPC %rgbFloat);

    $PostFXManager::Settings::HDR::blueShiftColor = %rgbFloat;
    $HDRPostFX::blueShiftColor = %rgbFloat;
}
