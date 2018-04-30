singleton Material(trailer_base)
{
    mapTo = "trailer_base";
    diffuseMap[1] = "vehicles/common/trailers/trailerbase_d.dds";
    specularMap[1] = "vehicles/common/trailers/trailerbase_s.dds";
    normalMap[1] = "vehicles/common/trailers/trailerbase_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/common/trailers/trailerbase_n.dds";
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

singleton Material(trailer_mudflap)
{
    mapTo = "trailer_mudflap";
    diffuseMap[0] = "vehicles/common/trailers/trailer_mudflap_d.dds";
    normalMap[0] = "vehicles/common/trailers/trailer_mudflap_n.dds";
    specularPower[0] = "128";
    pixelSpecular[0] = "1";
    useAnisotropic[0] = "1";
    specularMap[0] = "vehicles/common/trailers/trailer_mudflap_s.dds";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    diffuseColor[0] = "1 1 1 1";
};

singleton Material(boxutility)
{
    mapTo = "boxutility";
    diffuseMap[1] = "vehicles/boxutility/boxutility_d.dds";
    specularMap[1] = "vehicles/boxutility/boxutility_s.dds";
    normalMap[1] = "vehicles/boxutility/boxutility_n.dds";
    diffuseMap[0] = "vehicles/common/null.dds";
    specularMap[0] = "vehicles/common/null.dds";
    normalMap[0] = "vehicles/boxutility/boxutility_n.dds";
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