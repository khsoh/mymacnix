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
ObjC.import('CoreGraphics');

function run(argv) {
    const XAPP = argv.length == 0 ? "Terminal" : argv[0];
    var XFRACTION = argv.length <= 1 ? 0.5 : parseFloat(argv[1]);
    var YFRACTION = argv.length <= 2 ? 1.0 : parseFloat(argv[2]);
    var TOPLEFTX = 0;
    var TOPLEFTY = 0;
    var botrx = 0;
    var botry = 0;

    // Define max displays to fetch
    var maxDisplays = 32;
    var activeDisplays = new Uint32Array(maxDisplays); // JXA's native way to handle pointers
    var displayCount = Ref();
    var mainID = 0;

    // Pass references to the native C function
    // This populates 'activeDisplays' with an array of IDs
    $.CGGetActiveDisplayList(maxDisplays, activeDisplays, displayCount);

    for (var i = 0; i < displayCount[0]; i++) {
        var dID = activeDisplays[i];
        if ($.CGDisplayIsMain(dID) != 1) {
            continue;
        }
        mainID = dID;
        botrx = parseInt($.CGDisplayPixelsWide(dID) * XFRACTION);
        botry = parseInt($.CGDisplayPixelsHigh(dID) * YFRACTION);
    }
    if (botrx == 0) {
        console.log("Failed to find monitor");
        return;
    }

    const XID = Application(XAPP).id();
    var sys = Application('System Events');
    var xproc = sys.processes.whose({ bundleIdentifier: XID });
    if (xproc.length == 0) {
        // Cannot find process
        console.log(`${new Date()}: Failed to find process for app ${XAPP} with id ${XID}`);
        return;
    }
    if (xproc[0].windows.length == 0) {
        // Cannot find its window
        console.log(`${new Date()}: Failed to find windows for app ${XAPP} with id ${XID}`);
        return;
    }
    xproc[0].windows[0].position = [TOPLEFTX, TOPLEFTY];
    xproc[0].windows[0].size = [botrx, botry];
    console.log(`${new Date()}: Found ${XAPP} process to resize on display ${mainID} to ${botrx} x ${botry} pixels at ${TOPLEFTX}, ${TOPLEFTY}`);
}

