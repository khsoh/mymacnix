#!/usr/bin/osascript

use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

-- 1. Handle the File Path
-- Expanding ~/ manually to ensure AppleScript can find it
set tildePath to "~/.config/nix/secrets.json"
set absolutePath to (current application's NSString's stringWithString:tildePath)'s stringByExpandingTildeInPath() as text

-- 2. Read the File Content
-- Note: Wrapping (absolutePath as POSIX file) in parentheses prevents the -1700 error
set jsonString to (read (absolutePath as POSIX file) as «class utf8»)

-- 3. Parse the JSON String
set jsonData to current application's NSString's stringWithString:jsonString
set jsonBytes to jsonData's dataUsingEncoding:(current application's NSUTF8StringEncoding)
set {theJSON, theError} to current application's NSJSONSerialization's ¬
    JSONObjectWithData:jsonBytes options:0 |error|:(reference)

-- 4. Access your data
-- Replace "iMessageID" with the key you need
set imsgid to (theJSON's valueForKey:"iMessageID") as text

-- 5. Send iMessage to handle
-- tell application "Messages" to send "hello world" to buddy imsgid
tell application "Messages"
    -- Identify the active iMessage service
    set iMessageService to 1st service whose service type = iMessage
    
    -- Target the buddy (recipient) and send the message
    set theBuddy to buddy imsgid of iMessageService
    send "Test message from AppleScript" to theBuddy
end tell
