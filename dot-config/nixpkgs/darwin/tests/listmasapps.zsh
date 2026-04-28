#!/usr/bin/env zsh

# nix-instantiate --eval --json -E 'builtins.attrNames (import <darwin> {}).config.homebrew.masApps' | \
#     jq -r '.[]' | \
#     while read -r app; do
#         echo -n "$app = "
#         osascript -e "id of app \"$app\"" 2>/dev/null || echo "NOT FOUND"
#     done

nix-instantiate --eval --strict --json -E '(import <darwin> {}).config.homebrew.masApps' | \
    jq -r 'keys[]' | \
    while read -r app; do
        echo -n "$app = "

        id=$(osascript -e "id of app \"$app\"" 2>/dev/null)

        if [ -z "$id" ]; then
            app_path=$(find /Applications -maxdepth 1 -name "${app}*" -print -quit)
            if [ -n "$app_path" ]; then
                id=$(mdls -name kMDItemCFBundleIdentifier -r "$app_path")
            else
                echo "NOT FOUND"
                continue
            fi
        else
            app_path=$(mdfind "kMDItemCFBundleIdentifier == \"$id\"")
        fi

        ids=$(find "$app_path" -name "*.app" -exec mdls -name kMDItemCFBundleIdentifier -r {} \;)
        running=$(osascript -e "application id \"$id\" is running")
        echo "$id : $app_path : $ids : $running"
    done

