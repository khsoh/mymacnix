#!/usr/bin/osascript -l JavaScript

// 1. Access the Objective-C bridge
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// 2. secrets.json
const secretsPath = "~/.config/nix/secrets.json";

// 3. Use NSString to expand the tilde to a full POSIX path
const fullPath = $(secretsPath).stringByExpandingTildeInPath.js;


const secrets = JSON.parse(app.read(Path(fullPath)));

console.log(`iMessage receiver: ${secrets.iMessageID}`);

const Messages = Application('Messages');
const person = Messages.participants.whose({ handle: secrets.iMessageID });
if (person.length > 0) {
    Messages.send("hello world", { to: person[0] });
} else {
    console.log("Cannot find person to send to");
}
