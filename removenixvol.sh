#!/bin/sh

nixvol=$(/usr/sbin/diskutil list|/usr/bin/grep "Nix Store"|/usr/bin/sed -e 's/.*\(disk.*\)/\1/')
if [[ $nixvol ]]; then
    /usr/sbin/diskutil apfs deleteVolume $nixvol
fi
/bin/launchctl disable system/org.nixos.removenixvol && /bin/rm -f /Library/LaunchDaemons/org.nixos.removenixvol.plist
/bin/rm -f /var/db/com.apple.xpc.launchd/disabled.plist
/bin/rm -f /var/root/removenixvol.sh

