singleton Material(track_editor_base)
{
    mapTo = "track_editor_base";
    diffuseColor[0] = "0.803922 0.803922 0.803922 1";
    diffuseMap[0] = "track_editor_base_d.dds";
    specularPower[0] = "1";
    specularMap[0] = "track_editor_base_s.dds";
	useAnisotropic[0] = "1";
    doubleSided = "1";
    translucentBlendOp = "None";
    materialTag1 = "RoadAndPath";
    materialTag0 = "beamng";
};

singleton Material( track_editor_grid )
{
    mapTo = "track_editor_grid";
    diffuseMap[0] = "track_editor_grid";
    materialTag0 = "TestMaterial";
	useAnisotropic[0] = "1";
	doubleSided = "1";
};