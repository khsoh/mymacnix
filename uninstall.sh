#!/usr/bin/env bash

set -u
set -o pipefail

#
# Uninstall script for Nix package manager that was installed on MacOS using the NixOS install command:
#   sh <(curl -L https://nixos.org/nix/install)
#

readonly CLRLINE='\033[0K'
readonly ESC='\033[0m'
readonly BOLD='\033[1m'
readonly BLUE='\033[34m'
readonly BLUE_UL='\033[4;34m'
readonly GREEN='\033[32m'
readonly GREEN_UL='\033[4;32m'
readonly RED='\033[31m'

dly () {
   secs=$1
   while [ $secs -gt 0 ]; do
      #echo -ne "$secs\033[0K\r"
      echo -ne "\r$GREEN$secs$CLRLINE"
      sleep 1
      : $((secs--))
   done
   echo -ne "\r${CLRLINE}${ESC}"
}

getyesno () {
    local prompt="[y/n]"
    echo -n "$1 $prompt"
    while read -r y; do
        if [ "$y" = "y" ]; then
            return 0
        elif [ "$y" = "n" ]; then
            return 1
        else
            echo -e "$RED" "Sorry, I didn't understand. I can only understand answers of y or n${ESC}"
            echo -n "$prompt"
        fi
    done
}

# Edit /etc/zshrc, /etc/bashrc, and /etc/bash.bashrc to remove the lines sourcing nix-daemon.sh,
if [[ -f /etc/zshrc.backup-before-nix ]]; then
    sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
fi
if [[ -f /etc/bashrc.backup-before-nix ]]; then
    sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
fi
if [[ -f /etc/bash.bashrc.backup-before-nix ]]; then
    sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc

    # Check if the bash.bashrc can be removed
    if [[ $(sed -e '/# Nix/,/# End Nix/d' -e '/^[[:space:]]*$/d' /etc/bash.bashrc|wc -l) -eq 0 ]]; then
        # Remove file if there is nothing in it
        sudo rm /etc/bash.bashrc
    fi
elif [[ -f /etc/bash.bashrc ]]; then
    sudo rm /etc/bash.bashrc
fi

# Stop and remove the Nix daemon services:
sudo launchctl disable system/org.nixos.nix-daemon
sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl disable system/org.nixos.darwin-store
sudo rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist

# Remove the nixbld group and the _nixbuildN users
sudo dscl . -delete /Groups/nixbld
for u in $(sudo dscl . -list /Users | grep _nixbld); do sudo dscl . -delete /Users/$u; done

# Edit fstab using sudo vifs to remove the line mounting the Nix Store volume on /nix, 
# which looks like UUID=<uuid> /nix apfs rw,noauto,nobrowse,suid,owners or LABEL=Nix\040Store /nix apfs rw,nobrowse.
echo -e "${RED}Calling: sudo vifs  to edit /etc/fstab"
echo -e "  You will have to delete line that contains \"/nix apfs rw\""
echo -e "  and then save the file${ESC}"

dly 8
sudo vifs

echo ""
echo ""

# Edit /etc/synthetic.conf to remove the nix line. If this is the only line in the file 
# you can remove it entirely, sudo rm /etc/synthetic.conf. This will prevent the creation of 
# the empty /nix directory to provide a mountpoint for the Nix Store volume.
echo -e "${RED}Calling: sudo vim /etc/synthetic.conf  to edit /etc/synthetic.conf"
echo -e "  You will have to delete line that contains starts with \"nix\""
echo -e "  and then save the file."
echo -e "  If this is the only line, you may remove the file${ESC}"

dly 8
sudo vim /etc/synthetic.conf
echo ""
echo ""

if [[ $(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' /etc/synthetic.conf|wc -l) -eq 0 ]]; then
    if getyesno "/etc/synthetic.conf file can be removed.  Do you want to remove it?" ; then
        sudo rm /etc/synthetic.conf
    fi
fi

# Remove the files Nix added to your system:
sudo rm -rf /etc/nix /var/root/.nix-profile /var/root/.nix-defexpr /var/root/.nix-channels ~/.nix-profile ~/.nix-defexpr ~/.nix-channels


# Remove the Nix Store volume
if getyesno "Do you want to schedule a task to remove Nix Store volume after reboot?" ; then
    sudo cp -f $PWD/removenixvol.sh /var/root
    sudo chown root:wheel /var/root/removenixvol.sh
    sudo cp $PWD/org.nixos.removenixvol.plist /Library/LaunchDaemons
    sudo chown root:wheel /Library/LaunchDaemons/org.nixos.removenixvol.plist
    sudo launchctl enable system/org.nixos.removenixvol
    sudo rm -f /var/db/com.apple.xpc.launchd/disabled.plist

    if getyesno "The Nix Store volume will only be removed after reboot - do you want to reboot now?" ; then
        sudo shutdown -r now
    fi
else
    sudo rm -f /var/db/com.apple.xpc.launchd/disabled.plist
fi

