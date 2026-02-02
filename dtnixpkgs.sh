#!/usr/bin/env bash

OWNER="NixOS"
REPO="nixpkgs"
REF=$1

RAW_DATE=$(curl -s "https://api.github.com/repos/${OWNER}/${REPO}/commits/${REF}" | jq -r '.commit.committer.date')

date -jf "%Y-%m-%dT %H:%M:%SZ" "$RAW_DATE" +"%e %b %Y %T %Z"
