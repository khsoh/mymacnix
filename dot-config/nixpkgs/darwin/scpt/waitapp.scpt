#!/usr/bin/osascript

on run argv
    if (count of argv) is 0 then
        return
    end if
    set XAPP to item 1 of argv as text

    set query to "kMDItemFSName == " & quoted form of XAPP & " && kMDItemKind == 'Application'"
    set result to do shell script "mdfind " & quoted form of query
    if result is "" then
        return
    end if

    try
        set XID to id of app XAPP
        set startTime to (current date)

        repeat
            tell application "System Events"
                if exists (every process whose bundle identifier is XID) then
                    exit repeat
                end if
            end tell

            if ((current date) - startTime) > 60 then
                exit repeat
            end if
        end repeat
    on error
        -- No display link manager application installed - just continue
        log "App " & XAPP & " is not executing"
    end try

end run
