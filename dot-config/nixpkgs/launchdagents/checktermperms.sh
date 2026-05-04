#!/usr/bin/env bash

set -u
set -o pipefail

## Choice of repository host "github" or "gitlab"

readonly ESC="$(tput sgr0)"
readonly BOLD="$(tput bold)"
readonly GREEN="$(tput setaf 2)"
readonly RED="$(tput setaf 1)"

function cleanup() {
    printf "${ESC}"
}

trap cleanup EXIT INT TERM QUIT

TERMPROGS=("ghostty" "kitty")

declare -A term_perms

required_perms=("kTCCServiceAccessibility" "kTCCServiceSystemPolicyAllFiles")
for termprg in "${TERMPROGS[@]}"; do
    idprog=$(/usr/bin/osascript -e "id of application \"$termprg\"" 2>/dev/null)
    if [ $? -ne 0 ]; then
        # Terminal program not installed - so skip
        continue
    fi
    term_perms=()
    while IFS='|' read -r service client auth_value; do
        term_perms[$service]=$auth_value
    done < <(sudo sqlite3 --readonly /Library/Application\ Support/com.apple.TCC/TCC.db \
        "SELECT service, client, auth_value FROM access WHERE client LIKE \"%$idprog%\";")

    printf "===============\n"
    printf "$termprg security settings\n"
    for svc in "${!term_perms[@]}"; do
        if [ ${term_perms[$svc]} -ne 2 ]; then
            printf "${RED}${BOLD}$svc permission for $termprg is disabled${ESC}\n"
        else
            printf "$svc permission for $termprg is enabled\n"
        fi
    done

    # Check for missing permissions
    for perm in "${required_perms[@]}"; do
        if [[ ! -v term_perms["$perm"] ]]; then
            printf "${RED}${BOLD}$perm permission missing for $termprg${ESC}\n"
        fi
    done
    printf "\n";
done
