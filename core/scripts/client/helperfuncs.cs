
function setValueSafe(%dest, %val)
{
    %cmd = %dest.command;
    %alt = %dest.altCommand;
    %dest.command = "";
    %dest.altCommand = "";

    %dest.setValue(%val);

    %dest.command = %cmd;
    %dest.altCommand = %alt;
}

//------------------------------------------------------------------------------
// An Aggregate Control is a plain GuiControl that contains other controls,
// which all share a single job or represent a single value.
//------------------------------------------------------------------------------

// AggregateControl.setValue( ) propagates the value to any control that has an
// internal name.
function AggregateControl::setValue(%this, %val, %child)
{
    for(%i = 0; %i < %this.getCount(); %i++)
    {
        %obj = %this.getObject(%i);
        if( %obj == %child )
            continue;

        if(%obj.internalName !$= "")
            setValueSafe(%obj, %val);
    }
}

// AggregateControl.getValue() uses the value of the first control that has an
// internal name, if it has not cached a value via .setValue
function AggregateControl::getValue(%this)
{
    for(%i = 0; %i < %this.getCount(); %i++)
    {
        %obj = %this.getObject(%i);
        if(%obj.internalName !$= "")
        {
            //error("obj = " @ %obj.getId() @ ", " @ %obj.getName() @ ", " @ %obj.internalName );
            //error(" value = " @ %obj.getValue());
            return %obj.getValue();
        }
    }
}

// AggregateControl.updateFromChild( ) is called by child controls to propagate
// a new value, and to trigger the onAction() callback.
function AggregateControl::updateFromChild(%this, %child)
{
    %val = %child.getValue();
    if(%val == mCeil(%val)){
        %val = mCeil(%val);
    }else{
        if ( %val <= -100){
            %val = mCeil(%val);
        }else if ( %val <= -10){
            %val = mFloatLength(%val, 1);
        }else if ( %val < 0){
            %val = mFloatLength(%val, 2);
        }else if ( %val >= 1000){
            %val = mCeil(%val);
        }else if ( %val >= 100){
            %val = mFloatLength(%val, 1);
        }else if ( %val >= 10){
            %val = mFloatLength(%val, 2);
        }else if ( %val > 0){
            %val = mFloatLength(%val, 3);
        }
    }
    %this.setValue(%val, %child);
    %this.onAction();
}

// default onAction stub, here only to prevent console spam warnings.
function AggregateControl::onAction(%this)
{
}

// call a method on all children that have an internalName and that implement the method.
function AggregateControl::callMethod(%this, %method, %args)
{
    for(%i = 0; %i < %this.getCount(); %i++)
    {
        %obj = %this.getObject(%i);
        if(%obj.internalName !$= "" && %obj.isMethod(%method))
            eval(%obj @ "." @ %method @ "( " @ %args @ " );");
    }

}

// A function used in order to easily parse the MissionGroup for classes . I'm pretty
// sure at this point the function can be easily modified to search the any group as well.
function parseMissionGroup( %className, %childGroup )
{
    if( getWordCount( %childGroup ) == 0)
        %currentGroup = "MissionGroup";
    else
        %currentGroup = %childGroup;

    for(%i = 0; %i < (%currentGroup).getCount(); %i++)
    {
        if( (%currentGroup).getObject(%i).getClassName() $= %className )
            return true;

        if( (%currentGroup).getObject(%i).getClassName() $= "SimGroup" )
        {
            if( parseMissionGroup( %className, (%currentGroup).getObject(%i).getId() ) )
                return true;
        }
    }
}

// A variation of the above used to grab ids from the mission group based on classnames
function parseMissionGroupForIds( %className, %childGroup )
{
    if( getWordCount( %childGroup ) == 0)
        %currentGroup = "MissionGroup";
    else
        %currentGroup = %childGroup;

    for(%i = 0; %i < (%currentGroup).getCount(); %i++)
    {
        if( (%currentGroup).getObject(%i).getClassName() $= %className )
            %classIds = %classIds @ (%currentGroup).getObject(%i).getId() @ " ";

        if( (%currentGroup).getObject(%i).getClassName() $= "SimGroup" )
            %classIds = %classIds @ parseMissionGroupForIds( %className, (%currentGroup).getObject(%i).getId());
    }
    return %classIds;
}

//------------------------------------------------------------------------------
// Altered Version of TGB's QuickEditDropDownTextEditCtrl
//------------------------------------------------------------------------------

function QuickEditDropDownTextEditCtrl::onRenameItem( %this )
{
}

function QuickEditDropDownTextEditCtrl::updateFromChild( %this, %ctrl )
{
    if( %ctrl.internalName $= "PopUpMenu" )
    {
        %this->TextEdit.setText( %ctrl.getText() );
    }
    else if ( %ctrl.internalName $= "TextEdit" )
    {
        %popup = %this->PopupMenu;
        %popup.changeTextById( %popup.getSelected(), %ctrl.getText() );
        %this.onRenameItem();
    }
}
