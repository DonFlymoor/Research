datablock ParticleData(BNG_collectables_explosion_small : DefaultParticle)
{
    dragCoefficient = "0.800000012";
    gravityCoefficient = "0.6";
    inheritedVelFactor = "1";
    lifetimeMS = "1500";
    spinSpeed = "0.25";
    textureName = "art/shapes/particles/snow_explosion_small.dds";
    animTexName = "art/shapes/particles/snow_explosion_small.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 1";
    colors[2] = "1 1 1 1";
    colors[3] = "1 1 1 0";
    sizes[0] = "0.300000012";
    sizes[1] = "1";
    sizes[2] = "1.39999998";
    sizes[3] = "1.5";
    times[1] = "0.101961";
    times[2] = "0.435294";
    times[3] = "0.956863";
    lifetimeVarianceMS = "0";
    spinRandomMin = "-360";
    spinRandomMax = "360";
    times[0] = "0";
   constantAcceleration = "0.5";
};

datablock ParticleEmitterData(BNG_collectables_explosion_small_Emitter : DefaultEmitter)
{
    particles = "BNG_collectables_explosion_small";
    ejectionPeriodMS = "1";
    thetaMax = "180";
    softnessDistance = "1";
    blendStyle = "NORMAL";
   periodVarianceMS = "0";
   ejectionVelocity = "2.5";
   velocityVariance = "0.5";
   lifetimeMS = "10";
   lifetimeVarianceMS = "0";
};


datablock ParticleData(BNG_hay : DefaultParticle)
{
    textureName = "vehicles/haybale/haybale3_d.dds";
    animTexName = "vehicles/haybale/haybale3_d.dds";
    colors[0] = "1 1 1 1";
    colors[1] = "1 1 1 1";
    colors[2] = "1 1 1 1";
    colors[3] = "1 1 1 0.00";
    dragCoefficient = "3";
    gravityCoefficient = "1";
    inheritedVelFactor = "0";
    spinRandomMin = "-708";
    spinRandomMax = "833";
    lifetimeMS = "750";
    lifetimeVarianceMS = "400";
    sizes[0] = "0.5";
    sizes[1] = "0.5";
    sizes[2] = "0.5";
    sizes[3] = "0.5";
    times[0] = "0";
    times[1] = "0.0980392";
    times[2] = "0.6875";
    times[3] = "1";
    spinSpeed = "0.100";
};

datablock ParticleEmitterData(BNG_hay_emitter : DefaultEmitter)
{
    particles = "BNG_hay";
    blendStyle = "NORMAL";
    ejectionPeriodMS = "1";
    periodVarianceMS = "0";
    velocityVariance = "2";
    softParticles = "1";
    thetaMin = "0";
    thetaMax = "45";
    ejectionOffset = "0.2";
    reverseOrder = "1";
    softnessDistance = "0.85";
    ambientFactor = "0";
    alignDirection = "0 0 0";
    lifetimeMS = "10";
    lifetimeVarianceMS = "0";
    ejectionVelocity = "7";
    phiVariance = "360";
};
