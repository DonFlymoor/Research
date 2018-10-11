
function AIPathEditorGui::onWake( %this )
{
    $AIPath::EditorOpen = true;

    %count = EWorldEditor.getSelectionSize();
    for ( %i = 0; %i < %count; %i++ )
    {
        %obj = EWorldEditor.getSelectedObject(%i);
        if ( %obj.getClassName() !$= "AIPath" )
            EWorldEditor.unselectObject();
        else
            %this.setSelectedAIPath( %obj );
    }

    %this.onNodeSelected(-1);
}

function AIPathEditorGui::onSleep( %this )
{
    $AIPath::EditorOpen = false;
}

function AIPathEditorGui::paletteSync( %this, %mode )
{
    %evalShortcut = "ToolsPaletteArray-->" @ %mode @ ".setStateOn(1);";
    eval(%evalShortcut);
}

function AIPathEditorGui::onDeleteKey( %this )
{
    %aip = %this.getSelectedAIPath();
    %node = %this.getSelectedNode();

    if ( !isObject( %aip ) )
        return;

    if ( %node != -1 )
    {
        %this.deleteNode();
    }
    else
    {
        MessageBoxOKCancel( "Notice", "Delete selected AIPath?", "AIPathEditorGui.deleteAIPath();", "" );
    }
}

function AIPathEditorGui::onEscapePressed( %this )
{
    if( %this.getMode() $= "AIPathEditorAddNodeMode" )
    {
        %this.prepSelectionMode();
        return true;
    }
    return false;
}

//just in case we need it later
function AIPathEditorGui::onAIPathCreation( %this )
{
}

function AIPathEditorGui::onAIPathSelected( %this, %aip )
{
    %this.aip = %aip;

    // Update the materialEditorList
    if(isObject( %aip ))
        $Tools::materialEditorList = %aip.getId();

    AIPathInspector.inspect( %aip );
    AIPathTreeView.buildVisibleTree(true);
    if( AIPathTreeView.getSelectedObject() != %aip )
    {
        AIPathTreeView.clearSelection();
        %treeId = AIPathTreeView.findItemByObjectId( %aip );
        AIPathTreeView.selectItem( %treeId );
    }
}

function AIPathEditorGui::onNodeSelected( %this, %nodeIdx )
{

    if ( %nodeIdx == -1 )
    {
        AIPathEditorProperties-->position.setActive( false );
        AIPathEditorProperties-->position.setValue( "" );

        AIPathEditorProperties-->width.setActive( false );
        AIPathEditorProperties-->width.setValue( "" );
    }
    else
    {
        AIPathEditorProperties-->position.setActive( true );
        AIPathEditorProperties-->position.setValue( %this.getNodePosition() );

        AIPathEditorProperties-->width.setActive( true );
        AIPathEditorProperties-->width.setValue( %this.getNodeWidth() );
    }

}

function AIPathEditorGui::onNodeModified( %this, %nodeIdx )
{

    AIPathEditorProperties-->position.setValue( %this.getNodePosition() );
    AIPathEditorProperties-->width.setValue( %this.getNodeWidth() );

}

function AIPathEditorGui::editNodeDetails( %this )
{

    %this.setNodePosition( AIPathEditorProperties-->position.getText() );
    %this.setNodeWidth( AIPathEditorProperties-->width.getText() );
}

function AIPathEditorGui::onBrowseClicked( %this )
{
    //%filename = RETextureFileCtrl.getText();

    %dlg = new OpenFileDialog()
    {
        Filters        = "All Files (*.*)|*.*|";
        DefaultPath    = AIPathEditorGui.lastPath;
        DefaultFile    = %filename;
        ChangePath     = false;
        MustExist      = true;
    };

    %ret = %dlg.Execute();
    if(%ret)
    {
        AIPathEditorGui.lastPath = filePath( %dlg.FileName );
        %filename = %dlg.FileName;
        AIPathEditorGui.setTextureFile( %filename );
        RETextureFileCtrl.setText( %filename );
    }

    %dlg.delete();
}

function AIPathInspector::inspect( %this, %obj )
{
    %name = "";
    if ( isObject( %obj ) )
        %name = %obj.getName();
    else
        AIPathFieldInfoControl.setText( "" );

    //AIPathInspectorNameEdit.setValue( %name );
    Parent::inspect( %this, %obj );
}

function AIPathInspector::onInspectorFieldModified( %this, %object, %fieldName, %arrayIndex, %oldValue, %newValue )
{
    // Same work to do as for the regular WorldEditor Inspector.
    Inspector::onInspectorFieldModified( %this, %object, %fieldName, %arrayIndex, %oldValue, %newValue );
}

function AIPathInspector::onFieldSelected( %this, %fieldName, %fieldTypeStr, %fieldDoc )
{
    AIPathFieldInfoControl.setText( "<font:ArialBold:14>" @ %fieldName @ "<font:ArialItalic:14> (" @ %fieldTypeStr @ ") " NL "<font:Arial:14>" @ %fieldDoc );
}

function AIPathTreeView::onInspect(%this, %obj)
{
    AIPathInspector.inspect(%obj);
}

function AIPathTreeView::onSelect(%this, %obj)
{
    AIPathEditorGui.aip = %obj;
    AIPathInspector.inspect( %obj );
    if(%obj != AIPathEditorGui.getSelectedAIPath())
    {
        AIPathEditorGui.setSelectedAIPath( %obj );
    }
}

function AIPathEditorGui::prepSelectionMode( %this )
{
    %mode = %this.getMode();

    if ( %mode $= "AIPathEditorAddNodeMode"  )
    {
        if ( isObject( %this.getSelectedAIPath() ) )
            %this.deleteNode();
    }

    %this.setMode( "AIPathEditorSelectMode" );
    ToolsPaletteArray-->AIPathEditorSelectMode.setStateOn(1);
}
//------------------------------------------------------------------------------
function EAIPathEditorSelectModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function EAIPathEditorAddModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function EAIPathEditorMoveModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function EAIPathEditorScaleModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function EAIPathEditorInsertModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function EAIPathEditorRemoveModeBtn::onClick(%this)
{
    EditorGuiStatusBar.setInfo(%this.ToolTip);
}

function AIPathDefaultWidthSliderCtrlContainer::onWake(%this)
{
    AIPathDefaultWidthSliderCtrlContainer-->slider.setValue(AIPathDefaultWidthTextEditContainer-->textEdit.getText());
}
