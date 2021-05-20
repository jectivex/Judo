import SwiftJS
import MiscKit

public enum JudoErrors : Error {
    case cannotLoadScriptURL
    case evaluationErrorString(String)
    case evaluationError(ScriptObject)
}


public extension ScriptContext {
    /// Runs the script at the given URL.
    /// - Parameter url: the URL from which to run the script
    /// - Throws: an error if one occurs
    @discardableResult func eval(url: URL) throws -> ScriptObject {
        try eval(script: String(contentsOf: url, encoding: .utf8), url: url)
    }

    @discardableResult func eval(script: String, url: URL? = nil) throws -> ScriptObject {
        try trying {
            evaluateScript(script, this: nil, withSourceURL: url, startingLineNumber: 0)
        }
    }

    /// Tries to execute the given operation, and throws any exceptions that may exists
    func trying<T>(operation: () throws -> T) throws -> T {
        let result = try operation()
        if let error = self.exception {
            defer { self.exception = nil }
            if let string = error.stringValue {
                throw JudoErrors.evaluationErrorString(string)
            } else {
                throw JudoErrors.evaluationError(error)
            }
        }
        return result
    }


    /// Installs a top-level "global" variable.
    func installExports(require: Bool) {
        if self.global["exports"].isObject == false {
            let exports = ScriptObject(newObjectIn: self)
            self.global["exports"] = exports
        }

        if require == true && self.global["require"].isUndefined == true {
            self.global["require"] = ScriptObject(newFunctionIn: self) { ctx, this, args in
                dbg("require", args)
                return ScriptObject(nullIn: ctx)
            }
        }
    }

    /// Installs `console.log` and other functions to output to `os_log` via `MiscKit.dbg`
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/API/console
    func installConsole() {
        let console = ScriptObject(newObjectIn: self)
        let createLog = { (level: UInt8) in
            ScriptObject(newFunctionIn: self) { ctx, this, args in
                // debugPrint(arguments)
                dbg(level: level,
                    level == 0 ? "DEBUG" : level == 1 ? "LOG" : level == 2 ? "INFO" : level == 3 ? "WARN" : level == 4 ? "ERROR": "UNKNOWN",
                    args.count > 0 ? args[0] : nil,
                    args.count > 1 ? args[1] : nil,
                    args.count > 2 ? args[2] : nil,
                    args.count > 3 ? args[3] : nil,
                    args.count > 4 ? args[4] : nil,
                    args.count > 5 ? args[5] : nil,
                    args.count > 6 ? args[6] : nil,
                    args.count > 7 ? args[7] : nil,
                    args.count > 8 ? args[8] : nil,
                    args.count > 9 ? args[9] : nil,
                    args.count > 10 ? args[10] : nil
                )
                return ScriptObject(nullIn: ctx)
            }
        }

        console["debug"] = createLog(0)
        console["log"] = createLog(1)
        console["info"] = createLog(2)
        console["warn"] = createLog(3)
        console["error"] = createLog(4)

        self.global["console"] = console
    }

    /// Installs `setTimeout` to use `DispatchQueue.global.asyncAfter`
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setTimeout
    func installTimer() {
        let setTimeout = ScriptObject(newFunctionIn: self) { ctx, this, arguments in
            var args = arguments
            if args.count < 1 {
                dbg("error in setTimeout: too few arguments")
                return ScriptObject(nullIn: ctx)
            }

            let f = args.removeFirst()
            if !f.isFunction {
                dbg("first argument to setTimeout was not a function")
                return ScriptObject(nullIn: ctx)
            }

            let t = !args.isEmpty ? args.removeFirst().doubleValue ?? 0.0 : 0.0

            var timerID: Int = 0
            globalTimerQueue.sync {
                timerID = globalTimerCount
                globalTimerCount += 1

                let item = DispatchWorkItem {
                    _ = globalTimerQueue.sync {
                        globalTimers.removeValue(forKey: timerID)
                    }
                    f.call(withArguments: args, this: nil)
                }

                globalTimers[globalTimerCount] = item

                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(t)), execute: item)
            }


            // return the item identifier for the work item so we can cancel it later
            return ScriptObject(double: Double(timerID), in: ctx)
        }

        let clearTimeout = ScriptObject(newFunctionIn: self) { ctx, this, arguments in
            if let timeoutID = arguments.first?.doubleValue {
                globalTimerQueue.sync {
                    if let item = globalTimers.removeValue(forKey: Int(timeoutID)) {
                        item.cancel()
                    }
                }
            }
            return ScriptObject(nullIn: self)
        }

        self.global["setTimeout"] = setTimeout
        self.global["clearTimeout"] = clearTimeout
    }
}

private var globalTimers: [Int: DispatchWorkItem] = [:]
private var globalTimerCount = 0
private var globalTimerQueue = DispatchQueue(label: "globalTimers")

extension ScriptContext {
    static let browserfs = Bundle.module.url(forResource: "browserfs", withExtension: "js", subdirectory: "Resources/JavaScript")

    /// Installs the `browserfs.js` system and creates a mount to the native file system at the given point.
    /// - Parameter mountPoint: the mount point for the file system
    func installBrowserFS(mountPoint: String? = "/sys") throws {
        guard let browserfsURL = Self.browserfs else {
            throw JudoErrors.cannotLoadScriptURL
        }

        //dbg("loading browserfsURL:", browserfsURL.lastPathComponent)
        try self.eval(url: browserfsURL)

        try self.eval(script: """
            var mfs = new BrowserFS.FileSystem.MountableFileSystem(),
                fs = BrowserFS.BFSRequire('fs');
            BrowserFS.initialize(mfs);
            """)

        var implMethods: [String] = []

        // e.g.:
        // appendFile: function() { nativeFS.appendFile(...arguments); },
        // appendFileSync: function() { nativeFS.appendFileSync(...arguments); },
        let nativeFS = ScriptObject(newObjectIn: self)
        func addStub(name: String, sync makeSyncVersion: Bool = false, impl: @escaping JSObjectCallAsFunctionCallback) {
            let syncName = name + "Sync"

            let clog = "" // "console.log('\(name)', ...arguments); " // debug logging of API calls
            let clerr = "" // "console.error('\(name)', error); " // debug logging of API errors

            if makeSyncVersion {
                // the non-"Sync" version is stubbed in using a pure-JS implementation to use the final argument as the callback
                implMethods += [
                    "\(name): function() { \(clog) let args = Array.prototype.slice.call(arguments, 0, arguments.length); let cb = args.pop(); try { cb(null, nativeFS.\(name)Sync(...args)); } catch (error) { \(clerr) cb(error); } }"
                ]

                // we only actually implement the synchronous versions
                nativeFS[name + "Sync"] = ScriptObject(newFunctionIn: self) { ctx, this, arguments in
                    return try impl(ctx, this, arguments)
                }
                implMethods += [
                    "\(syncName): function() { \(clog) return nativeFS.\(syncName)(...arguments); }"
                ]
            } else {
                nativeFS[name] = ScriptObject(newFunctionIn: self) { ctx, this, arguments in
                    return try impl(ctx, this, arguments)
                }
                implMethods += [
                    "\(name): function() { \(clog) nativeFS.\(name)(...arguments); }"
                ]
            }
        }

        // http://jvilk.com/browserfs/1.4.1/interfaces/_core_file_system_.filesystem.html
        addStub(name: "getName", impl: FileManager.getName)
        addStub(name: "diskSpace", impl: FileManager.diskSpace)
        addStub(name: "isReadOnly", impl: FileManager.isReadOnly)
        addStub(name: "supportsLinks", impl: FileManager.supportsLinks)
        addStub(name: "supportsProps", impl: FileManager.supportsProps)
        addStub(name: "supportsSynch", impl: FileManager.supportsSynch)

        addStub(name: "appendFile", sync: true, impl: FileManager.appendFileSync)
        addStub(name: "chmod", sync: true, impl: FileManager.chmodSync)
        addStub(name: "chown", sync: true, impl: FileManager.chownSync)
        addStub(name: "exists", sync: true, impl: FileManager.existsSync)
        addStub(name: "link", sync: true, impl: FileManager.linkSync)
        addStub(name: "mkdir", sync: true, impl: FileManager.mkdirSync)
        addStub(name: "open", sync: true, impl: FileManager.openSync)
        addStub(name: "readFile", sync: true, impl: FileManager.readFileSync)
        addStub(name: "readdir", sync: true, impl: FileManager.readdirSync)
        addStub(name: "readlink", sync: true, impl: FileManager.readlinkSync)
        addStub(name: "realpath", sync: true, impl: FileManager.realpathSync)
        addStub(name: "rename", sync: true, impl: FileManager.renameSync)
        addStub(name: "rmdir", sync: true, impl: FileManager.rmdirSync)
        addStub(name: "stat", sync: true, impl: FileManager.statSync)
        addStub(name: "symlink", sync: true, impl: FileManager.symlinkSync)
        addStub(name: "truncate", sync: true, impl: FileManager.truncateSync)
        addStub(name: "unlink", sync: true, impl: FileManager.unlinkSync)
        addStub(name: "utimes", sync: true, impl: FileManager.utimesSync)
        addStub(name: "writeFile", sync: true, impl: FileManager.writeFileSync)

        self["nativeFS"] = nativeFS

        // we need to generate the glue in a prototype, since just passing the raw object doesn't seem to be sufficient to convince BrowserFS that we are really implementing their methods
        // e.g., the glue will look like: statSync: function() { nativeFS.statSync(...arguments); },

        if let mountPoint = mountPoint {
            dbg("mounting file system at:", mountPoint)
            let implGlue = implMethods.joined(separator: ",\n\t")

            // for some reason, setting the prototype directly as 'writeFile: nativeFS.writeFile" doesn't work, even through it is a proper JavaScript function object
            let mountScript = "mfs.mount('\(mountPoint)', Object({\(implGlue)}));"
            // dbg("writing mountScript", mountScript)
            try self.eval(script: mountScript)
        }
    }
}

/// FileSystem shims
private extension FileManager {
    /// ```getName(): string;```
    static let getName: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("getName", args)
        return ScriptObject(string: "KanjiVM", in: ctx)
    }

    /// Is this filesystem read-only?
    static let isReadOnly: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("isReadOnly", args)
        return ScriptObject(bool: false, in: ctx)
    }

    /// Does the filesystem support optional symlink/hardlink-related commands?
    static let supportsLinks: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("supportsLinks", args)
        return ScriptObject(bool: true, in: ctx)
    }

    /// Does the filesystem support optional property-related commands?
    static let supportsProps: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("supportsProps", args)
        return ScriptObject(bool: false, in: ctx)
    }

    /// Does the filesystem support the optional synchronous interface?
    static let supportsSynch: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("supportsSynch", args)
        return ScriptObject(bool: true, in: ctx)
    }

    /// ```diskSpace(p: string, cb: (total: number, free: number) => any): void;```
    static let diskSpace: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("diskSpace", args)
        throw err("Unsupported: diskSpace")
    }

    /// ```appendFileSync(fname: string, data: string | Buffer, encoding: string | null, flag: FileFlag, mode: number): void;```
    static let appendFileSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("appendFileSync", args)
        var args = args
        guard !args.isEmpty, let fname = args.removeFirst().stringValue else {
            throw err("first fname argument was not a string")
        }
        guard !args.isEmpty else {
            throw err("second data argument was unset")
        }
        let data = args.removeFirst()
        if !data.isString && !data.isArrayBuffer {
            throw err("second data argument not a string or buffer")
        }

        guard !args.isEmpty, let encoding = args.removeFirst().stringValue else {
            throw err("third encoding argument was not a string")
        }

        guard !args.isEmpty, let flag = args.removeFirst().doubleValue else {
            throw err("fourth flag argument was not a number")
        }

        guard !args.isEmpty, let mode = args.removeFirst().doubleValue else {
            throw err("fifth mode argument was not a number")
        }

        throw err("Unsupported: appendFileSync")
    }

    /// ```chmodSync(p: string, isLchmod: boolean, mode: number): void;```
    static let chmodSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("chmodSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLchmod argument was unset")
        }
        let isLchmod = args.removeFirst()
        if isLchmod.isBoolean {
            throw err("second isLchmod argument was not a boolean")
        }

        guard !args.isEmpty, let mode = args.removeFirst().doubleValue else {
            throw err("fourth mode argument was not a number")
        }

        throw err("Unsupported: chmodSync")
    }

    /// ```chownSync(p: string, isLchown: boolean, uid: number, gid: number): void;```
    static let chownSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("chownSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLchmod argument was unset")
        }
        let isLchown = args.removeFirst()
        if isLchown.isBoolean {
            throw err("second isLchown argument was not a boolean")
        }

        guard !args.isEmpty, let uid = args.removeFirst().doubleValue else {
            throw err("third uid argument was not a number")
        }

        guard !args.isEmpty, let gid = args.removeFirst().doubleValue else {
            throw err("fourth gid argument was not a number")
        }

        throw err("Unsupported: chownSync")
    }

    /// ```existsSync(p: string): boolean;```
    static let existsSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("existsSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        let exists = FileManager.default.fileExists(atPath: p)
        return ScriptObject(bool: exists, in: ctx)
    }

    /// ```linkSync(srcpath: string, dstpath: string): void;```
    static let linkSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("linkSync", args)
        var args = args
        guard !args.isEmpty, let srcpath = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let dstpath = args.removeFirst().stringValue else {
            throw err("second argument was not a string")
        }

        try FileManager.default.linkItem(atPath: srcpath, toPath: dstpath)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```mkdirSync(p: string, mode: number): void;```
    static let mkdirSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("mkdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        guard !args.isEmpty, let mode = args.removeFirst().doubleValue else {
            throw err("second argument was not a number")
        }

        let attrs: [FileAttributeKey : Any] = [
            FileAttributeKey.posixPermissions: NSNumber(value: Int16(mode))
        ]

        try FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: attrs)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```openSync(p: string, flag: FileFlag, mode: number): File;```
    static let openSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("openSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let flag = args.removeFirst().doubleValue else {
            throw err("second flag argument was not a number")
        }

        guard !args.isEmpty, let mode = args.removeFirst().doubleValue else {
            throw err("third mode argument was not a number")
        }

        throw err("Unsupported: openSync")
    }

    /// ```readFileSync(fname: string, encoding: string | null, flag: FileFlag): any;```
    static let readFileSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("readFileSync", args)
        var args = args
        guard !args.isEmpty, let fname = args.removeFirst().stringValue else {
            throw err("first fname argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second encoding argument was not set")
        }
        let encoding: String? = args.removeFirst().stringValue

        guard !args.isEmpty, let flag = args.removeFirst().doubleValue else {
            throw err("third flag argument was not a string")
        }

        if let encoding = encoding {
            let contents = try String(contentsOfFile: fname, encoding: parseEncoding(from: encoding))
            return ScriptObject(string: contents, in: ctx)
        } else {
            let file = FileHandle(forReadingAtPath: fname)
            defer { file?.closeFile() }
            var data = Data()
            if #available(macOS 10.15.4, *) {
                data = try file?.readToEnd() ?? Data()
                return ScriptObject(newArrayBufferWithBytes: data, in: ctx)
            } else {
                throw err("Unsupported: readFileSync")
            }
        }
    }

    /// ```readdirSync(p: string): string[];```
    static let readdirSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("readdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: p)

        var array = ScriptObject(newArrayIn: ctx)
        for (index, path) in files.enumerated() {
            array[index] = ScriptObject(string: path, in: ctx)
        }
        return array
    }

    /// ```readlinkSync(p: string): string;```
    static let readlinkSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("readlinkSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        throw err("Unsupported: readlinkSync")
    }

    /// ```realpathSync(p: string, cache: {[path: string]: string}): string;```
    static let realpathSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("realpathSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        throw err("Unsupported: realpathSync")
    }

    /// ```renameSync(oldPath: string, newPath: string): void;```
    static let renameSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("renameSync", args)
        var args = args
        guard !args.isEmpty, let oldPath = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let newPath = args.removeFirst().stringValue else {
            throw err("second argument was not a string")
        }

        try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```rmdirSync(p: string): void;```
    static let rmdirSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("rmdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        try FileManager.default.removeItem(atPath: p)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```statSync(p: string, isLstat: boolean | null): Stats;```
    static let statSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("statSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLstat argument was unset")
        }
        let isLstat = args.removeFirst()
        if isLstat.isBoolean {
            throw err("second isLstat argument was not a boolean")
        }

        throw err("Unsupported: statSync")
    }

    /// ```symlinkSync(srcpath: string, dstpath: string, type: string): void;```
    static let symlinkSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("symlinkSync", args)
        var args = args
        guard !args.isEmpty, let srcpath = args.removeFirst().stringValue else {
            throw err("first srcpath argument was not a string")
        }

        guard !args.isEmpty, let dstpath = args.removeFirst().stringValue else {
            throw err("second dstpath argument was not a string")
        }

        guard !args.isEmpty, let type = args.removeFirst().stringValue else {
            throw err("third type argument was not a string")
        }

        try FileManager.default.createSymbolicLink(atPath: srcpath, withDestinationPath: dstpath)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```truncateSync(p: string, len: number): void;```
    static let truncateSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("truncateSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        guard !args.isEmpty, let len = args.removeFirst().doubleValue else {
            throw err("second argument was not a number")
        }

        throw err("Unsupported: truncateSync")
    }

    /// ```unlinkSync(p: string): void;```
    static let unlinkSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("unlinkSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        try FileManager.default.removeItem(atPath: p)
        return ScriptObject(undefinedIn: ctx)
    }

    /// ```utimesSync(p: string, atime: Date, mtime: Date): void;```
    static let utimesSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("utimesSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        throw err("Unsupported: utimesSync")
    }

    /// ```writeFileSync(fname: string, data: string | Buffer, encoding: string | null, flag: FileFlag, mode: number): void;```
    static let writeFileSync: JSObjectCallAsFunctionCallback = { ctx, this, args in
        dbg("writeFileSync", args)
        var args = args
        guard !args.isEmpty, let fname = args.removeFirst().stringValue else {
            throw err("first fname argument was not a string")
        }
        guard !args.isEmpty else {
            throw err("second data argument was unset")
        }
        let data = args.removeFirst()
        if !data.isString && !data.isArrayBuffer {
            throw err("second data argument not a string or buffer")
        }

        guard !args.isEmpty, let encoding = args.removeFirst().stringValue else {
            throw err("third encoding argument was not a string")
        }

        guard !args.isEmpty, let flag = args.removeFirst().doubleValue else {
            throw err("fourth flag argument was not a number")
        }

        guard !args.isEmpty, let mode = args.removeFirst().doubleValue else {
            throw err("fifth mode argument was not a number")
        }

        if data.isString, let str = data.stringValue {
            try str.write(toFile: fname, atomically: false, encoding: parseEncoding(from: encoding))
        }
        return ScriptObject(undefinedIn: ctx)
    }

    private static func parseEncoding(from encodingString: String) -> String.Encoding {
        switch encodingString.lowercased() {
        case "utf8", "utf-8": return .utf8
        case "utf16", "utf-16": return .utf16
        case "utf32", "utf-32": return .utf32
        case "ascii": return .ascii
        default: return .utf8
        }
    }
}
