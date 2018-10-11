
datablock DecalData(tireTrackDecal)
{
    Material = "tireTrack";
    textureCoordCount = "0";
    size = "0.4";
    lifeSpan = "1800000";
    fadeTime = "1800000";
    fadeStartPixelSize = "5";
    fadeEndPixelSize = "8";
};

singleton SFXProfile(amb_windtrees_01 : EngineTestSound)
{
    filename = "art/sound/environment/amb_windtrees_01.ogg";
};

singleton SFXProfile(amb_birds_01 : amb_windtrees_01)
{
    filename = "art/sound/environment/amb_birds_01.ogg";
};

singleton SFXProfile(music_menu : MenuSound)
{
    filename = "art/sound/music/dicta.ogg";
    preload = true;
};

singleton SFXProfile(amb_rain_medium : amb_windtrees_01)
{
    filename = "art/sound/environment/amb_rain_medium.ogg";
    description = "AudioLoop2D"; //-> is this supposed to be the field "soundProfile"??
};

singleton SFXProfile(amb_beach_close_01 : amb_windtrees_01)
{
    filename = "art/sound/environment/amb_beach_close_01.ogg";
};
singleton SFXProfile(amb_beach_close_02 : amb_beach_close_01)
{
    filename = "art/sound/environment/amb_beach_close_02.ogg";
};

singleton SFXProfile(amb_river_crossing_01 : amb_beach_close_01)
{
    filename = "art/sound/environment/amb_river_crossing_01.ogg";
};


datablock PrecipitationData(Snow_menu)
{
    dropTexture = "art/shapes/particles/Particle_snow.dds";
};

datablock PrecipitationData(rain_medium)
{
    dropTexture = "art/shapes/particles/Particle_rain.dds";
    splashTexture = "art/shapes/particles/Particle_rain_splash.dds";
    dropsPerSide = "1";
    splashesPerSide = "2";
};

datablock LightFlareData(BNG_SunFlare_1 : LightFlareExample2)
{
    flareTexture = "art/special/BNG_lensFlareSheet0.png";
    elementTint[1] = "0.945098 0.92549 0.894118 1";
    elementUseLightColor[1] = "0";
    elementRect[8] = "1024 0 128 128";
    elementRect[9] = "1024 0 128 128";
    elementRect[10] = "1024 0 128 128";
    elementDist[8] = "5";
    elementDist[9] = "13";
    elementDist[10] = "-10";
    elementScale[1] = "1";
    elementScale[8] = "0.8";
    elementScale[9] = "3.5";
    elementScale[10] = "0.5";
    elementTint[8] = "1 1 1 1";
    elementTint[9] = "1 1 1 1";
    elementTint[10] = "0.694118 0.694118 0.694118 1";
    elementRotate[8] = "1";
    elementRotate[9] = "1";
    elementRect[11] = "1024 0 128 128";
    elementDist[11] = "-2.5";
    elementScale[11] = "0.3";
    elementTint[11] = "0.694118 0.694118 0.694118 1";
    elementRotate[11] = "1";
    overallScale = "1";
};


datablock ParticleData(lightTestParticle : DefaultParticle)
{
    sizes[0] = "0.997986";
    sizes[1] = "0.997986";
    sizes[2] = "0.997986";
    sizes[3] = "0.997986";
    times[1] = "0.329412";
    times[2] = "0.658824";
    lifetimeMS = "6751";
    lifetimeVarianceMS = "3563";
    colors[0] = "0.996078 0.992157 0.992157 1";
    colors[1] = "0.996078 0.996078 0.992157 0.637795";
    colors[2] = "0.996078 0.992157 0.992157 0.330709";
};

datablock ParticleEmitterData(lightTest1 : DefaultEmitter)
{
    particles = "lightTestParticle";
    ejectionPeriodMS = "20";
    ejectionVelocity = "2";
    velocityVariance = "1";
};

datablock ParticleEmitterNodeData(lightExampleEmitterNodeData1)
{
};

datablock PrecipitationData(rain_drop : rain_medium)
{
    dropTexture = "art/shapes/particles/Particle_rain_drop.dds";
};

datablock LightFlareData(BNG_Sunflare_2 : BNG_SunFlare_1)
{
    flareTexture = "art/special/BNG_lensFlare_1.png";
    elementRect[0] = "0 0 512 512";
    elementScale[0] = "1";
};

datablock ParticleData(targetParticle : DefaultParticle)
{
    sizes[0] = "1";
    sizes[1] = "3";
    sizes[2] = "6";
    sizes[3] = "20";
    times[1] = "0.329412";
    times[2] = "0.894118";
    lifetimeMS = "6751";
    lifetimeVarianceMS = "5437";
    colors[0] = "1 0 0.0314961 1";
    colors[1] = "0 1 0.0787402 0.984252";
    colors[2] = "1 0 0.0314961 1";
   colors[3] = "0.992126 0 0.0314961 0.00787402";
   constantAcceleration = "3.333";
};

datablock ParticleEmitterData(targetEmitter : DefaultEmitter)
{
    particles = "targetParticle";
    ejectionPeriodMS = "10";
    ejectionVelocity = "2";
    velocityVariance = "1";
   ejectionOffset = "0";
   thetaMax = "63.75";
   blendStyle = "NORMAL";
};


singleton SFXAmbience(QP07_773_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0773";
   VizColor = "0.894118 0 1 0.176471";
};

singleton SFXAmbience(Level_Tunnel_Closed)
{
   soundTrack = "snapshot:>Level Tunnel Closed";
};

singleton SFXAmbience(QP07_776_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0776";
   VizColor = "0.0352941 0 1 0.176471";
};


singleton SFXAmbience(QP07_778_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0778";
   VizColor = "1 0.172549 0 0.176471";
};

singleton SFXAmbience(QP07_790_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0790";
   VizColor = "1 0 0.870588 0.176471";
};

singleton SFXAmbience(QP07_767_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0767";
   VizColor = "0.129412 1 0 0.176471";
};

singleton SFXAmbience(QP07_767_LPF_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0767 LPF 01";
   VizColor = "0 1 0.733333 0.176471";
};

singleton SFXAmbience(Felix_294_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>Felix 328294";
   VizColor = "1 0 0.478431 0.176471";
};

singleton SFXAmbience(Felix_297_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>Felix 328297";
   VizColor = "0.454902 0 1 0.176471";
};

singleton SFXAmbience(QP07_781_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0781";
};

singleton SFXAmbience(QP07_774_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0774";
   VizColor = "0.996078 0.913726 0.00392157 0.176471";
};

singleton SFXAmbience(QP07_775_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0775";
   VizColor = "0 0.639216 1 0.43";
};

singleton SFXAmbience(QP07_777_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0777";
   VizColor = "0.207843 0.501961 0.34902 0.314";
};

singleton SFXAmbience(QP07_780_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0780";
   VizColor = "0.847059 1 0 0.176471";
};

singleton SFXAmbience(QP07_785_JR)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>QP07 0785";
   VizColor = "0 0.823529 1 0.176471";
};


singleton SFXAmbience(QP01_045_EC)
{
   VizColor = "1 0 0.0352941 0.176471";
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP01 045";
};

singleton SFXAmbience(QP08_829_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 829";
   VizColor = "1 0 0.870588 0.306";
};

singleton SFXAmbience(QP08_840_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 840";
   VizColor = "0.662745 0 1 0.176471";
};

singleton SFXAmbience(QP01_051_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP01 051";
   VizColor = "1 0.384314 0 0.176471";
};

singleton SFXAmbience(QP08_848_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 848";
   VizColor = "0.0352941 0 1 0.176471";
};

singleton SFXAmbience(QP08_849_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 849";
   VizColor = "0 0.521569 1 0.176471";
};

singleton SFXAmbience(QP08_850_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 850";
   VizColor = "0 0.964706 1 0.176471";
};

singleton SFXAmbience(QP08_853_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 853";
   VizColor = "0 1 0.431373 0.082";
};

singleton SFXAmbience(QP08_856_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 856";
   VizColor = "0.313726 1 0 0.176471";
};

singleton SFXAmbience(QP08_959_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 959";
   VizColor = "1 0.988235 0 0.176471";
};

singleton SFXAmbience(QP08_940_EC)
{
   soundTrack = "event:>Ambient>Maps>East Coast>2D>QP08 940";
};



singleton SFXAmbience(QP01_046_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP01 046";
};

singleton SFXAmbience(QP01_047_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP01 047";
};

singleton SFXAmbience(Felix_024_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>Felix 208024";
   VizColor = "1 0 0.0352941 0.176471";
};

singleton SFXAmbience(QP06_660_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP06 660";
   VizColor = "1 0 0.803922 0.176471";
};

singleton SFXAmbience(QP08_843_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 843";
   VizColor = "0.639216 0 1 0.176471";
};

singleton SFXAmbience(QP08_844_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 844";
   VizColor = "0 0.0588235 1 0.176471";
};

singleton SFXAmbience(QP08_937_IS)
{
   VizColor = "0 0.756863 1 0.176471";
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 937";
};

singleton SFXAmbience(QP08_944_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 944";
   VizColor = "0 1 0.662745 0.176471";
};

singleton SFXAmbience(QP08_946_IS)
{
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 946";
   VizColor = "0.0588235 1 0 0.176471";
};

singleton SFXAmbience(QP08_952_IS)
{
   VizColor = "1 0.988235 0 0.176471";
   soundTrack = "event:>Ambient>Maps>Industrial Side>2D>QP08 952 Loop1";
};

singleton SFXAmbience(Level_Building_Open)
{
   soundTrack = "snapshot:>Level Building Open";
};

singleton SFXAmbience(QP01_045_HR)
{
   soundTrack = "event:>Ambient>Maps>Hirochi>2D>QP01 045";
   VizColor = "1 0.0588235 0 0.176471";
};

datablock SFXAmbience(QP08_850_HR)
{
   soundTrack = "event:>Ambient>Maps>Hirochi>2D>QP08 850";
   VizColor = "0 1 0.545098 0.176471";
};

singleton SFXAmbience(QP08_853_HR)
{
   soundTrack = "event:>Ambient>Maps>Hirochi>2D>QP08 853";
   VizColor = "0.803922 1 0 0.176471";
};

singleton SFXAmbience(QP08_991_SI)
{
   soundTrack = "event:>Ambient>Maps>Small Island>2D>QP08 991";
   VizColor = "1 0.0588235 0 0.176471";
};

singleton SFXAmbience(QP06_660_SI)
{
   soundTrack = "event:>Ambient>Maps>Small Island>2D>QP06 660";
   VizColor = "0.847059 1 0 0.176471";
};

singleton SFXAmbience(QP06_571_SI)
{
   soundTrack = "event:>Ambient>Maps>Small Island>2D>QP06 571";
   VizColor = "0 1 0.988235 0.176471";
};

singleton SFXAmbience(QP06_567_SI)
{
   VizColor = "1 0 0.639216 0.176471";
};

singleton SFXAmbience(QP06_660_PO)
{
   soundTrack = "event:>Ambient>Maps>Port>2D>QP06 660";
   VizColor = "0 1 0.662745 0.176471";
};

singleton SFXAmbience(QP08_829_ETK)
{
   soundTrack = "event:>Ambient>Maps>ETK Driving Center>2D>QP08 829";
   VizColor = "1 0 0.615686 0.176471";
};

singleton SFXAmbience(QP08_850_ETK)
{
   soundTrack = "event:>Ambient>Maps>ETK Driving Center>2D>QP08 850";
   VizColor = "0 0.0588235 1 0.176471";
};

singleton SFXAmbience(QP08_853_ETK)
{
   soundTrack = "event:>Ambient>Maps>ETK Driving Center>2D>QP08 853";
   VizColor = "0 1 0.803922 0.176471";
};

singleton SFXAmbience(QP08_856_ETK)
{
   soundTrack = "event:>Ambient>Maps>ETK Driving Center>2D>QP08 856";
   VizColor = "1 0.709804 0 0.176471";
};

singleton SFXAmbience(QP06_660_ETK)
{
   soundTrack = "event:>Ambient>Maps>ETK Driving Center>2D>QP06 660";
   VizColor = "1 0 0.0352941 0.176471";
};

singleton SFXAmbience(QP01_122_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP01 122";
   VizColor = "1 0 0.0352941006 0.176470995";
};

singleton SFXAmbience(QP01_129_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP01 129 Quiet";
   VizColor = "1 0 0.894118011 0.176470995";
};

singleton SFXAmbience(QP12_1431_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1431 Loop1";
   VizColor = "0.498039007 0 1 0.176470995";
};

singleton SFXAmbience(QP12_1432_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1432";
   VizColor = "0 0.0588234998 1 0.176470995";
};

singleton SFXAmbience(QP12_1433_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1433 Quiet";
   VizColor = "0 0.521569014 1 0.176470995";
};

singleton SFXAmbience(QP12_1435_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1435";
   VizColor = "0 0.941177011 1 0.176470995";
};

singleton SFXAmbience(QP12_1438_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1438";
   VizColor = "0 1 0.407842994 0.176470995";
};

singleton SFXAmbience(QP12_1439_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1439";
   VizColor = "0.615685999 1 0 0.176470995";
};

singleton SFXAmbience(QP12_1449_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP12 1449";
   VizColor = "1 0.686275005 0 0.176470995";
};

singleton SFXAmbience(QP01_129_Howls_UT)
{
   soundTrack = "event:>Ambient>Maps>Utah>2D>QP01 129 Howls";
};

singleton SFXAmbience(QP06_567_DA)
{
   soundTrack = "event:>Ambient>Maps>Derby Arena>2D>QP06 567";
   VizColor = "1 0 0.0352941006 0.176470995";
};

singleton SFXAmbience(QP06_571_DA)
{
   soundTrack = "event:>Ambient>Maps>Derby Arena>2D>QP06 571";
   VizColor = "0.172548994 0 1 0.176470995";
};

singleton SFXAmbience(QP06_660_DA)
{
   soundTrack = "event:>Ambient>Maps>Derby Arena>2D>QP06 660";
   VizColor = "0.407842994 1 0 0.176470995";
};

singleton SFXAmbience(QP08_850_CD)
{
   soundTrack = "event:>Ambient>Maps>Car Dealership>2D>QP08 850";
   VizColor = "1 0 0.0352941006 0.176470995";
};

singleton SFXAmbience(QP06_660_CD)
{
   soundTrack = "event:>Ambient>Maps>Car Dealership>2D>QP06 660";
   VizColor = "0.870588005 0 1 0.176470995";
};

singleton SFXAmbience(QP06_571_CD)
{
   soundTrack = "event:>Ambient>Maps>Car Dealership>2D>QP06 571";
   VizColor = "0 1 0.988234997 0.176470995";
};

singleton SFXAmbience(Freesound_210523_CD)
{
   soundTrack = "event:>Ambient>Maps>Car Dealership>2D>Freesound 210523";
   VizColor = "1 0.756862998 0 0.176470995";
};

singleton SFXAmbience(Room_Tone_17_CD)
{
   soundTrack = "event:>Ambient>Maps>Car Dealership>2D>17 Room Tone";
   VizColor = "1 0.0588234998 0 0.176470995";
};

singleton SFXAmbience(Level_Building_Closed)
{
   soundTrack = "snapshot:>Level Building Closed";
};


singleton SFXAmbience(SnapshotTrigger)
{
   soundTrack = "event:>Snapshot_Trigger";
};

singleton SFXAmbience(Level_Tunnel_Open_Dynamic)
{
   soundTrack = "snapshot:>Level Tunnel Open Dynamic 2D";
};

singleton SFXAmbience(Level_Tunnel_Closed_Dynamic)
{
   soundTrack = "snapshot:>Level Tunnel Closed Dynamic 2D";
};

singleton SFXAmbience(Level_Tunnel_Open)
{
   soundTrack = "snapshot:>Level Tunnel Open";
};

singleton SFXAmbience(Felix_024_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Felix 208024";
   VizColor = "0 0.709803998 1 0.176470995";
};

singleton SFXAmbience(Freesound_City_Freeway_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound City Freeway";
};

singleton SFXAmbience(Freesound_Heavy_Traffic_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound Heavy Traffic";
};

singleton SFXAmbience(Freesound_Chorus_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound Insect Chorus";
   VizColor = "0.823529005 0 1 0.176470995";
};

singleton SFXAmbience(Freesound_Insects_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound Insects";
   VizColor = "0 1 0.545098007 0.176470995";
};

singleton SFXAmbience(Freesound_Quiet_Street_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound Quiet Street";
};

singleton SFXAmbience(QP06_660_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP06 660";
   VizColor = "0.196078002 1 0 0.176470995";
};

singleton SFXAmbience(QP08_829_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 829";
};

singleton SFXAmbience(QP08_843_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 843";
   VizColor = "0.129411995 0 1 0.176470995";
};

singleton SFXAmbience(QP08_844_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 844";
};

singleton SFXAmbience(QP08_856_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 856";
};

singleton SFXAmbience(QP08_937_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 937";
};

singleton SFXAmbience(QP08_952_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>QP08 952";
};

singleton SFXAmbience(Freesound_T019_WC)
{
   soundTrack = "event:>Ambient>Maps>West Coast>2D>Freesound T019";
   VizColor = "1 0 0.0352941006 0.176470995";
};

singleton SFXAmbience(Felix_024_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>Felix 208024";
   VizColor = "1 0 0.0352941006 0.176470995";
};

singleton SFXAmbience(Freesound_575_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>Freesound 169575";
   VizColor = "0.733332992 0 1 0.176470995";
};

singleton SFXAmbience(Freesound_977_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>(Freesound 195977)";
   VizColor = "0 0.129411995 1 0.176470995";
};

singleton SFXAmbience(Freesound_Chorus_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>Freesound Insect Chorus";
   VizColor = "0 1 0.756862998 0.176470995";
};

singleton SFXAmbience(Freesound_Insects_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>Freesound Insects";
   VizColor = "0.384314001 1 0 0.176470995";
};

singleton SFXAmbience(Freesound_Cicadas_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>Freesound Summer Cicadas";
   VizColor = "1 0.870588005 0 0.176470995";
};

singleton SFXAmbience(QP06_660_IT)
{
   soundTrack = "event:>Ambient>Maps>Italy>2D>QP06 660";
   VizColor = "0.219607994 0 1 0.176470995";
};

singleton SFXAmbience(Reverb_IT_Open)
{
   soundTrack = "snapshot:>Reverb_IT_Open";
};

singleton SFXAmbience(Reverb_IT_Mountains)
{
   soundTrack = "snapshot:>Reverb_IT_Mountains";
};

singleton SFXAmbience(Reverb_WC_City)
{
   soundTrack = "snapshot:>Reverb_WC_City";
};

singleton SFXAmbience(Reverb_WC_Open)
{
   soundTrack = "snapshot:>Reverb_WC_Open";
};

singleton SFXAmbience(Reverb_PO)
{
   soundTrack = "snapshot:>Reverb_PO";
};

singleton SFXAmbience(Reverb_EC)
{
   soundTrack = "snapshot:>Reverb_EC";
};

singleton SFXAmbience(Reverb_UT)
{
   soundTrack = "snapshot:>Reverb_UT";
};

singleton SFXAmbience(Reverb_JR)
{
   soundTrack = "snapshot:>Reverb_JR";
};

singleton SFXAmbience(Reverb_IS)
{
   soundTrack = "snapshot:>Reberb_IS";
};

singleton SFXAmbience(Reverb_SI)
{
   soundTrack = "snapshot:>Reverb_SI";
};

singleton SFXAmbience(Reverb_ETK)
{
   soundTrack = "snapshot:>Reverb_ETK";
};

singleton SFXAmbience(Reverb_DA)
{
   soundTrack = "snapshot:>Reverb_DA";
};

singleton SFXAmbience(Reverb_CD_Showroom)
{
   soundTrack = "snapshot:>Reverb_CD_Showroom";
};

singleton SFXAmbience(Reverb_CL)
{
   soundTrack = "snapshot:>Reverb_CL";
};

singleton SFXAmbience(Level_Tunnel_Racetrack_Dynamic)
{
   soundTrack = "snapshot:>Level Racetrack Dynamic 2D";
};

singleton SFXAmbience(Level_Under_Bridge_B)
{
   soundTrack = "snapshot:>Level Bridge B";
};

singleton SFXAmbience(Level_Under_Bridge_A)
{
   soundTrack = "snapshot:>Level Bridge A";
};

singleton SFXAmbience(Level_Parking_House)
{
   soundTrack = "snapshot:>Level Parking Garage";
};

singleton SFXAmbience(Level_Under_Bridge)
{
   soundTrack = "snapshot:>Level Under Bridge";
};

singleton SFXAmbience(Reverb_GA)
{
   soundTrack = "snapshot:>Reverb_GA";
};

singleton SFXAmbience(Garage_Ambience)
{
   soundTrack = "event:>Ambient>Maps>Garage>Generic";
   VizColor = "0.0117646996 1 0 0.176470995";
};

singleton SFXAmbience(Water_QP04_374)
{
   soundTrack = "event:>Ambient>Maps>Jungle Rock>2D>Water QP04 374";
};

singleton SFXAmbience(Reverb_ATT_Mountains)
{
   soundTrack = "snapshot:>Reverb_ATT_Mountains";
   VizColor = "1 0 0.545098007 0.176470995";
};

singleton SFXAmbience(Reverb_ATT_Dam)
{
   soundTrack = "snapshot:>Reverb_ATT_Dam";
   VizColor = "0 1 0.894118011 0.176470995";
};

singleton SFXAmbience(Reverb_ATT_Forest)
{
   soundTrack = "snapshot:>Reverb_ATT_Forest";
   VizColor = "1 0.803921998 0 0.176470995";
};

singleton SFXAmbience(Wind_Mountains_ATT)
{
   soundTrack = "event:>Ambient>Maps>Automation Test Track>2D>Wind Generic Desert QP02 139";
   VizColor = "1 0.0588234998 0 0.176470995";
};

singleton SFXAmbience(Wind_Generic_ATT)
{
   soundTrack = "event:>Ambient>Maps>Automation Test Track>2D>Wind Generic Desert QP02 247";
   VizColor = "0.917647004 1 0 0.176470995";
};
