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
    console.log("Usage: reqCloseApp.js <appBundleId>\n");
    $.exit(1);
  }

  const bundleId = argv[0];

  const app = Application.currentApplication();
  app.includeStandardAdditions = true;

  const sys = Application("System Events");

  // Force evaluation of the process list immediately
  const appProc = sys
    .processes()
    .filter((p) => p.bundleIdentifier() == bundleId)[0];
  if (appProc) {
    try {
      const pid = appProc.unixId();
      const oldApp = Application(pid);

      const runningVersion = oldApp.version();

      const installedPath = app.doShellScript(
        `mdfind kMDItemCFBundleIdentifier = "${bundleId}"`,
      );

      const installedVersion = app.doShellScript(
        `/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${installedPath}/Contents/Info.plist"`,
      );

      const response = app.displayDialog(
        `New version ${installedVersion} of ${appProc.name()} was installed.\n\nClose current app version ${runningVersion}?`,
        {
          buttons: ["Yes", "No"],
          withIcon: "caution",
        },
      );
      if (response.buttonReturned === "Yes") {
        oldApp.quit();
        while (sys.processes.whose({ bundleIdentifier: bundleId }).length > 0) {
          delay(0.2);
        }
        Application(bundleId).activate();
      }
    } catch (e) {
      console.log(`Error is: ${e.message}`);
    }
  }
}
