#!/usr/bin/osascript -l JavaScript

// Redo console.log function to write to stdout
// By default, JXA console.log writes to stderr
console.log = function(message) {
    ObjC.import('Foundation');
    var str = $.NSString.alloc.initWithString(String(message) + "\n");
    var data = str.dataUsingEncoding($.NSUTF8StringEncoding);
    $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
};

ObjC.import('AppKit');

function run(argv) {
    if (argv.length == 0) {
        return;
    }
    const XAPP = argv[0];
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
            var sys = Application('System Events');
            const xproc = sys.processes.whose({ bundleIdentifier: XID });
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

