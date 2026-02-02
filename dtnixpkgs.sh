#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <GitCommitRef>"
    exit 1
fi
OWNER="NixOS"
REPO="nixpkgs"
REF=$1

RAW_DATE=$(curl -s "https://api.github.com/repos/${OWNER}/${REPO}/commits/${REF}" | jq -r '.commit.committer.date')

date -jf "%Y-%m-%dT %H:%M:%SZ" "$RAW_DATE" +"%e %b %Y %T %Z"
