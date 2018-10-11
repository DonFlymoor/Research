
//-----------------------------------------------------------------------------
// Special audio state that will always and only be active when no other
// state is active.  Useful for letting slots apply specifically when no
// other slot in a list applies.

singleton SFXState( AudioStateNone ) {};

AudioStateNone.activate();

function SFXState::onActivate( %this )
{
    if( %this.getId() != AudioStateNone.getId() )
        AudioStateNone.disable();
}

function SFXState::onDeactivate( %this )
{
    if( %this.getId() != AudioStateNone.getId() )
        AudioStateNone.enable();
}

//-----------------------------------------------------------------------------
// AudioStateExclusive class.
//
// Automatically deactivates sibling SFXStates in its parent SimGroup
// when activated.

function AudioStateExclusive::onActivate( %this )
{
    Parent::onActivate( %this );

    %group = %this.parentGroup;
    %count = %group.getCount();

    for( %i = 0; %i < %count; %i ++ )
    {
        %obj = %group.getObject( %i );

        if( %obj != %this && %obj.isMemberOfClass( "SFXState" ) && %obj.isActive() )
            %obj.deactivate();
    }
}
