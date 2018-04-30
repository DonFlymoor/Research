--[[ {
    replacement = <string>
    obsolete = true | false
    executeOnLoad = true or false --This is here to support executing previous onLoad / init functions
    returnOnFail = true or false --Early out on failure
}]]--
return {
    onLoad = {replacement = 'onExtensionLoaded', executeOnModuleLoad=true, returnOnFail = true},
    init = {replacement = 'onExtensionLoaded', executeOnModuleLoad=true},
    onRaceWaypoint = {replacement = 'onRaceWaypointReached'},
    onScenarioRaceCountingDone = {replacement = 'onCountdownEnded', disablePatching=false},
}



