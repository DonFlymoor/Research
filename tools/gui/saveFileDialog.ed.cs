
function getSaveFilename( %filespec, %callback, %currentFile, %overwrite )
{
    if( %overwrite $= "" )
        %overwrite = true;

    if( filePath( %currentFile ) !$= "" )
        %DefaultPathtmp = filePath( %currentFile );
    else
        %DefaultPathtmp = getUserPath();

    %dlg = new SaveFileDialog()
    {
        Filters = %filespec;
        DefaultFile = %currentFile;
        DefaultPath = %DefaultPathtmp;
        ChangePath = false;
        OverwritePrompt = %overwrite;
    };

    if( filePath( %currentFile ) !$= "" )

    if( %dlg.Execute() )
    {
        %filename = %dlg.FileName;
        eval( %callback @ "(\"" @ %filename @ "\");" );
    }

    %dlg.delete();
}
