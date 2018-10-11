exec("./BNG_DynamicReflectionsDebugCtrl.gui");

function BNG_DynamicReflectionsDebugCtrl::onWake(%this)
{
    $pref::BeamNGVehicle::dynamicReflection::debugEnabled = true;
}

function BNG_DynamicReflectionsDebugCtrl::onSleep(%this)
{
    $pref::BeamNGVehicle::dynamicReflection::debugEnabled = false;
}

function debugDynamicsReflections()
{
    if( !isObject(BNG_DynamicReflectionsDebugCtrl) )
        return;

    Canvas.pushDialog(BNG_DynamicReflectionsDebugCtrl);
}
