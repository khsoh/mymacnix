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

    var app = Application.currentApplication();
    app.includeStandardAdditions = true;

    // 2. Run the shell script and store the JSON string result
    var jsonString = app.doShellScript("system_profiler SPDisplaysDataType -json");

    // 3. Parse the JSON string into a native JavaScript object
    var jsonRecord = JSON.parse(jsonString);

    // 4. Access the specific property (SPDisplaysDataType)
    var spdisplays = jsonRecord.SPDisplaysDataType;

    // To get the number of displays (counting items in the array)
    var displayCount = spdisplays.length;

    if (displayCount > 0) {
        // This segment for handling multiple displays
        const fdispdrv = spdisplays[0].spdisplays_ndrvs.find(d => d?.spdisplays_main == "spdisplays_yes");
        if (!fdispdrv) {
            return;
        }
        const dispres = fdispdrv._spdisplays_resolution.match(/(\d+)\s+x\s+(\d+)/);
        botrx = parseInt(parseInt(dispres[1]) * XFRACTION);
        botry = parseInt(parseInt(dispres[2]) * YFRACTION);
        const theMenuBarHeight = $.NSMenu.menuBarHeight;

        TOPLEFTY = theMenuBarHeight + 1 + TOPLEFTY;
        const Finder = Application("Finder");

        // 2. Get the bounds [left, top, right, bottom]
        const terminalSize = Finder.desktop.window.bounds();
    } else {
        // 1. Initialize Finder
        const Finder = Application("Finder");

        // 2. Get the bounds { x, y, width, height }
        const terminalSize = Finder.desktop.window.bounds();

        // 3. Perform the calculations
        TOPLEFTX = terminalSize.x;
        TOPLEFTY = Math.floor(terminalSize.y + 1 + TOPLEFTY);
        botrx    = Math.floor(terminalSize.width * XFRACTION);
        botry    = Math.floor(terminalSize.height * YFRACTION);
    }

    const XID = Application(XAPP).id();
    var sys = Application('System Events');
    var xproc = sys.processes.whose({ bundleIdentifier: XID });
    if (xproc.length == 0 || xproc[0].windows.length == 0) {
        // Cannot find process or its window
        return;
    }
    xproc[0].windows[0].position = [TOPLEFTX, TOPLEFTY];
    xproc[0].windows[0].size = [botrx, botry];
}

