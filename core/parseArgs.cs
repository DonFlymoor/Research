
//-----------------------------------------------------------------------------
// Support functions used to manage the directory list

function pushFront(%list, %token, %delim)
{
    if (%list !$= "")
        return %token @ %delim @ %list;
    return %token;
}

function pushBack(%list, %token, %delim)
{
    if (%list !$= "")
        return %list @ %delim @ %token;
    return %token;
}

function popFront(%list, %delim)
{
    return nextToken(%list, unused, %delim);
}

//-----------------------------------------------------------------------------
// The default global argument parsing

function defaultParseArgs()
{
    debug("command line args:");
    for ($i = 0; $i < $Game::argc ; $i++) {
        debug(" - " @ $i @ " = " @ $Game::argv[$i]);
    }

    for ($i = 1; $i < $Game::argc ; $i++)
    {
        $arg = $Game::argv[$i];
        $nextArg = $Game::argv[$i+1];
        $hasNextArg = $Game::argc - $i > 1;
        $logModeSpecified = false;

        switch$ ($arg)
        {
            //--------------------
            case "-log":
                if ($hasNextArg)
                {
                    // Turn on console logging
                    if ($nextArg != 0)
                    {
                        // Dump existing console to logfile first.
                        $nextArg += 4;
                    }
                    setLogMode($nextArg);
                    $logModeSpecified = true;
                    $i++;
                }
                else
                    error("Error: Missing Command Line argument. Usage: -log <Mode: 0,1,2>");

            //--------------------
            case "-console":
                enableWinConsole(true);

            //--------------------
            case "-cefdev":
                enableCEFDevConsole(true);

            case "-vehicle":
                $beamngVehicleArgs = $nextArg;
                $i++;

            case "-luafile":
                LuaExecuteFile($nextArg);
                $i++;

            case "-lua":
                LuaExecuteQueueString($nextArg);
                $i++;

            case "-onLevelLoad_ext":
                LuaExecuteQueueString("queueExtensionToLoad(" @ $nextArg @ ")");
                $i++;

            case "-level":
                if ($hasNextArg) {
                    $levelToLoad = $nextArg;
                    $i++;
                } else {
                    error("Error: Missing Command Line argument. Usage: -level <level file name (no path), with or without extension>");
                }

            //-------------------
            case "-worldeditor":
                $startWorldEditor = true;
        }
    }
}
