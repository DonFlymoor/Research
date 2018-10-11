
function loadDirectory(%path, %type)
{
    if( %type $= "" )
        %type = "ed.cs";
    %cspath = %path @ "/*." @ %type;
    %file = findFirstFile(%cspath);
    while(%file !$= "")
    {
        exec(%file);
        %file = findNextFile(%cspath);
    }
}

function listDirectory(%path)
{
    %file = findFirstFile(%path);

    debug("Listing Directory " @ %path @ " ...");
    while(%file !$= "")
    {
        debug("  " @ %file);
        %file = findNextFile(%path);
    }
}
