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

// 4. Find the person whose account can receive iMessage
const person = Messages.participants.whose({ handle: secrets.iMessageID })().
    find(p => p.account().serviceType() == 'iMessage');

if (person) {
    Messages.send("hello world", { to: person });
} else {
    console.log("Cannot find person to send to");
}
