
// This is the default save location for any Particle datablocks created in the
// Particle Editor (this script is executed from onServerCreated())

datablock ParticleData(BNG_Leaf1 : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_oak_leaf_01.dds";
    animTexName = "art/shapes/particles/particle_oak_leaf_01.dds";
    spinRandomMin = "-208";
    spinRandomMax = "417";
    colors[0] = "0.992126 0.992126 0.992126 1";
    colors[1] = "0.992126 0.992126 0.992126 1";
    colors[2] = "0.992126 0.992126 0.992126 1";
    colors[3] = "0.992126 0.992126 0.992126 1";
    sizes[0] = "0.497467";
    sizes[1] = "0.497467";
    sizes[2] = "0";
    sizes[3] = "0";
    gravityCoefficient = "2";
    lifetimeMS = "5438";
    lifetimeVarianceMS = "0";
    inheritedVelFactor = "1";
    constantAcceleration = "10";
    useInvAlpha = "0";
    times[1] = "0";
    dragCoefficient = "4.98534";
    times[0] = "0.0625";
    times[2] = "0";
    times[3] = "0";
};

datablock ParticleData(BNG_Leaf2 : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_oak_leaf_02.dds";
    animTexName = "art/shapes/particles/particle_oak_leaf_02.dds";
    lifetimeMS = "15000";
    colors[0] = "0.996078 0.992157 0.992157 1";
    colors[1] = "0.996078 0.996078 0.992157 1";
    colors[2] = "0.996078 0.992157 0.992157 1";
    colors[3] = "0.996078 0.996078 0.992157 1";
    lifetimeVarianceMS = "0";
    constantAcceleration = "10";
    dragCoefficient = "5";
    inheritedVelFactor = "1";
    times[1] = "0.75";
    times[2] = "0.979167";
    sizes[0] = "0.5";
    sizes[1] = "0.5";
    sizes[2] = "0";
    sizes[3] = "0";
    useInvAlpha = "0";
};

datablock ParticleData(BNG_sparks : DefaultParticle)
{
    textureName = "art/shapes/particles/Sparkparticle.png";
    animTexName = "art/shapes/particles/Sparkparticle.png";
    colors[0] = "0.996078 0.996078 0.992157 1";
    colors[1] = "0.996078 0.996078 0.992157 1";
    colors[2] = "0.996078 0.458824 0.196078 1";
    colors[3] = "0.996078 0.0784314 0.00784314 0.025";
    dragCoefficient = "2.49756";
    gravityCoefficient = "0.998779";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "800";
    lifetimeVarianceMS = "700";
    sizes[0] = "0.04";
    sizes[2] = "0.08";
    sizes[3] = "0.04";
    times[1] = "0.416667";
    times[2] = "0.8125";
    times[3] = "1";
    spinSpeed = "0.5";
    sizes[1] = "0.12";
    times[0] = "0";
    constantAcceleration = "0";
};

datablock ParticleData(BNG_sparks_explosion : DefaultParticle)
{
    textureName = "art/shapes/particles/Sparkparticle.png";
    animTexName = "art/shapes/particles/Sparkparticle.png";
    colors[0] = "0.996078 0.996078 0.992157 1";
    colors[1] = "0.996078 0.996078 0.992157 1";
    colors[2] = "0.996078 0.458824 0.196078 1";
    colors[3] = "0.996078 0.0784314 0.00784314 0.025";
    dragCoefficient = "4";
    gravityCoefficient = "1";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "800";
    lifetimeVarianceMS = "700";
    sizes[0] = "0.1";
    sizes[2] = "0.15";
    sizes[3] = "0.04";
    times[1] = "0.416667";
    times[2] = "0.8125";
    times[3] = "1";
    spinSpeed = "0.5";
    sizes[1] = "0.12";
    times[0] = "0";
    constantAcceleration = "0";
};

datablock ParticleData(BNG_dust_light : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "1 0.968504 0.937008 0.349";
    colors[1] = "1 0.968504 0.937008 0.212";
    colors[2] = "1 0.968504 0.937008 0.149606";
    colors[3] = "1 0.968504 0.937008 0";
    dragCoefficient = "5";
    gravityCoefficient = "0.0";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "3000";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.497467";
    sizes[2] = "0.997986";
    sizes[3] = "2.09974";
    times[1] = "0.2";
    times[2] = "0.4";
    times[3] = "0.698039";
    spinSpeed = "0.14";
    sizes[1] = "0.997986";
};

datablock ParticleData(BNG_dust_dark : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_dust_soft_01.dds";
    animTexName = "art/shapes/particles/particle_dust_soft_01.dds";
    colors[0] = "0.685039 0.637795 0.590551 0.23622";
    colors[1] = "0.685039 0.637795 0.590551 1";
    colors[2] = "0.685039 0.637795 0.590551 0.6";
    colors[3] = "0.685039 0.637795 0.590551 0.00787402";
    dragCoefficient = "3.48974";
    gravityCoefficient = "0";
    inheritedVelFactor = "0.694716";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "6000";
    lifetimeVarianceMS = "4000";
    sizes[0] = "1";
    sizes[2] = "3";
    sizes[3] = "6";
    times[1] = "0.0588235";
    times[2] = "0.247059";
    times[3] = "0.729167";
    spinSpeed = "0.14";
   sizes[1] = "1";
};

datablock ParticleData(BNG_dust_dirt : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_dust_soft_01.dds";
    animTexName = "art/shapes/particles/particle_dust_soft_01.dds";
    colors[0] = "0.8 0.745 0.69 0.00";
    colors[1] = "0.8 0.745 0.69 0.25";
    colors[2] = "0.8 0.745 0.69 0.1";
    colors[3] = "0.8 0.745 0.69 0.00";
    dragCoefficient = "2";
    gravityCoefficient = "-0.02";
    inheritedVelFactor = "1";
    spinRandomMin = "-708";
    spinRandomMax = "833";
    lifetimeMS = "2500";
    lifetimeVarianceMS = "2000";
    sizes[0] = "0.3";
    sizes[1] = "1.0";
    sizes[2] = "1.6";
    sizes[3] = "2";
    times[0] = "0";
    times[1] = "0.02";
    times[2] = "0.6875";
    times[3] = "1";
    spinSpeed = "0.05";
};

datablock ParticleData(BNG_dirt : DefaultParticle)
{
    textureName = "art/shapes/particles/Particle_dirt_01.dds";
    animTexName = "art/shapes/particles/Particle_dirt_01.dds";
    colors[0] = "0.99 1 1 0.917";
    colors[1] = "1 1 0.99 0.934";
    colors[2] = "1 1 0.99 0.967";
    colors[3] = "1 1 0.99 0.015748";
    dragCoefficient = "0.498534";
    gravityCoefficient = "1";
    inheritedVelFactor = "0.4";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "1000";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.793505";
    sizes[2] = "0.793505";
    sizes[3] = "0.793505";
    times[1] = "0.229167";
    times[2] = "0.784314";
    times[3] = "1";
    spinSpeed = "0.167";
    sizes[1] = "0.997986";
};

datablock ParticleData(BNG_smoke_white : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_lightblue.dds";
    animTexName = "art/shapes/particles/particle_smoke_lightblue.dds";
    colors[0] = "1 1 1 0.00";
    colors[1] = "1 1 1 0.15";
    colors[2] = "1 1 1 0.05";
    colors[3] = "1 1 1 0.00";
    dragCoefficient = ".7";
    gravityCoefficient = "-0.06";
    inheritedVelFactor = "0";
    spinRandomMin = "-708";
    spinRandomMax = "833";
    lifetimeMS = "3500";
    lifetimeVarianceMS = "2000";
    sizes[0] = "0.3";
    sizes[1] = "1";
    sizes[2] = "1.7";
    sizes[3] = "2.2";
    times[0] = "0";
    times[1] = "0.0980392";
    times[2] = "0.6875";
    times[3] = "1";
    spinSpeed = "0.1";
};

datablock ParticleData(BNG_smoke_white2 : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 0.199";
    colors[2] = "0.8 0.85 0.9 0.108";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "3.99316";
    gravityCoefficient = "-0.0610501";
    inheritedVelFactor = "0";
    spinRandomMin = "-1000";
    spinRandomMax = "1000";
    lifetimeMS = "700";
    lifetimeVarianceMS = "399";
    sizes[0] = "0.799609";
    sizes[2] = "1.0987";
    sizes[3] = "1.19636";
    times[1] = "0.14902";
    times[2] = "0.517647";
    times[3] = "1";
    spinSpeed = "0.2";
    sizes[1] = "0.997986";
    times[0] = "0";
};

datablock ParticleData(BNG_smoke_white3 : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_lightblue.dds";
    animTexName = "art/shapes/particles/particle_smoke_lightblue.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.08";
    colors[2] = "1 1 1 0.03";
    colors[3] = "1 1 1 0.01";
    colors[4] = "1 1 1 0";
    dragCoefficient = "5";
    gravityCoefficient = "-0.0610501";
    inheritedVelFactor = "0.4";
    spinRandomMin = "-1000";
    spinRandomMax = "1000";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.2";
	sizes[1] = "0.6";
	sizes[2] = "0.8";
    sizes[3] = "0.9";
    sizes[4] = "1";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.25";
    times[3] = "0.5";
    times[3] = "1";
    spinSpeed = "0.1";
};

datablock ParticleData(BNG_volcano_smoke : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_01.dds";
    colors[0] = "0.992126 0.992126 0.992126 0";
    colors[1] = "0.992126 0.992126 0.992126 0.264";
    colors[2] = "0.992126 0.992126 0.992126 0.058";
    colors[3] = "0.992126 0.992126 0.992126 0.008";
    dragCoefficient = "1";
    gravityCoefficient = "-0.21";
    inheritedVelFactor = "1";
    spinRandomMin = "-1000";
    spinRandomMax = "1000";
    lifetimeMS = "12000";
    lifetimeVarianceMS = "1875";
    sizes[0] = "2.08143";
    sizes[2] = "6.25";
    sizes[3] = "19.7917";
    times[1] = "0.14902";
    times[2] = "0.513726";
    times[3] = "1";
    spinSpeed = "0.021";
    sizes[1] = "3.125";
    times[0] = "0";
};

datablock ParticleData(BNG_smoke_black : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 0.9";
    colors[2] = "1 1 1 0.5";
    colors[3] = "1 1 1 0";
    dragCoefficient = "4";
    gravityCoefficient = "-0.06";
    inheritedVelFactor = "0.7";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "3500";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.6";
    sizes[2] = "1.1";
    sizes[3] = "2.4";
    times[1] = "0.0416667";
    times[2] = "0.125";
    times[3] = "0.791667";
    spinSpeed = "0.14";
};

datablock ParticleData(BNG_dust_sand : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_dust_soft_01.dds";
    animTexName = "art/shapes/particles/particle_dust_soft_01.dds";
    colors[0] = "0.996078 0.905882 0.815686 1";
    colors[1] = "0.996078 0.909804 0.835294 0.897638";
    colors[2] = "0.996078 0.901961 0.807843 0.838";
    colors[3] = "0.996078 0.937255 0.878431 0";
    dragCoefficient = "2.99609";
    gravityCoefficient = "0.0366306";
    inheritedVelFactor = "0.798434";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "3500";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.497467";
    sizes[2] = "1.0987";
    sizes[3] = "2.39883";
    times[1] = "0.0392157";
    times[2] = "0.121569";
    times[3] = "0.788235";
    spinSpeed = "0.14";
    sizes[1] = "0.997986";
};

datablock ParticleData(BNG_dust_small : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_dust_soft_01.dds";
    animTexName = "art/shapes/particles/particle_dust_soft_01.dds";
    colors[0] = "0.992126 0.929134 0.889764 0";
    colors[1] = "0.992126 0.92126 0.866142 1";
    colors[2] = "0.992126 0.897638 0.834646 0.645669";
    colors[3] = "0.992126 0.897638 0.834646 0.00787402";
    times[1] = "0.0470588";
    times[2] = "0.0980392";
    dragCoefficient = "2.98143";
    gravityCoefficient = "0";
    inheritedVelFactor = "0.455969";
    lifetimeMS = "2200";
    lifetimeVarianceMS = "500";
    spinSpeed = "0.146";
    spinRandomMin = "-416";
    spinRandomMax = "541";
    sizes[2] = "0.93";
    sizes[3] = "2.0";
};

datablock ParticleData(BNG_gravel : DefaultParticle)
{
    dragCoefficient = "0.5";
    gravityCoefficient = "0.6";
    inheritedVelFactor = "0.9";
    lifetimeMS = "1501";
    spinSpeed = "0.042";
    textureName = "art/shapes/particles/particle_dust_gravel_01.dds";
    animTexName = "art/shapes/particles/particle_dust_gravel_01.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 1";
    colors[2] = "1 1 1 1";
    colors[3] = "1 1 1 0";
    sizes[0] = "0.8";
    sizes[1] = "0.8";
    sizes[2] = "0.8";
    sizes[3] = "0.8";
    times[1] = "0.101961";
    times[2] = "0.435294";
    times[3] = "0.956863";
    lifetimeVarianceMS = "0";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    times[0] = "0";
};

datablock ParticleData(BNG_chunk_small : DefaultParticle)
{
    dragCoefficient = "0.498534";
    gravityCoefficient = "0.798535";
    inheritedVelFactor = "0";
    lifetimeMS = "1501";
    spinSpeed = "2";
    textureName = "art/shapes/particles/particle_chunk_01.dds";
    animTexName = "art/shapes/particles/particle_chunk_01.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "0.996078 0.992157 0.992157 1";
    colors[2] = "1 1 1 1";
    colors[3] = "1 1 1 0";
    sizes[0] = "0.3";
    sizes[1] = "0.3";
    sizes[2] = "0.3";
    sizes[3] = "0.3";
    times[1] = "0.101961";
    times[2] = "0.411765";
    times[3] = "1";
    lifetimeVarianceMS = "200";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    times[0] = "0";
};

datablock ParticleData(BNG_chunk_med : DefaultParticle)
{
    dragCoefficient = "0.25";
    gravityCoefficient = "0.798535";
    inheritedVelFactor = "0";
    lifetimeMS = "1501";
    spinSpeed = "0.646";
    textureName = "art/shapes/particles/particle_chunk_01.dds";
    animTexName = "art/shapes/particles/particle_chunk_01.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 1";
    colors[2] = "1 1 1 1";
    colors[3] = "0.996078 0.996078 0.996078 0";
    sizes[0] = "0.5";
    sizes[1] = "0.9";
    sizes[2] = "0.7";
    sizes[3] = "1.2";
    times[1] = "0.104167";
    times[2] = "0.431373";
    times[3] = "0.956863";
    lifetimeVarianceMS = "200";
    spinRandomMin = "-500";
    spinRandomMax = "583.5";
    times[0] = "0";
};


datablock ParticleData(BNG_sand : DefaultParticle)
{
    dragCoefficient = "5";
    gravityCoefficient = "0.3";
    inheritedVelFactor = "1";
    lifetimeMS = "1000";
    spinSpeed = "0";
    textureName = "art/shapes/particles/particle_sandspray_01.dds";
    animTexName = "art/shapes/particles/particle_sandspray_01.dds";
    colors[0] = "1 1 1 0.195";
    colors[1] = "1 1 1 1";
    colors[2] = "1 1 1 0.187";
    colors[3] = "1 1 1 0";
    sizes[0] = "0.4";
    sizes[1] = "0.5";
    sizes[2] = "1.6";
    sizes[3] = "2.2";
    times[1] = "0.1875";
    times[2] = "0.4375";
    times[3] = "1";
    lifetimeVarianceMS = "0";
    spinRandomMin = "-708";
    spinRandomMax = "708";
    times[0] = "0";
};


datablock ParticleData(BNG_mud_1 : DefaultParticle)
{
    sizes[0] = "0.0976622";
    sizes[1] = "0.799609";
    sizes[2] = "1.99902";
    sizes[3] = "1.59922";
    times[1] = "0.0823529";
    times[2] = "0.580392";
    textureName = "art/shapes/particles/Particle_mud_01.dds";
    animTexName = "art/shapes/particles/Particle_mud_01.dds";
    colors[0] = "0.992126 0.992126 0.992126 1";
    colors[1] = "0.992126 0.992126 0.992126 1";
    colors[2] = "0.992126 0.992126 0.992126 1";
    gravityCoefficient = "0.495726";
    spinSpeed = "0.3";
    dragCoefficient = "0.298143";
    lifetimeMS = "1400";
    lifetimeVarianceMS = "375";
    times[0] = "0";
    times[3] = "1";
    inheritedVelFactor = "0.248532";
    colors[3] = "0.992126 0.992126 0.992126 0";
};

datablock ParticleData(BNG_glassbreak : DefaultParticle)
{
    sizes[0] = "0.399805";
    sizes[1] = "0.399805";
    sizes[2] = "0.497467";
    sizes[3] = "0.598181";
    times[1] = "0.227451";
    times[2] = "0.75";
    textureName = "art/shapes/particles/Particle_glass_01.dds";
    animTexName = "art/shapes/particles/Particle_glass_01.dds";
    colors[0] = "0.992126 0.992126 0.992126 1";
    colors[1] = "0.992126 0.992126 0.992126 1";
    colors[2] = "0.992126 0.992126 0.992126 1";
    colors[3] = "0.992126 0.992126 0.992126 0";
    gravityCoefficient = "0.3";
    spinSpeed = "0.646";
    inheritedVelFactor = "0.299413";
    dragCoefficient = "0.562072";
    lifetimeMS = "1900";
    lifetimeVarianceMS = "300";
};

datablock ParticleData(BNG_grass : DefaultParticle)
{
    sizes[0] = "0.399805";
    sizes[1] = "0.7";
    sizes[2] = "0.7";
    sizes[3] = "0.7";
    times[1] = "0.227451";
    times[2] = "0.74902";
    textureName = "art/shapes/particles/Particle_grass_01.dds";
    animTexName = "art/shapes/particles/Particle_grass_01.dds";
    colors[0] = "0.843137 0.843137 0.843137 1";
    colors[1] = "0.890196 0.890196 0.890196 2";
    colors[2] = "0.87451 0.87451 0.87451 1";
    colors[3] = "0.992126 0.992126 0.992126 0";
    gravityCoefficient = "0.667";
    spinSpeed = "0.646";
    inheritedVelFactor = "0.1";
    dragCoefficient = "0.75";
    lifetimeMS = "1900";
    lifetimeVarianceMS = "300";
};

datablock ParticleData(BNG_splash : DefaultParticle)
{
    sizes[0] = "1";
    sizes[1] = "3";
    sizes[2] = "4";
    sizes[3] = "4";
    times[1] = "0.354167";
    times[2] = "0.74902";
    textureName = "art/shapes/particles/Particle_splash.dds";
    animTexName = "art/shapes/particles/Particle_splash.dds";
    colors[0] = "0.996078 0.996078 0.996078 0.512";
    colors[1] = "0.996078 0.996078 0.996078 2";
    colors[2] = "0.996078 0.996078 0.996078 1.967";
    colors[3] = "0.996078 0.996078 0.996078 0.008";
    gravityCoefficient = "0.666667";
    spinSpeed = "0.3";
    inheritedVelFactor = "1";
    dragCoefficient = "0.747801";
    lifetimeMS = "1900";
    lifetimeVarianceMS = "300";
    times[0] = "0.125";
};

datablock ParticleData(BNG_spray : DefaultParticle)
{
    textureName = "art/shapes/particles/Particle_spray.dds";
    animTexName = "art/shapes/particles/Particle_spray.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "0.988235 0.988235 0.988235 1";
    colors[2] = "0.996078 0.996078 0.996078 1";
    colors[3] = "1 1 1 0.00";
    dragCoefficient = "0.5";
    gravityCoefficient = "1";
    inheritedVelFactor = "1";
    spinRandomMin = "-708";
    spinRandomMax = "833";
    lifetimeMS = "700";
    lifetimeVarianceMS = "0";
    sizes[0] = "0.6";
    sizes[1] = "0.7";
    sizes[2] = "0.8";
    sizes[3] = "1";
    times[0] = "0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "0.167";
};


datablock ParticleData(BNG_steam : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_steam.dds";
    animTexName = "art/shapes/particles/particle_steam.dds";
    colors[0] = "0.992126 0.992126 0.992126 0";
    colors[1] = "0.992126 0.992126 0.992126 1";
    colors[2] = "0.992126 0.992126 0.992126 0.5";
    colors[3] = "0.992126 0.992126 0.992126 0.0";
    dragCoefficient = "1";
    gravityCoefficient = "-0.11";
    inheritedVelFactor = "1";
    spinRandomMin = "-1000";
    spinRandomMax = "1000";
    lifetimeMS = "5000";
    lifetimeVarianceMS = "1875";
    sizes[0] = "1";
    sizes[2] = "2";
    sizes[3] = "5";
    times[1] = "0.1";
    times[2] = "0.513726";
    times[3] = "1";
    spinSpeed = "0.04";
	sizes[0] = "1";
    sizes[1] = "3";
	sizes[2] = "5";
	sizes[3] = "7";
    times[0] = "0";
};

datablock ParticleData(BNG_fire_small : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 1";
    colors[2] = "1 0.7 0.7 0.5";
    colors[3] = "1 0.3 0.3 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.15";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "700";
    lifetimeVarianceMS = "375";
    sizes[0] = "0";
	sizes[1] = "0.7";
    sizes[2] = "0.55";
    sizes[3] = "0";
	times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.6";
};

datablock ParticleData(BNG_fire_small_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 1";
    colors[2] = "1 0.7 0.7 0.5";
    colors[3] = "1 0.3 0.3 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.15";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "300";
    lifetimeVarianceMS = "180";
    sizes[0] = "0";
	sizes[1] = "0.7";
    sizes[2] = "0.55";
    sizes[3] = "0";
	times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.9";
};

datablock ParticleData(BNG_smoke_small_black : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.2";
    colors[2] = "1 1 1 0.1";
    colors[3] = "1 1 1 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.12";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "4000";
    lifetimeVarianceMS = "3000";
    sizes[1] = "1";
    sizes[2] = "1.5";
    sizes[3] = "1.8";
    times[1] = "0";
	times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.18";
};

datablock ParticleData(BNG_fire_medium : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame4.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame4.dds";
    colors[0] = "1 0.639216 0 0.008";
    colors[1] = "1 1 1 1";
    colors[2] = "1 0.7 0.7 0.4";
    colors[3] = "1 0.3 0.3 0";
    dragCoefficient = "1.99902";
    gravityCoefficient = "-0.300366";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "700";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.1";
	sizes[1] = "0.698895";
    sizes[2] = "1";
    sizes[3] = "0.9";
	times[0] = "0.0833333";
    times[1] = "0.229167";
    times[2] = "0.625";
    times[3] = "1";
    spinSpeed = "0.6";
};

datablock ParticleData(BNG_fire_medium_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame4.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame4.dds";
    colors[0] = "1 0.639216 0 0.008";
    colors[1] = "1 1 1 1";
    colors[2] = "1 0.7 0.7 0.4";
    colors[3] = "1 0.3 0.3 0";
    dragCoefficient = "1.99902";
    gravityCoefficient = "-0.300366";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "300";
    lifetimeVarianceMS = "180";
    sizes[0] = "0.1";
	sizes[1] = "0.698895";
    sizes[2] = "1";
    sizes[3] = "0.9";
	times[0] = "0.0833333";
    times[1] = "0.229167";
    times[2] = "0.625";
    times[3] = "1";
    spinSpeed = "0.9";
};

datablock ParticleData(BNG_smoke_medium_black : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.3";
    colors[2] = "1 1 1 0.2";
    colors[3] = "1 1 1 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.3";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "5000";
    lifetimeVarianceMS = "3000";
    sizes[1] = "3";
    sizes[2] = "4";
    sizes[3] = "4.5";
    times[1] = "0";
	times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.14";
};

datablock ParticleData(BNG_fire_large : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame.dds";
    colors[0] = "1 0.9 0.9 0";
    colors[1] = "1 0.9 0.9 0.8";
    colors[2] = "1 0.7 0.7 0.4";
    colors[3] = "1 0.5 0.5 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.7";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "1000";
    lifetimeVarianceMS = "375";
    sizes[0] = "0";
	sizes[1] = "2";
    sizes[2] = "1.5";
    sizes[3] = "0";
	times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.6";
};

datablock ParticleData(BNG_fire_large_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame.dds";
    colors[0] = "1 0.9 0.9 0";
    colors[1] = "1 0.9 0.9 0.8";
    colors[2] = "1 0.7 0.7 0.4";
    colors[3] = "1 0.5 0.5 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.7";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "400";
    lifetimeVarianceMS = "180";
    sizes[0] = "0";
	sizes[1] = "2";
    sizes[2] = "1.5";
    sizes[3] = "0";
	times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.6";
    times[3] = "0.9";
    spinSpeed = "0.9";
};

datablock ParticleData(BNG_fireball_large : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_fire2.dds";
    animTexName = "art/shapes/particles/particle_fire2.dds";
    colors[0] = "0.8 0 0 0.636";
    colors[1] = "1 0.8 0.8 1";
    colors[2] = "1 0.6 0.6 1";
    colors[3] = "1 0.3 0.3 0.008";
    dragCoefficient = "4.5";
    gravityCoefficient = "-1.4";
    inheritedVelFactor = "1";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "1500";
    lifetimeVarianceMS = "375";
    sizes[0] = "0.2";
	sizes[1] = "2";
    sizes[2] = "2.5";
    sizes[3] = "4.5";
	times[0] = "0";
    times[1] = "0.08";
    times[2] = "0.4";
    times[3] = "1";
    spinSpeed = "0.6";
};

datablock ParticleData(BNG_smoke_large : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.3";
    colors[2] = "1 1 1 0.6";
    colors[3] = "1 1 1 0";
    dragCoefficient = "4";
    gravityCoefficient = "-1";
    inheritedVelFactor = "0.8";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    lifetimeMS = "8000";
    lifetimeVarianceMS = "3000";
    sizes[0] = "8";
	sizes[1] = "9";
    sizes[2] = "10";
    sizes[3] = "20";
    times[0] = "0";
	times[1] = "0.2";
    times[2] = "0.5";
    times[3] = "0.9";
    spinSpeed = "0.1";
};

datablock ParticleData(BNG_vapor_01 : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_01.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 1";
    colors[2] = "0.8 0.85 0.9 0.5";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "3.99316";
    gravityCoefficient = "-0.0610501";
    inheritedVelFactor = "1";
    spinRandomMin = "-1000";
    spinRandomMax = "1000";
    lifetimeMS = "800";
    lifetimeVarianceMS = "500";
    sizes[0] = "1";
	sizes[1] = "1.5";
    sizes[2] = "2";
    sizes[3] = "2.3";
    times[1] = "0.1";
    times[2] = "0.517647";
    times[3] = "1";
    spinSpeed = "0.15";

    times[0] = "0";
};

datablock ParticleData(BNG_steam_light_exhaust : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0.5";
    colors[1] = "0.8 0.85 0.9 0.3";
    colors[2] = "0.8 0.85 0.9 0.1";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "3000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.1";
	sizes[1] = "1";
    sizes[2] = "2";
    sizes[3] = "3";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.25";
};

datablock ParticleData(BNG_steam_heavy_coolant : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 0.3";
    colors[2] = "0.8 0.85 0.9 0.15";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "0.6";
    gravityCoefficient = "-0.075";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "4000";
    lifetimeVarianceMS = "2000";
    sizes[0] = "0.5";
	sizes[1] = "1";
    sizes[2] = "2";
    sizes[3] = "4";
    times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.15";
};

datablock ParticleData(BNG_steam_heavy_coolant_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 0.15";
    colors[2] = "0.8 0.85 0.9 0.075";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "0.6";
    gravityCoefficient = "-0.075";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1500";
    sizes[0] = "1";
	sizes[1] = "2";
    sizes[2] = "4";
    sizes[3] = "8";
    times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.3";
};


datablock ParticleData(BNG_smoke_blue_exhaust : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_blue_a.dds";
    animTexName = "art/shapes/particles/particle_smoke_blue_a.dds";
    colors[0] = "0.8 0.85 0.9 0.3";
    colors[1] = "0.8 0.85 0.9 0.2";
    colors[2] = "0.8 0.85 0.9 0.1";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "3000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.1";
	sizes[1] = "0.75";
    sizes[2] = "1.5";
    sizes[3] = "1.8";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.25";
};

datablock ParticleData(BNG_smoke_blue_exhaust_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_blue_a.dds";
    animTexName = "art/shapes/particles/particle_smoke_blue_a.dds";
    colors[0] = "0.8 0.85 0.9 0.2";
    colors[1] = "0.8 0.85 0.9 0.1";
    colors[2] = "0.8 0.85 0.9 0.05";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "1.3";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.2";
	sizes[1] = "1.5";
    sizes[2] = "3";
    sizes[3] = "3.6";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};

datablock ParticleData(BNG_smoke_gray_exhaust : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.5 0.47 0.45 0.1";
    colors[1] = "0.5 0.47 0.45 0.05";
    colors[2] = "0.5 0.47 0.45 0.02";
    colors[3] = "0.5 0.47 0.45 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "400";
    lifetimeVarianceMS = "250";
    sizes[0] = "0.1";
	sizes[1] = "0.4";
    sizes[2] = "0.5";
    sizes[3] = "1";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "1";
};

datablock ParticleData(BNG_smoke_gray_exhaust_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.45 0.42 0.45 0.1";
    colors[1] = "0.45 0.42 0.45 0.03";
    colors[2] = "0.45 0.42 0.45 0.01";
    colors[3] = "0.45 0.42 0.45 0";
    dragCoefficient = "1";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "350";
    lifetimeVarianceMS = "200";
    sizes[0] = "0.2";
	sizes[1] = "0.8";
    sizes[2] = "1.4";
    sizes[3] = "3.4";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "1.3";
};

datablock ParticleData(BNG_steam_light_exhaust_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0.3";
    colors[1] = "0.8 0.85 0.9 0.2";
    colors[2] = "0.8 0.85 0.9 0.1";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "1.3";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.2";
	sizes[1] = "2";
    sizes[2] = "4";
    sizes[3] = "6";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};

datablock ParticleData(BNG_smoke_exhaust_light : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "0.8 0.85 0.9 0.1";
    colors[1] = "0.8 0.85 0.9 0.04";
    colors[2] = "0.8 0.85 0.9 0.01";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.1";
	sizes[1] = "0.75";
    sizes[2] = "1.5";
    sizes[3] = "1.8";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.25";
};

datablock ParticleData(BNG_smoke_exhaust_heavy : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "0.8 0.85 0.9 0.3";
    colors[1] = "0.8 0.85 0.9 0.2";
    colors[2] = "0.8 0.85 0.9 0.1";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "3000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.1";
	sizes[1] = "0.75";
    sizes[2] = "1.5";
    sizes[3] = "1.8";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.25";
};

datablock ParticleData(BNG_smoke_exhaust_light_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "0.8 0.85 0.9 0.05";
    colors[1] = "0.8 0.85 0.9 0.03";
    colors[2] = "0.8 0.85 0.9 0.01";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "1500";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.2";
	sizes[1] = "0.8";
    sizes[2] = "3.2";
    sizes[3] = "5";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};

datablock ParticleData(BNG_smoke_exhaust_heavy_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_black_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_black_01.dds";
    colors[0] = "0.8 0.85 0.9 0.15";
    colors[1] = "0.8 0.85 0.9 0.1";
    colors[2] = "0.8 0.85 0.9 0.05";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "1500";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.2";
	sizes[1] = "0.8";
    sizes[2] = "3.2";
    sizes[3] = "5";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};

datablock ParticleData(BNG_afterfire_orange_flame2 : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame2.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame2.dds";
    colors[0] = "1 1 2 0";
    colors[1] = "1 1 2 1";
    colors[2] = "1 1 1 0.5";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "30";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.35";
    sizes[2] = "0.4";
    sizes[3] = "0.3";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "15";
};

datablock ParticleData(BNG_afterfire_orange_flame3 : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame3.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame3.dds";
    colors[0] = "1 1 2 0";
    colors[1] = "1 1 2 1";
    colors[2] = "1 1 1 0.5";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "30";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.35";
    sizes[2] = "0.4";
    sizes[3] = "0.3";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_afterfire_orange_flame1 : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_flame.dds";
    animTexName = "art/shapes/particles/afterfire_orange_flame.dds";
    colors[0] = "1 1 2 0";
    colors[1] = "1 1 2 1";
    colors[2] = "1 1 1 0.5";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "30";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.2";
    sizes[2] = "0.4";
    sizes[3] = "0.3";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "10";
};

datablock ParticleData(BNG_afterfire_orange_glow : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_glow.dds";
    animTexName = "art/shapes/particles/afterfire_orange_glow.dds";
    colors[0] = "1 1 1 0.2";
    colors[1] = "1 1 1 0.3";
    colors[2] = "1 1 1 0.5";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "20";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.3";
    sizes[2] = "0.8";
    sizes[3] = "0.2";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_afterfire_blue_flame1 : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_blue_flame1.dds";
    animTexName = "art/shapes/particles/afterfire_blue_flame1.dds";
    colors[0] = "1 1 2 1";
    colors[1] = "1 1 2 0.5";
    colors[2] = "1 1 1 0.2";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "20";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.3";
    sizes[2] = "0.8";
    sizes[3] = "0.2";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_afterfire_blue_small : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_blue_flame1.dds";
    animTexName = "art/shapes/particles/afterfire_blue_flame1.dds";
    colors[0] = "1 1 2 0.0";
    colors[1] = "1 1 2 0.2";
    colors[2] = "1 1 1 0.1";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "60";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.1";
	sizes[1] = "0.15";
    sizes[2] = "0.2";
    sizes[3] = "0.15";
	times[0] = "0.0";
    times[1] = "0.1";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "10";
};

datablock ParticleData(BNG_afterfire_red_small : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_red_flame1.dds";
    animTexName = "art/shapes/particles/afterfire_red_flame1.dds";
    colors[0] = "1 1 2 0.0";
    colors[1] = "1 1 2 0.2";
    colors[2] = "1 1 1 0.1";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "60";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.1";
	sizes[1] = "0.15";
    sizes[2] = "0.2";
    sizes[3] = "0.15";
	times[0] = "0.0";
    times[1] = "0.1";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "10";
};

datablock ParticleData(BNG_afterfire_blue_jet : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_blue_jet.dds";
    animTexName = "art/shapes/particles/afterfire_blue_jet.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.5";
    colors[2] = "1 1 1 0.2";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "40";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.2";
	sizes[1] = "0.4";
    sizes[2] = "0.6";
    sizes[3] = "0.8";
	times[0] = "0.0";
    times[1] = "0.1";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_nitrouspurge1 : DefaultParticle)
{
    textureName = "art/shapes/particles/nitrous_purge1.dds";
    animTexName = "art/shapes/particles/nitrous_purge1.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 0.4";
    colors[2] = "1 1 1 0.15";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "75";
    lifetimeVarianceMS = "40";
    sizes[0] = "0.03";
	sizes[1] = "0.06";
    sizes[2] = "0.1";
    sizes[3] = "0.2";
	times[0] = "0.0";
    times[1] = "0.2";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_nitrouspurge2 : DefaultParticle)
{
    textureName = "art/shapes/particles/nitrous_purge1.dds";
    animTexName = "art/shapes/particles/nitrous_purge1.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 0.4";
    colors[2] = "1 1 1 0.15";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "150";
    lifetimeVarianceMS = "40";
    sizes[0] = "0.05";
	sizes[1] = "0.12";
    sizes[2] = "0.3";
    sizes[3] = "0.5";
	times[0] = "0.0";
    times[1] = "0.2";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "5";
};

datablock ParticleData(BNG_nitrouspurge3 : DefaultParticle)
{
    textureName = "art/shapes/particles/nitrous_purge2.dds";
    animTexName = "art/shapes/particles/nitrous_purge2.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0";
    colors[2] = "1 1 1 0.4";
    colors[3] = "1 1 1 0.1";
    colors[4] = "1 1 1 0";
    dragCoefficient = "3";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "400";
    lifetimeVarianceMS = "150";
    sizes[0] = "0.2";
	sizes[1] = "0.2";
    sizes[2] = "0.3";
    sizes[3] = "0.7";
    sizes[4] = "1.3";
	times[0] = "0.0";
    times[1] = "0.1";
    times[2] = "0.2";
    times[3] = "0.5";
    times[4] = "1";
    spinSpeed = "2";
};

datablock ParticleData(BNG_condensation_exhaust : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0.15";
    colors[1] = "0.8 0.85 0.9 0.1";
    colors[2] = "0.8 0.85 0.9 0.05";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "2";
    gravityCoefficient = "-0.15";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "2000";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.1";
	sizes[1] = "0.3";
    sizes[2] = "0.6";
    sizes[3] = "0.8";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.25";
};

datablock ParticleData(BNG_condensation_exhaust_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0.1";
    colors[1] = "0.8 0.85 0.9 0.06";
    colors[2] = "0.8 0.85 0.9 0.03";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "1.3";
    gravityCoefficient = "-0.15";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "1000";
    lifetimeVarianceMS = "800";
    sizes[0] = "0.2";
	sizes[1] = "0.6";
    sizes[2] = "1.2";
    sizes[3] = "2";
    times[0] = "0";
    times[1] = "0.1";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};

datablock ParticleData(BNG_steam_light_coolant : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 0.15";
    colors[2] = "0.8 0.85 0.9 0.07";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "0.6";
    gravityCoefficient = "-0.075";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "3000";
    lifetimeVarianceMS = "2000";
    sizes[0] = "0.5";
	sizes[1] = "0.7";
    sizes[2] = "1.5";
    sizes[3] = "3";
    times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.15";
};

datablock ParticleData(BNG_steam_light_coolant_fast : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_02.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_02.dds";
    colors[0] = "0.8 0.85 0.9 0";
    colors[1] = "0.8 0.85 0.9 0.05";
    colors[2] = "0.8 0.85 0.9 0.02";
    colors[3] = "0.8 0.85 0.9 0";
    dragCoefficient = "0.6";
    gravityCoefficient = "-0.075";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "1000";
    lifetimeVarianceMS = "600";
    sizes[0] = "1";
	sizes[1] = "2";
    sizes[2] = "4";
    sizes[3] = "8";
    times[0] = "0";
    times[1] = "0.3";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.3";
};


datablock ParticleData(BNG_utah_dust : DefaultParticle)
{
    textureName = "art/shapes/particles/Particle_dust.dds";
    animTexName = "art/shapes/particles/Particle_dust.dds";
    colors[0] = "0.992126 0.929134 0.889764 0";
    colors[1] = "0.992126 0.92126 0.866142 0.43";
    colors[2] = "0.992126 0.897638 0.834646 0.372";
    colors[3] = "0.992126 0.897638 0.834646 0.00787402";
    times[1] = "0.104167";
    times[2] = "0.4375";
    dragCoefficient = "0.146";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    lifetimeMS = "15000";
    lifetimeVarianceMS = "500";
    spinSpeed = "0.146";
    spinRandomMin = "-416";
    spinRandomMax = "541";
    sizes[2] = "5";
    sizes[3] = "8";
   sizes[0] = "3";
   sizes[1] = "4";
   constantAcceleration = "0.117";
};

datablock ParticleData(BNG_utah_dust_huge : DefaultParticle)
{
    textureName = "art/shapes/particles/Particle_dust.dds";
    animTexName = "art/shapes/particles/Particle_dust.dds";
    colors[0] = "0.992126 0.929134 0.889764 0";
    colors[1] = "0.992126 0.92126 0.866142 0.425197";
    colors[2] = "0.992126 0.897638 0.834646 0.370079";
    colors[3] = "0.992126 0.897638 0.834646 0.00787402";
    times[1] = "0.101961";
    times[2] = "0.435294";
    dragCoefficient = "0.14174";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    lifetimeMS = "25000";
    lifetimeVarianceMS = "500";
    spinSpeed = "0.146";
    spinRandomMin = "-416";
    spinRandomMax = "541";
    sizes[2] = "15.625";
    sizes[3] = "25";
   sizes[0] = "6.25";
   sizes[1] = "9.375";
   constantAcceleration = "0.117";
};

datablock ParticleData(BNG_water_wheels : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_splash.dds";
    animTexName = "art/shapes/particles/particle_splash.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 0.9";
    colors[2] = "1 1 1 0.4";
    colors[3] = "1 1 1 0.00";
    dragCoefficient = "2";
    gravityCoefficient = "1";
    inheritedVelFactor = "1";
    spinRandomMin = "-708";
    spinRandomMax = "833";
    lifetimeMS = "500";
    lifetimeVarianceMS = "300";
    sizes[0] = "0.5";
    sizes[1] = "0.9";
    sizes[2] = "1";
    sizes[3] = "1.5";
    times[0] = "0";
    times[1] = "0.0980392";
    times[2] = "0.6875";
    times[3] = "1";
    spinSpeed = "0.167";
};

datablock ParticleData(BNG_jatoflare1 : DefaultParticle)
{
    textureName = "art/shapes/particles/afterfire_orange_glow.dds";
    animTexName = "art/shapes/particles/afterfire_orange_glow.dds";
    colors[0] = "1 1 1 0";
    colors[1] = "1 1 1 0.1";
    colors[2] = "1 1 1 0.05";
    colors[3] = "1 1 1 0";
    dragCoefficient = "0";
    gravityCoefficient = "0";
    inheritedVelFactor = "1";
    spinRandomMin = "-180";
    spinRandomMax = "180";
    lifetimeMS = "20";
    lifetimeVarianceMS = "10";
    sizes[0] = "0.4";
	sizes[1] = "2";
    sizes[2] = "3";
    sizes[3] = "4";
	times[0] = "0.0";
    times[1] = "0.33";
    times[2] = "0.67";
    times[3] = "1";
    spinSpeed = "2";
};

datablock ParticleData(BNG_smoke_JATO : DefaultParticle)
{
    textureName = "art/shapes/particles/particle_smoke_soft_01.dds";
    animTexName = "art/shapes/particles/particle_smoke_soft_01.dds";
    colors[0] = "0.6 0.45 0.3 0";
    colors[1] = "0.6 0.45 0.3 0.1";
    colors[2] = "0.6 0.45 0.3 0.02";
    colors[3] = "0.6 0.45 0.3 0";
    dragCoefficient = "1";
    gravityCoefficient = "-0.1";
    inheritedVelFactor = "1";
    spinRandomMin = "-300";
    spinRandomMax = "300";
    lifetimeMS = "1500";
    lifetimeVarianceMS = "1000";
    sizes[0] = "0.5";
	sizes[1] = "2";
    sizes[2] = "10";
    sizes[3] = "15";
    times[0] = "0";
    times[1] = "0.15";
    times[2] = "0.7";
    times[3] = "1";
    spinSpeed = "0.5";
};