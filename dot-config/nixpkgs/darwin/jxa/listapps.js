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
    var procArray = sys.processes().map(p => {
        return {
            name: p.name(),
            bundleId: p.bundleIdentifier(),
            dispName: p.displayedName(),
            shortName: p.shortName()
            // props: p.properties()
        };
    });

    console.log(JSON.stringify(procArray, null, 2));
}
