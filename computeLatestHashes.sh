#!/run/current-system/sw/bin/zsh

## This script gets the latest commit hash of the main/master branch of the repos
## referenced in home.nix and computes the SRI SHA256 checksum for each repo
declare -a REPOS=()
REPOS+=("https://github.com/khsoh/kickstart.nvim;refs/heads/master")
REPOS+=("https://github.com/khsoh/tmuxconf;refs/heads/master")
REPOS+=("https://github.com/khsoh/kittyconf;refs/heads/main")

for repo in "${REPOS[@]}";  do
    IFS=";"; read url ref <<< $repo
    rev=$(git ls-remote $url $ref|awk '{print $1}')
    hash=$(nix-hash --to-sri --type sha256 $(nix-prefetch-url --unpack $url/archive/${rev}.tar.gz 2> /dev/null))
    printf "REPO=$url\nREV=$rev\nSHA256=$hash\n\n"
done
