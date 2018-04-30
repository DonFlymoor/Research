
singleton Material(decalroad_concrete)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_concrete_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/road_concrete_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    specularMap[0] = "levels/west_coast_usa/art/road/road_concrete_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "STREET";
};

singleton Material(AsphaltRoad_edge_concrete)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/AsphaltRoad_edge_concrete_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/AsphaltRoad_edge_concrete_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/AsphaltRoad_edge_concrete_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "1";
    alphaRef = "32";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "STREET";
};

singleton Material(road1_concrete)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/street_concrete1_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/street_concrete1_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/street_concrete1_d.dds";
   annotation = "STREET";
   specularStrength0 = "0";
   annotation = "STREET";
};

singleton Material(road_blue)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/chalk_marking_d.dds";
    useAnisotropic[0] = "1";
    castShadows = "0";
    translucent = "1";
    translucentZWrite = "1";
    materialTag0 = "beamng";
    materialTag1 = "decal";
    materialTag2 = "RoadAndPath";
    specularPower[0] = "14";
    diffuseColor[0] = "0.37 0.59 0.9 0.87";
};

singleton Material(sidewalk_concrete)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/street_concrete1_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/street_concrete1_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "150";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/street_concrete1_d.dds";
   annotation = "SIDEWALK";
   specularStrength0 = "0";
   annotation = "SIDEWALK";
   materialTag2 = "industrial";
};

singleton Material(road_asphalt_2lane)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_d.dds";
   annotation = "STREET";
   specularStrength0 = "0";
   specularColor0 = "0 0 0";
   annotation = "STREET";
};

singleton Material(checkered_line)
{
    mapTo = "checkered_line";
    diffuseMap[0] = "levels/west_coast_usa/art/road/checkered_line_d.dds";
    materialTag0 = "beamng";
    materialTag1 = "RoadAndPath";
    specularPower[0] = "128";
    pixelSpecular[0] = "0";
    useAnisotropic[0] = "1";
    castShadows = "0";
    translucent = "1";
    translucentZWrite = "1";
    specular[0] = "0.996078 0.996078 0.996078 1";
    materialTag2 = "RoadAndPath";
    specularStrength[0] = "0.882353";
    alphaRef = "208";
};

singleton Material(road_asphalt_light)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/road_asphalt_light_d.dds";
   annotation = "STREET";
   specularStrength0 = "0";
   annotation = "STREET";
};

singleton Material(road_invisible)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "0";
    translucentZWrite = "0";
    alphaTest = "1";
    alphaRef = "127";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/shapes/roads/invisible.dds";
   annotation = "STREET";
   specularStrength0 = "0";
   annotation = "STREET";
};

singleton Material(road_asphalt_edge)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_asphalt_edge_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/road_asphalt_edge_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_edge_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(road_dirt)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_dirt_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_dirt_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_dirt_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(road_dirt_tracks)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/dirtroad_tracks_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_dirt_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_dirt_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(track_edge)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/track_edge_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/track_edge_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/track_edge_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(road_edge)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_edge_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_edge_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    annotationMap = "road_edge_annotation.png";
    specularStrength[0] = "0";
};

singleton Material(repair1)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/repair1_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(repair2)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/repair2_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/repair2_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //specularMap[0] = "levels/west_coast_usa/art/road/track_edge_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(road_patches1)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_patches1.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "202";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(gutter1)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/gutter1_d.dds";
    normalMap[0] = "levels/west_coast_usa/art/road/gutter1_n.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "STREET";
};

singleton Material(grass_edge)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/grass_edge.dds";
    normalMap[0] = "levels/west_coast_usa/art/road/grass_edge_n.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(road_rubber_sticky)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_s.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/road/road_rubber_sticky_d.dds";
    cubemap = "global_cubemap_metalblurred";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(grass_mown)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/grass_mown.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/repair2_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //specularMap[0] = "levels/west_coast_usa/art/road/track_edge_s.dds";
    //reflectivityMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_r.dds";
    cubemap = "cubemap_road_sky_reflection";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
};

singleton Material(track_rubber)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/AsphaltRoad_track_tirewear_a.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    diffuseMap[1] = "levels/west_coast_usa/art/road/AsphaltRoad_track_tirewear_d.dds";
    cubemap = "cubemap_road_sky_reflection";
    specularPower[1] = "1";
    useAnisotropic[1] = "1";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    materialTag2 = "driver_training";
};

singleton Material(line_yellowblack)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_d.dds";
   annotation = "SOLID_LINE";
   annotationMap = "line_yellowblack_annotation.png";
   specularStrength0 = "0";
};

singleton Material(line_white)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/line_white_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_white_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
   colorMap[0] = "levels/west_coast_usa/art/road/line_white_d.dds";
   annotation = "SOLID_LINE";
   specularStrength0 = "0";
   specularColor0 = "1 1 1 1";
   materialTag2 = "driver_training";
};

singleton Material(line_white)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_white_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/line_white_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "SOLID_LINE";
};

singleton Material(line_yellow)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/line_white_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "SOLID_LINE";
   colorMap[0] = "levels/west_coast_usa/art/road/line_yellow_d.dds";
   specularStrength0 = "0";
};

singleton Material(line_dashed_short)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_dashed_short_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "DASHED_LINE";
};

singleton Material(line_parking1)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_parking1_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "1";
    alphaRef = "32";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "SOLID_LINE";
};

singleton Material(line_parking2)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_parking2_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "1";
    alphaRef = "32";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "SOLID_LINE";
};

singleton Material(line_dashed_long)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_dashed_long_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/line_dashed_long_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "DASHED_LINE";
};

singleton Material(line_reflectors)
{

    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/line_reflectors_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/line_reflectors_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/line_yellowblack_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "STREET";
};

singleton Material(road_slashes)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_slashes_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_slashes_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/road_slashes_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "RESTRICTED_STREET";
};

singleton Material(road_chevrons)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_chevrons_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_slashes_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    //specularMap[0] = "levels/west_coast_usa/art/road/road_slashes_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "RESTRICTED_STREET";
};

singleton Material(road_slashes_tram)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/road_slashes_tram_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_slashes_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    specularMap[0] = "levels/west_coast_usa/art/road/road_asphalt_2lane_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotationMap = "road_slashes_tram_annotation.png";
    annotation = "RESTRICTED_STREET";
};

singleton Material(AsphaltRoad_variation_01)
{
    mapTo = "AsphaltRoad_variation_01";
    diffuseMap[0] = "AsphaltRoad_variation_01_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularPower[1] = "1";
    useAnisotropic[1] = "1";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
};

singleton Material(AsphaltRoad_variation_02)
{
    mapTo = "AsphaltRoad_variation_01";
    diffuseMap[0] = "AsphaltRoad_variation_02_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularPower[1] = "1";
    useAnisotropic[1] = "1";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
};

singleton Material(crossing_white)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/crossing_white_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_slashes_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    specularMap[0] = "levels/west_coast_usa/art/road/crossing_white_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "ZEBRA_CROSSING";
};

singleton Material(crossing_yellow)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/crossing_yellow_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    //normalMap[0] = "levels/west_coast_usa/art/road/road_slashes_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    //cubemap = "cubemap_road_sky_reflection";
    specularMap[0] = "levels/west_coast_usa/art/road/crossing_white_s.dds";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "ZEBRA_CROSSING";
};

singleton Material(road_tramline)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "levels/west_coast_usa/art/road/tramline_d.dds";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    normalMap[0] = "levels/west_coast_usa/art/road/tramline_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    specularMap[0] = "levels/west_coast_usa/art/road/tramline_s.dds";
    reflectivityMap[0] = "levels/west_coast_usa/art/road/tramline_r.dds";
    cubemap = "global_cubemap_metalblurred";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "255";
    castShadows = "0";
    specularStrength[0] = "0";
    annotation = "STREET";
};


singleton Material(AsphaltRoad_track_skidmarks)
{
    mapTo = "unmapped_mat";
    doubleSided = "0";
    translucentBlendOp = "LerpAlpha";
    specularPower[0] = "19";
    useAnisotropic[0] = "1";
    materialTag0 = "RoadAndPath";
    materialTag1 = "beamng";
    normalMap[0] = "white_n.dds";
    diffuseMap[0] = "AsphaltRoad_track_skidmarks_d.dds";
    specularMap[0] = "white.dds";
    specularPower[1] = "1";
    specularStrength[0] = "1.37255";
    useAnisotropic[1] = "1";
    translucent = "1";
    translucentZWrite = "1";
    alphaTest = "0";
    alphaRef = "80";
    castShadows = "0";
    materialTag2 = "hirochi_raceway";
};

