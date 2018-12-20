
function getSaveFilename( %filespec, %callback, %currentFile, %overwrite )
{
    if( %overwrite $= "" )
        %overwrite = true;

    if( filePath( %currentFile ) !$= "" )
        %DefaultPathtmp = filePath( %currentFile );
    else
        %DefaultPathtmp = getUserPath();

    debug("% - getSaveFilename Manager - DefaultPathtmp = " @ %DefaultPathtmp);

    %dlg = new SaveFileDialog()
    {
        Filters = %filespec;
        DefaultFile = %currentFile;
        DefaultPath = %DefaultPathtmp;
        ChangePath = false;
        OverwritePrompt = %overwrite;
    };

    if( %dlg.Execute() )
    {
        %filename = %dlg.FileName;
        eval( %callback @ "(\"" @ %filename @ "\");" );
    }

    %dlg.delete();
}
