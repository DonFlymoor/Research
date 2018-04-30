singleton Material(tsfb)
{
    mapTo = "tsfb";
    diffuseMap[1] = "vehicles/tsfb/tsfb_d.dds";
    specularMap[1] = "vehicles/tsfb/tsfb_s.dds";
    normalMap[1] = "vehicles/tsfb/tsfb_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/tsfb/tsfb_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
};

singleton Material(moonhawk_drag)
{
    mapTo = "moonhawk_drag";
    diffuseMap[1] = "vehicles/moonhawk/moonhawk_drag_d.dds";
    specularMap[1] = "vehicles/moonhawk/moonhawk_drag_d.dds";
    normalMap[1] = "vehicles/moonhawk/moonhawk_drag_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/moonhawk/moonhawk_drag_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(semi_taillight_L)
{
    mapTo = "semi_taillight_L";
};

singleton Material(semi_taillight_R)
{
    mapTo = "semi_taillight_R";
};

singleton Material(trailer_signal_L)
{
    mapTo = "trailer_signal_L";
};

singleton Material(trailer_signal_R)
{
    mapTo = "trailer_signal_R";
};

singleton Material(trailer_taillight)
{
    mapTo = "trailer_taillight";
};

singleton Material(rallyparts)
{
    mapTo = "rallyparts";
    diffuseMap[0] = "rallyparts_d.dds";
    specularMap[0] = "rallyparts_s.dds";
    normalMap[0] = "rallyparts_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    diffuseColor[0] = "1 1 1 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
};

singleton Material(semi_lights)
{
    mapTo = "semi_lights";
    diffuseMap[1] = "vehicles/common/semi_lights_d.dds";
    specularMap[1] = "vehicles/common/semi_lights_s.dds";
    normalMap[1] = "vehicles/common/semi_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/semi_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(semi_lights_on)
{
    mapTo = "semi_lights_on";
    diffuseMap[2] = "vehicles/common/semi_lights_g.dds";
    specularMap[2] = "vehicles/common/semi_lights_s.dds";
    normalMap[2] = "vehicles/common/semi_lights_n.dds";
    diffuseMap[1] = "vehicles/common/semi_lights_d.dds";
    specularMap[1] = "vehicles/common/semi_lights_s.dds";
    normalMap[1] = "vehicles/common/semi_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/semi_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.2";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(semi_lights_on_intense)
{
    mapTo = "semi_lights_on_intense";
    diffuseMap[2] = "vehicles/common/semi_lights_g.dds";
    specularMap[2] = "vehicles/common/semi_lights_s.dds";
    normalMap[2] = "vehicles/common/semi_lights_n.dds";
    diffuseMap[1] = "vehicles/common/semi_lights_d.dds";
    specularMap[1] = "vehicles/common/semi_lights_s.dds";
    normalMap[1] = "vehicles/common/semi_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/semi_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.35";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(semi_lights_dmg)
{
    mapTo = "semi_lights_dmg";
    diffuseMap[1] = "vehicles/common/semi_lights_dmg_d.dds";
    specularMap[1] = "vehicles/common/semi_lights_dmg_s.dds";
    normalMap[1] = "vehicles/common/semi_lights_dmg_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/semi_lights_dmg_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(car_trim)
{
    mapTo = "trim";
    diffuseMap[1] = "trim_d.dds";
    specularMap[1] = "trim_s.dds";
    normalMap[1] = "trim_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "trim_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(n2o)
{
    mapTo = "n2o";
    diffuseMap[0] = "n2o_d.dds";
    specularMap[0] = "n2o_s.dds";
    normalMap[0] = "n2o_n.dds";
    reflectivityMap[0] = "n2o_r.dds";
    specularPower[0] = "15";
    pixelSpecular[0] = "1";
    useAnisotropic[0] = "1";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng";
    materialTag1 = "vehicle";
};

singleton Material(car_snorkel)
{
    mapTo = "snorkel";
    diffuseMap[1] = "snorkel_d.dds";
    specularMap[1] = "snorkel_s.dds";
    normalMap[1] = "snorkel_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "snorkel_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(spotlight_police)
{
    mapTo = "spotlight_police";
    diffuseMap[1] = "spotlight_d.dds";
    specularMap[1] = "spotlight_s.dds";
    normalMap[1] = "spotlight_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "spotlight_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(adcarrier)
{
    mapTo = "adcarrier";
    diffuseMap[1] = "adcarrier_d.dds";
    specularMap[1] = "adcarrier_s.dds";
    normalMap[1] = "adcarrier_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "adcarrier_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(adcarrier_ad)
{
    mapTo = "adcarrier_ad";
    diffuseMap[1] = "adcarrier_ad_d.dds";
    specularMap[1] = "adcarrier_ad_s.dds";
    normalMap[1] = "adcarrier_ad_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "adcarrier_ad_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material("adcarrier_ad.skin_taxi_ad.pointie")
{
    mapTo = "adcarrier_ad.skin_taxi_ad.pointie";
    diffuseMap[1] = "adcarrier_ad_d_pointie.dds";
    specularMap[1] = "adcarrier_ad_s.dds";
    normalMap[1] = "adcarrier_ad_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "adcarrier_ad_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material("adcarrier_ad.skin_taxi_ad.burger")
{
    mapTo = "adcarrier_ad.skin_taxi_ad.burger";
    diffuseMap[1] = "adcarrier_ad_d_burger.dds";
    specularMap[1] = "adcarrier_ad_s.dds";
    normalMap[1] = "adcarrier_ad_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "adcarrier_ad_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(towhitch)
{
    mapTo = "towhitch";
    normalMap[0] = "vehicles/common/towhitch_n.dds";
    diffuseMap[0] = "vehicles/common/towhitch_d.dds";
    specularMap[0] = "vehicles/common/towhitch_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(etk_engine_i6)
{
    mapTo = "etk_engine_i6";
    normalMap[0] = "etk_engine_i6_n.dds";
    diffuseMap[0] = "etk_engine_i6_d.dds";
    specularMap[0] = "etk_engine_i6_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(pessima_engine)
{
    mapTo = "pessima_engine";
    normalMap[0] = "pessima_engine_n.dds";
    diffuseMap[0] = "pessima_engine_d.dds";
    specularMap[0] = "pessima_engine_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};


singleton Material(gavril_lettering)
{
    mapTo = "gavril_lettering";
    specularMap[0] = "vehicles/common/gavril_lettering_s.dds";
    normalMap[0] = "vehicles/common/gavril_lettering_n.dds";
    diffuseMap[0] = "vehicles/common/gavril_lettering_d.dds";
    reflectivityMap[0] = "vehicles/common/gavril_lettering_s.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "0";
    translucent = "1";
    //translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle"; materialTag2 = "decal";
    //translucentZWrite = "1";
};


singleton Material(pushbar_01)
{
    mapTo = "pushbar_01";
    diffuseMap[1] = "vehicles/common/pushbar_01_d.dds";
    specularMap[1] = "vehicles/common/pushbar_01_s.dds";
    normalMap[1] = "vehicles/common/pushbar_01_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/pushbar_01_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};


singleton Material(cargobox)
{
    mapTo = "cargobox";
    diffuseMap[1] = "vehicles/common/cargobox_d.dds";
    specularMap[1] = "vehicles/common/cargobox_s.dds";
    normalMap[1] = "vehicles/common/cargobox_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/cargobox_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(supercharger_blower)
{
    mapTo = "supercharger_blower";
    diffuseMap[1] = "vehicles/common/supercharger_blower_d.dds";
    specularMap[1] = "vehicles/common/supercharger_blower_s.dds";
    normalMap[1] = "vehicles/common/supercharger_blower_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/supercharger_blower_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(gavril_v8)
{
    mapTo = "gavril_v8";
    diffuseMap[1] = "vehicles/common/gavril_v8_d.dds";
    specularMap[1] = "vehicles/common/gavril_v8_s.dds";
    normalMap[1] = "vehicles/common/gavril_v8_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/gavril_v8_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(fullsize_engbay)
{
    mapTo = "fullsize_engbay";
    diffuseMap[2] = "vehicles/fullsize/fullsize_c_alt.dds";
    specularMap[2] = "vehicles/fullsize/fullsize_s.dds";
    normalMap[2] = "vehicles/fullsize/fullsize_n.dds";
    diffuseMap[1] = "vehicles/fullsize/fullsize_d.dds";
    specularMap[1] = "vehicles/fullsize/fullsize_s.dds";
    normalMap[1] = "vehicles/fullsize/fullsize_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/fullsize/fullsize_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    diffuseColor[2] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    //diffuseColor[3] = "0 0.3 0.9 1";
    //diffuseColor[3] = "1.5 1.5 1.5 1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    instanceDiffuse[2] = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(glass_mirror)
{
    mapTo = "glass_mirror";
    diffuseColor[0] = "1 1 1 1";
    specular[0] = "1 1 1 1";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "LerpAlpha";
    alphaTest = "0";
    alphaRef = "0";
    doubleSided = "1";
    subSurface[0] = "0";
    subSurfaceColor[0] = "1 1 1 1";
    subSurfaceRolloff[0] = "1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(mirror)
{
    mapTo = "mirror";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/mirror_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};
singleton Material(glass_invisible)
{
    mapTo = "glass_invisible";
    diffuseColor[0] = "1 1 1 1";
    diffuseMap[0] = "vehicles/common/invisible.dds";
    translucentBlendOp = "addAlpha";
    specular[0] = "0 0 0 0";
    specularPower[0] = "128";
    emissive[0] = "1";
    materialTag0 = "Miscellaneous";
    beamngDiffuseColorSlot = "2";
    translucent = "1";
    pixelSpecular[0] = "1";
};

singleton Material(grille)
{
    mapTo = "grille";
    normalMap[0] = "vehicles/common/grille_n.dds";
    diffuseMap[0] = "vehicles/common/grille_d.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "128";
    specularPower[1] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "lerpAlpha";
    alphaTest = "1";
    alphaRef = "5";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(van_lights)
{
    mapTo = "van_lights";
    diffuseMap[1] = "vehicles/common/van_lights_d.dds";
    specularMap[1] = "vehicles/common/van_lights_s.dds";
    normalMap[1] = "vehicles/common/van_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/van_lights_n.dds";
    //diffuseMap[2] = "vehicles/common/van_lights_dirt.dds";
    //normalMap[2] = "vehicles/common/van_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    //diffuseColor[2] = "1.5 1.5 1.5 1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(van_lights_on)
{
    mapTo = "van_lights_on";
    diffuseMap[2] = "vehicles/common/van_lights_g.dds";
    specularMap[2] = "vehicles/common/van_lights_s.dds";
    normalMap[2] = "vehicles/common/van_lights_n.dds";
    diffuseMap[1] = "vehicles/common/van_lights_d.dds";
    specularMap[1] = "vehicles/common/van_lights_s.dds";
    normalMap[1] = "vehicles/common/van_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/van_lights_n.dds";
    //diffuseMap[3] = "vehicles/common/van_lights_dirt.dds";
    //normalMap[3] = "vehicles/common/van_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.15";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    //diffuseColor[3] = "1.5 1.5 1.5 1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(van_lights_on_intense)
{
    mapTo = "van_lights_on_intense";
    diffuseMap[2] = "vehicles/common/van_lights_g.dds";
    specularMap[2] = "vehicles/common/van_lights_s.dds";
    normalMap[2] = "vehicles/common/van_lights_n.dds";
    diffuseMap[1] = "vehicles/common/van_lights_d.dds";
    specularMap[1] = "vehicles/common/van_lights_s.dds";
    normalMap[1] = "vehicles/common/van_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/van_lights_n.dds";
    //diffuseMap[3] = "vehicles/common/van_lights_dirt.dds";
    //normalMap[3] = "vehicles/common/van_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.30";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    //diffuseColor[3] = "1.5 1.5 1.5 1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(van_lights_dmg)
{
    mapTo = "van_lights_dmg";
    diffuseMap[1] = "vehicles/common/van_lights_dmg_d.dds";
    specularMap[1] = "vehicles/common/van_lights_dmg_s.dds";
    normalMap[1] = "vehicles/common/van_lights_dmg_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/van_lights_dmg_n.dds";
    //diffuseMap[2] = "vehicles/common/van_lights_dirt.dds";
    //normalMap[2] = "vehicles/common/van_lights_dmg_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    //diffuseColor[2] = "1.5 1.5 1.5 1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(steer_01a)
{
    mapTo = "steer_01a";
    diffuseMap[0] = "vehicles/common/steer_01a_d.dds";
    specularMap[0] = "vehicles/common/steer_01a_s.dds";
    normalMap[0] = "vehicles/common/steer_01a_n.dds";
    diffuseColor[0] = "1.5 1.5 1.5 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(steer_02a)
{
    mapTo = "steer_02a";
    diffuseMap[0] = "vehicles/common/steer_02a_d.dds";
    specularMap[0] = "vehicles/common/steer_02a_s.dds";
    normalMap[0] = "vehicles/common/steer_02a_n.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(steer_03a)
{
    mapTo = "steer_03a";
    diffuseMap[1] = "vehicles/common/steer_03a_d.dds";
    specularMap[1] = "vehicles/common/steer_03a_s.dds";
    normalMap[1] = "vehicles/common/steer_03a_n.dds";
    diffuseMap[0] = "vehicles/common/steer_03a_d.dds";
    specularMap[0] = "vehicles/common/steer_03a_s.dds";
    reflectivityMap[0] = "vehicles/common/steer_03a_s.dds";
    normalMap[0] = "vehicles/common/steer_03a_n.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    emissive[1] = "1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    diffuseColor[0] = "1.5 1.5 1.5 1";
    diffuseColor[1] = "1.5 1.5 1.5 0.4";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(steer_04a)
{
    mapTo = "steer_04a";
    diffuseMap[0] = "vehicles/common/steer_04a_d.dds";
    specularMap[0] = "vehicles/common/steer_04a_s.dds";
    normalMap[0] = "vehicles/common/steer_04a_n.dds";
    diffuseColor[0] = "1.5 1.5 1.5 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(screen_gps)
{
    mapTo = "screen_gps";
    diffuseMap[0] = "@screen_gps";
    specularMap[0] = "vehicles/common/null.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    emissive[0] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(steer_05a)
{
    mapTo = "steer_05a";
    diffuseMap[0] = "vehicles/common/steer_05a_d.dds";
    specularMap[0] = "vehicles/common/steer_05a_s.dds";
    normalMap[0] = "vehicles/common/steer_05a_n.dds";
    diffuseColor[0] = "1.2 1.2 1.2 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(suctionmount)
{
    mapTo = "suctionmount";
    diffuseMap[0] = "vehicles/common/suctionmount_d.dds";
    specularMap[0] = "vehicles/common/suctionmount_s.dds";
    normalMap[0] = "vehicles/common/suctionmount_n.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(gps)
{
    mapTo = "gps";
    diffuseMap[0] = "vehicles/common/gps_d.dds";
    specularMap[0] = "vehicles/common/gps_s.dds";
    normalMap[0] = "vehicles/common/gps_n.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(oilcooler)
{
    mapTo = "oilcooler";
    diffuseMap[0] = "vehicles/common/oilcooler_d.dds";
    specularMap[0] = "vehicles/common/oilcooler_s.dds";
    normalMap[0] = "vehicles/common/oilcooler_n.dds";
    diffuseColor[0] = "1.5 1.5 1.5 1";
    specularPower[0] = "128";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
};

singleton Material(decals_police)
{
    mapTo = "decals_police";
    reflectivityMap[0] = "vehicles/common/decals_police.dds";
    diffuseMap[0] = "vehicles/common/decals_police.dds";
    specularMap[0] = "vehicles/common/null.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "0 0.3 0.9 1";
    useAnisotropic[0] = "1";
    diffuseMap[1] = "vehicles/common/decals_police.dds";
    specularMap[1] = "vehicles/common/null.dds";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[1] = "0 0.3 0.9 0.65";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle"; materialTag2 = "decal";
    translucentZWrite = "1";
};

singleton Material(decals_sheriff)
{
    mapTo = "decals_sheriff";
    reflectivityMap[0] = "vehicles/common/decals_sheriff.dds";
    diffuseMap[0] = "vehicles/common/decals_sheriff.dds";
    specularMap[0] = "vehicles/common/null.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "0.4 0.55 0.15 1";
    useAnisotropic[0] = "1";
    diffuseMap[1] = "vehicles/common/decals_sheriff.dds";
    specularMap[1] = "vehicles/common/null.dds";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    diffuseColor[1] = "0.4 0.55 0.15 0.65";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle"; materialTag2 = "decal";
    translucentZWrite = "1";
};

singleton Material(decals_gauges)
{
    mapTo = "decals_gauges";
    diffuseMap[0] = "vehicles/common/decals_gauges.dds";
    diffuseColor[0] = "1 1 1 1";
    diffuseMap[1] = "vehicles/common/decals_gauges.dds";
    diffuseColor[1] = "1 1 1 0.35";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    glow[1] = "1";
    emissive[1] = "1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle"; materialTag2 = "decal";
};

singleton Material(rollcage_01a)
{
    mapTo = "rollcage_01a";
    colorPaletteMap[0] = "vehicles/common/nullcolormask.dds";
    reflectivityMap[0] = "vehicles/common/null3.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null3.dds";
    normalMap[0] = "vehicles/common/null_n.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(rollcage_01b)
{
    mapTo = "rollcage_01b";
    reflectivityMap[0] = "vehicles/common/null3.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null3.dds";
    normalMap[0] = "vehicles/common/null_n.dds";
    diffuseColor[0] = "0.1 0.1 0.1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(invis)
{
    mapTo = "invis";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(signal_L)
{
    mapTo = "signal_L";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(signal_R)
{
    mapTo = "signal_R";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(parkingbrake)
{
    mapTo = "parkingbrake";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(battery)
{
    mapTo = "battery";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(checkengine)
{
    mapTo = "checkengine";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(hazard)
{
    mapTo = "hazard";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(lowpressure)
{
    mapTo = "lowpressure";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(abs)
{
    mapTo = "abs";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(abswarn)
{
    mapTo = "abswarn";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(tcs)
{
    mapTo = "tcs";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(esc)
{
    mapTo = "esc";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(temp)
{
    mapTo = "temp";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(oil)
{
    mapTo = "oil";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(lowfuel)
{
    mapTo = "lowfuel";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(highbeam)
{
    mapTo = "highbeam";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(lowbeam)
{
    mapTo = "lowbeam";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(foglight)
{
    mapTo = "foglight";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(rearfog)
{
    mapTo = "rearfog";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(ramplow)
{
    mapTo = "ramplow";
    diffuseMap[1] = "vehicles/common/ramplow_d.dds";
    specularMap[1] = "vehicles/common/ramplow_s.dds";
    normalMap[1] = "vehicles/common/ramplow_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/ramplow_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "32";
    pixelSpecular[1] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
};

singleton Material(skidplate)
{
    mapTo = "skidplate";
    normalMap[0] = "vehicles/common/skidplate_n.dds";
    diffuseMap[0] = "vehicles/common/skidplate_d.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "128";
    specularPower[1] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(light_generic)
{
    mapTo = "light_generic";
    diffuseMap[1] = "vehicles/common/light_generic_d.dds";
    specularMap[1] = "vehicles/common/light_generic_s.dds";
    normalMap[1] = "vehicles/common/light_generic_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/light_generic_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(light_generic_dmg)
{
    mapTo = "light_generic_dmg";
    diffuseMap[1] = "vehicles/common/light_generic_d.dds";
    specularMap[1] = "vehicles/common/light_generic_s.dds";
    normalMap[1] = "vehicles/common/light_generic_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/light_generic_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(light_generic_on)
{
    mapTo = "light_generic_on";
    diffuseMap[2] = "vehicles/common/light_generic_g.dds";
    specularMap[2] = "vehicles/common/light_generic_s.dds";
    normalMap[2] = "vehicles/common/light_generic_n.dds";
    diffuseMap[1] = "vehicles/common/light_generic_d.dds";
    specularMap[1] = "vehicles/common/light_generic_s.dds";
    normalMap[1] = "vehicles/common/light_generic_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/light_generic_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.12";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(light_generic_on_intense)
{
    mapTo = "light_generic_on_intense";
    diffuseMap[2] = "vehicles/common/light_generic_g.dds";
    specularMap[2] = "vehicles/common/light_generic_s.dds";
    normalMap[2] = "vehicles/common/light_generic_n.dds";
    diffuseMap[1] = "vehicles/common/light_generic_d.dds";
    specularMap[1] = "vehicles/common/light_generic_s.dds";
    normalMap[1] = "vehicles/common/light_generic_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/light_generic_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.20";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(tsfb_lights)
{
    mapTo = "tsfb_lights";
    diffuseMap[1] = "vehicles/common/tsfb_lights_d.dds";
    specularMap[1] = "vehicles/common/tsfb_lights_s.dds";
    normalMap[1] = "vehicles/common/tsfb_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/tsfb_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(tsfb_lights_on)
{
    mapTo = "tsfb_lights_on";
    diffuseMap[2] = "vehicles/common/tsfb_lights_g.dds";
    specularMap[2] = "vehicles/common/tsfb_lights_s.dds";
    normalMap[2] = "vehicles/common/tsfb_lights_n.dds";
    diffuseMap[1] = "vehicles/common/tsfb_lights_d.dds";
    specularMap[1] = "vehicles/common/tsfb_lights_s.dds";
    normalMap[1] = "vehicles/common/tsfb_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/tsfb_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.12";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(tsfb_lights_on_intense)
{
    mapTo = "tsfb_lights_on_intense";
    diffuseMap[2] = "vehicles/common/tsfb_lights_g.dds";
    specularMap[2] = "vehicles/common/tsfb_lights_s.dds";
    normalMap[2] = "vehicles/common/tsfb_lights_n.dds";
    diffuseMap[1] = "vehicles/common/tsfb_lights_d.dds";
    specularMap[1] = "vehicles/common/tsfb_lights_s.dds";
    normalMap[1] = "vehicles/common/tsfb_lights_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/tsfb_lights_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    diffuseColor[2] = "1.5 1.5 1.5 0.20";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    useAnisotropic[2] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    glow[2] = "1";
    emissive[2] = "1";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(tsfb_lights_dmg)
{
    mapTo = "tsfb_lights_dmg";
    diffuseMap[1] = "vehicles/common/tsfb_lights_dmg_d.dds";
    specularMap[1] = "vehicles/common/tsfb_lights_dmg_s.dds";
    normalMap[1] = "vehicles/common/tsfb_lights_dmg_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/tsfb_lights_dmg_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 1";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    diffuseColor[1] = "1.5 1.5 1.5 1";
    dynamicCubemap = true; //cubemap = "BNG_Sky_02_cubemap";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(tsfb_reverselight)
{
    mapTo = "tsfb_reverselight";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(tsfb_taillight)
{
    mapTo = "tsfb_taillight";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(tsfb_signal_R)
{
    mapTo = "tsfb_signal_R";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

singleton Material(tsfb_signal_L)
{
    mapTo = "tsfb_signal_L";
    diffuseColor[0] = "0 0 0 0";
    castShadows = "0";
    translucent = "1";
};

//red
singleton Material(beaconlight_red)
{
    mapTo = "beaconlight_red";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_red_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_red_glass)
{
    mapTo = "beaconlight_red_glass";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_red_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_red_on)
{
    mapTo = "beaconlight_red_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_red_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    glow[2] = "1";
    emissive[2] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_red_glass_on)
{
    mapTo = "beaconlight_red_glass_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_red_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    emissive[1] = "1";
    glow[1] = "1";
    glow[2] = "1";
    emissive[2] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

//orange
singleton Material(beaconlight_orange)
{
    mapTo = "beaconlight_orange";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_orange_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_orange_glass)
{
    mapTo = "beaconlight_orange_glass";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_orange_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_orange_on)
{
    mapTo = "beaconlight_orange_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_orange_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    glow[2] = "1";
    emissive[2] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_orange_glass_on)
{
    mapTo = "beaconlight_orange_glass_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_orange_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    normalMap[1] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    emissive[1] = "1";
    glow[1] = "1";
    glow[2] = "1";
    emissive[2] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

//blue_beacon
singleton Material(beaconlight_blue)
{
    mapTo = "beaconlight_blue";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
	normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_blue_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_blue_glass)
{
    mapTo = "beaconlight_blue_glass";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
	normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_blue_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
	normalMap[1] = "vehicles/common/beaconlight_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_blue_on)
{
    mapTo = "beaconlight_blue_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
	normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_blue_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
	normalMap[1] = "vehicles/common/beaconlight_n.dds";
	diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
	glow[2] = "1";
	emissive[2] = "1";
    castShadows = "0";
    translucent = "0";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(beaconlight_blue_glass_on)
{
    mapTo = "beaconlight_blue_glass_on";
    diffuseMap[0] = "vehicles/common/beaconlight_d.dds";
    specularMap[0] = "vehicles/common/null.dds";
	normalMap[0] = "vehicles/common/beaconlight_n.dds";
    diffuseMap[1] = "vehicles/common/beaconlight_blue_da.dds";
    specularMap[1] = "vehicles/common/null.dds";
	normalMap[1] = "vehicles/common/beaconlight_n.dds";
	diffuseMap[2] = "vehicles/common/beaconlight_g.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    specularPower[1] = "128";
    pixelSpecular[1] = "1";
    diffuseColor[0] = "1 1 1 1";
    diffuseColor[1] = "1 1 1 0.75";
    useAnisotropic[0] = "1";
    useAnisotropic[1] = "1";
	emissive[1] = "1";
	glow[1] = "1";
	glow[2] = "1";
	emissive[2] = "1";
    castShadows = "0";
    translucent = "1";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true;
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(bigwing_01a)
{
    mapTo = "bigwing_01a";
    normalMap[0] = "bigwing_01a_n.dds";
    diffuseMap[0] = "bigwing_01a_d.dds";
    specularMap[0] = "bigwing_01a_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(bigwing_02a)
{
    mapTo = "bigwing_02a";
    normalMap[0] = "bigwing_02a_n.dds";
    diffuseMap[0] = "bigwing_02a_d.dds";
    specularMap[0] = "bigwing_02a_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(bigwing_03a)
{
    mapTo = "bigwing_03a";
    normalMap[0] = "bigwing_03a_n.dds";
    diffuseMap[0] = "bigwing_03a_d.dds";
    specularMap[0] = "bigwing_03a_s.dds";
    diffuseColor[0] = "1 1 1 1";
    specularPower[0] = "32";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    dynamicCubemap = true; //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(semi_reverselight)
{
    mapTo = "semi_reverselight";
};

singleton Material(semi_signal_L)
{
    mapTo = "semi_signal_L";
};

singleton Material(semi_signal_R)
{
    mapTo = "semi_signal_R";
};

singleton Material(semi_lowbeam)
{
    mapTo = "semi_lowbeam";
};

singleton Material(semi_highbeam)
{
    mapTo = "semi_highbeam";
};

singleton Material(semi_taillight)
{
    mapTo = "semi_taillight";
};

singleton Material(semi_runninglight)
{
    mapTo = "semi_runninglight";
};

singleton Material(van_signal_L)
{
    mapTo = "van_signal_L";
};

singleton Material(van_signal_R)
{
    mapTo = "van_signal_R";
};

singleton Material(van_taillight)
{
    mapTo = "van_taillight";
};

singleton Material(van_taillight_L)
{
    mapTo = "van_taillight_L";
};

singleton Material(van_taillight_R)
{
    mapTo = "van_taillight_R";
};

singleton Material(van_headlight)
{
    mapTo = "van_headlight";
};

singleton Material(van_chmsl)
{
    mapTo = "van_chmsl";
};

singleton Material(van_reverselight)
{
    mapTo = "van_reverselight";
};

singleton Material(van_runninglight)
{
    mapTo = "van_runninglight";
};

singleton Material(van_runningbrakelight)
{
    mapTo = "van_runningbrakelight";
};
