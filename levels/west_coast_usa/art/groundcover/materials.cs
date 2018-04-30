
singleton Material(wca_groundcover)
{
    mapTo = "wca_groundcover";
    normalMap[0] = "levels/west_coast_usa/art/groundcover/wca_groundcover_n.dds";
    doubleSided = "1";
    alphaTest = "1";
    alphaRef = "128";
    useAnisotropic[0] = "1";
    materialTag1 = "beamng";
    materialTag0 = "beamng";
    materialTag2 = "vegetation";
    materialTag3 = "Natural";
    annotation = "NATURE";
   colorMap[0] = "levels/west_coast_usa/art/groundcover/wca_groundcover_d.dds";
   materialTag4 = "east_coast_usa";
};

singleton Material(grass_field)
{
    mapTo = "grass_field";
    diffuseMap[0] = "levels/west_coast_usa/art/groundcover/grass_field.dds";
    normalMap[0] = "levels/west_coast_usa/art/groundcover/normalsfix.dds";
    doubleSided = "1";
    alphaTest = "1";
    alphaRef = "147";
    materialTag1 = "beamng";
    materialTag0 = "beamng";
    materialTag2 = "vegetation";
    materialTag3 = "Natural";
    annotation = "NATURE";
};

singleton Material(BNGGrass_3)
{
    mapTo = "unmapped_mat";
    diffuseColor[0] = "0.996078 0.996078 0.996078 1";
    diffuseMap[0] = "levels/hirochi_raceway/art/shapes/groundcover/Grass03_d.dds";
    useAnisotropic[0] = "1";
    doubleSided = "1";
    alphaTest = "1";
    alphaRef = "60";
    materialTag0 = "beamng";
    materialTag1 = "vegetation";
    normalMap[0] = "levels/hirochi_raceway/art/shapes/groundcover/Grass03_n.dds";
    annotation = "NATURE";
};

