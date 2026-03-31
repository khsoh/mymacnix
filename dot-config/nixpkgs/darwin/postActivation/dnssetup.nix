{
  config,
  pkgs,
  lib,
  ...
}:
{
  system.activationScripts.postActivation.text = lib.mkBefore ''
    # shellcheck disable=SC2034
    ESC="\x1b[0m"
    # shellcheck disable=SC2034
    BOLD="\x1b[1m"
    # shellcheck disable=SC2034
    RED="\x1b[31m"
    # shellcheck disable=SC2034
    GREEN="\x1b[32m"
    # shellcheck disable=SC2034
    YELLOW="\x1b[33m"
    # shellcheck disable=SC2034
    BLUE="\x1b[34m"
    # shellcheck disable=SC2059
    printf "''${GREEN}''${BOLD}======== DNS Setup ========''${ESC}\n"
    CFGFILE="${config.environment.etc."mobileconfig/quad9_secured_dns.mobileconfig".source}"
    TMPFILE=$(/usr/bin/mktemp /tmp/quad9.XXXXXX)
    TMPCFG="$TMPFILE".mobileconfig
    rm -f "$TMPFILE"


    ### Validate the configuration file and save the clean config into temporary file
    if /usr/bin/openssl smime -inform DER -verify -in "$CFGFILE" -noverify >"$TMPCFG" 2>/dev/null; then
      PAYLOAD_JSON=$(/usr/bin/plutil -convert json -o - "$TMPCFG")
      PAYLOAD_ID=$(${pkgs.jq}/bin/jq -r ".PayloadIdentifier" <<<"$PAYLOAD_JSON")
      PAYLOAD_UUID=$(${pkgs.jq}/bin/jq -r ".PayloadUUID" <<<"$PAYLOAD_JSON")
      PAYLOAD_VERSION=$(${pkgs.jq}/bin/jq -r ".PayloadVersion" <<<"$PAYLOAD_JSON")
      TARGET_DNS=$(${pkgs.jq}/bin/jq -r '.PayloadContent[0].DNSSettings.ServerAddresses | join(" ")' <<<"$PAYLOAD_JSON")

      INSTALLED_JSON=$(/usr/bin/profiles show -output stdout-xml | \
        /usr/bin/plutil -convert json -o - - | \
        ${pkgs.jq}/bin/jq -c --arg id "$PAYLOAD_ID" \
        '.["_computerlevel"][]? | select (.ProfileIdentifier == $id)')
      INSTALLED_UUID=$(${pkgs.jq}/bin/jq -r '.ProfileUUID' <<< "$INSTALLED_JSON")
      INSTALLED_VERSION=$(${pkgs.jq}/bin/jq -r '.ProfileVersion' <<< "$INSTALLED_JSON")

      if [ "$PAYLOAD_UUID" != "$INSTALLED_UUID" ] ; then
        if [ -n "$INSTALLED_UUID" ]; then
          # shellcheck disable=SC2059
          printf "''${BLUE}''${BOLD}==>''${ESC} Removing old Quad9 Secured DNS profile before installing new profile\n"
          /usr/bin/profiles remove -identifier "$PAYLOAD_ID"
          # shellcheck disable=SC2059
          printf "''${BLUE}''${BOLD}==>''${ESC} Removed old Quad9 Secured DNS profile UUID $INSTALLED_UUID version $INSTALLED_VERSION\n"
        fi
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}==>''${ESC} Installing Profile UUID $PAYLOAD_UUID version $PAYLOAD_VERSION for Quad9 Secured DNS\n"
        /usr/bin/open "x-apple.systempreferences:com.apple.preferences.configurationprofiles" "$CFGFILE"
        # shellcheck disable=SC2059
        printf "''${RED}"
        read -n 1 -s -r -p "...Press any key after you have installed the profile..."
        # shellcheck disable=SC2059
        printf "''${ESC}"
        echo ""
      fi

      ## Check the DNS setup
      # 1. Get the list of all network services
      service_order=$(networksetup -listnetworkserviceorder)
      TOUCHED=false

      networksetup -listallnetworkservices | grep -v "\*" | while read -r service; do
        # Find the device ID (en0, en1, etc.)
        device=$(echo "$service_order" | grep -A 1 "$service" | grep -oE "en[0-9]+" || :)

        if [[ -n "$device" ]]; then
          # Check if interface is 'active' (online)
          if ifconfig "$device" 2>/dev/null | grep -q "status: active" && ifconfig "$device" | grep -q "inet "; then
            # Get current DNS (v4 and v6 are returned together)
            current_dns=$(networksetup -getdnsservers "$service" | xargs 2>/dev/null || :)
              
            # Compare current to target
            if [[ "$current_dns" != "$TARGET_DNS" ]]; then
              # shellcheck disable=SC2059
              printf "''${BLUE}''${BOLD}==>''${ESC} Updating $service ($device): DNS is currently ($current_dns)\n"
                  
              # Single command for both IPv4 and IPv6
              # shellcheck disable=SC2086
              networksetup -setdnsservers "$service" $TARGET_DNS
              TOUCHED=true
            else
              # shellcheck disable=SC2059
              printf "''${BLUE}''${BOLD}==>''${ESC} DNS for $service ($device) is already setup to use Quad9.\n"
            fi
          fi
        fi
      done

      # 2. Flush cache if any change was made
      if [ "$TOUCHED" = true ]; then
        dscacheutil -flushcache
        killall -HUP mDNSResponder
        # shellcheck disable=SC2059
        printf "''${BLUE}''${BOLD}==>''${ESC} Changes applied and DNS cache flushed.\n"
      fi
    else
      ## Corrupted DNS mobileconfig file
      # shellcheck disable=SC2059
      printf "''${RED}''${BOLD}...!!!CORRUPTED mobileconfig file: $CFGFILE''${ESC}\n"
    fi
    rm -f "$TMPCFG"
  '';
}
