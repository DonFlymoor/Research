
// Always declare audio Descriptions (the type of sound) before Profiles (the
// sound itself) when creating new ones.

// ----------------------------------------------------------------------------
// Now for the profiles - these are the usable sounds
// ----------------------------------------------------------------------------

datablock SFXProfile(MenuSound)
{
    filename = "art/sound/environment/amb";
    description = AudioLoop2D;
};


datablock SFXProfile(WindySound)
{
    filename = "art/sound/environment/open_bridge_wind_c.ogg";
    description = AudioLoop2D;
};



singleton SFXProfile(EngineTestSound)
{
    fileName = "vehicles/common/sounds/V8_default.ogg";
    description = "AudioDefaultLoop3D";
};


singleton SFXProfile(CrashTestSound)
{
    fileName = "art/sound/crash.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound1)
{
    fileName = "art/sound/glass_shatter_01.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound2)
{
    fileName = "art/sound/glass_shatter_02.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound3)
{
    fileName = "art/sound/glass_shatter_03.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound4)
{
    fileName = "art/sound/glass_shatter_04.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound5)
{
    fileName = "art/sound/glass_shatter_05.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound6)
{
    fileName = "art/sound/glass_shatter_06.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound7)
{
    fileName = "art/sound/glass_shatter_07.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound8)
{
    fileName = "art/sound/glass_shatter_08.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound9)
{
    fileName = "art/sound/glass_shatter_09.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(GlassBreakSound10)
{
    fileName = "art/sound/glass_shatter_10.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(TireBurstSound)
{
    fileName = "art/sound/tire_burst.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(FireBallSound)
{
    fileName = "art/sound/fireball.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(FireLoopSound1)
{
    fileName = "art/sound/fireloop1.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(FireLoopSound2)
{
    fileName = "art/sound/fireloop2.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(BumpStopSound)
{
    fileName = "art/sound/bumpstop.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(ShiftTestSound)
{
    fileName = "art/sound/shift.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(TurboBovSound)
{
    fileName = "vehicles/common/sounds/turbo_bov.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(Knock)
{
    fileName = "art/sound/knock.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(PianoSmash1)
{
    fileName = "art/sound/piano_smash_01.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(PianoSmash2)
{
    fileName = "art/sound/piano_smash_02.ogg";
    description = "AudioDefault3D";
};

singleton SFXProfile(PianoSmash3)
{
    fileName = "art/sound/piano_smash_03.ogg";
    description = "AudioDefault3D";
};
singleton SFXProfile(PianoSmash4)
{
    fileName = "art/sound/piano_smash_04.ogg";
    description = "AudioDefault3D";
};

datablock SFXProfile("event:UI_Checkpoint")
{
    fileName = "event:>UI>Checkpoint";
    preload = false;
};

datablock SFXProfile("event:UI_Countdown1")
{
    fileName = "event:>UI>Countdown 1";
    preload = false;
};

datablock SFXProfile("event:UI_Countdown2")
{
    fileName = "event:>UI>Countdown 2";
    preload = false;
};

datablock SFXProfile("event:UI_Countdown3")
{
    fileName = "event:>UI>Countdown 3";
    preload = false;
};

datablock SFXProfile("event:UI_CountdownGo")
{
    fileName = "event:>UI>Countdown Go";
    preload = false;
};
