import XCTest
@testable import Judo

import SwiftJS
import MiscKit

final class JudoTests: XCTestCase {
    let fm = FileManager.default

//    func testInitDeinit() throws {
//        let context = ScriptContext()
//    }

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

        let mount = "/sys"

        try ctx.installBrowserFS(mountPoint: "\(mount)")

        XCTAssertEqual("[object Object]", try ctx.eval(script: "new fs.FS.Stats()").stringValue)
        XCTAssertEqual("false", try ctx.eval(script: "new fs.FS.Stats().isDirectory()").stringValue)

        func fstat(path: String, mnt: Bool) throws -> ScriptObject {
            try ctx.eval(script: "fs.statSync('\(mnt ? mount : "")\(path)').isDirectory()")
        }

        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('/').isDirectory()").boolValue)
        XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('/xyzxyz').isDirectory()")) // ENOENT: No such file or directory., \'/xyzxyz\'

        // this will return our own Stats impl…
        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)').isDirectory()").boolValue)
        XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('\(mount)/xyzxyz').isDirectory()")) // ENOENT: No such file or directory., \'/xyzxyz\'

        XCTAssertEqual(false, try ctx.eval(script: "fs.statSync('\(mount)/etc/').isFile()").boolValue)
        //XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)/etc/').isDirectory()").boolValue)

        XCTAssertEqual(false, try ctx.eval(script: "fs.statSync('\(mount)/etc/hosts').isDirectory()").boolValue)
        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)/etc/hosts').isFile()").boolValue)


        // write a random string to a temporary file, then read it back and see if it works

        // TODO: test async/await like:
        /*
            async function xxx() {
                await fs.writeFile('\(path)', '\(string)');
                return await fs.readFile('/sys/tmp/test.txt');
            };
            await xxx();
        */

        func roundtripFile(sync: Bool, path: String, string: String, encoding: String) throws -> ScriptObject {
            if sync {
                return try ctx.eval(script: """
                (function() {
                    fs.writeFileSync('\(path)', '\(string)', '\(encoding)');
                    const contentString = fs.readFileSync('\(path)', '\(encoding)');
                    if (typeof contentString !== 'string') {
                        throw "file contents have wrong type: " + typeof contents;
                    }
                    return contentString;
                })();
                """)
            } else {
                return try ctx.eval(script: """
                (function() {
                    let contentString = '';
                    let error = null;
                    fs.writeFile('\(path)', '\(string)', '\(encoding)', function(err) {
                        if (err != null) { throw err; }
                        fs.readFile('\(path)', '\(encoding)', function(err, contents) {
                            if (err != null) { throw err; }
                            if (typeof contents !== 'string') {
                                throw "file contents have wrong type: " + typeof contents;
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
        }

        for sync in [true, false] { // try with both the sync and non-sync APIs
            let uniq = UUID().uuidString
            for enc in ["ascii", "utf-8"] { // , "utf-16"] { // utf16 fails on linux!
                let randomString = (1...Int.random(in: 1...10)).map({ _ in UUID().uuidString }).joined(separator: "")
                let relpath = "/tmp/testfile-\(uniq)-\(enc).txt"
                let path = "\(mount)\(relpath)"

                XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('\(path)').isFile()"))

                XCTAssertEqual(randomString, try roundtripFile(sync: sync, path: path, string: randomString, encoding: enc).stringValue)

                XCTAssertNoThrow(try ctx.eval(script: "fs.statSync('\(path)').isFile()"))
                XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(path)').isFile()").boolValue)

                XCTAssertTrue(fm.fileExists(atPath: relpath))
                let attrs = try fm.attributesOfItem(atPath: relpath)

                do { // check that stat's size is correct
                    let size = try XCTUnwrap(attrs[.size] as? Int)
                    let jsize = try XCTUnwrap(try ctx.eval(script: "fs.statSync('\(path)').size").doubleValue)

                    XCTAssertEqual(size, .init(jsize))
                }

                do { // check that stat's mtime is (about) correct
                    let mtime = try XCTUnwrap(attrs[.modificationDate] as? Date)
                    let jmtime = try XCTUnwrap(try ctx.eval(script: "fs.statSync('\(path)').mtime").dateValue)

                    XCTAssertEqual(mtime.timeIntervalSince1970, jmtime.timeIntervalSince1970, accuracy: 0.1)
                }
            }
        }
    }
}
