-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local function logMessage(ctx, level, msg)
  local origin = ctx.lastFile
  if ctx.lastBytes then origin = origin .. ':' .. string.format("%05d", ctx.lastBytes) end

  if not ctx.messages then ctx.messages = {} end
  if not ctx.messages[origin] then ctx.messages[origin] = {} end
  table.insert(ctx.messages[origin], {level, msg})
end

function isint(n)
  local m = tonumber(n)
  return m == floor(m)
end

local valid_class_properties = {
  ScatterSky = {
    parent = 'SceneObject',
    skyBrightness ='float',
    mieScattering ='float',
    sunSize ='float',
    colorizeAmount ='float',
    colorize ='ColorF',
    colorizeGradientFile ='string', --StringFilename
    ambientScale = 'ColorF',
    ambientScaleGradientFile ='string', --StringFilename
    fogScale = 'ColorF',
    fogScaleGradientFile='string', --StringFilename
    exposure ='float',
    azimuth = 'float',
    elevation ='float',
    moonAzimuth ='float',
    moonElevation ='float',
    castShadows ='bool',
    brightness ='float',
    flareType = 'LightFlareData',
    flareScale ='float',
    nightColor ='ColorF',
    nightFogColor ='ColorF',
    moonEnabled ='bool',
    moonMat = 'string' , --MatrialName
    moonScale ='float',
    moonLightColor ='ColorF',
    useNightCubemap ='bool',
    nightCubemap = 'string'--CubemapName
  },
  SkyBox = {
    parent = 'SceneObject',
    material =  'string' , --MatrialName
    drawBottom ='bool',
    fogBandHeight = 'float',
  },
  Sun = {
    parent ='SceneObject',
    material =  'string' , --MatrialName
    drawBottom ='bool',
    fogBandHeight = 'float',
  },
  TimeOfDay = {
    parent ='SceneObject',
    axisTilt= 'float',
    dayLength ='float',
    startTime ='float',
    time ='float',
    play ='bool',
    azimuthOverride ='float',
    dayScale ='float',
    nightScale ='float',
  },
  WaterBlock = {
    parent = 'WaterObject',
    gridElementSize = 'float',
    gridSize = 'float',
  },
  WaterPlane = {
    parent = 'WaterObject',
    gridElementSize = 'float',
    gridSize = 'float',
  },
  Forest = {
    parent = 'SceneObject',
    dataFile ='string', --Filename
    lodReflectScalar ='float',

  },
  ForestTool = {
    parent = 'SimObject',
  },
  ForestBrushTool = {
    parent = 'ForestTool',
    mode = 'string', --Brushmode
    size = 'float',
    pressure ='float',
    hardness ='float',
  },
  ForestWindEmitter = {
    parent = 'SceneObject',
    windEnabled = 'bool',
    radialEmitter ='bool',
    strength = 'float',
    radius = 'float',
    gustStrength = 'float',
    gustFrequency= 'float',
    gustYawAngle = 'float',
    gustYawFrequency = 'float',
    gustWobbleStrength = 'float',
    turbulenceStrength = 'float',
    turbulenceFrequency = 'float',
    hasMount = 'float',
  },
  ForestItemData = {
    parent = 'SimDataBlock',
    shapeFile= 'string',  --ShapeFilename
    collidable='bool',
    radius='float',
    mass ='float',
    rigidity ='float',
    tightnessCoefficient = 'float',
    dampingCoefficient ='float',
    windScale = 'float',
    trunkBendScale ='float',
    branchAmp ='float',
    detailAmp ='float',
    detailFreq = 'float',
  },
  ForestBrushElement ={
    parent = 'SimObject',
    forestItemData = 'ForestItemData',
    probability ='float',
    rotationRange ='float',
    scaleMin ='float',
    scaleMax ='float',
    scaleExponent ='float',
    sinkMin='float',
    sinkMax='float',
    sinkRadius = 'float',
    slopeMin ='float',
    slopeMax='float',
    elevationMin= 'float',
    elevationMax ='float',
  },
  ForestEditorCtrl = {
   parent = 'EditTSCtrl',
  },
  LightFlareData ={
    parent ='SimDataBlock',
    overallScale ='float',
    occlusionRadius ='float',
    renderReflectPass ='bool',
    flareEnabled ='bool',
    flareTexture = 'string', --ImageFilename
    elementRect ='RectF',
    elementDist ='float',
    elementScale ='float',
    elementTint ='ColorF',
    elementRotate ='bool',
    elementUseLightColor ='bool',
  },
  ConsoleObject = {
    parent = 'EngineObject',
  },
  SimObject = {
    parent = 'ConsoleObject',
    name = 'string',
    internalName ='string',
    parentGroup ='SimObject',
    class ='string',
    superClass ='string',
    className ='string',
    hidden ='bool',
    locked ='bool',
    canSave ='bool',
    canSaveDynamicFields ='bool',
    persistentId= 'SimPersistID',--TypePID

  },
  NetObject ={
    parent = 'SimObject',
  },
  Base ={
    --template
  },
  SceneSpace = {
    parent = 'SceneObject',
 --   classType = 'abstract',
  },
  SceneZoneSpace = {
    parent = 'SceneSpace',
    zoneGroup ='int',
  --  classType = 'abstract',
  },
  SceneSimpleZone = {
    parent ='SceneZoneSpace',
  --  classType = 'abstract'
    useAmbientLightColor = 'bool',
    ambientLightColor = 'ColorF',
  },
  ScenePolyhedralObject = {
    parent = 'Base',
    plane ='string',
    point ='string',
    edge ='string',
  },

  SceneAmbientSoundObject = {
    parent = 'Base',
    soundAmbience = 'SFXAmbience',
  },
  SceneObject = {
    parent = 'NetObject',
    position = 'MatrixF',
    rotation = 'MatrixF',
    scale = 'Point3F',
    isRenderEnabled = 'bool',
    isSelectionEnabled ='bool',
    mountPID = 'SimPersistID',
    mountNode = 'int',
    mountPos = 'MatrixF',
    mountRot = 'MatrixF',
  },
  GroundCover ={
    parent = 'SceneObject',
    material ='string',
    radius ='float',
    dissolveRadius ='float',
    reflectScale ='float',
    gridSize ='int',
    zOffset='float',
    seed ='int',
    maxElements= 'int',
    maxBillboardTiltAngle ='float',
    shapeCullRadius = 'float',
    shapesCastShadows ='bool',
    billboardUVs ='RectF',
    shapeFilename ='string',
    layer  ='string', --TypeTerrainMaterialName
    invertLayer ='bool',
    probability ='float',
    sizeMin ='float',
    sizeMax ='float',
    sizeExponent ='float',
    windScale ='float',
    maxSlope ='float',
    minElevation ='float',
    maxElevation ='float',
    minClumpCount ='int',
    maxClumpCount = 'int',
    clumpExponent ='float',
    clumpRadius ='float',
    windDirection ='Point2F',
    windGustLength='float',
    windGustFrequency='float',
    windGustStrength ='float',
    windTurbulenceFrequency ='float',
    windTurbulenceStrength= 'float',
    lockFrustum ='bool',
    renderCells ='bool',
    noBillboards= 'bool',
    noShapes ='bool',
  },
  LightningData = {
    parent = 'GameBaseData',
    strikeSound = 'SFXTrack',
    thunderSounds ='SFXTrack',
    strikeTextures ='string',
  },
  Lightning = {
    parent = 'GameBase',
    strikesPerMinute = 'int',
    strikeWidth ='float',
    strikeRadius ='float',
    color ='ColorF',
    fadeColor= 'ColorF',
    chanceToHitTarget ='float',
    boltStartRadius= 'float',
    useFog ='bool',
  },
  fxShapeReplicator ={
    parent ='SceneObject',
    HideReplications ='bool',
    ShowPlacementArea='bool',
    PlacementAreaHeight='int',
    PlacementColour ='ColorF',
    ShapeFile ='string', --TypeShapeFilename
    Seed ='int',
    ShapeCount ='int',
    ShapeRetries ='int',
    InnerRadiusX ='int',
    InnerRadiusY ='int',
    OuterRadiusX = 'int',
    OuterRadiusY = 'int',
    AllowOnTerrain ='bool',
    AllowOnStatics= 'bool',
    AllowOnWater ='bool',
    AllowWaterSurface= 'bool',
    AllowedTerrainSlope = 'int',
    AlignToTerrain ='bool',
    Interactions= 'bool',
    TerrainAlignment ='Point3F',
    ShapeScaleMin ='Point3F',
    ShapeScaleMax ='Point3F',
    ShapeRotateMin ='Point3F',
    ShapeRotateMax ='Point3F',
    OffsetZ = 'int',
  },
  fxFoliageReplicator = {
    parent ='SceneObject',
    UseDebugInfo ='bool',
    DebugBoxHeight ='float',
    HideFoliage ='bool',
    ShowPlacementArea ='bool',
    PlacementAreaHeight ='int',
    PlacementColour= 'ColorF',
    Seed ='int',
    FoliageFile ='string', --Filename
    FoliageCount ='int',
    FoliageRetries ='int',
    InnerRadiusX ='int',
    InnerRadiusY ='int',
    OuterRadiusX = 'int',
    OuterRadiusY = 'int',
    MinWidth = 'float',
    MaxWidth ='float',
    MinHeight = 'float',
    MaxHeight ='float',
    FixAspectRatio ='bool',
    FixSizeToMax ='bool',
    OffsetZ ='float',
    RandomFlip ='bool',
    UseTrueBillboards= 'bool',
    UseCulling= 'bool',
    CullResolution ='int',
    ViewDistance ='float',
    ViewClosest ='float',
    FadeInRegion ='float',
    FadeOutRegion='float',
    AlphaCutoff='float',
    GroundAlpha ='float',
    SwayOn='bool',
    SwaySync='bool',
    SwayMagSide='float',
    SwayMagFront ='float',
    MinSwayTime ='float',
    MaxSwayTime ='float',
    LightOn ='bool',
    LightSync='bool',
    MinLuminance ='float',
    MaxLuminance ='float',
    LightTime='float',
    AllowOnTerrain ='bool',
    AllowOnStatics= 'bool',
    AllowOnWater ='bool',
    AllowWaterSurface= 'bool',
    AllowedTerrainSlope = 'int',
  },
  GameBaseData = {
  parent = 'SimDataBlock',
  category = 'string'
  },
  GameBase = {
    parent = 'SceneObject',
    dataBlock = 'GameBaseData',
  },
  BeamNGTrigger = {
    parent = 'GameBase',
    TriggerType = 'string',
    TriggerMode = 'string',
    luaFunction = 'command',
    tickPeriod= 'int',
    debug = 'bool',
    ticking = 'bool',
    triggerColor ='colorI',
    force ='float',
  },
  BeamNGEnvTrigger = {
    parent = 'BeamNGTrigger',
    time = 'float',
    play ='bool',
    speed = 'float',
    windSpeed = 'float',
    cloudCover = 'float',
    fogDensity = 'fogDensity',
    rainDrops = 'float',
    gravity = 'gravity',
  },
  ShapeBase = {
    parent = 'GameBase',
    skin = 'string',
    isAiControlled = 'bool',
  },
  ReflectorDesc={
    parent = 'SimDataBlock',
    texSize = 'int',
    nearDist ='float',
    farDist ='float',
    objectTypeMask ='int',
    detailAdjust = 'float',
    useLowDetailMaterials ='float',
    priority = 'float',
    maxRateMs ='int',
    useOcclusionQuery ='bool',
  },
  BeamNGVehicle = {
    parent = 'ShapeBase',
    JBeam = 'string',
    color = 'ColorF',
    colorPalette0 = 'ColorF',
    colorPalette1 = 'ColorF',
    colorPalette2 = 'ColorF',
    colorPalette3 = 'ColorF',
    partConfig = 'string',
    renderDistance = 'float',
    renderFade = 'float',

  },
  PhysicalZone = {
    parent = 'SceneObject',
    velocityMod ='float',
    gravityMod ='float',
    appliedForce ='Point3F',
    polyhedron = 'string',
  },
  CameraBookmark ={
    parent = 'MissionMarker',
  },
  SpawnSphere = {
    parent = 'MissionMarker',
    spawnClass ='string',
    spawnDatablock ='string',
    spawnProperties ='string',
    spawnScript ='string',
    autoSpawn ='bool',
    spawnTransform ='bool',
    radius ='float',
    sphereWeight ='float',
    indoorWeight ='float',
    outdoorWeight ='float',
  },
  WayPoint = {
    parent = 'MissionMarker',
    markerName = 'string',
    team = 'WayPointTeam'
  },
  MissionMarker = {
    parent= 'ShapeBase',
  },
  MissionArea = {
    parent ='NetObject',
    area = 'RectI',
    flightCeiling ='float',
    flightCeilingRange ='float',
  },
  LightDescription = {
    parent ='SimDataBlock',
    color = 'ColorF',
    brightness ='float',
    castShadows ='bool',
    range ='float',
    animationType = 'LightAnimData',
    animationPeriod ='float',
    animationPhase ='float',
    flareType ='LightFlareData',
    flareScale ='float',
  },
  LightBase = {
    parent ='SceneObject',
    isEnabled= 'bool',
    color = 'ColorF',
    brightness ='float',
    castShadows ='bool',
    priority = 'float',
    animate ='bool',
    animationType = 'LightAnimData',
    animationPeriod ='float',
    animationPhase ='float',
    flareType ='LightFlareData',
    flareScale ='float',

  },
  LightAnimData = {
    parent ='SimDataBlock',
    offsetA = 'float',
    offsetZ = 'float',
    offsetPeriod ='float',
    offsetKeys ='string',
    offsetSmooth ='bool',
    rotA ='float',
    rotZ = 'float',
    rotKeys ='string',
    rotSmooth = 'bool',
    colorA ='float',
    colorZ ='float',
    colorPeriod = 'float',
    colorKeys ='string',
    colorSmooth ='bool',
    brightnessA = 'float',
    brightnessZ ='float',
    brightnessPeriod ='float',
    brightnessKeys ='string',
    brightnessSmooth='bool',
  },
  LevelInfo = {
    parent ='NetObject',
    nearClip ='float',
    visibleDistance ='float',
    decalBias ='float',
    gravity ='float',
    fogColor ='ColorF',
    fogDensity ='float',
    fogDensityOffset ='float',
    fogAtmosphereHeight ='float',
    canvasClearColor ='ColorI',
    ambientLightBlendPhase ='float',
    ambientLightBlendCurve ='EaseF',
    advancedLightmapSupport ='bool',
    globalEnviromentMap ='CubemapData',
    soundAmbience ='SFXAmbience',
    soundDistanceModel = 'string',  --SFXDistanceModel
  },
  Item = {
    parent = 'ShapeBase',
    static ='bool',
    rotate = 'bool',
  },
  ItemData = {
    parent ='ShapeBaseData',
    friction = 'float',
    elasticity ='float',
    sticky ='bool',
    gravityMod ='float',
    maxVelocity ='float',
    lightType = 'string', --Item::LightType
    lightColor = 'ColorF',
    lightTime = 'int',
    lightRadius ='float',
    lightOnlyStatic ='bool',
    simpleServerCollision ='bool',
  },
  GuiObjectView = {
    parent ='GuiTSCtrl',
    shapeFile = 'string',
    skin ='string',
    animSequence ='string',
    mountedShapeFile ='string',
    mountedSkin ='string',
    mountedNode ='string',
    lightColor ='ColorF',
    lightAmbient ='ColorF',
    lightDirection ='Point3F',
    orbitDiststance ='float',
    minOrbitDiststance ='float',
    maxOrbitDiststance ='float',
    cameraSpeed ='float',
    cameraRotation ='Point3F',
  },
  GroundPlane = {
    parent ='SceneObject',
    squareSize ='float',
    scaleU = 'float',
    scaleV = 'float',
    material ='string',
  },

  Debris ={
    parent = 'GameBase',
    lifetime ='float',
  },
  ConvexShape ={
    parent = 'SceneObject',
    material = 'string',
    surface ='string',
  },
  Camera ={
    parent = 'ShapeBase',
    controlMode = 'string', --CameraMotionMode
    newtonMode ='bool',
    newtonRotation ='bool',
    mass = 'float',
    drag = 'float',
    force = 'float',
    angularDrag = 'float',
    angularForce = 'float',
    speedMultiplier = 'float',
    brakeMultiplier = 'float',
  },
  Projectile ={
    parent = 'GameBase',
    initialPosition ='Point3F',
    initialVelocity ='Point3F',
    sourceObject ='int',
    sourceSlot ='int',
  },
  RigidShapeData = {
    parent = 'ShapeBaseData',
    massCenter ='Point3F',
    massBox='Point3F',
    bodyRestitution= 'float',
    bodyFriction= 'float',
    minImpactSpeed= 'float',
    softImpactSpeed= 'float',
    hardImpactSpeed= 'float',
    minRollSpeed= 'float',
    maxDrag= 'float',
    minDrag= 'float',
    integration ='int',
    collisionTol= 'float',
    contactTol= 'float',
    dragForce= 'float',
    vertFactor= 'float',
    dustEmitter = 'ParticleEmitterData',
    triggerDustHeight= 'float',
    dustHeight= 'float',
    dustTrailEmitter= 'ParticleEmitterData',
    splashEmitter= 'ParticleEmitterData',
    splashFreqMod= 'float',
    splashVelEpsilon= 'float',
    softImpactSound= 'SFXTrack',
    hardImpactSound ='SFXTrack',
    exitSplashSoundVelocity= 'float',
    softSplashSoundVelocity= 'float',
    mediumSplashSoundVelocity= 'float',
    hardSplashSoundVelocity= 'float',
    exitingWater='SFXTrack',
    impactWaterEasy='SFXTrack',
    impactWaterMedium='SFXTrack',
    impactWaterHard='SFXTrack',
    waterWakeSound='SFXTrack',
    cameraRoll = 'bool',
    cameraLag= 'float',
    cameraDecay= 'float',
    cameraOffset= 'float',
  },
  RigidShape ={
    parent = 'ShapeBase',
  },
  StaticShape ={
    parent = 'ShapeBase',
  },
  ScopeAlwaysShape ={
    parent = 'StaticShape',
  },
  ProximityMineData = {
    parent = 'ItemData',
    armingDelay ='float',
    armingSound = 'SFXTrack',
    autoTriggerDelay ='float',
    triggerOnOwner='bool',
    triggerRadius='float',
    triggerSpeed='float',
    triggerDelay='float',
    triggerSound ='SFXTrack',
    explosionOffset ='float',
  },
  ProjectileData ={
    parent = 'GameBaseData',
    particleEmitter = 'ParticleEmitterData',
    particleWaterEmitter ='ParticleEmitterData',
    projectileShapeName='string',
    scale ='Point3F',
    sound ='SFXTrack',
    explosion ='ExplosionData',
    splash ='SplashData',
    decal='decalData',
    lightDesc ='LightDescription',
    isBallistic ='bool',
    velInheritFactor ='float',
    muzzleVelocity ='float',
    impactForce ='float',
    lifetime ='int',
    armingDelay ='int',
    fadeDelay ='int',
    bounceElasticity ='float',
    bounceFriction ='float',
    gravityMod ='float',
  },
  CameraData ={
    parent ='ShapeBaseData',
  },
  Prefab ={
    parent ='SceneObject',
    filename ='string',
    useGlobalTranslation= 'bool',
  },
  Portal = {
    parent = 'Zone',
    frontSidePassable = 'bool',
    backSidePassable ='bool',
  },
  PointLight ={
    parent = 'LightBase',
    radius ='float',
  },
  PlayerData = {
    parent = 'ShapeBaseData',
    pickupRadius ='float',
    maxTimeScale ='float',
    renderFirstPerson ='bool',
    firstPersonShadows ='bool',
    minLookAngle ='float',
    maxLookAngle ='float',
    maxFreelookAngle ='float',
    maxStepHeight= 'float',
    runForce ='float',
    runEnergyDrain ='float',
    minRunEnergy ='float',
    maxForwardSpeed ='float',
    maxBackwardSpeed ='float',
    maxSideSpeed ='float',
    runSurfaceAngle ='float',
    minImpactSpeed ='float',
    minLateralImpactSpeed ='float',
    horizMaxSpeed ='float',
    horizResistSpeed ='float',
    horizResistFactor ='float',
    upMaxSpeed='float',
    upResistSpeed ='float',
    upResistFactor ='float',
    jumpForce ='float',
    jumpEnergyDrain ='float',
    minJumpEnergy ='float',
    minJumpSpeed ='float',
    maxJumpSpeed ='float',
    jumpSurfaceAngle ='float',
    jumpDelay ='int',
    airControl ='float',
    jumpTowardsNormal ='bool',
    sprintForce ='float',
    sprintEnergyDrain ='float',
    minSprintEnergy ='float',
    maxSprintForwardSpeed ='float',
    maxSprintBackwardSpeed ='float',
    maxSprintSideSpeed ='float',
    sprintStrafeScale ='float',
    sprintYawScale ='float',
    sprintPitchScale ='float',
    sprintCanJump ='bool',
    swimForce ='float',
    maxUnderwaterForwardSpeed ='float',
    maxUnderwaterBackwardSpeed ='float',
    maxUnderwaterSideSpeed ='float',
    crouchForce ='float',
    maxCrouchForwardSpeed ='float',
    maxCrouchBackwardSpeed ='float',
    maxCrouchSideSpeed ='float',
    proneForce ='float',
    maxProneForwardSpeed ='float',
    maxProneBackwardSpeed ='float',
    maxProneSideSpeed ='float',
    jetJumpForce ='float',
    jetJumpEnergyDrain ='float',
    jetMinJumpEnergy ='float',
    jetMinJumpSpeed ='float',
    jetMaxJumpSpeed ='float',
    jetJumpSurfaceAngle ='float',
    fallingSpeedThreshold ='float',
    recoverDelay ='int',
    recoverRunForceScale ='float',
    landSequenceTime ='float',
    transitionToLand ='bool',
    boundingBox ='Point3F',
    crouchBoundingBox ='Point3F',
    proneBoundingBox ='Point3F',
    swimBoundingBox ='Point3F',
    boxHeadPercentage ='float',
    boxTorsoPercentage ='float',
    boxHeadLeftPercentage ='float',
    boxHeadRightPercentage ='float',
    boboxHeadFrontPercentage ='float',
    xHeadBackPercentage ='float',
    footPuffEmitter ='ParticleEmitterData',
    footPuffNumParts ='int',
    footPuffRadius  ='float',
    dustEmitter =' ParticleEmitterData',
    decalData = 'decalData',
    decalOffset ='float',
    FootSoftSound = 'SFXTrack',
    FootHardSound= 'SFXTrack',
    FootMetalSound= 'SFXTrack',
    FootSnowSound= 'SFXTrack',
    FootShallowSound= 'SFXTrack',
    FootWadingSound= 'SFXTrack',
    FootUnderwaterSound= 'SFXTrack',
    FootBubblesSound= 'SFXTrack',
    movingBubblesSound= 'SFXTrack',
    waterBreathSound= 'SFXTrack',
    impactSoftSound= 'SFXTrack',
    impactHardSound= 'SFXTrack',
    impactMetalSound= 'SFXTrack',
    impactSnowSound= 'SFXTrack',
    impactWaterEasy= 'SFXTrack',
    impactWaterMedium= 'SFXTrack',
    impactWaterHard= 'SFXTrack',
    exitingWater= 'SFXTrack',
    splash = 'SplashData',
    splashVelocity ='float',
    splashAngle='float',
    splashFreqMod='float',
    splashVelEpsilon='float',
    bubbleEmitTime='float',
    splashEmitter ='ParticleEmitterData',
    footstepSplashHeight='float',
    mediumSplashSoundVelocity='float',
    hardSplashSoundVelocity='float',
    exitSplashSoundVelocity='float',
    groundImpactMinSpeed='float',
    groundImpactShakeFreq ='Point3F',
    groundImpactShakeAmp ='Point3F',
    groundImpactShakeDuration='float',
    groundImpactShakeFalloff='float',
    physicsPlayerType ='string',
    imageAnimPrefixFP ='string',
    shapeNameFP ='string',
    imageAnimPrefix ='string',
    allowImageStateAnimation ='bool',
  },
  AIPlayer ={
    parent = 'Palyer',
    mMoveTolerance ='float',
    moveStuckTolerance ='float',
    moveStuckTestDelay ='int',
  },
  SFXEmitter ={
    parent = 'SceneObject',
    track = 'SFXTrack',
    fileName = 'string',
    playOnAdd ='bool',
    useTrackDescriptionOnly ='bool',
    isLooping ='bool',
    isStreaming ='bool',
    sourceGroup = 'SFXSource',
    volume ='float',
    pitch ='float',
    fadeInTime = 'float',
    fadeOutTime ='float',
    is3D ='bool',
    referenceDistance ='float',
    maxDistance ='float',
    scatterDistance ='Point3F',
    coneInsideAngle ='int',
    coneOutsideAngle ='int',
    coneOutsideVolume ='float',
  },
  PhysicsShape ={
    parent = 'GameBase',
    playAmbient ='bool',
  },
  PhysicsShapeData ={
    parent = 'GameBaseData',
    shapeName ='string',
    debris = 'SimObjectRef',
    destroyedShape ='SimObjectRef',
    mass = 'float',
    friction = 'float',
    staticFriction = 'float',
    restitution = 'float',
    linearDamping = 'float',
    angularDamping = 'float',
    linearSleepThreshold = 'float',
    angularSleepThreshold = 'float',
    waterDampingScale = 'float',
    buoyancyDensity = 'float',
    simType = 'PhysicsShapeData',
  },
  PhysicsForce ={
    parent = 'SceneObject',
  },
  PhysicsDebris ={
    parent = 'GameBase',
   },
  PhysicsDebrisData ={
    parent = 'GameBaseData',
    shapeFile ='string',
    castShadows= 'bool',
    lifetime ='float',
    lifetimeVariance ='float',
    mass ='float',
    friction ='float',
    staticFriction ='float',
    restitution ='float',
    linearDamping ='float',
    angularDamping ='float',
    linearSleepThreshold ='float',
    angularSleepThreshold ='float',
    waterDampingScale ='float',
    buoyancyDensity ='float',
  },
  SplashData ={
    parent = 'GameBaseData',
    soundProfile = 'SFXProfile',
    scale ='Point3F',
    emitter ='ParticleEmitterData',
    delayMS ='int',
    delayVariance ='int',
    lifetimeMS ='int',
    lifetimeVariance ='int',
    width = 'float',
    numSegments ='int',
    velocity ='float',
    height ='float',
    acceleration ='float',
    times ='float',
    colors ='ColorF',
    texture ='string',
    texWrap ='float',
    texFactor ='float',
    ejectionFreq ='float',
    ejectionAngle ='float',
    ringLifetime ='float',
    startRadius ='float',
    explosion = 'ExplosionData'
  },
   Precipitation ={
    parent = 'GameBase',
    numDrops ='int',
    boxWidth ='float',
    boxHeight ='float',
    dropSize ='float',
    splashSize ='float',
    splashMS ='int',
    animateSplashes ='bool',
    dropAnimateMS ='int',
    fadeDist ='float',
    fadeDistEnd ='float',
    useTrueBillboards ='bool',
    useLighting ='bool',
    glowIntensity ='ColorF',
    reflect ='bool',
    rotateWithCamVel ='bool',
    doCollision ='bool',
    hitPlayers ='bool',
    hitVehicles ='bool',
    followCam ='bool',
    useWind ='bool',
    minSpeed ='float',
    maxSpeed ='float',
    minMass = 'float',
    maxMass ='float',
    useTurbulence ='bool',
    maxTurbulence ='float',
    turbulenceSpeed ='float',
  },
  PrecipitationData ={
    parent = 'GameBaseData',
    soundProfile ='SFXTrack',
    dropTexture ='string',
    dropShader = 'string',
    splashTexture ='string',
    splashShader ='string',
    dropsPerSide ='int',
    splashesPerSide='int',
  },
  ParticleEmitterNodeData ={
    parent = 'GameBaseData',
    timeMultiple = 'float',
    active ='bool',
    emitter = 'ParticleEmitterData',
    velocity ='float',
  },
  ParticleData ={
    parent = 'SimDataBlock',
    dragCoefficient ='float',
    windCoefficient ='float',
    gravityCoefficient ='float',
    inheritedVelFactor ='float',
    constantAcceleration ='float',
    lifetimeMS ='int',
    lifetimeVarianceMS ='int',
    spinSpeed ='float',
    spinRandomMin ='float',
    useInvAlpha ='bool',
    animateTexture ='bool',
    framesPerSec ='int',
    textureCoords ='Point2F',
    animTexTiling ='Point2I',
    animTexFrames = 'string', --StringTableEntry
    textureName = 'string', --StringTableEntry
    animTexName = 'string', --StringTableEntry
    colors ='ColorF',
    sizes ='float',
    times ='float',
  },
  ParticleEmitterData = {
    parent = 'GameBaseData',
    ejectionPeriodMS = 'int',
    periodVarianceMS = 'int',
    ejectionVelocity = 'float',
    velocityVariance = 'float',
    ejectionOffset = 'float',
    ejectionOffsetVariance = 'float',
    thetaMin ='float',
    thetaMax = 'float',
    phiReferenceVel = 'float',
    phiVariance = 'float',
    softnessDistance = 'float',
    ambientFactor = 'float',
    overrideAdvance = 'bool',
    orientParticles = 'bool',
    orientOnVelocity ='bool',
    particles = 'string', -- StringTableEntry
    lifetimeMS = 'int',
    lifetimeVarianceMS = 'int',
    useEmitterSizes = 'bool',
    useEmitterColors = 'bool',
    blendStyle = 'ParticleRenderInst',
    sortParticles ='bool',
    reverseOrder = 'bool',
    textureName = 'string',
    alignParticles = 'bool',
    alignDirection ='Point3F',
    highResOnly ='bool',
    renderReflection ='bool',
    backLighting ='float',
    useLighting = 'bool',

  },
  DebrisData = {
    parent = 'GameBaseData',
    texture = 'string',
    shapeFile= 'string',--TypeShapeFilename
    emitters ='ParticleEmitterData',
    explosion ='ExplosionData',
    elasticity ='float',
    friction = 'float',
    numBounces = 'int',
    bounceVariance = 'int',
    minSpinSpeed = 'float',
    maxSpinSpeed = 'float',
    gravModifier = 'float',
    terminalVelocity = 'float',
    velocity ='float',
    velocityVariance ='float',
    lifetime ='float',
    lifetimeVariance = 'float',
    useRadiusMass = 'bool',
    baseRadius ='float',
    explodeOnMaxBounce = 'bool',
    staticOnMaxBounce ='bool',
    snapOnMaxBounce = 'bool',
    fade = 'bool',
    ignoreWater ='bool',
  },
  SFXEnvironment = {
    parent = 'SimDataBlock',
    envSize= 'float',
    envDiffusion ='float',
    room ='int',
    roomHF = 'int',
    roomLF ='int',
    decayTime ='float',
    decayHFRatio ='float',
    decayLFRatio ='float',
    reflections ='int',
    reflectionsDelay ='float',
    reflectionsPan ='float',
    reverb='int',
    reverbDelay ='float',
    reverbPan ='float',
    echoTime ='float',
    echoDepth ='float',
    modulationTime ='float',
    modulationDepth ='float',
    airAbsorptionHF ='float',
    HFReference ='float',
    LFReference ='float',
    roomRolloffFactor ='float',
    diffusion ='float',
    density ='float',
    flags ='int'
  },
  SFXController = {
    parent = 'SFXSource',
    trace ='bool',
  },

  SFXState ={
    parent = 'SimDataBlock',
    includedStates ='SFXState',
    excludedStates ='SFXState',

  },
  SFXProfile ={
    parent = 'SFXTrack',
    filename = 'string', --stringFilename
    preload = 'bool',
  },
  SFXPlayList ={
    parent = 'SFXTrack',
    random = 'string', --ERandomMode
    loopMode = 'string', --ELoopMode
    numSlotsToPlay ='int',
    track ='SFXTrack',
    replay = 'string', --EReplayMode
    transitionIn = 'string',-- ETransitionMode
    delayTimeIn ='float',
    delayTimeOut ='float',
    delayTimeOutVariance ='Point2F',
    fadeTimeIn ='float',
    fadeTimeInVariance ='Point2F',
    fadeTimeOut ='float',
    fadeTimeOutVariance = 'Point2F',
    referenceDistance ='float',
    referenceDistanceVariance ='Point2F',
    maxDistance = 'float',
    maxDistanceVariance ='Point2F',
    volumeScale ='float',
    volumeScaleVariance ='Point2F',
    pitchScale = 'float',
    pitchScaleVariance ='Point2F',
    repeatCount ='float',
    state = 'SFXState',
    stateMode = 'string', --EStateMode
  },
  SFXParameter ={
    parent = 'SimObject',
    value = 'float',
    range ='Point2F',
    channel ='string', --SFXChannel

  },
  SFXAmbience = {
    parent = 'SimDataBlock',
    environment = 'SFXEnvironment',
    soundTrack = 'SFXTrack',
    rolloffFactor ='float',
    dopplerFactor = 'float',
    states = 'SFXState',
    defaultValue ='float',
    description ='string',
  },
  SFXSource = {
    parent = 'SimGroup',
    description ='SFXDescription', --TypeSFXDescriptionName
    statusCallback = 'string',
  },
  SFXDescription = {
    parent = 'SimDataBlock',
    sourceGroup = 'SFXSource', --TypeSFXSourceName
    volume = 'float',
    pitch = 'float',
    isLooping = 'bool',
    priority = 'float',
    useHardware = 'bool',
    parameters = 'string', --TypeSFXParameterName
    fadeInTime = 'float',
    fadeOutTime = 'float',
    fadeInEase = 'EaseF',
    fadeOutEase = 'EaseF',
    fadeLoops = 'bool',
    is3D = 'bool',
    referenceDistance = 'float',
    maxDistance = 'float',
    scatterDistance = 'Point3F',
    coneInsideAngle = 'int',
    coneOutsideAngle = 'int',
    coneOutsideVolume = 'float',
    rolloffFactor = 'float',
    isStreaming = 'bool',
    streamPacketSize = 'int',
    streamReadAhead = 'int',
    useCustomReverb = 'bool',
    reverbDirect = 'int',
    reverbDirectHF = 'int',
    reverbRoom = 'int',
    reverbRoomHF = 'int',
    reverbObstruction = 'int',
    reverbObstructionLFRatio = 'float',
    reverbOcclusion ='int',
    reverbOcclusionLFRatio = 'float',
    reverbOcclusionRoomRatio ='float',
    reverbOcclusionDirectRatio = 'float',
    reverbExclusion ='int',
    reverbExclusionLFRatio = 'float',
    reverbOutsideVolumeHF ='int',
    reverbDopplerFactor ='float',
    reverbReverbRolloffFactor ='float',
    reverbRoomRolloffFactor ='float',
    reverbAirAbsorptionFactor = 'float',
    reverbFlags = 'int',



  },
  SFXTrack ={
    parent = 'SimDataBlock',
    description = 'SFXDescription', --SFXDescriptionName
    parameters = 'string', --TypeSFXParameterName
  },
  Explosion = {
    parent = 'GameBase',
  },
  ExplosionData = {
    parent = 'GameBaseData',
    explosionShape = 'string', --ShapFilename
    explosionScale = 'Point3F',
    playSpeed = 'float',
    soundProfile = 'SFXTrack',
    faceViewer = 'bool',
    particleEmitter = 'ParticleEmitterData',
    particleDensity = 'int',
    particleRadius = 'float',
    emitter = 'ParticleEmitterData',
    debris ='DebrisDataeb',
    debrisThetaMin ='float',
    debrisThetaMax ='float',
    debrisPhiMin = 'float',
    debrisPhiMax = 'float',
    debrisNum ='int',
    debrisNumVariance = 'int',
    debrisVelocity = 'float',
    debrisVelocityVariance = 'float',
    subExplosion = 'ExplosionData',
    delayMS = 'int',
    delayVariance = 'int',
    lifetimeMS = 'int',
    lifetimeVariance = 'int',
    offset = 'float',
    times = 'float',
    sizes = 'Point3F',
    shakeCamera = 'bool',
    camShakeFreq = 'Point3F',
    camShakeAmp = 'Point3F',
    camShakeDuration = 'float',
    camShakeRadius = 'float',
    camShakeFalloff = 'float',
    lightStartRadius = 'float',
    lightEndRadius = 'float',
    lightStartColor = 'ColorF',
    lightEndColor = 'ColorF',
    lightStartBrightness = 'float',
    lightEndBrightness = 'float',
    lightNormalOffset = 'float',
  },
  SpotLight ={
    parent = 'LightBase',
    range ='float',
    innerAngle='float',
    outerAngle='float',
  },
  StaticShapeData ={
    parent = 'ShapeBaseData',
    noIndividualDamage ='bool',
    dynamicType ='int',
  },
  ShapeBaseImageData ={
    parent = 'GameBaseData',
    emap = 'bool',
    ShapeFile = 'string',
    shapeFileFP ='string',
    imageAnimPrefix ='string',
    imageAnimPrefixFP ='string',
    animateAllShapes ='bool',
    animateOnServer ='bool',
    scriptAnimTransitionTime ='float',
    projectile ='ProjectileData',
    cloakable ='bool',
    mountPoint ='int',
    offset='MatrixF',
    rotation= 'MatrixF',
    eyeRotation ='MatrixF',
    eyeOffset ='MatrixF',
    useEyeNode ='bool',
    correctMuzzleVector ='bool',
    correctMuzzleVectorTP ='bool',
    mass ='float',
    usesEnergy ='bool',
    minEnergy='float',
    accuFire ='bool',
    lightType = 'string', --ShapeBaseImageData::LightType
    lightColor ='ColorF',
    lightDuration ='int',
    lightRadius='float',
    lightBrightness ='float',
    shakeCamera ='bool',
    camShakeFreq ='Point3F',
    camShakeAmp ='Point3F',
    casing = 'DebrisData',
    shellExitDir ='Point3F',
    shellExitVariance ='float',
    shellVelocity ='float',
    stateName='string',
    stateTransitionOnLoaded='string',
    stateTransitionOnNotLoaded='string',
    stateTransitionOnAmmo='string',
    stateTransitionOnNoAmmo='string',
    stateTransitionOnTarget='string',
    stateTransitionOnNoTarget='string',
    stateTransitionOnWet='string',
    stateTransitionOnNotWet='string',
    stateTransitionOnMotion='string',
    stateTransitionOnNoMotion='string',
    stateTransitionOnTriggerUp='string',
    stateTransitionOnTriggerDown='string',
    stateTransitionOnAltTriggerUp='string',
    stateTransitionOnAltTriggerDown='string',
    stateTransitionOnTimeout='string',
    stateTransitionGeneric0In='string',
    stateTransitionGeneric0Out='string',
    stateTransitionGeneric1In='string',
    stateTransitionGeneric1Out='string',
    stateTransitionGeneric2In='string',
    stateTransitionGeneric2Out='string',
    stateTransitionGeneric3In='string',
    stateTransitionGeneric3Out='string',
    stateTimeoutValue = 'float',
    stateWaitForTimeout ='bool',
    stateFire ='bool',
    stateAlternateFire ='bool',
    stateReload ='bool',
    stateEjectShell ='bool',
    stateEnergyDrain ='float',
    stateAllowImageChange ='bool',
    stateDirection ='bool',
    stateLoadedFlag = 'string', --ShapeBaseImageData::StateData::SpinState
    stateRecoil ='ShapeBaseImageData',
    stateSequence = 'string',
    stateSequenceRandomFlash ='bool',
    stateScaleAnimation='bool',
    stateScaleAnimationFP='bool',
    stateSequenceTransitionIn='bool',
    stateSequenceTransitionOut='bool',
    stateSequenceNeverTransition='bool',
    stateSequenceTransitionTime = 'float',
    stateShapeSequence ='string',
    stateScaleShapeSequence ='bool',
    stateSound ='SFXTrack',
    stateScript ='string',
    stateEmitter ='ParticleEmitterData',
    stateEmitterTime ='float',
    stateEmitterNode ='string',
    stateIgnoreLoadedForReady ='bool',
    computeCRC ='bool',
    maxConcurrentSounds ='int',
    useRemainderDT ='bool',
  },
  StaticShape ={
    parent = 'ShapeBase',
  },
  EventManager ={
    parent = 'SimObject',
    queue = 'string',
  },
  Settings ={
    parent='SimObject',
    file ='string',
  },
  MessageForwarder ={
    parent ='ScriptMsgListener',
    toQueue ='string',
  },
  UndoManager ={
    parent = 'SimObject',
    numLevels='int',
  },
  UndoAction ={
    parent = 'SimObject',
    actionName='string',
  },
  TSShapeConstructor ={
    parent = 'SimObject',
    baseShape ='string',
    upAxis ='string',
    unit ='float',
    lodType = 'string', -- ColladaUtils::ImportOptions::eLodType
    singleDetailSize ='int',
    matNamePrefix ='string',
    alwaysImport ='string',
    neverImport ='string',
    alwaysImportMesh ='string',
    neverImportMesh ='string',
    ignoreNodeScale ='bool',
    adjustCenter='bool',
    adjustFloor='bool',
    forceUpdateMaterials='bool',
    sequence ='string',
  },
  TerrainMaterial ={
    parent = 'SimObject',
    diffuseMap= 'string',
    diffuseSize ='float',
    normalMap ='string',
    detailMap ='string',
    detailSize ='float',
    detailStrength='float',
    detailDistance='float',
    useSideProjection ='bool',
    macroMap ='string',
    macroSize='float',
    macroStrength='float',
    macroDistance='float',
    parallaxScale='float',
  },
  TerrainBlock ={
    parent ='SceneObject',
    terrainFile ='string',
    castShadows ='bool',
    squareSize ='float',
    maxHeight ='float',
    baseTexSize ='int',
    lightMapSize ='int',
    screenError ='int',

  },
  TriggerData ={
    parent = 'GameBaseData',
    tickPeriodMS ='int',
    clientSide ='bool',
  },
  TSStatic ={
    parent = 'SceneObject',
    shapeName ='string',
    skin ='string',
    playAmbient ='bool',
    meshCulling ='bool',
    originSort ='bool',
    collisionType= 'string' ,--TSMeshType
    decalType= 'string' ,--TSMeshType
    allowPlayerStep= 'bool',
    prebuildCollisionData ='bool',
    renderNormals ='float',
    forceDetail ='int' ,
  },
  Trigger ={
    parent ='GameBase',
    polyhedron = 'string', --ConsoleType( floatList, TypeTriggerPolyhedron, Polyhedron )
    enterCommand = 'string',
    leaveCommand ='string',
    tickCommand ='string',
  },
  ShapeBaseData = {
    parent = 'GameBaseData',
    shadowEnable = 'bool',
    shadowSize = 'float',
    shadowMaxVisibleDistance = 'float',
    shadowProjectionDistance = 'float',
    shadowSphereAdjust= 'float',
    shapeFile = 'string', --ShapeFilename
    explosion = 'ExplosionData',
    underwaterExplosion ='ExplosionData',
    debris = 'DebrisData',
    renderWhenDestroyed = 'bool',
    debrisShapeName = 'string', --ShapeFilename
    mass = 'float',
    density = 'float',
    maxEnergy = 'float',
    maxDamage = 'float',
    disabledLevel ='float',
    destroyedLevel = 'float',
    repairRate = 'float',
    inheritEnergyFromMount = 'bool',
    isInvincible = 'bool',
    cameraCanBank ='bool',
    mountedImagesBank = 'bool',
    computeCRC = 'bool',
    cubeReflectorDesc = 'string',
  },
  BeamNGVehicleData = {
    parent = 'ShapeBaseData',
  },
  BeamNGWaypoint = {
    parent ='SceneObject',
    drawDebug = 'bool',
  },
  GuiTSCtrl = {
    parent = 'GuiContainer',
    cameraZRot ='float',
    forceFOV = 'float',
    reflectPriority = 'float',
    renderStyle = 'string', --RenderStyles
  },
  GizmoProfile = {
    parent ='SimObject',
    alignment ='string', --GizmoAlignment
    mode = 'string', --GizmoMode
    snapToGrid = 'bool',
    allowSnapRotations ='bool',
    rotationSnap ='float',
    allowSnapScale ='bool',
    scaleSnap ='float',
    renderWhenUsed = 'bool',
    renderInfoText = 'bool',
    renderPlane = 'bool',
    renderPlaneHashes = 'bool',
    renderSolid = 'bool',
    renderMoveGrid = 'bool',
    gridColor ='ColorI',
    planeDim ='float',
    gridSize ='Point3F',
    screenLength = 'int',
    rotateScalar ='float',
    scaleScalar ='float',
    flags = 'int',
  },
  BasicClouds ={
    parent = 'SceneObject',
    layerEnabled ='bool',
    texture = 'string', --ImageFilename
    texScale = 'float',
    texDirection = 'Point2F',
    texSpeed = 'float',
    texOffset = 'Point2F',
    height ='float',
  },
  DecalData = {
    parent = 'SimDataBlock',
    size ='float',
    material =' string', --TypeMaterialName
    fadeStartPixelSize ='float',
    fadeEndPixelSize = 'float',
    renderPriority = 'string',  --S8
    clippingAngle = 'float',
    frame ='int',
    randomize ='bool',
    textureCoordCount ='int',
    texRows ='int',
    texCols ='int',
    textureCoords ='RectF',
  },
  DecalRoad ={
    parent = 'SceneObject',
    drivability ='float',
    material = 'string', --MaterialName
    textureLength ='float',
    breakAngle ='float',
    renderPriority ='int',
    zBias ='float',
    decalBias ='float',
    distanceFade = 'Point2F',
    startEndFade ='Point2F',
    node ='string',
  },
  MeshRoad = {
    parent = 'SceneObject',
    topMaterial = 'string', --MatrialName
    bottomMaterial = 'string', --MatrialName
    sideMaterial = 'string', --MatrialName
    textureLength ='float',
    breakAngle ='float',
    widthSubdivisions ='int',
    Node ='string',
  },
  WaterObject = {
    parent = 'SceneObject',
    density ='float',
    viscosity ='float',
    liquidType ='string',
    baseColor ='ColorI',
    fresnelBias ='float',
    fresnelPower ='float',
    specularPower ='float',
    specularColor ='ColorF',
    emissive ='bool',
    waveDir = 'Point2F',
    waveSpeed ='float',
    waveMagnitude ='float',
    overallWaveMagnitude ='float',
    rippleTex ='string', --ImageFilename
    rippleDir ='Point2F',
    rippleSpeed ='float',
    rippleTexScale ='Point2F',
    rippleMagnitude ='float',
    overallRippleMagnitude ='float',
    foamTex = 'string', --ImageFilename
    foamDir ='Point2F',
    foamSpeed='float',
    foamTexScale = 'Point2F',
    foamOpacity = 'float',
    overallFoamOpacity = 'float',
    foamMaxDepth = 'float',
    foamAmbientLerp = 'float',
    foamRippleInfluence ='float',
    cubemap = 'string', --CubemapName
    fullReflect ='bool',
    reflectivity = 'float',
    reflectPriority='float',
    reflectMaxRateMs ='int',
    reflectDetailAdjust ='float',
    reflectNormalUp ='bool',
    useOcclusionQuery ='bool',
    reflectTexSize ='int',
    waterFogDensity ='float',
    waterFogDensityOffset= 'float',
    wetDepth = 'float',
    wetDarkening = 'float',
    depthGradientTex = 'string', --ImageFilename
    depthGradientMax ='float',
    distortStartDist = 'float',
    distortEndDist ='float',
    distortFullDepth ='float',
    clarity ='float',
    soundAmbience ='SFXAmbience' --SFXAmbienceName

  },
  River = {
    parent = 'WaterObject',
    SegmentLength = 'float',
    SubdivideLength = 'float',
    FlowMagnitude ='float',
    LowLODDistance = 'float',
    Node ='string',
  },
  CloudLayer = {
    parent = 'SceneObject',
    texture ='string', --ImageFilename
    texScale= 'float',
    texDirection = 'float',
    baseColor ='ColorF',
    exposure = 'float',
    coverage = 'float',
    windSpeed= 'float',
    height ='float',
  },
  CubemapData = {
    parent = 'SimObject',
    cubeFace ='string', --stringFilename
    dynamic = 'bool',
    dynamicSize = 'int',
    dynamicNearDist ='float',
    dynamicFarDist ='float',
    dynamicObjectTypeMask ='int',
  },
  GFXSamplerStateData= {
    parent = 'SimObject',
    textureColorOp = 'string', --GFXTextureOp
    colorArg1 = 'string', --GFXTextureArgument
    colorArg2 = 'string',--GFXTextureArgument
    colorArg3 = 'string',--GFXTextureArgument
    alphaOp = 'string', --GFXTextureOp
    alphaArg1 = 'string',--GFXTextureArgument
    alphaArg2 = 'string',--GFXTextureArgument
    alphaArg3 = 'string',--GFXTextureArgument
    addressModeU = 'string', --GFXTextureAddressMode
    addressModeV = 'string', --GFXTextureAddressMode
    addressModeW = 'string', --GFXTextureAddressMode
    magFilter = 'string', --GFXTextureFilterType
    minFilter = 'string', --GFXTextureFilterType
    mipFilter = 'string', --GFXTextureFilterType
    mipLODBias ='float',
    maxAnisotropy = 'int',
    textureTransform = 'string',--GFXTextureTransformFlags
    resultArg = 'string',--GFXTextureArgument
  },
  TheoraTextureObject = {
    parent ='SimObject',
    theoraFile = 'string' ,--StringFilename
    texTargetName ='string',
    sfxDescription = 'SFXDescription',
    loop = 'bool',
  },
  ShaderData = {
    parent = 'SimObject',
    DXVertexShaderFile ='string', --StringFilename
    DXPixelShaderFile ='string', --StringFilename
    OGLVertexShaderFile ='string', --StringFilename
    OGLPixelShaderFile ='string', --StringFilename
    useDevicePixVersion ='bool',
    pixVersion = 'float',
    defines ='string',

  },
  PopupMenu ={
    parent = 'SimObject',
    isPopup ='bool',
    barTitle ='string',
  },
  OpenFileDialog = {
    parent = 'FileDialog',
    MustExist ='bool',
    MultipleFiles ='bool',
  },
  SaveFileDialog = {
    parent = 'FileDialog',
    OverwritePrompt ='bool',
  },
  OpenFolderDialog ={
    parent = 'OpenFileDialog',
    fileMustExist ='string',
  },
  FileDialog ={
    parent = 'SimObject',
    defaultPath ='string',
    defaultFile ='string',
    fileName ='string',
    filters = 'string',
    title ='string',
    changePath ='bool',
  },
  Marker ={
    seqNum = 'int',
    Type = 'string', --KnotType
    msToNext ='int',
    smoothingType ='string', --smoothingType
  },

  Path = {
    parent = 'SimGroup',
    isLooping = 'bool',
  },
  RenderPassManager ={

  },
  RenderTerrainMgr ={
    parent = 'RenderBinManager',

  },
  RenderTexTargetBinManager = {
    parent = 'RenderBinManager',
  },
  RenderOcclusionMgr = {
    parent = 'RenderBinManager',
  },
  RenderObjectMgr = {
    parent = 'RenderBinManager',
  },
  RenderPassStateToken = {
    parent = 'SimObject',
    enabled ='bool',
  },
  RenderImposterMgr = {
    parent = 'RenderBinManager',
  },
   RenderPassStateBin = {
    parent = 'RenderBinManager',
    stateToken = 'RenderPassStateToken',
  },
  RenderFormatToken = {
    parent = 'RenderPassStateToken',
    format = 'string', --GFXFormat
    depthFormat = 'string', --GFXFormat
    copyEffect = 'PostEffect',
    resolveEffect = 'PostEffect',
    aaLevel ='int',

  },
  RenderBinManager = {
    parent = 'SimObject',
  },
  RenderMeshMgr = {
    parent = 'RenderBinManager',
    binType = 'string',
    renderOrder ='float',
    processAddOrder ='float',
  },
  ForcedMaterialMeshMgr ={
    parent = 'RenderMeshMgr',
    material ='Material',
  },
  PostEffect = {
    parent = 'SimGroup',
    shader ='string',
    stateBlock ='GFXStateBlockData',
    target = 'string',
    targetDepthStencil ='string',
    targetScale ='Point2F',
    targetSize ='Point2I',
    targetFormat = 'string', --GFXFormat
    targetClearColor ='ColorF',
    targetClear ='string', --PFXTargetClear
    targetViewport ='string', --PFXTargetViewport
    texture = 'string', --ImageFilename
    renderTime = 'string', --PFXRenderTime
    renderBin ='string',
    renderPriority ='float',
    allowReflectPass ='bool',
    isEnabled ='bool',
    onThisFrame ='bool',
    oneFrameOnly ='bool',
    v ='bool',
  },
  CustomMaterial = {
    parent = 'Material',
    version ='float',
    fallback ='Material',
    shader ='string',
    stateBlock ='GFXStateBlockData',
    target ='string',
    forwardLit = 'bool',
  },
  GFXStateBlockData = {
    parent = 'SimObject',
    blendDefined ='bool',
    blendEnable ='bool',
    blendSrc ='string', --GFXBlend
    separateAlphaBlendDest ='string', --GFXBlend
    separateAlphaBlendOp ='string', --GFXBlendOp
    alphaDefined ='bool',
    alphaTestEnable ='bool',
    alphaTestFunc ='string', --GFXCmpFunc
    alphaTestRef ='int',
    colorWriteDefined = 'bool',
    colorWriteRed ='bool',
    colorWriteBlue ='bool',
    colorWriteGreen ='bool',
    colorWriteAlpha ='bool',
    cullDefined = 'bool',
    cullMode = 'string',--GFXCullMode
    zDefined ='bool',
    zEnable ='bool',
    zWriteEnable ='bool',
    zFunc = 'string', --GFXCmpFunc
    zBias ='float',
    zSlopeBias ='float',
    stencilDefined ='bool',
    stencilEnable ='bool',
    stencilFailOp = 'string', --GFXStencilO
    stencilZFailOp = 'string', --GFXStencilO
    stencilPassOp = 'string', --GFXStencilO
    stencilFunc = 'string', --GFXCmpFunc
    stencilRef ='int',
    stencilMask ='int',
    stencilWriteMask ='int',
    stencilWriteMask ='bool',
    vertexColorEnable ='bool',
    samplersDefined ='bool',
    samplerStates = 'GFXSamplerStateData',
    textureFactor ='ColorI',
  },
  GuiShapeNameHud ={
    parent = '',
    fillColor ='ColorF',
    frameColor = 'ColorF',
    textColor = 'ColorF',
    labelFillColor ='ColorF',
    labelFrameColor ='ColorF',
    showFill ='bool',
    showFrame ='bool',
    showLabelFill ='bool',
    showLabelFrame ='bool',
    labelPadding = 'Point2I',
    verticalOffset ='float',
    distanceFade ='float',
  },
  GuiClockHud = {
    parent = 'GuiControl',
    showFill ='bool',
    showFrame ='bool',
    fillColor ='ColorF',
    frameColor = 'ColorF',
    textColor ='ColorF',
  },
  GuiHealthTextHud = {
    parent = 'GuiControl',
    fillColor ='ColorF',
    frameColor ='ColorF',
    textColor = 'ColorF',
    warningColor ='ColorF',
    showFill ='bool',
    showFrame = 'bool',
    showTrueValue ='bool',
    showEnergy ='bool',
    warnThreshold ='float',
    pulseThreshold ='float',
    pulseRate ='int',
  },
  GuiHealthBarHud = {
    parent = 'GuiControl',
    fillColor = 'ColorF',
    frameColor = 'ColorF',
    damageFillColor = 'ColorF',
    pulseRate = 'int',
    pulseThreshold ='float',
    showFill ='bool',
    showFrame = ' bool',
    displayEnergy ='bool',
  },
  GuiCrossHairHud ={
    parent = 'GuiBitmapCtrl',
    damageFillColor = 'ColorF',
    damageFrameColor = 'ColorF',
    damageRect = 'Point2I',
    damageOffset = 'Point2I',
  },
  EditTSCtrl ={
    parent = 'GuiTSCtrl',
    gridSize ='float',
    gridColor ='ColorI',
    gridOriginColor= 'ColorI',
    gridMinorTickColor ='ColorI',
    renderOrthoGrid ='bool',
    renderOrthoGridPixelBias ='float',
    renderMissionArea ='bool',
    missionAreaFillColor ='ColorI',
    missionAreaFrameColor ='ColorI',
    missionAreaHeightAdjust ='float',
    allowBorderMove ='bool',
    borderMovePixelSize ='int',
    borderMoveSpeed ='float',
    consoleFrameColor = 'ColorI',
    consoleFillColor ='ColorI',
    consoleSphereLevel = 'int',
    consoleCircleSegments ='int',
    consoleLineWidth ='int',
    gizmoProfile = 'GizmoProfile',
  },
  GuiMeshRoadEditorCtrl= {
    parent ='EditTSCtrl',
    DefaultWidth ='float',
    DefaultDepth ='float',
    DefaultNormal ='Point3F',
    HoverSplineColor = 'ColorI',
    SelectedSplineColor ='ColorI',
    HoverNodeColor ='ColorI',
    isDirty ='bool',
    topMaterialName ='string',
    bottomMaterialName ='string',
    sideMaterialName ='string',
  },
  GuiRoadEditorCtrl = {
    parent ='EditTSCtrl',
    DefaultWidth ='float',
    HoverSplineColor = 'ColorI',
    SelectedSplineColor ='ColorI',
    HoverNodeColor ='ColorI',
    isDirty ='bool',
    materialName ='string',
    templateRoad = 'DecalRoad',

  },
  GuiRiverEditorCtrl = {
    parent = 'EditTSCtrl',
    DefaultWidth ='float',
    DefaultDepth = 'float',
    DefaultNormal ='Point3F',
    HoverSplineColor ='ColorI',
    SelectedSplineColor ='ColorI',
    HoverNodeColor ='ColorI',
    isDirty = 'bool',
  },
  GuiControl ={
    parent = 'SimGroup',
    position = 'Point2I',
    extent = 'Point2I',
    minExtent = 'Point2I',
    horizSizing = 'string', --horizSizingOptions
    vertSizing = 'string', --vertSizingOptions
    profile = 'GuiControlProfile',
    visible = 'bool',
    active ='bool',
    variable = 'string',
    command ='string',
    altCommand = 'string',
    mouseEnterCommand ='string',
    mouseLeaveCommand ='string',
    accelerator = 'string',
    tooltipProfile ='GuiControlProfile',
    tooltip = 'string',
    hovertime = 'int',
    isContainer = 'bool',
    langTableMod ='string',

   },
  GuiGraphCtrl = {
    parent = 'GuiControl',
    centerY = 'float',
    plotColor = 'ColorF',
    plotType ='GuiGraphType',
    plotVariable = 'string',
    plotInterval = 'int',

  },
  GuiBeamNGDebugGraphDisplay = {
    parent = 'GuiGraphCtrl',
  },
  GuiContainer = {
    parent = 'GuiControl',
    docking = 'string', --< Docking::DockingType >
    margin= 'RectSpacingI',
    padding ='RectSpacingI',
    anchorTop ='bool',
    anchorBottom ='bool',
    anchorLeft ='bool',
    anchorRight ='bool',
  },
  CefGui = {
    parent = 'GuiContainer',
    startURL = 'string',
    debugEnabled = 'bool',
  },
  SimComponent = {
    parent = 'NetObject',
    Template ='bool',
  },
  ArrayObject = {
    parent = 'SimObject',
    caseSensitive ='bool',
    key ='string',
  },
  ConsoleLogger = {
    parent = 'SimObject',
  },
  SimGroup = {
    parent = 'SimSet',
    canSave = 'bool',
    canSaveDynamicFields = 'bool',
    enabled = 'bool',
  },
  SimXMLDocument = {
    parent = 'SimObject',
  },
  Material = {
    mapTo = 'string',
    diffuseColor = 'ColorF',
    instanceDiffuse = 'bool',
    diffuseMap = 'imagefilename',
    colorMap = 'imagefilename',
    overlayMap = 'imagefilename',
    opacityMap = 'imagefilename',
    colorPaletteMap = 'imagefilename',
    lightMap = 'imagefilename',
    toneMap = 'imagefilename',
    detailMap = 'imagefilename',
    detailScale = 'Point2F',
    normalMap = 'imagefilename',
    detailNormalMap = 'imagefilename',
    detailNormalMapStrength = 'float',
    specular = 'colorf',
    specularPower = 'float',
    pixelSpecular = 'bool',
    specularMap = 'imagefilename',
    parallaxScale = 'float',
    useAnisotropic = 'bool',
    envMap = 'imagefilename',
    reflectivityMap = 'imagefilename',
    vertLit = 'bool',
    vertColor = 'bool',
    minnaertConstant = 'float',
    subSurface = 'bool',
    subSurfaceColor = 'ColorF',
    subSurfaceRolloff = 'float',
    glow = 'bool',
    emissive = 'bool',
    doubleSided = 'bool',
    animFlags = 'hexnumber',
    scrollDir = 'Point2F',
    scrollSpeed = 'float',
    rotSpeed = 'float',
    rotPivotOffset = 'Point2F',
    waveType = 'string',
    waveFreq = 'float',
    waveAmp = 'float',
    sequenceFramePerSec = 'float',
    sequenceSegmentSize = 'float',
    cellIndex = 'Point2I',
    cellLayout = 'Point2I',
    cellSize = 'int',
    bumpAtlas = 'bool',

    baseTex = 'string', -- ImageFilename
    detailTex = 'string', -- ImageFilename
    overlayTex = 'string', -- ImageFilename
    bumpTex = 'string', -- ImageFilename
    envTex = 'string', -- ImageFilename
    colorMultiply = 'ColorF',

    castShadows = 'bool',
    planarReflection = 'bool',
    translucent = 'bool',
    translucentBlendOp = 'string',
    translucentZWrite = 'bool',
    alphaTest = 'bool',
    alphaRef = 'int',
    cubemap = 'CubemapData',
    dynamicCubemap = 'bool',
    groundType = 'string',
    groundDepth = 'float',

    materialTag0 = 'string',
    materialTag1 = 'string',
    materialTag2 = 'string',
  },
}
local datatype_verifiers = {
    int = function(s) return isint(s) end,
    float = function(s) return tonumber(s) ~= nil end,
    bool = function(s) s = tostring(s) ; return s == '1' or s == '0' or s == 'true' or s == 'false' end,
    colorf = function(s)
      local c = split(s, ' ')
      if #c ~= 4
        or tonumber(c[1]) == nil
        or tonumber(c[2]) == nil
        or tonumber(c[3]) == nil
        or tonumber(c[4]) == nil
      then return false end
      return true end,
    string = function(s) return true end,
    imagefilename = function(s) return true end,
    Point2F = function(s) return true end,
    CubemapData = function(s) return true end,
    hexnumber = function(s) return true end, -- animFlags[2] = '0x00000005";
}


local function test()
  print('>>###################################################################')
  local dir = 'levels/'

  local ctx = {}

  local files = FS:findFilesByRootPattern(dir, '*', -1, false, false)
  for _,file in pairs(files) do

    ctx.lastFile = file
    ctx.lastBytes = nil

    if not path.is_file(file) then logMessage(ctx, 'E', 'Not a file or unable to open') end
    local filesize = getFileSize(file)
    if filesize == 0 then logMessage(ctx, 'E', 'File empty') end

    if string.match(file, '[^a-zA-Z0-9-_/%.]') then logMessage(ctx, 'E', 'File name contains invalid characters') end

    local dir, filename, ext = path.split(file)
    ext = ext:lower()
    if ext == '' then logMessage(ctx, 'E', 'No extension') end
    if ext == 'cs' or ext == 'mis' or ext == 'prefab' or ext == 'gui' then

      local content = readFile(file)
      if content then

        local function checkProperty(className, o)
          local propName = o[1]
          local propIndex = nil
          local propVal = nil
          if type(o[2]) == 'table' and o[2].id == 'propertyIndex' then
            propIndex = o[2][1]
            propVal = o[3]
          else
            propVal = o[2]
          end
          ctx.lastBytes = o.pos
          --logMessage(ctx, 'D', '> ' .. tostring(className) .. ' > ' .. tostring(propName) .. ' > ' .. tostring(propVal))

          if valid_class_properties[className][propName] then
            local type = valid_class_properties[className][propName]
            if datatype_verifiers[type] then
              local res = datatype_verifiers[type](propVal)
              if not res then
                logMessage(ctx, 'E', 'Data incorrect: ' .. tostring(propName) .. ' > ' .. tostring(propVal) .. ' [' .. type .. '] = ' .. tostring(res))
              end
            else
              logMessage(ctx, 'E', 'Data verifier missing for type: ' .. tostring(type))
            end
          else
            logMessage(ctx, 'E', 'Unknown property for class: ' .. tostring(className) .. ' > ' .. tostring(propName))
          end
        end

        local function checkObject(o)
          if not o then return end
          ctx.lastBytes = o.pos
          if o.id == 'tsfile' then
            for i = 1, #o do
              checkObject(o[i])
            end
          elseif o.id == 'functionRecursion' or o.id == 'fct' then
            -- nothing, ignore functions
          elseif o.id == 'object' then
            local constructor = o[1]
            local className = o[2]

            if valid_class_properties[className] then
              local objectName = nil
              local parentObject = nil
              for i = 3, #o do
                if o[i].id == 'objectName' then objectName = o[i][1]
                elseif o[i].id == 'parentObject' then parentObject = o[i][1]
                elseif o[i].id == 'property' then checkProperty(className, o[i])
                elseif o[i].id == 'object' then checkObject(o[i])
                else
                  print("unknown stuff:" .. dumps(o[i]))
                end
              end
            else
              logMessage(ctx, 'E', 'unknown class: ' .. tostring(className))
            end
          else
            print("unknown stuff:" .. dumps(o))
          end
        end

        local ok, ast = require('utils/torqueScriptParser').parse(content)
        --dump(ast)
        if not ok then
          ctx.lastBytes = nil
          logMessage(ctx, 'E', file, 'Parsing error in file: ' .. tostring(ast))
        end
        checkObject(ast)
        --dump(ast)

      else
        logMessage(ctx, 'E', file, 'Unable to read file')
      end
--]==]
    end

  end


  dump(ctx)
  print('<<###################################################################')

end

test()

M.test = test

return M
