// use this on game startup, where the UI needs to load first
function createGameInitial(%level) {
    // wait for the UI to load
    schedule("1500", 0, LuaExecuteStringSync, "core_levels.startFreeroam('" @ %level @ "')");
}

