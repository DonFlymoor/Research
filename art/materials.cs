
singleton Material(tireTrack)
{
    mapTo = "unmapped_mat";
    diffuseMap[0] = "art/decals/tiremark.png";
    vertColor[ 0 ] = true;
    materialTag2 = "beamng";
    materialTag0 = "decal";
    diffuseColor[0] = "1 1 1 0.199";
    emissive[0] = "1";
    translucent = "1";
    alphaRef = "1";
    castShadows = "0";
    translucentZWrite = "1";
    showFootprints = "0";
    specularPower[0] = "1";
};

singleton Material(eca_bld_woodcladding_01_bare_mat)
{
    mapTo = "eca_bld_woodcladding_01_bare";
    diffuseMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_woodcladding_01_bare_d.dds";
    materialTag0 = "beamng";
    materialTag1 = "building";
    materialTag2 = "east_coast_usa";
    normalMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_woodcladding_01_n.dds";
    specularMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_woodcladding_01_s.dds";
    detailMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_grungewood_b.dds";
    detailScale[0] = "0.1 0.1";
};

singleton Material(eca_bld_brick_brown_mat)
{
    mapTo = "eca_bld_brick_brown";
    diffuseMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_brick_01_brown_d.dds";
    detailMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_grungewood_b.dds";
    detailScale[0] = "0.1 0.1";
    normalMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_brick_01_n.dds";
    specularMap[0] = "levels/east_coast_usa/art/shapes/buildings/eca/eca_bld_brick_01_s.dds";
    materialTag0 = "beamng";
    materialTag1 = "building";
    materialTag2 = "east_coast_usa";
};

singleton Material(DefaultMaterial2)
{
   mapTo = "usa_roadsigns_turn_warning";
   specularStrength0 = "0.588235";
   materialTag2 = "east_coast_usa";
   materialTag1 = "building";
   materialTag0 = "beamng";
   specularStrength1 = "0.980392";
};

new CubemapData(CloudyCubemap)
{
   cubeFace[0] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_1.png";
   cubeFace[1] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_2.png";
   cubeFace[2] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_3.png";
   cubeFace[3] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_4.png";
   cubeFace[4] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_5.png";
   cubeFace[5] = "levels/derby/art/skies/BNG_Sky_03_storm/cubemap/skybox_6.png";
};

new CubemapData(cubemap_forest)
{
   cubeFace[0] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0001.png";
   cubeFace[1] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0002.png";
   cubeFace[2] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0003.png";
   cubeFace[3] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0004.png";
   cubeFace[4] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0005.png";
   cubeFace[5] = "levels/driver_training/art/skies/BNG_Sky_02/cubemap/cubemap_forest0006.png";
};
