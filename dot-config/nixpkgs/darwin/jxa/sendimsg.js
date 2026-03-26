#!/usr/bin/osascript -l JavaScript

const app = Application.currentApplication();
app.includeStandardAdditions = true;
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
  if (argv.length < 2) {
    console.log(
      'Usage: sendimsg.js <recipient_handle> "<msgline0>" "<msgline1>" ...\n   Each message line is on a new line',
    );
    $.exit(1);
  }

  const Messages = Application("Messages");
  // Test that iMessage service is enabled
  const iMessageService = Messages.accounts().find((s) => {
    try {
      return s.enabled() && s.serviceType() === "iMessage";
    } catch (e) {
      return false;
    }
  });
  if (!iMessageService) {
    // No iMessage Service - just get out as we cannot send iMessage
    console.log("==============");
    console.log(new Date());
    console.log("iMessage service is not enabled - cannot send iMessage");
    app.displayNotification("Cannot send iMessage", {
      withTitle: "iMessage service is not enabled",
    });
    $.exit(1);
  }

  // Wait for IP address to be up before trying to send iMessage
  let currentIP = "";
  let networkActive = false;
  for (let i = 0; i < 30; i++) {
    currentIP = app.systemInfo().ipv4Address;
    if (
      currentIP &&
      currentIP != "127.0.0.1" &&
      !currentIP.startsWith("169.254")
    ) {
      networkActive = true;
      break;
    }
    delay(2); // Wait 2 seconds before retrying
  }
  if (!networkActive) {
    console.log("==============");
    console.log(new Date());
    console.log(
      `Network not yet available - Cannot send iMessage from IP address ${currentIP}`,
    );
    app.displayNotification(
      `Cannot send iMessage from IP address ${currentIP}`,
      { withTitle: "Network not yet available" },
    );
    $.exit(1);
  } else {
    const person = Messages.participants
      .whose({ handle: argv[0] })()
      .find((p) => p.account().serviceType() === "iMessage");
    if (person) {
      var msgText = argv.slice(1).join("\n");
      Messages.send(msgText, { to: person });
    } else {
      console.log("==============");
      console.log(new Date());
      let msg = `iMessage recipient ${argv[0]} not found - Cannot send iMessage`;
      console.log(msg);
      app.displayNotification(msg, {
        withTitle: "iMessage recipient not found",
      });
      $.exit(1);
    }
  }
}
