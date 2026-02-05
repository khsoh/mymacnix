#!/usr/bin/osascript


try
    tell application "System Events"
        repeat with theProcess in processes
            set theName to name of theProcess
            set theBundleId to bundle identifier of theProcess
            set theDispName to displayed name of theProcess
            set theShortName to short name of theProcess
            log "Name: " & theName & "\n" & ¬
              "Bundle ID: " & theBundleId & "\n" & ¬ 
              "Disp Name: " & theDispName & "\n" & ¬
              "Short Name: " & theShortName & "\n\n"
        end repeat
    end tell

on error
end try

