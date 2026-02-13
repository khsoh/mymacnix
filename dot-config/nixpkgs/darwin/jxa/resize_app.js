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

    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    var bootTime = app.doShellScript('sysctl -n kern.boottime | awk \'{print $4}\' | tr -d ,');
    var now = 0;
    var secondsSinceBoot = 0;
    var xproc = null;
    var found = false;

    const XID = Application(XAPP).id();
    var sys = Application('System Events');
    while (secondsSinceBoot < 150) {
        xproc = sys.processes.whose({ bundleIdentifier: XID });

        now = Math.floor(Date.now() / 1000);
        secondsSinceBoot = now - parseInt(bootTime);
        console.log(`Uptime : ${secondsSinceBoot} seconds`);

        if (xproc.length == 0) {
            // Cannot find process
            console.log(`${new Date()}: Failed to find process for app ${XAPP} with id ${XID}`);
            delay(10);
            continue;
        }
        if (xproc[0].windows.length == 0) {
            // Cannot find its window
            console.log(`${new Date()}: Failed to find windows for app ${XAPP} with id ${XID}`);
            delay(10);
            continue;
        }
        found = true;
        break;
    }
    if (!found) {
        return;
    }
    xproc[0].windows[0].position = [TOPLEFTX, TOPLEFTY];
    xproc[0].windows[0].size = [botrx, botry];
    console.log(`${new Date()}: Found ${XAPP} process to resize on primary display to ${botrx} x ${botry} pixels at ${TOPLEFTX}, ${TOPLEFTY}`);
}

