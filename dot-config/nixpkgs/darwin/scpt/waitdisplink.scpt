#!/usr/bin/osascript

set XID to id of application "DisplayLink Manager"
set startTime to (current date)

try
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
end try

