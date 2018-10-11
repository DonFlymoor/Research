
// This is the default save location for any Particle Emitter datablocks created in the
// Particle Editor (this script is executed from onServerCreated())


datablock ParticleEmitterData(BNG_Leaves : DefaultEmitter)
{
    ejectionPeriodMS = "687";
    periodVarianceMS = "603";
    ejectionVelocity = "2";
    orientParticles = "0";
    particles = "BNG_Leaf1";
    blendStyle = "NORMAL";
    thetaMin = "142.5";
    thetaMax = "146.3";
    alignParticles = "0";
    alignDirection = "0 0.707107 0.707107";
    phiVariance = "142.5";
    softnessDistance = "1";
    ejectionOffset = "0.2";
    originalName = "BNGTESTEM";
    velocityVariance = "1.5";
};

//datablock ParticleEmitterData(BNG_Black_Smoke : DefaultEmitter)
//{
    //particles = "BNG_Leaf2";
    //ejectionVelocity = "4.167";
    //velocityVariance = "0";
    //softnessDistance = "1";
    //blendStyle = "NORMAL";
    //colors0 = "1 0.0705882 0 1";
    //sizes1 = "18.75";
    //colors1 = "0.00392157 0.00392157 0.00392157 0.407";
    //sizes2 = "1";
    //times3 = "0";
    //colors2 = "0.996078 0.992157 0.992157 1";
    //sizes3 = "1";
    //colors3 = "0.996078 0.992157 0.992157 1";
    //sizes0 = "20.8333";
    //useInvAlpha = "1";
    //lifetimeMS = "376";
    //lifetimeVarianceMS = "0";
    //times1 = "0.25";
    //times2 = "0";
    //inheritedVelFactor = "2.5";
    //dragCoefficient = "0.083";
    //spinRandomMin = "166.1";
    //constantAcceleration = "0.833";
    //spinRandomMax = "167.1";
    //times0 = "0.1875";
    //gravityCoefficient = "0.042";
    //textureName = "art/textures/Particles/particle_oak_leaf_02.dds";
    //spinSpeed = "0";
    //ejectionPeriodMS = "146";
//};

//datablock ParticleEmitterData(BNG_Black_Smoke : DefaultEmitter)
//{
    //particles = "newParticle";
    //blendStyle = "NORMAL";
//};

//datablock ParticleEmitterData(BNG_dust_large : DefaultEmitter)
//{
    //softnessDistance = "1";
    //particles = "BNG_dirt_small";
    //blendStyle = "NORMAL";
    //ejectionOffset = "0.417";
    //thetaMin = "0";
    //thetaMax = "180";
    //originalName = "BNG_dust_small";
    //ejectionPeriodMS = "50";
    //velocityVariance = "0.8";
//};

//datablock ParticleEmitterData(BNG_dust_small : DefaultEmitter)
//{
    //particles = "newParticle2";
    //softnessDistance = "1";
    //blendStyle = "NORMAL";
    //ejectionOffset = "0";
    //thetaMin = "90";
    //thetaMax = "108.8";
//};

//datablock ParticleEmitterData(BNG_Dust_small01 : DefaultEmitter)
//{
    //particles = "BNG_dust_small";
    //softnessDistance = "1";
    //blendStyle = "NORMAL";
    //ejectionVelocity = "1";
    //ejectionOffset = "0.2";
    //thetaMax = "180";
    //periodVarianceMS = "25";
    //ejectionPeriodMS = "50";
//};

/*
datablock ParticleEmitterData(BNG_TestExplosion : DefaultEmitter)
{
    ejectionPeriodMS = "50";
    softnessDistance = "1";
    particles = "newParticle3";
    lifetimeMS = "20";
    blendStyle = "NORMAL";
};
*/

datablock ParticleEmitterData(BNG_dust_gravel : DefaultEmitter)
{
    particles = "BNG_gravel";
    ejectionPeriodMS = "167";
    thetaMax = "45";
    softnessDistance = "1";
    blendStyle = "NORMAL";
};

//datablock ParticleEmitterData(BNG_Dust_Gravel1 : DefaultEmitter)
//{
    //particles = "BNG_Dust_gravel";
    //blendStyle = "NORMAL";
    //ejectionOffset = "0";
    //softnessDistance = "1";
    //ejectionPeriodMS = "101";
    //reverseOrder = "1";
//};

datablock ParticleEmitterData(BNGP_1 : DefaultEmitter)
{
    particles = "BNG_sparks";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0.1";
    reverseOrder = "1";
    softnessDistance = "0.01";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "1";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_2 : DefaultEmitter)
{
    particles = "BNG_dust_light";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
};

datablock ParticleEmitterData(BNGP_3 : DefaultEmitter)
{
    particles = "BNG_dust_dark";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "25";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    highResOnly = 1;
};

datablock ParticleEmitterData(BNGP_4 : DefaultEmitter)
{
    particles = "BNG_dust_dirt";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "180";
    originalName = "BNGP_4";
    highResOnly = 1;
};

datablock ParticleEmitterData(BNGP_5 : DefaultEmitter)
{
    particles = "BNG_dirt";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "10";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
};

datablock ParticleEmitterData(BNGP_6 : DefaultEmitter)
{
    particles = "BNG_smoke_white";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "1";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "180";
    originalName = "BNGP_6";
    highResOnly = 1;
};

datablock ParticleEmitterData(BNGP_7 : DefaultEmitter)
{
    particles = "BNG_smoke_black";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
};

datablock ParticleEmitterData(BNGP_8 : DefaultEmitter)
{
    particles = "BNG_dust_sand";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
};

datablock ParticleEmitterData(BNGP_9 : DefaultEmitter)
{
    particles = "BNG_sparks_explosion";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "4";
    thetaMin = "0";
    thetaMax = "131.300003";
    ejectionOffset = "0.1";
    reverseOrder = "1";
    softnessDistance = "0.01";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "15";
    phiVariance = "360";
    orientParticles = "1";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_13 : DefaultEmitter)
{
    particles = "BNG_chunk_small BNG_chunk_med";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "1";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
};

datablock ParticleEmitterData(BNGP_16 : DefaultEmitter)
{
    particles = "BNG_gravel";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
};

datablock ParticleEmitterData(BNGP_17 : DefaultEmitter)
{
    particles = "BNG_sand";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "1";
    softParticles = "1";
};

datablock ParticleEmitterData(BNGP_18 : DefaultEmitter)
{
    particles = "BNG_mud_1";
    ejectionOffset = "0";
    phiVariance = "0";
    blendStyle = "NORMAL";
    reverseOrder = "0";
    softnessDistance = "0.1";
    ejectionPeriodMS = "10";
};

datablock ParticleEmitterData(BNGP_19 : DefaultEmitter)
{
    particles = "BNG_glassbreak";
    ejectionOffset = "0.1";
    phiVariance = "360";
    blendStyle = "NORMAL";
    reverseOrder = "1";
    softnessDistance = "1.5";
    ejectionPeriodMS = "50";
    lifetimeMS = "25";
    periodVarianceMS = "0";
    thetaMax = "180";
    orientParticles = "0";
    alignParticles = "0";
    thetaMin = "0";
    ejectionVelocity = "0.8";
    softParticles = "1";
};

datablock ParticleEmitterData(BNGP_20 : DefaultEmitter)
{
    particles = "BNG_smoke_white2";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0.2";
    reverseOrder = "1";
    softnessDistance = "0.05";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_21 : DefaultEmitter)
{
    particles = "BNG_grass";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "100";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0.2";
    reverseOrder = "1";
    softnessDistance = "0.85";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_21";
};

datablock ParticleEmitterData(BNGP_22 : DefaultEmitter)
{
    particles = "BNG_smoke_white3";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.3";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_22";
    highResOnly = 0;
};

datablock ParticleEmitterData(BNGP_23 : DefaultEmitter)
{
    particles = "BNG_splash";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "50";
    periodVarianceMS = "40";
    velocityVariance = "2";
    thetaMin = "1";
    thetaMax = "1";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.85";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_23";
    ejectionOffsetVariance = "0.1";
};

datablock ParticleEmitterData(BNGP_60 : DefaultEmitter)
{
    particles = "BNG_volcano_smoke";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "396";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "180";
    thetaMax = "180";
    ejectionOffset = "1.45";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_20";
    softParticles = "1";
};

datablock ParticleEmitterData(BNGP_24 : DefaultEmitter)
{
    particles = "BNG_steam";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "180";
    thetaMax = "180";
    ejectionOffset = "1.45";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_20";
    softParticles = "1";
};

datablock ParticleEmitterData(BNGP_25 : DefaultEmitter)
{
    particles = "BNG_fire_small";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "1";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.15";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_26 : DefaultEmitter)
{
    particles = "BNG_fire_small_fast";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "1";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.15";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_51 : DefaultEmitter)
{
    particles = "BNG_smoke_small_black";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0.15";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_27 : DefaultEmitter)
{
    particles = "BNG_fire_medium";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.15";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_28 : DefaultEmitter)
{
    particles = "BNG_fire_medium_fast";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.15";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_52 : DefaultEmitter)
{
    particles = "BNG_smoke_medium_black";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0.2";
    reverseOrder = "1";
    softnessDistance = "0.15";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "360";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_29 : DefaultEmitter)
{
    particles = "BNG_fire_large";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_30 : DefaultEmitter)
{
    particles = "BNG_fire_large_fast";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.5";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_31 : DefaultEmitter)
{
    particles = "BNG_fireball_large";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "5";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0.5";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "10";
    phiVariance = "360";
    useLighting = "0";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_32 : DefaultEmitter)
{
    particles = "BNG_smoke_large";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "7";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "20";
    phiVariance = "360";
    originalName = "BNGP_20";
};

datablock ParticleEmitterData(BNGP_33 : DefaultEmitter)
{
    particles = "BNG_vapor_01";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "10";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_33";
};

datablock ParticleEmitterData(BNGP_34 : DefaultEmitter)
{
    particles = "BNG_steam_light_exhaust";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_34";
};

datablock ParticleEmitterData(BNGP_35 : DefaultEmitter)
{
    particles = "BNG_steam_heavy_coolant";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.3";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.3";
    phiVariance = "0";
    originalName = "BNGP_33";
};

datablock ParticleEmitterData(BNGP_36 : DefaultEmitter)
{
    particles = "BNG_smoke_blue_exhaust";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_36";
};

datablock ParticleEmitterData(BNGP_37 : DefaultEmitter)
{
    particles = "BNG_steam_heavy_coolant_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.3";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.3";
    phiVariance = "0";
    originalName = "BNGP_37";
};

datablock ParticleEmitterData(BNGP_38 : DefaultEmitter)
{
    particles = "BNG_smoke_blue_exhaust_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_38";
};

datablock ParticleEmitterData(BNGP_39 : DefaultEmitter)
{
    particles = "BNG_steam_light_exhaust_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_34";
};

datablock ParticleEmitterData(BNGP_40 : DefaultEmitter)
{
    particles = "BNG_smoke_exhaust_light";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_40";
};

datablock ParticleEmitterData(BNGP_41 : DefaultEmitter)
{
    particles = "BNG_smoke_exhaust_light_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_41";
};

datablock ParticleEmitterData(BNGP_42 : DefaultEmitter)
{
    particles = "BNG_smoke_exhaust_heavy";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_40";
};

datablock ParticleEmitterData(BNGP_43 : DefaultEmitter)
{
    particles = "BNG_smoke_exhaust_heavy_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_41";
};

datablock ParticleEmitterData(BNGP_44 : DefaultEmitter)
{
    particles = "BNG_smoke_gray_exhaust";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    originalName = "BNGP_44";
};

datablock ParticleEmitterData(BNGP_45 : DefaultEmitter)
{
    particles = "BNG_smoke_gray_exhaust_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    originalName = "BNGP_45";
};

datablock ParticleEmitterData(BNGP_64 : DefaultEmitter)
{
    particles = "BNG_afterfire_blue_flame1";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_65 : DefaultEmitter)
{
    particles = "BNG_afterfire_orange_glow";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_66 : DefaultEmitter)
{
    particles = "BNG_afterfire_blue_small";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_67 : DefaultEmitter)
{
    particles = "BNG_afterfire_red_small";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_68 : DefaultEmitter)
{
    particles = "BNG_afterfire_blue_jet";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "1";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_70 : DefaultEmitter)
{
    particles = "BNG_nitrouspurge1";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "3";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_71 : DefaultEmitter)
{
    particles = "BNG_nitrouspurge2";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_72 : DefaultEmitter)
{
    particles = "BNG_nitrouspurge3";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "20";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_63 : DefaultEmitter)
{
    particles = "BNG_afterfire_orange_flame3";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_62 : DefaultEmitter)
{
    particles = "BNG_afterfire_orange_flame2";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_61 : DefaultEmitter)
{
    particles = "BNG_afterfire_orange_flame1";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "5";
    periodVarianceMS = "0";
    velocityVariance = "0.5";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "1";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_46 : DefaultEmitter)
{
    particles = "BNG_condensation_exhaust";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_46";
};

datablock ParticleEmitterData(BNGP_47 : DefaultEmitter)
{
    particles = "BNG_condensation_exhaust_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.4";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.4";
    phiVariance = "0";
    originalName = "BNGP_46";
};

datablock ParticleEmitterData(BNGP_48 : DefaultEmitter)
{
    particles = "BNG_steam_light_coolant";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.3";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.3";
    phiVariance = "0";
    originalName = "BNGP_48";
};

datablock ParticleEmitterData(BNGP_49 : DefaultEmitter)
{
    particles = "BNG_steam_light_coolant_fast";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0.3";
    thetaMin = "0";
    thetaMax = "180";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0.3";
    phiVariance = "0";
    originalName = "BNGP_37";
};

datablock ParticleEmitterData(BNGP_utah_dust : DefaultEmitter)
{
    particles = "BNG_utah_dust";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "150";
    periodVarianceMS = "20";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "18.75";
    ejectionOffset = "1.458";
    reverseOrder = "1";
    softnessDistance = "2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "4.167";
    phiVariance = "360";
    originalName = "BNGP_37";
   ejectionOffsetVariance = "2.604";
};

datablock ParticleEmitterData(BNGP_utah_dust_huge : DefaultEmitter)
{
    particles = "BNG_utah_dust_huge";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "650";
    periodVarianceMS = "20";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "18";
    ejectionOffset = "1.45";
    reverseOrder = "1";
    softnessDistance = "2";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "4.16";
    phiVariance = "360";
    originalName = "BNGP_37";
   ejectionOffsetVariance = "2.6";
};

datablock ParticleEmitterData(BNGP_sprinkler : DefaultEmitter)
{
    particles = "BNG_spray";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "30";
    periodVarianceMS = "0";
    velocityVariance = "1";
    thetaMin = "0";
    thetaMax = "15";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "3";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "3";
    phiVariance = "0";
   orientParticles = "1";
   originalName = "BNGP_2";
};

datablock ParticleEmitterData(BNGP_50 : DefaultEmitter)
{
    particles = "BNG_water_wheels";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "0";
    ejectionOffset = "0.2";
    reverseOrder = "1";
    softnessDistance = "0.85";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "2";
    phiVariance = "0";
    originalName = "BNGP_21";
};

datablock ParticleEmitterData(BNGP_80 : DefaultEmitter)
{
    particles = "BNG_jatoflare1";
    blendStyle = "ADDITIVE";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};

datablock ParticleEmitterData(BNGP_81 : DefaultEmitter)
{
    particles = "BNG_smoke_JATO";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "0";
    thetaMin = "0";
    thetaMax = "80";
    ejectionOffset = "0";
    reverseOrder = "1";
    softnessDistance = "0.1";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "0";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "0";
    phiVariance = "0";
    orientParticles = "0";
    useLighting = "0";
};
