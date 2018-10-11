exec( "./options/graphic_OptionsHelper.cs");
exec( "./options/audio_OptionsHelper.cs");
exec( "./options/postFX_SSAO_OptionsHelper.cs");
exec( "./options/postFX_HDR_OptionsHelper.cs");
exec( "./options/postFX_LightRays_OptionsHelper.cs");
exec( "./options/postFX_DOF_OptionsHelper.cs");

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------

function getSettingsValue( %setting )
{
    if( isObject(%setting) )
    {
        %options = "null";
        if( %setting.isMethod("getOptions") )
                %options = %setting.getOptions();

        return "[\"" @ %setting.getValue( )  @ "\", " @ %options @ " ]";
    }

    %value = eval( %setting @ "_getValue();" );
    %options = "null";
    if( isFunction( %setting @ "_getOptions" ) )
        %options = eval( %setting @ "_getOptions();" );


    // not needed anymore since we use the callbacksolution
    //%cmd = "onUpdateOptionValue( \"" @ %obj @ "\",\"" @ %value  @ "\", \"" @ %options @ "\" );" ;
    // just send it to both context types, for the options page and the ingame options
    //beamNGExecuteJS( %cmd );

    return "[\"" @ %value  @ "\", " @ %options @ " ]";
}

function setSettingsValue(%setting, %value )
{
    if( %value $= "false" )
        %value = false;
    else if( %value $= "true")
        %value = true;

    if( isObject(%setting) )
    {
        %setting._setValue( %value );
    }
    else
    {
        %cmd = %setting @ "_setValue( \"" @ %value @ "\");";
        debug( ">>>>" @ %cmd);
        eval( %cmd );
    }
}

function setSettingsValueByIndex(%setting, %value )
{
    if( %value $= "false" )
        %value = false;
    else if( %value $= "true")
        %value = true;

    if( isObject(%setting) )
    {
        %setting.setValueByIndex( %value );
    }
    else
    {
        %cmd = %setting @ "_setValue( \"" @ %value @ "\");";
        debug( ">>>>" @ %cmd);
        eval( %cmd );
    }
}

function applyOptions()
{
    applyOptions_Graphic();
    applyAudioOptions();
}

function cleanRGB( %rgb )
{
    if( stricmp( %rgb , "rgb(" ) > 0 )
    {
        //clean value string
        %rgb = strreplace( %rgb , "rgb(", "" );
        %rgb = strreplace( %rgb , ",", "" );
        %rgb = strreplace( %rgb , ")", "" );
    }

    return %rgb;
}

function findField( %fieldList, %field )
{
    for( %itr = 0; %itr < getFieldCount( %fieldList ); %itr++ )
    {
        if( %field $= getField( %fieldList, %itr ) )
                return %itr;
    }

    return -1;
}

function OptionHelper::getValue( %this )
{
    if( %this.optionType $= "Slice" || getFieldCount( %this.optionsPrettyFields ) == 0 )
        return %this._getValue();

    %idx = findField( %this.optionsFields, %this._getValue() );

    if( %idx == -1 )
        %idx = 0;

    return getField( %this.optionsPrettyFields, %idx );
}

function OptionHelper::setValue( %this, %idx )
{
    %this._setValue( %value );
}

function OptionHelper::setValueByIndex( %this, %idx )
{
    if( %this.optionType $= "Slice" || getFieldCount( %this.optionsPrettyFields ) == 0 )
        %value = %idx;
    else
        %value = getField( %this.optionsFields, %idx);

    %this._setValue( %value );
}

function OptionHelper::clearOptions( %this )
{
    %this.optionsFields = "";
    %this.optionsPrettyFields = "";
}

function OptionHelper::getOptions( %this )
{
    %this.clearOptions();
    %this._buildOptions();
    %out = "";

    if( %this.optionType $= "Slice" || getFieldCount( %this.optionsPrettyFields ) == 0 )
        return "null";

    if( getFieldCount( %this.optionsPrettyFields ) == 1 )
        return "[\"" @ getField( %this.optionsPrettyFields, 0 ) @ "\"]";

    %out = "\"" @ getField( %this.optionsPrettyFields, 0 ) @ "\"";
    for( %i = 1; %i < getFieldCount( %this.optionsPrettyFields ); %i++ )
    {
        %out = %out @ ", \"" @ getField( %this.optionsPrettyFields, %i ) @ "\"";
    }

    %out = "[" @ %out @ "]";
    return %out;
}

function OptionHelper::getOptions2( %this )
{
    %this.clearOptions();
    %this._buildOptions();
    %out = "";

    if( %this.optionType $= "Slice" || getFieldCount( %this.optionsFields ) == 0 )
        return "null";

    if( getFieldCount( %this.optionsFields ) == 1 )
        return "[\"" @ getField( %this.optionsFields, 0 ) @ "\"]";

    %out = "\"" @ getField( %this.optionsFields, 0 ) @ "\"";
    for( %i = 1; %i < getFieldCount( %this.optionsFields ); %i++ )
    {
        %out = %out @ ", \"" @ getField( %this.optionsFields, %i ) @ "\"";
    }

    %out = "[" @ %out @ "]";
    return %out;
}

function OptionHelper::addOption( %this, %fiel, %prettyfield )
{
    if( findField( %this.optionsFields, %fiel ) == -1 )
    {
        %idx = getFieldCount(%this.optionsFields);
        %this.optionsFields = setField( %this.optionsFields, %idx, %fiel );
        %this.optionsPrettyFields = setField( %this.optionsPrettyFields, %idx, %prettyfield );
    }
}

singleton SimObject( OptionHelperEventRcv );
function OptionHelperEventRcv::onExit( %this )
{
    debug("Saving PostFX options");
    PostFXManager::savePresetHandler($PostFXManager::defaultPreset);
}

MainEventManager.subscribe( OptionHelperEventRcv, "onExit", "onExit");

function _asString( %value )
{
    return "\"" @ %value @ "\"";
}

function getSetting(%name)
{
    if( !isObject(%name) )
        return "";

    %modes = %name.getOptions2();
    if( %modes $= "null" )
        %modes = "[ ]";

    %descs = %name.getOptions();
    if( %descs $= "null" )
        %descs = "[ ]";

    return %str = "[ " @ _asString(%name) SPC "," SPC _asString( %name._getValue() ) SPC "," SPC %modes SPC "," SPC %descs SPC "]\n" ;
}

function getSettingsState()
{
    %state = "";
    %state = %state @ getGraphicSettingsState();
    %state = %state @ getAudioSettingsState();
    return %state;
}
