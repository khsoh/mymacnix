#!/usr/bin/env bash

set -u
set -o pipefail

## Choice of repository host "github" or "gitlab"

readonly ESC="$(tput sgr0)"
readonly BOLD="$(tput bold)"
readonly GREEN="$(tput setaf 2)"
readonly RED="$(tput setaf 1)"
readonly BLUE="$(tput setaf 4)"

function cleanup() {
    printf "${ESC}"
}

trap cleanup EXIT INT TERM QUIT

TERMPROGS=("ghostty" "kitty")

declare -A term_perms

required_perms=("kTCCServiceAccessibility" "kTCCServiceSystemPolicyAllFiles")
max_len=0
for perm in "${required_perms[@]}"; do
    len=${#perm}

    if (( len > max_len )); then
        max_len=$len
    fi
done

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

    printf "${GREEN}${BOLD}=== $termprg security settings ===${ESC}\n"
    for svc in "${!term_perms[@]}"; do
        if [ ${term_perms[$svc]} -ne 2 ]; then
            printf "${BLUE}${BOLD}==>${RED}${BOLD}  %*s permission disabled${ESC}\n" "$max_len" "$svc"
        else
            printf "${BLUE}${BOLD}==>${ESC}  %*s permission enabled\n" "$max_len" "$svc"
        fi
    done

    # Check for missing permissions
    for perm in "${required_perms[@]}"; do
        if [[ ! -v term_perms["$perm"] ]]; then
            printf "${BLUE}${BOLD}==>${RED}${BOLD}  %*s permission missing${ESC}\n" "$max_len" "$perm"
        fi
    done
    printf "\n";
done
