import XCTest
import Judo
import MiscKit

/// A running count of all the contexts that have been created and not destroyed
private final class JXDebugContext : JXContext {
    static var debugContextCount = 0

    convenience init() {
        self.init(group: JXContextGroup())
    }

    override init(group: JXContextGroup) {
        super.init(group: group)
        Self.debugContextCount += 1
    }

    deinit {
        Self.debugContextCount -= 1
    }
}


/// A running count of all the values that have been created and not destroyed
private final class JXDebugValue : JXValue {
    static var debugValueCount = 0

    override init(env: JXContext, value: OpaquePointer) {
        Self.debugValueCount += 1
        super.init(env: env, value: value)
    }

    deinit {
        Self.debugValueCount -= 1
    }
}

final class JudoTests: XCTestCase {
    let res = Bundle.module.resourceURL
    let fm = FileManager.default

    /// Ensure that contexts are destroued as expected
    func testContextDeinit() throws {
        XCTAssertEqual(0, JXDebugContext.debugContextCount)

        defer {
            XCTAssertEqual(0, JXDebugContext.debugContextCount, "context did not deinit")
        }

        do {
            let ctx = JXDebugContext()
            XCTAssertEqual(1, JXDebugContext.debugContextCount)
            let _ = ctx
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func testFetch() throws {
        let ctx = JXDebugContext()
        // bogus fetch that just returns the string itself
        ctx.installFetch { ctx, url, opts in (nil, url.data(using: .utf8)) }


        let checkString = UUID().uuidString
        let promise = try ctx.eval("(async () => { this['fetchResult'] = await fetch('\(checkString)'); })();")
        XCTAssertEqual("[object Promise]", promise.stringValue)

        let result = ctx["fetchResult"]
        // https://developer.mozilla.org/en-US/docs/Web/API/Response
        XCTAssertEqual("true", result["ok"].stringValue)
        XCTAssertEqual(200, result["status"].numberValue)
        XCTAssertEqual(checkString, result["text"].call().stringValue)
    }

    func testCallbackFunctions() throws {
        XCTAssertEqual(0, JXDebugContext.debugContextCount)

        defer {
            XCTAssertEqual(0, JXDebugContext.debugContextCount, "context did not deinit")
        }

        do {
            let ctx = JXDebugContext()
            XCTAssertEqual(1, JXDebugContext.debugContextCount)

            var warnings: [String?] = []

            // set up a callback for the warning console
            try ctx.installConsole(warn: { ctx, this, args in
                warnings.append(args.map(\.stringValue).compactMap({ $0 }).joined())
                return JXValue(undefinedIn: ctx)
            })

            // clear the custom console
            //defer { ctx.global.removeProperty("console") }

            try ctx.eval(script: "console.log('test log');")

            if true {
                try ctx.eval(script: "console.warn('test2');")
                XCTAssertEqual(["test2"], warnings)
                warnings.removeAll()
            }

            // set up a timer to use a manual dispatch mechanism
            ctx.installTimer(immediate: true) { t, item in
                DispatchQueue.global(qos: .userInitiated)
                    .asyncAfter(deadline: .now() + .milliseconds(Int(t)),
                                execute: item)
            }

            if false {
                XCTAssertEqual(0, ctx.pendingTimeouts.count)
                // set a timer for a callback, so we can force it to execute immediately
                let tid0 = try ctx.eval(script: "setTimeout(function() { console.warn('Call', '–', 'Back'); }, 1.000);")
                XCTAssertEqual(1, ctx.pendingTimeouts.count)

                ctx.crushTimeouts()

                if false {
                    XCTAssertEqual(0, tid0.numberValue)
                    XCTAssertEqual([], warnings)
                    XCTAssertEqual(1, ctx.pendingTimeouts.count)

                    while let tid = ctx.processNextTimeout() {
                        dbg("flushed timeout:", tid)
                    }

                    XCTAssertEqual(0, ctx.pendingTimeouts.count)

                    XCTAssertEqual(["Call–Back"], warnings)
                    warnings.removeAll()
                }
            }

            if false {
                XCTAssertEqual(0, ctx.pendingTimeouts.count)
                let tid1 = try ctx.eval(script: "setTimeout(function() { console.warn('call', 'back2'); }, 2);").numberValue
                XCTAssertEqual(1, ctx.pendingTimeouts.count)

                if let tid = tid1 { // clear the timeout
                    dbg("clearing timeout \(tid)")
                    try ctx.eval(script: "clearTimeout(\(tid))")
                }

                while let tid = ctx.processNextTimeout() {
                    dbg("flushed timeout:", tid)
                }

                XCTAssertEqual([], ctx.pendingTimeouts)
                XCTAssertEqual([], warnings) // the callback to log the message should have been cancelled
            }

            // lastly, check that a scheduled timeout actually executes successfully
            if false {
                let xpc = expectation(description: "__cbfun")

                XCTAssertEqual(0, JXDebugValue.debugValueCount)
                do {
                    let cb = JXDebugValue(newFunctionIn: ctx) { ctx, _, _ in
                        xpc.fulfill()
                        return JXValue(undefinedIn: ctx)
                    }

                    XCTAssertEqual(1, JXDebugValue.debugValueCount)
                    XCTAssertEqual(0, ctx.pendingTimeouts.count)
                    ctx["setTimeout"].call(withArguments: [cb, JXValue(double: 0.01, in: ctx)])
                    XCTAssertEqual(1, ctx.pendingTimeouts.count)
                    XCTAssertEqual(1, JXDebugValue.debugValueCount)

                    wait(for: [xpc], timeout: 1.00)
                    XCTAssertEqual(0, ctx.pendingTimeouts.count)
                }

                XCTAssertEqual(0, JXDebugValue.debugValueCount)
            }
        }
    }

    #warning("TODO: re-enable once timing issues are resolved")
    @available(macOS 10.12, macCatalyst 13.0, iOS 10.0, tvOS 10.0, *)
    func XXXtestFileBrowser() throws {
        let ctx = JXContext()

        try ctx.trying { try ctx.installConsole() }
        try ctx.trying { ctx.installTimer() }

        // must not have require for BrowserFS to install correctly
        // try ctx.trying { ctx.installExports(require: false) }

        let mount = "/sys"

        try ctx.installBrowserFS(mountPoint: "\(mount)")
        while ctx.processNextTimeout() != nil { } // flush timeouts

        XCTAssertEqual("[object Object]", try ctx.eval(script: "new fs.FS.Stats()").stringValue)
        XCTAssertEqual("false", try ctx.eval(script: "new fs.FS.Stats().isDirectory()").stringValue)

        func fstat(path: String, mnt: Bool) throws -> JXValue {
            try ctx.eval(script: "fs.statSync('\(mnt ? mount : "")\(path)').isDirectory()")
        }

        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('/').isDirectory()").booleanValue)
        XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('/xyzxyz').isDirectory()")) // ENOENT: No such file or directory., \'/xyzxyz\'

        // this will return our own Stats impl…
        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)').isDirectory()").booleanValue)
        XCTAssertThrowsError(try ctx.eval(script: "fs.statSync('\(mount)/xyzxyz').isDirectory()")) // ENOENT: No such file or directory., \'/xyzxyz\'

        XCTAssertEqual(false, try ctx.eval(script: "fs.statSync('\(mount)/etc/').isFile()").booleanValue)
        //XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)/etc/').isDirectory()").booleanValue)

        XCTAssertEqual(false, try ctx.eval(script: "fs.statSync('\(mount)/etc/hosts').isDirectory()").booleanValue)
        XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(mount)/etc/hosts').isFile()").booleanValue)


        // write a random string to a temporary file, then read it back and see if it works

        // TODO: test async/await like:
        /*
         async function xxx() {
         await fs.writeFile('\(path)', '\(string)');
         return await fs.readFile('/sys/tmp/test.txt');
         };
         await xxx();
         */

        func roundtripFile(sync: Bool, path: String, string: String, encoding: String) throws -> JXValue {
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
                XCTAssertEqual(true, try ctx.eval(script: "fs.statSync('\(path)').isFile()").booleanValue)

                let data = try XCTUnwrap(try ctx.eval(script: "fs.readFileSync('\(path)')").copyBytes())

                XCTAssertTrue(fm.fileExists(atPath: relpath))
                let attrs = try fm.attributesOfItem(atPath: relpath)

                do { // check that stat's size is correct
                    let size = try XCTUnwrap(attrs[.size] as? Int)
                    let jsize = try XCTUnwrap(try ctx.eval(script: "fs.statSync('\(path)').size").numberValue)

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

    func testRoundTripBric() throws {
        let ctx = JXContext()

        func rt(_ bric: Bric, native: Bool = true, line: UInt = #line) throws {
            XCTAssertEqual(bric, try ctx.encode(bric).toBric(native: native), line: line)
        }

        try rt(1)
        try rt("X")
        try rt(true)
        try rt(false)
        try rt(nil)
        try rt(1.234)

        try rt([])
        try rt([:])

        try rt(["x": 1])
        try rt(["x": 1.1])
        try rt(["x": true])
        try rt(["x": false])
        try rt(["x": "ABC"])
        try rt(["x": [1,true,false,0.1,"XYZ"]])

    }

    func testRoundTripCodables() throws {
        let ctx = JXContext()

        func rt<T: Codable & Equatable>(equal: Bool = true, _ item: T, line: UInt = #line) throws {
            let encoded = try ctx.encode(item)
            let decoded = try encoded.toDecodable(ofType: T.self)

            if equal {
                XCTAssertEqual(item, decoded, line: line)
            } else {
                XCTAssertNotEqual(item, decoded, line: line)
            }
        }


        for _ in 1...5 {
            try rt(["q":nil] as Bric)

            try rt([:] as Bric)
            try rt([1] as Bric)
            try rt([1, true] as Bric)
            try rt([1, false, "XXX"] as Bric)

            try rt(1)
            try rt("X")
            try rt(true)
            try rt(false)
            try rt(1.234)

            try rt(["x": 1])
            try rt(["x": 1.1])
            try rt(["x": true])
            try rt(["x": false])
            try rt(["x": "ABC"])

            try rt(["x": 1] as Bric)
            try rt(["x": 1.1] as Bric)
            try rt(["x": true] as Bric)
            try rt(["x": false] as Bric)
            try rt(["x": "ABC"] as Bric)

            try rt([1] as Bric)
            try rt([true] as Bric)
            try rt([[[]]] as Bric)
            try rt([[[:]]] as Bric)
            try rt([[["q":[1, [true, ["X", [2.3]]], "Z"]]]] as Bric)
            try rt([[["q":[[[[[[[[]]]]]]]]]]] as Bric)

            try rt(["x": [1,true,false,0.1,"XYZ"]] as Bric)

            try rt(["X"] as Bric)

            struct DataStruct: Codable, Equatable { var data: Data }
            try rt(DataStruct(data: Data("XYZ".utf8)))
            try rt(DataStruct(data: Data(UUID().uuidString.utf8)))

            struct DateStruct: Codable, Equatable { var date: Date }
            try rt(DateStruct(date: Date(timeIntervalSince1970: 0)))
            //try rt(DateStruct(date: Date(timeIntervalSinceReferenceDate: 0)))
        }
    }

    func testCodableArguments() throws {
        let ctx = JXContext()

        let htpy = JXValue(newFunctionIn: ctx) { ctx, this, args in
            JXValue(double: sqrt(pow(args.first?["x"].numberValue ?? 0.0, 2) + pow(args.first?["y"].numberValue ?? 0.0, 2)), in: ctx)
        }

        struct Args : Encodable {
            let x: Int16
            let y: Float
        }

        func hfun(_ args: Args) throws -> Double? {
            htpy.call(withArguments: [try ctx.encode(args)]).numberValue
        }

        XCTAssertEqual(5, try hfun(Args(x: 3, y: 4)))
        XCTAssertEqual(hypot(1, 2), try hfun(Args(x: 1, y: 2)))
        XCTAssertEqual(hypot(2, 2), try hfun(Args(x: 2, y: 2)))
        XCTAssertEqual(hypot(10, 10), try hfun(Args(x: 10, y: 10)))
    }

    @available(macOS 10.12, macCatalyst 13.0, iOS 10.0, tvOS 10.0, *)
    func testLoadSheetJS() throws {
        // re-use a single JXSheet for bechmarking
        let sheetjs = try JXSheet()

        measure {
            do {
                try checkSheetJSSamples(sheetjs)
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    // sample data for equality check

    let xlsSample: Bric = [
        ["name":"Sheet1",
         "data": [
            ["Column A","Column B","Column C","Column D","Column E"],
            [1,"A",5.1,"black",11.2],
            [2,"B",9.4334,"red",20.8668],
            [3,"C",4.323,"white",11.646],
            [4,"D",2.33,"grey",8.66],
            [5,"E",1.11,"green",7.220000000000001],
            [6,"F",3.2,"blue",12.4],
            [7,"G",9.99,"yellow",26.98],
            [8,"H",8.32,"orangle",24.64],
            [9,"I",1024.1,"purple",2057.2],
            [10,"J",22,"maroon",54]
         ]],
        ["name":"Sheet3",
         "data":[
            ["COL1","COL2"],
            ["XXX","YYY"]
         ]],
        ["name":"Sheet4",
         "data":[
            ["AAA","BBB","CCC"],
            [nil,"DDD","EEE","FFF"],
            [nil,nil,"GGG","HHH","III"],
            [nil,nil,nil,1,2,3]
         ]]
    ]

    let xlsxSample: Bric = [["name":"Sheet1","data":[["Column A","Column B","Column C","Column D","Column E"], [1,"A",5.1,"black"], [2,"B",9.4334,"red"], [3,"C",4.323,"white"], [4,"D",2.33,"grey"], [5,"E",1.11,"green"], [6,"F",3.2,"blue"], [7,"G",9.99,"yellow"], [8,"H",8.32,"orangle"], [9,"I",1024.1,"purple"], [10,"J",22,"maroon"]]]]

    let csvSample: Bric = [["data":[["A","B","C"], [1,"true","'xyz","abc'"]],"name":"Sheet1"]]

    let htmlSample: Bric = [ ["name":"Sheet1","data":[["Years","CBR","Years","CBR"], ["1950–1955",36.9,"2000–2005",21], ["1955–1960",35.4,"2005–2010",20.3], ["1960–1965",35.2,"2010–2015",19.5], ["1965–1970",34,"2015–2020",18.5], ["1970–1975",31.4,"2020–2025",17.5], ["1975–1980",28.5,"2025–2030",16.6], ["1980–1985",27.7,"2030–2035",16], ["1985–1990",27.4,"2035–2040",15.5], ["1990–1995",24.2,"2040–2045",15], ["1995–2000",22.2,"2045–2050",14.6]]]]

    @available(macOS 10.12, macCatalyst 13.0, iOS 10.0, tvOS 10.0, *)
    func checkSheetJSSamples(_ sheetjs: JXSheet, extensions: [String] = ["xls", "xlsx", "csv", "html"]) throws {
        for ext in extensions {
            guard let demoURL = Bundle.module.url(forResource: "demo", withExtension: ext, subdirectory: "TestResources/sheets") else {
                return XCTFail("could not load demo.\(ext)")
            }

            let ropts = JXSheet.ParsingOptions(type: ext == "csv" ? .array : .buffer)

            let sheets: [JXSheet.Sheet] = try sheetjs.extractSheet(data: try Data(contentsOf: demoURL), readopts: ropts)

            let expected = ext == "csv" ? csvSample
                : ext == "html" ? htmlSample
                : ext == "xlsx" ? xlsxSample
                : ext == "xls" ? xlsSample
                : Bric.nul

            XCTAssertEqual(try sheets.bricEncoded(), expected)
        }
    }

    func testLoadFromJSON() throws {
        let ctx = JXContext()
        XCTAssertNil(JXValue(json: "]", in: ctx))
        XCTAssertNotNil(JXValue(json: "[]", in: ctx))
        XCTAssertNil(JXValue(json: "['x', 1, true]", in: ctx))
        XCTAssertNotNil(JXValue(json: "[\"x\", 1, true]", in: ctx))
        XCTAssertNil(JXValue(json: "{1, true]", in: ctx))
    }

    struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
        init(seed: Int) {
            // Set the random seed
            srand48(seed)
        }

        func next() -> UInt64 {
            // drand48() returns a Double, transform to UInt64
            return withUnsafeBytes(of: drand48()) { bytes in
                bytes.load(as: UInt64.self)
            }
        }
    }

    func testCodableDirectPerformance() throws {
        // [Time, seconds] average: 0.037, relative standard deviation: 8.080%, values: [0.044274, 0.039708, 0.035382, 0.033773, 0.035470, 0.034955, 0.035116, 0.036936, 0.038773, 0.035343]
        try bricPerformanceTest(native: true)
    }

    func testCodableJSONPerformance() throws {
        // [Time, seconds] average: 0.035, relative standard deviation: 7.715%, values: [0.042545, 0.034334, 0.033519, 0.033150, 0.032862, 0.034576, 0.034465, 0.033346, 0.033869, 0.035678]
        try bricPerformanceTest(native: false)
    }


    func bricPerformanceTest(native: Bool, seed: Int = 11111) throws {
        let ctx = JXContext()
        try ctx.installConsole()

        var rnd = RandomNumberGeneratorWithSeed(seed: seed)

        func fillObject(count: Int, level: Int, to bric: inout Bric) {
            if level <= 0 { return }

            for i in 0...count {
                let key = "key_\(level)_\(i)"
                switch Int.random(in: 0...5, using: &rnd) {
                case 0: // .nul
                    bric[key] = .nul
                case 1: // .str
                    bric[key] = .str(((0...Int.random(in: 0...9, using: &rnd)).map({ _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }).joined()))
                case 2: // .num
                    bric[key] = .num(Double.random(in: -9999...9999, using: &rnd))
                case 3: // .bol
                    bric[key] = .bol(Bool.random(using: &rnd))
                case 4: // .obj
                    var obj: Bric = [:]
                    for _ in 0...level {
                        fillObject(count: count, level: level - 1, to: &obj)
                    }
                    bric[key] = obj
                case 5, _: // .arr
                    var obj: Bric = [:]
                    for _ in 0...level {
                        fillObject(count: count, level: level - 1, to: &obj)
                    }
                    bric[key] = .arr(Array(obj.obj!.values)) // convert to object values
                }
            }
        }

        var bric: Bric = [:]

        do {
            // make a big random Bric
            fillObject(count: 10_000, level: 450, to: &bric)

            let str = try bric.encodedString()
            dbg("testing with JSON size:", str.count)

            let ob1 = try XCTUnwrap(JXValue(json: str, in: ctx))
            let ob2 = try ctx.encode(bric)

            XCTAssertEqual(try ob1.toDecodable(ofType: Bric.self), try ob2.toDecodable(ofType: Bric.self))
        } catch {
            XCTFail("\(error)")
        }

        measure {
            do {
                let ob: JXValue?
                if native {
                    ob = try JXValueEncoder(context: ctx).encode(bric)
                } else {
                    ob = JXValue(json: try bric.encodedString(), in: ctx)
                }
                XCTAssertNotNil(ob)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}

public extension JXContext {
    static let sheetjs = Bundle.module.url(forResource: "xlsx", withExtension: "js", subdirectory: "TestResources/JavaScript")
    static let jszipjs = Bundle.module.url(forResource: "jszip", withExtension: "js", subdirectory: "TestResources/JavaScript")

    /// Runs `jszip.js` to set up JSZip.
    func installJSZip() throws {
        guard let jszipjsURL = Self.jszipjs else {
            throw JudoErrors.cannotLoadScriptURL
        }
        try self.eval(url: jszipjsURL)
    }

    /// Runs `xlsx.js` to set up the VM.
    @discardableResult func installSheetJS() throws -> JXValue {
        try installJSZip()

        guard let sheetjsURL = Self.sheetjs else {
            throw JudoErrors.cannotLoadScriptURL
        }

        return try self.eval(url: sheetjsURL)
    }
}

/// Uses `JXKit` and `SheetJS`
open class JXSheet {
    open var ctx: JXContext
    let sheet_to_json: JXValue

    public init(ctx: JXContext = JXContext()) throws {
        self.ctx = ctx

        // ctx.installExports(require: true)
        // ctx.installConsole()
        // ctx.installTimer(immediate: true)

        try ctx.installSheetJS()

        // cache commonly-used functions

        self.sheet_to_json = try ctx.eval(script: """
            (function(buffer, readopts, jsonopts) {
                const workbook = XLSX.read(buffer, readopts);
                return workbook.SheetNames.map(sheetName => {
                    return {
                        name: sheetName,
                        data: XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], jsonopts)
                    };
                });
            })
            """)

        if !sheet_to_json.isFunction {
            throw err("Could not load XLSX.utils.sheet_to_json in SheetJS")
        }
    }

    @available(macOS 10.12, macCatalyst 13.0, iOS 10.0, tvOS 10.0, *)
    public func extractSheet(data: Data, readopts: JXSheet.ParsingOptions, jsonopts: JXSheet.JSONOptions = JXSheet.JSONOptions(header: 1)) throws -> [Sheet] {

        // encode the array arguments
        let buffer = JXValue(newArrayBufferWithBytes: data, in: ctx)
        let readopts = try ctx.encode(readopts)
        let jsonopts = try ctx.encode(jsonopts)
        let sheet = try ctx.trying {
            sheet_to_json.call(withArguments: [buffer, readopts, jsonopts])
        }

        return try sheet.toDecodable(ofType: [Sheet].self)
    }


    /// A sheet that contains some data
    public struct Sheet: Codable, Hashable {
        /// The name of the sheet (defaulting to "Sheet1")
        public var name: String
        /// The data contained in the sheet. The structure of the data will depending on the value of the `JXSheet.JSONOptions.header` option.
        public var data: [Bric]
    }


    /// https://github.com/sheetjs/sheetjs#json
    public struct JSONOptions : Hashable, Codable {
        /// Use raw values (true) or formatted strings (false)
        public var raw: Bool?

        /// Override Range (see table below)
        ///
        /// • (number): Use worksheet range but set starting row to the value
        ///
        /// • (string): Use specified range (A1-style bounded range string)
        ///
        /// • (default): Use worksheet range (ws['!ref'])
        public var range: Bric?

        /// Control output format
        ///
        /// header is expected to be one of:
        ///
        /// • 1: Generate an array of arrays ("2D Array")
        ///
        /// • "A": Row object keys are literal column labels
        ///
        /// • array of strings: Use specified strings as keys in row objects
        ///
        /// • (default): Read and disambiguate first row as keys
        public var header: Bric?

        /// Use specified date format in string output
        public var dateNF: Bric?

        /// Use specified value in place of null or undefined
        public var defval: Bric?

        /// Include blank lines in the output **
        public var blankrows: Bool?

        public init(raw: Bool? = nil, range: Bric? = nil, header: Bric? = nil, dateNF: Bric? = nil, defval: Bric? = nil, blankrows: Bool? = nil) {
            self.raw = raw
            self.range = range
            self.header = header
            self.dateNF = dateNF
            self.defval = defval
            self.blankrows = blankrows
        }
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

        public init(type: JXSheet.ParsingOptions.InputType? = nil, raw: Bool? = nil, codepage: String? = nil, cellFormula: Bool? = nil, cellHTML: Bool? = nil, cellNF: Bool? = nil, cellStyles: Bool? = nil, cellText: Bool? = nil, cellDates: Bool? = nil, dateNF: String? = nil, sheetStubs: Bool? = nil, sheetRows: Int? = nil, bookDeps: Bool? = nil, bookFiles: Bool? = nil, bookProps: Bool? = nil, bookSheets: Bool? = nil, bookVBA: Bool? = nil, password: String? = nil, WTF: Bool? = nil, sheets: [String]? = nil, PRN: Bool? = nil, xlfn: Bool? = nil) {
            self.type = type
            self.raw = raw
            self.codepage = codepage
            self.cellFormula = cellFormula
            self.cellHTML = cellHTML
            self.cellNF = cellNF
            self.cellStyles = cellStyles
            self.cellText = cellText
            self.cellDates = cellDates
            self.dateNF = dateNF
            self.sheetStubs = sheetStubs
            self.sheetRows = sheetRows
            self.bookDeps = bookDeps
            self.bookFiles = bookFiles
            self.bookProps = bookProps
            self.bookSheets = bookSheets
            self.bookVBA = bookVBA
            self.password = password
            self.WTF = WTF
            self.sheets = sheets
            self.PRN = PRN
            self.xlfn = xlfn
        }

    }
}

