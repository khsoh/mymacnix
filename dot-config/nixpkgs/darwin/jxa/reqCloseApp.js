#!/usr/bin/osascript -l JavaScript

ObjC.import("stdlib");

// Redo console.log function to write to stdout
// By default, JXA console.log writes to stderr
// console.log = function (message) {
//   ObjC.import("Foundation");
//   var str = $.NSString.alloc.initWithString(String(message) + "\n");
//   var data = str.dataUsingEncoding($.NSUTF8StringEncoding);
//   $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
// };

function run(argv) {
  if (argv.length < 1) {
    console.log("Usage: reqCloseApp.js <appName>\n");
    $.exit(1);
  }

  const appName = argv[0];

  const app = Application.currentApplication();
  app.includeStandardAdditions = true;

  const sys = Application("System Events");

  // Force evaluation of the process list immediately
  const appProc = sys
    .processes()
    .filter((p) => p.name().startsWith(appName));
  if (appProc.length > 0) {
    try {
      const pid = appProc[0].unixId();
      const oldApp = Application(pid);

      const runningVersion = oldApp.version();

      const volumeName = "Macintosh HD";

      var hfsPath = appProc[0].file().path();
      var pathWithoutVolume = hfsPath.replace(new RegExp(`^${volumeName}`), "");
      var installedPath = pathWithoutVolume.replace(/:$/, "").replace(/:/g, "/");

      const installedVersion = app.doShellScript(
        `/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${installedPath}/Contents/Info.plist"`,
      );

      const response = app.displayDialog(
        `New version ${installedVersion} of ${appName} was installed.\n\nClose current app version ${runningVersion}?`,
        {
          buttons: ["Yes", "No"],
          withIcon: "caution",
        },
      );
      if (response.buttonReturned === "Yes") {
        // oldApp.quit();
        // while (sys.processes.whose({ bundleIdentifier: bundleId }).length > 0) {
        //   delay(0.2);
        // }
        // Application(bundleId).activate();
        var script = `
        pkill -f "${appName}" > /dev/null
        COUNTDOWN=30
        while pgrep -f "${appName}"; do
          ((COUNTDOWN--))
          sleep 1
        done
        FULLAPP=$(mdfind "kMDItemFSName == '${appName}.app'" | head -n1)
        [ -n "$FULLAPP" ] || FULLAPP=$(mdfind "kMDItemFSName == '${appName}*.app'" | head -n1)
        open "$FULLAPP"
        `;
        app.doShellScript(script);
      }
    } catch (e) {
      console.log(`Error is: ${e.message}`);
    }
  }
}
