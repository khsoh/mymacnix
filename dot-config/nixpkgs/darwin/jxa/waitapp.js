#!/usr/bin/osascript -l JavaScript

// Redo console.log function to write to stdout
// By default, JXA console.log writes to stderr
console.log = function(message) {
    ObjC.import('Foundation');
    var str = $.NSString.alloc.initWithString(String(message) + "\n");
    var data = str.dataUsingEncoding($.NSUTF8StringEncoding);
    $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
};

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

ObjC.import('AppKit');

function run(argv) {
    if (argv.length == 0) {
        return;
    }
    const XAPP = argv[0];

    const sys = Application('System Events');
    if (!waitForGUI(sys)) {
        // Timed out waiting for gui
        console.log(`${new Date()}: Timed out waiting for GUI`);
        return;
    }

    var app = Application.currentApplication();
    app.includeStandardAdditions = true;

    const installedApp = app.doShellScript(`mdfind "kMDItemFSName == '${XAPP}' && kMDItemKind == 'Application'"`);
    if (!installedApp) {
        return;
    }

    try {
        const XID = Application(XAPP).id();
        const endTime = new Date();
        endTime.setSeconds(endTime.getSeconds() + 60);
        do {
            const xproc = sys.processes.whose({ bundleIdentifier: XID })();
            if (xproc.length > 0) {
                return;
            }
            delay(1);
        } while (new Date() < endTime);

        console.log(`${XAPP} is not executing`);
    } catch (e) {
        console.log(`ERROR in waiting for ${XAPP}: ${e?.message}`);
    }
}

