import XCTest
@testable import Judo

import SwiftJS
import MiscKit
import BricBrac

final class JudoTests: XCTestCase {
    let res = Bundle.module.resourceURL
    let fm = FileManager.default

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
            var encodings = ["ascii", "utf-8"]
            #if !os(Linux)
            encodings.append(contentsOf: ["utf-16", "utf-32"]) // utf16 & 32 fails on linux!
            #endif

            for enc in encodings {
                let randomString = (1...Int.random(in: 1...10)).map({ _ in UUID().uuidString }).joined(separator: "")
                let relpath = "/tmp/testfile-\(uniq)-\(enc).txt"
                let path = "\(mount)\(relpath)"

                XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('\(path)').isFile()"))

                XCTAssertEqual(randomString, try roundtripFile(sync: sync, path: path, string: randomString, encoding: enc).stringValue)

                XCTAssertNoThrow(try ctx.eval(script: "fs.statSync('\(path)').isFile()"))
                XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(path)').isFile()").boolValue)

                let data = try XCTUnwrap(try ctx.eval(script: "fs.readFileSync('\(path)')").copyBytes())

                XCTAssertTrue(fm.fileExists(atPath: relpath))
                let attrs = try fm.attributesOfItem(atPath: relpath)

                do { // check that stat's size is correct
                    let size = try XCTUnwrap(attrs[.size] as? Int)
                    let jsize = try XCTUnwrap(try ctx.eval(script: "fs.statSync('\(path)').size").doubleValue)

                    XCTAssertEqual(data.count, size)
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

    func testLoadSheetJS() throws {

        let ctx = ScriptContext()

        try ctx.trying { ctx.installConsole() }
        try ctx.trying { ctx.installTimer() }
        try ctx.installBrowserFS(mountPoint: "/")
        try ctx.installSheetJS()

        XCTAssertNoThrow(try ctx.eval(script: "XLSX.read('');"))
        XCTAssertThrowsError(try ctx.eval(script: "XLSX.read(null);")) // “TypeError: null is not an object (evaluating \'f.slice\')”

        XCTAssertNoThrow(try ctx.eval(script: "fs.readFileSync('/etc/hosts');"))

        //XCTAssertNoThrow(try ctx.eval(script: "XLSX.readFile('/etc/hosts');"))

        XCTAssertTrue(try ctx.eval(script: "XLSX.utils").isObject)
        XCTAssertTrue(try ctx.eval(script: "XLSX.utils.sheet_to_json").isFunction)

        func parseSheet(data: Data, opts: SheetJS.ParsingOptions = SheetJS.ParsingOptions(type: .buffer)) throws -> ScriptObject {
            ctx["buffer"] = ScriptObject(newArrayBufferWithBytes: data, in: ctx)
            defer { ctx["buffer"] = ScriptObject(undefinedIn: ctx) }
            ctx["opts"] = try ScriptObject(json: opts.encodedString(), in: ctx)
            defer { ctx["opts"] = ScriptObject(undefinedIn: ctx) }

            let sheet = try ctx.eval(script: """
            (function() {
                const workbook = XLSX.read(buffer, opts);
                return workbook.SheetNames.map(sheetName => {
                    return {
                        sheetName: sheetName,
                        data: XLSX.utils.sheet_to_json(workbook.Sheets[sheetName])
                    };
                });
            })()
            """)

            return sheet
        }

        guard let demoURL = Bundle.module.url(forResource: "demo", withExtension: "xls", subdirectory: "Resources/sheets") else {
            return XCTFail("could not load demo.xls")
        }


        let json = try parseSheet(data: try Data(contentsOf: demoURL)).toBric() ?? .nul

        XCTAssertEqual(json, [
            ["sheetName":"Sheet1","data":[
                ["Column E":11.2,"Column C":5.1,"Column B":"A","Column A":1,"Column D":"black"],
                ["Column E":20.8668,"Column D":"red","Column A":2,"Column B":"B","Column C":9.4334],
                ["Column E":11.646,"Column D":"white","Column A":3,"Column B":"C","Column C":4.323],
                ["Column E":8.66,"Column D":"grey","Column A":4,"Column B":"D","Column C":2.33],
                ["Column D":"green","Column B":"E","Column A":5,"Column C":1.11,"Column E":7.220000000000001],
                ["Column D":"blue","Column B":"F","Column A":6,"Column C":3.2,"Column E":12.4],
                ["Column C":9.99,"Column A":7,"Column E":26.98,"Column D":"yellow","Column B":"G"],
                ["Column D":"orangle","Column B":"H","Column A":8,"Column C":8.32,"Column E":24.64],
                ["Column A":9,"Column D":"purple","Column B":"I","Column C":1024.1,"Column E":2057.2],
                ["Column D":"maroon","Column B":"J","Column A":10,"Column C":22,"Column E":54]]],
          ["sheetName":"Sheet3","data":[
                ["COL2":"YYY","COL1":"XXX"]]],
          ["sheetName":"Sheet4","data":[
                ["BBB":"DDD","CCC":"EEE","__EMPTY":"FFF"],
                ["__EMPTY_1":"III","__EMPTY":"HHH","CCC":"GGG"],
                ["__EMPTY_1":2,"__EMPTY":1,"__EMPTY_2":3]]]] as Bric)
    }
}


public extension ScriptContext {
    static let sheetjs = Bundle.module.url(forResource: "xlsx", withExtension: "js", subdirectory: "Resources/JavaScript")

    /// Runs `xlsx.js` to set up the VM.
    func installSheetJS() throws {
        guard let sheetjsURL = Self.sheetjs else {
            throw JudoErrors.cannotLoadScriptURL
        }
        try self.eval(url: sheetjsURL)
    }
}

/// Uses `SwiftJS` and `SheetJS`
public final class SheetJS {
    public static let shared = Result { try SheetJS() }
    let ctx: ScriptContext

    private init(mnt: String = "/sys/") throws {
        self.ctx = ScriptContext()

        // ctx.installExports(require: true)
        ctx.installConsole()
        ctx.installTimer(immediate: true)

        try ctx.installBrowserFS(mountPoint: mnt)
        try ctx.installSheetJS()

    }

    /// https://github.com/sheetjs/sheetjs#parsing-options
    public struct ParsingOptions : Hashable, Codable {
        /// Input data encoding (see Input Type below)
        public var type: InputType?
        /// If true, plain text parsing will not parse values (default: `false`)
        public var raw: Bool?
        /// If specified, use code page when appropriate **
        public var codepage: String?
        /// Save formulae to the .f field (default: `true`)
        public var cellFormula: Bool?
        /// Parse rich text and save HTML to the .h field (default: `true`)
        public var cellHTML: Bool?
        /// Save number format string to the .z field (default: `false`)
        public var cellNF: Bool?
        /// Save style/theme info to the .s field (default: `false`)
        public var cellStyles: Bool?
        // Generated formatted text to the .w field (default: `true`)
        public var cellText: Bool?
        /// Store dates as type d (default is n) (default: `false`)
        public var cellDates: Bool?
        /// If specified, use the string for date code 14 **
        public var dateNF: String?
        /// Create cell objects of type z for stub cells (default: `false`)
        public var sheetStubs: Bool?
        /// If >0, read the first sheetRows rows **
        public var sheetRows: Int?
        /// If true, parse calculation chains (default: `false`)
        public var bookDeps: Bool?
        /// If true, add raw files to book object ** (default: `false`)
        public var bookFiles: Bool?
        /// If true, only parse enough to get book metadata ** (default: `false`)
        public var bookProps: Bool?
        /// If true, only parse enough to get the sheet names (default: `false`)
        public var bookSheets: Bool?
        /// If true, copy VBA blob to vbaraw field ** (default: `false`)
        public var bookVBA: Bool?
        /// If defined and file is encrypted, use password **
        public var password: String?
        /// If true, throw errors on unexpected file features ** (default: `false`)
        public var WTF: Bool?
        /// If specified, only parse specified sheets **
        public var sheets: [String]?
        /// If true, allow parsing of PRN files ** (default: `false`)
        public var PRN: Bool?
        /// If true, preserve _xlfn. prefixes in formulae ** (default: `false`)
        public var xlfn: Bool?

        /// https://github.com/sheetjs/sheetjs#input-type
        public enum InputType: String, Codable {
            /// string: Base64 encoding of the file
            case base64
            /// string: binary string (byte n is data.charCodeAt(n))
            case binary
            /// string: JS string (characters interpreted as UTF8)
            case string
            /// nodejs Buffer
            case buffer
            /// array: array of 8-bit unsigned int (byte n is data[n])
            case array
            /// string: path of file that will be read (nodejs only)
            case file
        }
    }
}

