
// Load up all datablocks.  This function is called when
// a server is constructed.
exec("./audioProfiles.cs");
exec("./sounds.cs");
exec("./lights.cs");
if(isFile("./player.cs")) exec("./player.cs");

datablock ShapeBaseData(default_vehicle)
{
};
