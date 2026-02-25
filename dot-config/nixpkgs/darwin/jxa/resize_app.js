#!/usr/bin/osascript -l JavaScript

// Redo console.log function to write to stdout
// By default, JXA console.log writes to stderr
// console.log = function(message) {
//     ObjC.import('Foundation');
//     var str = $.NSString.alloc.initWithString(String(message) + "\n");
//     var data = str.dataUsingEncoding($.NSUTF8StringEncoding);
//     $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
// };

ObjC.import('AppKit');
ObjC.import('Foundation');

// wait for Desktop to be ready
function waitForGUI(sys) {
    for (let attempts = 0; attempts < 30; attempts++) {
        try {
            // Check for Dock or Finder as a GUI readiness proxy
            if (sys.processes["Finder"].exists()) {
                return true;
            }
        } catch (e) {
            // System Events might not be responding yet
        }
        delay(2);
    }
    return false;
}

function run(argv) {
    const XAPP = argv.length == 0 ? "Terminal" : argv[0];
    var XFRACTION = argv.length <= 1 ? 0.5 : parseFloat(argv[1]);
    var YFRACTION = argv.length <= 2 ? 1.0 : parseFloat(argv[2]);
    var TOPLEFTX = 0;
    var TOPLEFTY = 0;
    var botrx = 0;
    var botry = 0;

    // Define max displays to fetch
    const screens = $.NSScreen.screens.js;

    // Primary display is always at index 0
    botrx = parseInt(screens[0].frame.size.width * XFRACTION);
    botry = parseInt(screens[0].frame.size.height * YFRACTION);

    if (botrx == 0) {
        console.log("Failed to find monitor");
        return;
    }

    const sys = Application('System Events');
    if (!waitForGUI(sys)) {
        // Timed out waiting for gui
        console.log(`${new Date()}: Timed out waiting for GUI`);
        return;
    }

    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    var bootTime = app.doShellScript('sysctl -n kern.boottime | awk \'{print $4}\' | tr -d ,');
    console.log(`${new Date(bootTime * 1000)}: System started`);

    var xproc = null;
    var attempts = 0;
    var targetWindow = null;
    var wins = null;
    const maxAttempts = 6;  // 6 times max
    const XID = Application(XAPP).id();
    while (attempts < maxAttempts && targetWindow == null) {
        attempts++;

        xproc = sys.processes.whose({ bundleIdentifier: XID })();
        if (xproc.length == 0) {
            // Cannot find process
            console.log(`${new Date()}: Failed to find process for app ${XAPP} with id ${XID}`);
            delay(10);
            continue;
        }

        wins = xproc[0].windows();

        if (wins.length == 0) {
            // Cannot find its window
            console.log(`${new Date()}: Failed to find windows for app ${XAPP} with id ${XID}`);
            delay(10);
            continue;
        }

        if (wins[0].exists()) {
            targetWindow = wins[0];
            break;
        }
    }

    if (targetWindow == null) {
        // Cannot find window
        return;
    }
    targetWindow.position = [TOPLEFTX, TOPLEFTY];
    targetWindow.size = [botrx, botry];
    console.log(`${new Date()}: Found ${XAPP} process to resize on primary display to ${botrx} x ${botry} pixels at ${TOPLEFTX}, ${TOPLEFTY}`);
}

