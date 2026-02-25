#!/usr/bin/osascript -l JavaScript

// Redo console.log function to write to stdout
// By default, JXA console.log writes to stderr
console.log = function(message) {
    ObjC.import('Foundation');
    var str = $.NSString.alloc.initWithString(String(message) + "\n");
    var data = str.dataUsingEncoding($.NSUTF8StringEncoding);
    $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
};

function run(argv) {
    const sys = Application('System Events');

    // Force evaluation of the process list immediately
    const allProcs = sys.processes();
    const procArray = [];

    // Loop to get properties
    allProcs.forEach(p => {
        try {
            // Call the properties as functions to fetch them
            procArray.push({
                name: p.name() || "Unknown",
                bundleId: p.bundleIdentifier() || "Unknown",
                dispName: p.displayedName() || "Unknown",
                shortName: p.shortName() || "Unknown"
            });
        } catch (e) {
            console.log(`Error in allProcs iteration: ${e?.message}`);
        }
    });

    console.log(JSON.stringify(procArray, null, 2));
}
