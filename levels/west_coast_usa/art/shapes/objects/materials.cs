
singleton Material(trafficlight)
{
    mapTo = "trafficlight";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/traffic_cycle.png";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "0";
    translucent = "0";
    emissive[0] = "1";
    glow[0] = "1";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    animFlags[0] = "0x00000010";
    sequenceFramePerSec[0] = "10";
    sequenceSegmentSize[0] = "0.0014";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "TRAFFIC_SIGNALS";
};

singleton Material(barrierfence)
{
    mapTo = "barrierfence";
    vertColor[0] = "0";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/barrierfence_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/barrierfence_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/barrierfence_n.dds";
    overlayMap[0] = "levels/west_coast_usa/art/shapes/roads/sponsors.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "OBSTACLES";
};

singleton Material(billboards)
{
    mapTo = "billboards";
    vertColor[0] = "0";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/billboards_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/billboards_s.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    alphaTest = "0";
    alphaRef = "0";
    materialTag0 = "beamng"; materialTag1 = "commercial";
    annotation = "BUILDINGS";
};
singleton Material(catchfence)
{
    mapTo = "catchfence";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/catchfence_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/catchfence_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/catchfence_n.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    alphaTest = "1";
    alphaRef = "90";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "BUILDINGS";
};

singleton Material(chainlink)
{
    mapTo = "chainlink";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/chainlink_d.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/chainlink_n.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "lerpAlpha";
    alphaTest = "1";
    alphaRef = "40";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "BUILDINGS";
};

singleton Material(wirefence)
{
    mapTo = "wirefence";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/wirefence_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/wirefence_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/wirefence_n.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    alphaTest = "1";
    alphaRef = "64";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "OBSTACLES";
};

singleton Material(solar_panel)
{
    mapTo = "solarpanel";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/solarpanel_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/solarpanel_s.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/shapes/objects/solarpanel_r.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    cubemap = "global_cubemap_metalblurred";
    alphaTest = "1";
    alphaRef = "64";
    annotation = "BUILDINGS";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
};

singleton Material(metal_plates)
{
    mapTo = "metal_plates";
    vertColor[0] = "1";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/metal_plates_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/metal_plates_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/metal_plates_n.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/shapes/objects/metal_plates_r.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    cubemap = "global_cubemap_metalblurred";
    alphaTest = "1";
    alphaRef = "64";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "GUARD_RAIL";
};

singleton Material(wca_objects1)
{
    mapTo = "wca_objects1";
    vertColor[0] = "1";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_n.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_r.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    cubemap = "global_cubemap_metalblurred";
    alphaTest = "1";
    alphaRef = "64";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "POLE";
};

singleton Material(shock_absorber)
{
    mapTo = "shock_absorber";
    groundType = "shock_absorber";
    groundDepth = 0.6;
};

singleton Material(wca_objects_construction)
{
    mapTo = "wca_objects_construction";
    vertColor[0] = "1";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_construction_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_construction_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_construction_n.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/shapes/objects/wca_objects_construction_r.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    cubemap = "global_cubemap_metalblurred";
    alphaTest = "1";
    alphaRef = "64";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "OBSTACLES";
};

singleton Material(corrugation)
{
    mapTo = "corrugation";
    vertColor[0] = "1";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/corrugation_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/corrugation_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/corrugation_n.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/shapes/objects/corrugation_r.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "0";
    emissive[0] = "0";
    glow[0] = "0";
    translucentBlendOp = "None";
    cubemap = "cubemap_city";
    alphaTest = "1";
    alphaRef = "64";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    annotation = "BUILDINGS";
};

singleton Material(roadsigns)
{
    mapTo = "roadsigns";
    vertColor[0] = "1";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/roads/roadsigns.dds";
    //specularMap[0] = "levels/west_coast_usa/art/shapes/roads/metal_galvanized_s.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    specularColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "1";
    translucent = "1";
    translucentBlendOp = "None";
    alphaTest = "1";
    alphaRef = "128";
    materialTag0 = "beamng"; materialTag1 = "vehicle";
    //cubemap = "global_cubemap_metalblurred";
    detailScale[0] = "4 0.5";
    annotation = "TRAFFIC_SIGNS";
};

singleton Material(power_cables)
{
    mapTo = "power_cables";
    vertColor[0] = "0";
    diffuseMap[0] = "levels/west_coast_usa/art/shapes/objects/cables_d.dds";
    specularMap[0] = "levels/west_coast_usa/art/shapes/objects/cables_s.dds";
    normalMap[0] = "levels/west_coast_usa/art/shapes/objects/cables_n.dds";
    specularPower[0] = "32";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "1 1 1 1";
    useAnisotropic[0] = "1";
    castShadows = "0";
    translucent = "1";
    translucentBlendOp = "lerpAlpha";
    alphaTest = "0";
    alphaRef = "100";
    doubleSided = "1";
    //cubemap = "global_cubemap_metalblurred";
    materialTag0 = "beamng"; materialTag1 = "building";
    annotation = "OBSTACLES";
};
