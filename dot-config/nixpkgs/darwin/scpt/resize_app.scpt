#!/usr/bin/osascript

use framework "Foundation"
use framework "AppKit"
use scripting additions


on run argv
    -- Terminal is the default window to move
    set XAPP to "Terminal"
    set XFRACTION to 0.5
    set YFRACTION to 1.0

    if count of argv > 0 then
        set XAPP to item 1 of argv as text
    end if
    if count of argv > 1 then
        set XFRACTION to item 2 of argv as real
    end if
    if count of argv > 2 then
        set YFRACTION to item 3 of argv as real
    end if

    set TOPLEFTX to 0 as integer
    set TOPLEFTY to 0 as integer

    set jsonString to my (NSString's stringWithString:(do shell script "system_profiler SPDisplaysDataType -json"))
    set jsonData to jsonString's dataUsingEncoding:(my NSUTF8StringEncoding)
    set jsonRecord to (my (NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(missing value))) as record

    set spdisplays to SPDisplaysDataType of jsonRecord

    if (count spdisplays) > 0 then
        -- This segment for handling multiple displays
        set fdispdrv to null
        repeat with dispdrv in my spdisplays_ndrvs of (item 1 of spdisplays)
            if dispdrv contains { spdisplays_main:"spdisplays_yes" } then
                set fdispdrv to dispdrv
                exit repeat
            end if
        end repeat
        if fdispdrv is null then
            return
        end if

        set dispres to _spdisplays_resolution of fdispdrv
        set BOTRIGHTX to word 1 of dispres as integer
        set BOTRIGHTY to word 3 of dispres as integer
        set theMenuBarHeight to current application's NSMenu's menuBarHeight() as integer

        set TOPLEFTY to (theMenuBarHeight + 1 + TOPLEFTY) as integer
        set botrx to (BOTRIGHTX * XFRACTION) as integer
        set botry to (BOTRIGHTY * YFRACTION) as integer
    else
        -- For handling UTM screens
        tell application "Finder" to set terminalSize to bounds of window of desktop

        set TOPLEFTX to item 1 of terminalSize
        set TOPLEFTY to (item 2 of terminalSize + 1 + TOPLEFTY) as integer
        set botrx to (item 3 of terminalSize * XFRACTION) as integer
        set botry to (item 4 of terminalSize * YFRACTION) as integer
    end if

    tell application "System Events"
        set found to false
        repeat with theProcess in (processes where name is XAPP)
            set theProcess to theProcess
            set found to true
            exit repeat
        end repeat
        if not found then
            return
        end if

        tell theProcess to set theWindow to first item of windows
        set position of theWindow to { TOPLEFTX, TOPLEFTY }
        set size of theWindow to { botrx, botry }

    end tell
end run

