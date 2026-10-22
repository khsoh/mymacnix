{
  config,
  osConfig,
  pkgs,
  lib,
  user,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  secretsjsonPath = "${config.xdg.configHome}/nixpkgs/secrets/user/${config.home.username}/secrets.json.age";
in
builtins.seq [ config osConfig pkgs user lib ] {
  launchd.agents.monitor-wsgx = {
    enable = true;
    config = {
      Label = "org.nixos.hm.monitor-wsgx";
      RunAtLoad = true;
      KeepAlive = false;
      StartInterval = 60 * 60 * 2;
      StandardOutPath = "${homeDir}/log/org.nixos.hm.monitor-wsgx-Out.log";
      StandardErrorPath = "${homeDir}/log/org.nixos.hm.monitor-wsgx-Error.log";
      ProgramArguments = [
        "${pkgs.zsh}/bin/zsh"
        "-l"
        "-c"
        # zsh
        ''
          ICLOUD_DIR="${homeDir}/Library/Mobile Documents/com~apple~CloudDocs";

          # Check if iCloud drive exists
          if [[ ! -d "$ICLOUD_DIR" ]]; then
            >&2 date
            >&2 echo "iCloud Drive not yet mounted"
            >&2 echo "==================="
            exit 0
          fi

          WSGX_FILE="$ICLOUD_DIR/WSGX/non-sim.mobileconfig";
          if [[ ! -f "$WSGX_FILE" ]]; then
            >&2 date
            >&2 echo "Warning: Wireless@SGx Profile file absent from WSGX folder in iCloud drive"
            >&2 echo "==================="
            /usr/bin/osascript -l JavaScript <<'EOF_javascript'
              const app = Application.currentApplication();
              app.includeStandardAdditions = true;

              let response;
              try {
                // Display the alert
                response = app.displayAlert("Wireless@SGx not installed", {
                  message: "Click OK to download Wireless@SGx mobile profile for non-SIM host",
                  buttons: ["Cancel", "OK"],
                  defaultButton: "OK"
                });
              } catch (e) {
                // Handles user clicking "Cancel" which throws an error in JXA
                response = { buttonReturned: "Cancel" };
              }

              // Handle user response
              if (response.buttonReturned === "OK") {
                app.openLocation("https://go.gov.sg/wsgx");
              }
              void(0);
          EOF_javascript
            exit 0
          fi

          # Get the signing time
          SIGNTIME=$(/usr/bin/openssl cms -inform DER -in "$WSGX_FILE" -cmsout -print|grep -A 2 "signingTime"|grep "UTCTIME" | ${pkgs.gnused}/bin/sed 's/.*UTCTIME://' | tr -d '\n')
          EXPIRE_DATE="$(date -j -v+12m -f "%b %d %H:%M:%S %Y %Z" "$SIGNTIME" "+%b %d %Y")"
          WARN_EPOCH="$(date -j -v +11m -v +10d -f "%b %d %H:%M:%S %Y %Z" "$SIGNTIME" "+%s")"

          # Check if need to update the profile
          if [[ "$(date "+%s")" -gt "$WARN_EPOCH" ]]; then
            >&2 date
            >&2 echo "Warning: Wireless@SGx Profile will expire on $EXPIRE_DATE"
            >&2 echo "==================="
            /usr/bin/osascript -l JavaScript <<'EOF_javascript'
              const app = Application.currentApplication();
              app.includeStandardAdditions = true;

              let response;
              try {
                // Display the alert
                response = app.displayAlert("Wireless@SGx profile expiring soon", {
                  message: "Click OK to download Wireless@SGx mobile profile for non-SIM host",
                  buttons: ["Cancel", "OK"],
                  defaultButton: "OK"
                });
              } catch (e) {
                // Handles user clicking "Cancel" which throws an error in JXA
                response = { buttonReturned: "Cancel" };
              }

              // Handle user response
              if (response.buttonReturned === "OK") {
                app.openLocation("https://go.gov.sg/wsgx");
              }
              void(0);
          EOF_javascript
            exit 0
          fi

          # Verify the profile
          TMPFILE=$(/usr/bin/mktemp /tmp/wsgx.XXXXXX)
          TMPCFG="$TMPFILE".mobileconfig
          rm -f "$TMPFILE"

          if /usr/bin/openssl smime -inform DER -verify -in "$WSGX_FILE" -noverify >"$TMPCFG" 2>/dev/null; then
            PAYLOAD_JSON=$(/usr/bin/plutil -convert json -o - "$TMPCFG")
            PAYLOAD_ID=$(${pkgs.jq}/bin/jq -r ".PayloadIdentifier" <<<"$PAYLOAD_JSON")
            PAYLOAD_UUID=$(${pkgs.jq}/bin/jq -r ".PayloadUUID" <<<"$PAYLOAD_JSON")
            PAYLOAD_VERSION=$(${pkgs.jq}/bin/jq -r ".PayloadVersion" <<<"$PAYLOAD_JSON")

            INSTALLED_JSON=$(/usr/bin/profiles show -output stdout-xml | \
                /usr/bin/plutil -convert json -o - - | \
                ${pkgs.jq}/bin/jq -c --arg id "$PAYLOAD_ID" \
                '.[env.USER][]? | select (.ProfileIdentifier == $id)')
            INSTALLED_UUID=$(${pkgs.jq}/bin/jq -r '.ProfileUUID' <<< "$INSTALLED_JSON")
            INSTALLED_VERSION=$(${pkgs.jq}/bin/jq -r '.ProfileVersion' <<< "$INSTALLED_JSON")

            if [[ "$PAYLOAD_UUID" == "$INSTALLED_UUID" ]]; then
              ANNOUNCEMENT="ANNOUNCE: $(date -j '+Week %V %d %b %Y')"
              GREPANNOUNCE="ANNOUNCE: $(date -j '+Week %V .*%Y$')"
              if ! /usr/bin/grep -q "$GREPANNOUNCE" "${config.launchd.agents.monitor-wsgx.config.StandardOutPath}"; then
                EXIT_STATUS=0
                ${lib.optionalString (builtins.pathExists secretsjsonPath)
                  # zsh
                  ''
                    IMSGID=$(${pkgs.jq}/bin/jq -r '.iMessageID' ${config.age.secrets."secrets.json".path} 2>/dev/null)
                    if [[ -n "$IMSGID" ]]; then
                      LOCALHOSTNAME=$(/usr/sbin/scutil --get LocalHostName)
                      "${homeDir}/${config.xdg.configFile.sendimsg.target}" $IMSGID "Wireless@SGx profile is still valid on $LOCALHOSTNAME - will expire on $EXPIRE_DATE"
                      EXIT_STATUS=$?
                    fi
                  ''
                }
                if [[ $EXIT_STATUS -eq 0 ]]; then
                  echo "$ANNOUNCEMENT"
                  echo "Wireless@SGx profile is still valid - will expire on $EXPIRE_DATE"
                fi
              fi
            else
              export TMPCFG
              /usr/bin/osascript -l JavaScript <<'EOF_javascript'
                // 1. Get the environment variable
                const app = Application.currentApplication();
                app.includeStandardAdditions = true;
                const tmpCfg = app.systemAttribute("TMPCFG");

                // 2. Display the alert
                let response;
                try {
                  response = app.displayAlert("Install Wireless@SGx profile", {
                    message: "Click OK to install Wireless@SGx mobile profile for non-SIM host",
                    buttons: ["Cancel", "OK"],
                    defaultButton: "OK"
                  });
                } catch (e) {
                  // Handles user clicking "Cancel" which throws an error in JXA
                  response = { buttonReturned: "Cancel" };
                }

                // 3. Check user response
                if (response.buttonReturned === "OK") {
                  // Stage the mobileconfig file
                  app.doShellScript(`open "''${tmpCfg}"`);

                  // Open System Settings to the Profiles pane
                  app.doShellScript(
                    'open "x-apple.systempreferences:com.apple.Profiles-Settings.extension"',
                  );
                }
          EOF_javascript
            fi
          else
            >&2 date
            >&2 echo "Warning: Wireless@SGx Profile file is CORRUPTED: $WSGX_FILE"
            >&2 echo "==================="
            /usr/bin/osascript -l JavaScript <<'EOF_javascript'
              const app = Application.currentApplication();
              app.includeStandardAdditions = true;

              let response;
              try {
                // Display the alert
                response = app.displayAlert("Wireless@SGx profile corrupted", {
                  message: "Click OK to download Wireless@SGx mobile profile for non-SIM host",
                  buttons: ["Cancel", "OK"],
                  defaultButton: "OK"
                });
              } catch (e) {
                // Handles user clicking "Cancel" which throws an error in JXA
                response = { buttonReturned: "Cancel" };
              }

              // Handle user response
              if (response.buttonReturned === "OK") {
                app.openLocation("https://go.gov.sg/wsgx");
              }
              void(0);
          EOF_javascript
          fi
          rm -f "$TMPCFG"
        ''
      ];
    };
  };
}
