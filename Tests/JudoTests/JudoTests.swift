import XCTest
@testable import Judo

import SwiftJS
import MiscKit

final class JudoTests: XCTestCase {
    func testCallbackFunctions() throws {
        let context = ScriptContext()

        context.installConsole()
        try context.eval(script: "console.log('test');")

        context.installTimer()
        try context.eval(script: "setTimeout(function() { console.log('call', 'back'); }, 2);")

        context.installExports(require: true)
        try context.eval(script: "exports.x")
    }

    func testFileBrowser() throws {
        let ctx = ScriptContext()

        try ctx.trying { ctx.installConsole() }
        try ctx.trying { ctx.installTimer() }

        // must not have require for BrowserFS to install correctly
        // try ctx.trying { ctx.installExports(require: false) }

        try ctx.installBrowserFS(mountPoint: "/sys/")

        // write a random string to a temporary file, then read it back and see if it works

        // TODO: test async/await like:
        /*
            async function xxx() {
                await fs.writeFile('\(path)', '\(string)');
                return await fs.readFile('/sys/tmp/test.txt');
            };
            await xxx();
        */

        func roundtripFile(path: String, string: String, encoding: String) throws -> ScriptObject {
            try ctx.eval(script: """
                (function() {
                    let contentString = '';
                    let error = null;
                    fs.writeFile('\(path)', '\(string)', '\(encoding)', function(err) {
                        if (err != null) { throw err; }
                        fs.readFile('\(path)', '\(encoding)', function(err, contents) {
                            if (err != null) { throw err; }
                            if (typeof contents !== 'string') {
                                throw "Written file has wrong type: " + typeof contents;
                            } else {
                                contentString = contents;
                                //console.info("initialized virtual file system:", contents.toString());
                            }
                        });
                    });
                    if (error != null) { throw error; }
                    return contentString;
                })();
                """)
        }

        for enc in ["ascii", "utf-8", "utf-16"] {
            let randomString = UUID().uuidString
            XCTAssertEqual(randomString, try roundtripFile(path: "/sys/tmp/file-\(enc).txt", string: randomString, encoding: enc).stringValue)
        }
    }
}
