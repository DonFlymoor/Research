
singleton Material(utah_mesh_barricade)
{
   mapTo = "utah_mesh_barricade";
   colorMap[0] = "levels/Utah/art/shapes/race/ut_mesh_barricade_d.dds";
   detailScale[0] = "40 40";
   specularStrength0 = "0.196078";
   materialTag0 = "beamng";
   materialTag2 = "utah";
   materialTag1 = "race";
   detailNormalMapStrength[0] = "1";
   detailMap[0] = "levels/Utah/art/shapes/race/safety_mesh_tile_detail_d.dds";
   detailNormalMap[0] = "levels/Utah/art/shapes/race/safety_mesh_tile_detail_n.dds";
};

singleton Material(Concrete_Road_Barrier_a)
{
    mapTo = "concrete_road_barrier_a";
    diffuseMap[0] = "concrete_road_barrier_a_d.dds";
    specularMap[0] = "concrete_road_barrier_a_s.dds";
    normalMap[0] = "concrete_road_barrier_a_n.dds";
    specularPower[0] = "1";
    pixelSpecular[0] = "0";
    diffuseColor[0] = "0.992157 0.992157 0.992157 1";
    materialTag0 = "beamng";
    materialTag1 = "Industrial";
};

singleton Material(utah_caution_tape)
{
   mapTo = "utah_caution_tape";
   doubleSided = "0";
   translucentBlendOp = "None";
   normalMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_n.dds";
   specularMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_s.dds";
   specularPower[0] = "1";
   useAnisotropic[0] = "1";
   materialTag0 = "beamng";
   materialTag1 = "race";
   materialTag2 = "utah";
  colorMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_d.dds";
  detailScale[0] = "0.1 0.1";
  specularStrength0 = "0.196078";
};

singleton Material(utah_caution_tape_poles)
{
   mapTo = "utah_caution_tape_poles";
   doubleSided = "0";
   translucentBlendOp = "None";
   normalMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_poles_n.dds";
   specularMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_poles_s.dds";
   specularPower[0] = "1";
   useAnisotropic[0] = "1";
   materialTag0 = "beamng";
   materialTag1 = "race";
   materialTag2 = "utah";
  colorMap[0] = "levels/Utah/art/shapes/race/ut_caution_tape_barricade_poles_d.dds";
  detailScale[0] = "0.1 0.1";
  specularStrength0 = "0.196078";
};

singleton Material(race_rally_start_finish)
{
    mapTo = "race_rally_start_finish";
    diffuseMap[0] = "race_rally_start_finish_d.dds";
    normalMap[0] = "race_rally_start_finish_n.dds";
    specularPower[0] = "1";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "0.992157 0.992157 0.992157 1";
    specularStrength[0] = "0.588235";
    materialTag0 = "beamng";
    materialTag1 = "Race";
    materialTag1 = "rally";
};

singleton Material(race_checkered)
{
    mapTo = "race_checkered";
    diffuseMap[0] = "race_checkered_d.dds";
    normalMap[0] = "race_checkered_n.dds";
    specularPower[0] = "1";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "0.992157 0.992157 0.992157 1";
    specularStrength[0] = "0.588235";
    materialTag0 = "beamng";
    materialTag1 = "Race";
    materialTag1 = "rally";
};

singleton Material(race_rally_finish_checkpoints)
{
    mapTo = "race_rally_finish_checkpoints";
    diffuseMap[0] = "race_rally_finish_checkpoints_d.dds";
    normalMap[0] = "race_rally_finish_checkpoints_n.dds";
    specularPower[0] = "39";
    pixelSpecular[0] = "1";
    diffuseColor[0] = "0.992157 0.992157 0.992157 1";
    specularStrength[0] = "0.588235";
    materialTag0 = "beamng";
    materialTag1 = "rally";
    materialTag1 = "rally";
    doubleSided = "1";
};

singleton Material(checkpoint_sign)
{
    mapTo = "checkpoint_sign";
    diffuseMap[0] = "checkpoint_sign.dds";
    specularPower[0] = "15";
    pixelSpecular[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "beamng";
    materialTag1 = "Race";
    materialTag1 = "rally";
};


singleton Material(sign_arrows)
{
    mapTo = "sign_arrows";
    diffuseColor[0] = "0.996078 0.996078 0.996078 1";
    specular[0] = "0.5 0.5 0.5 1";
    specularPower[0] = "50";
    translucentBlendOp = "None";
    diffuseMap[0] = "arrows_sign_d.dds";
    specularMap[0] = "arrows_sign_s.dds";
    materialTag0 = "beamng";
    materialTag1 = "Race";
    materialTag1 = "rally";
};

singleton Material(race_wood)
{
    mapTo = "race_wood";
    diffuseMap[0] = "wood_d.dds";
    doubleSided = "0";
    translucentBlendOp = "None";
    specularMap[0] = "wood_s.dds";
    normalMap[0] = "wood_n.dds";
    specularPower[0] = "1";
    useAnisotropic[0] = "1";
    materialTag0 = "beamng";
    materialTag1 = "Race";
    materialTag1 = "rally";
};

singleton Material(race_rally_gate_finish_race_checkered)
{
    mapTo = "race_checkered";
    diffuseColor[0] = "0.64 0.64 0.64 1";
    doubleSided = "1";
    translucentBlendOp = "None";
};
