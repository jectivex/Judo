
import JXKit
import MiscKit
import Foundation
import Dispatch

extension JXContext {
    /// Installs the `browserfs.js` system and creates a mount to the native file system at the given point.
    /// - Parameter mountPoint: the mount point for the file system
    public func installBrowserFS(mountPoint: String? = "/sys") throws {
        let _ = try installModule(named: "browserfs", in: .module)

        try self.eval(script: """
            var mfs = new BrowserFS.FileSystem.MountableFileSystem(),
                fs = BrowserFS.BFSRequire('fs');
            BrowserFS.initialize(mfs);
            """)

        var implMethods: [String] = []

        // e.g.:
        // appendFile: function() { nativeFS.appendFile(...arguments); },
        // appendFileSync: function() { nativeFS.appendFileSync(...arguments); },
        let nativeFS = JXValue(newObjectIn: self)
        func addStub(name: String, sync makeSyncVersion: Bool = false, passthrough: String = "", impl: @escaping JXFunction) {
            let syncName = name + "Sync"

            let clog = "" // "console.log('\(name)', ...arguments); " // debug logging of API calls
            let clerr = "" // "console.error('\(name)', error); " // debug logging of API errors

            if makeSyncVersion {
                // the non-"Sync" version is stubbed in using a pure-JS implementation to use the final argument as the callback
                implMethods += [
                    "\(name): function() { \(clog) let args = Array.prototype.slice.call(arguments, 0, arguments.length); let cb = args.pop(); try { cb(null, \(passthrough)(nativeFS.\(name)Sync(...args))); } catch (error) { \(clerr) cb(error); } }"
                ]

                // we only actually implement the synchronous versions
                nativeFS[name + "Sync"] = JXValue(newFunctionIn: self) { ctx, this, arguments in
                    return try impl(ctx, this, arguments)
                }
                implMethods += [
                    "\(syncName): function() { \(clog) return \(passthrough)(nativeFS.\(syncName)(...arguments)); }"
                ]
            } else {
                nativeFS[name] = JXValue(newFunctionIn: self) { ctx, this, arguments in
                    return try impl(ctx, this, arguments)
                }
                implMethods += [
                    "\(name): function() { \(clog) return \(passthrough)(nativeFS.\(name)(...arguments)); }"
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
        addStub(name: "symlink", sync: true, impl: FileManager.symlinkSync)
        addStub(name: "truncate", sync: true, impl: FileManager.truncateSync)
        addStub(name: "unlink", sync: true, impl: FileManager.unlinkSync)
        addStub(name: "utimes", sync: true, impl: FileManager.utimesSync)
        addStub(name: "writeFile", sync: true, impl: FileManager.writeFileSync)

        addStub(name: "stat", sync: true, passthrough: """
            (function(array) {
                return new fs.FS.Stats(array[0], array[1], array[2], new Date(array[3]), new Date(array[4]), new Date(array[5]));
            })
            """, impl: FileManager.statSync)

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

    /// Indicates the type of the given file. Applied to 'mode'.
    enum FileType: Int {
      case FILE = 0x8000,
      DIRECTORY = 0x4000,
      SYMLINK = 0xA000
    }

    /// ```getName(): string;```
    static let getName: JXFunction = { ctx, this, args in
        dbg("getName", args)
        return JXValue(string: "KanjiVM", in: ctx)
    }

    /// Is this filesystem read-only?
    static let isReadOnly: JXFunction = { ctx, this, args in
        dbg("isReadOnly", args)
        return JXValue(bool: false, in: ctx)
    }

    /// Does the filesystem support optional symlink/hardlink-related commands?
    static let supportsLinks: JXFunction = { ctx, this, args in
        dbg("supportsLinks", args)
        return JXValue(bool: true, in: ctx)
    }

    /// Does the filesystem support optional property-related commands?
    static let supportsProps: JXFunction = { ctx, this, args in
        dbg("supportsProps", args)
        return JXValue(bool: false, in: ctx)
    }

    /// Does the filesystem support the optional synchronous interface?
    static let supportsSynch: JXFunction = { ctx, this, args in
        dbg("supportsSynch", args)
        return JXValue(bool: true, in: ctx)
    }

    /// ```diskSpace(p: string, cb: (total: number, free: number) => any): void;```
    static let diskSpace: JXFunction = { ctx, this, args in
        dbg("diskSpace", args)
        throw err("Unsupported: diskSpace")
    }

    /// ```appendFileSync(fname: string, data: string | Buffer, encoding: string | null, flag: FileFlag, mode: number): void;```
    static let appendFileSync: JXFunction = { ctx, this, args in
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

        guard !args.isEmpty, let flag = args.removeFirst().numberValue else {
            throw err("fourth flag argument was not a number")
        }

        guard !args.isEmpty, let mode = args.removeFirst().numberValue else {
            throw err("fifth mode argument was not a number")
        }

        throw err("Unsupported: appendFileSync")
    }

    /// ```chmodSync(p: string, isLchmod: boolean, mode: number): void;```
    static let chmodSync: JXFunction = { ctx, this, args in
        dbg("chmodSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLchmod argument was unset")
        }
        let isLchmod = args.removeFirst()
        if isLchmod.isBoolean != true {
            throw err("second isLchmod argument was not a boolean")
        }

        guard !args.isEmpty, let mode = args.removeFirst().numberValue else {
            throw err("fourth mode argument was not a number")
        }

        throw err("Unsupported: chmodSync")
    }

    /// ```chownSync(p: string, isLchown: boolean, uid: number, gid: number): void;```
    static let chownSync: JXFunction = { ctx, this, args in
        dbg("chownSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLchmod argument was unset")
        }
        let isLchown = args.removeFirst()
        if isLchown.isBoolean != true {
            throw err("second isLchown argument was not a boolean")
        }

        guard !args.isEmpty, let uid = args.removeFirst().numberValue else {
            throw err("third uid argument was not a number")
        }

        guard !args.isEmpty, let gid = args.removeFirst().numberValue else {
            throw err("fourth gid argument was not a number")
        }

        throw err("Unsupported: chownSync")
    }

    /// ```existsSync(p: string): boolean;```
    static let existsSync: JXFunction = { ctx, this, args in
        dbg("existsSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        let exists = FileManager.default.fileExists(atPath: p)
        return JXValue(bool: exists, in: ctx)
    }

    /// ```linkSync(srcpath: string, dstpath: string): void;```
    static let linkSync: JXFunction = { ctx, this, args in
        dbg("linkSync", args)
        var args = args
        guard !args.isEmpty, let srcpath = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let dstpath = args.removeFirst().stringValue else {
            throw err("second argument was not a string")
        }

        try FileManager.default.linkItem(atPath: srcpath, toPath: dstpath)
        return JXValue(undefinedIn: ctx)
    }

    /// ```mkdirSync(p: string, mode: number): void;```
    static let mkdirSync: JXFunction = { ctx, this, args in
        dbg("mkdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        guard !args.isEmpty, let mode = args.removeFirst().numberValue else {
            throw err("second argument was not a number")
        }

        let attrs: [FileAttributeKey : Any] = [
            FileAttributeKey.posixPermissions: NSNumber(value: Int16(mode))
        ]

        try FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: attrs)
        return JXValue(undefinedIn: ctx)
    }

    /// ```openSync(p: string, flag: FileFlag, mode: number): File;```
    static let openSync: JXFunction = { ctx, this, args in
        dbg("openSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let flag = args.removeFirst().numberValue else {
            throw err("second flag argument was not a number")
        }

        guard !args.isEmpty, let mode = args.removeFirst().numberValue else {
            throw err("third mode argument was not a number")
        }

        //FileHandle(fileDescriptor: fd).closeFile()
        if let handle = FileHandle(forReadingAtPath: p) {
            // TODO: wrap Foundation.FileHandle in node's FileHandle (https://nodejs.org/api/fs.html#fs_class_filehandle)
            handle.closeFile()
        }

        throw err("Unsupported: openSync")
    }

    /// ```readFileSync(fname: string, encoding: string | null, flag: FileFlag): any;```
    static let readFileSync: JXFunction = { ctx, this, args in
        //dbg("readFileSync", args)
        var args = args
        guard !args.isEmpty, let fname = args.removeFirst().stringValue else {
            throw err("first fname argument was not a string")
        }

        let encoding: JXValue? = args.isEmpty ? nil : args.removeFirst()

        let flag: Double? = args.isEmpty ? nil : args.removeFirst().numberValue

        let data = try Data(contentsOf: URL(fileURLWithPath: fname), options: [])
        if let encoding = encoding, encoding.isString, let enc = encoding.stringValue {
            guard let contents = try String(data: data, encoding: parseEncoding(from: enc)) else {
                throw err("Unable to load string with encoding \(enc)")
            }
            return JXValue(string: contents, in: ctx)
        } else {
            if #available(macOS 10.12, iOS 10.0, tvOS 10.0, *) {
                return JXValue(newArrayBufferWithBytes: data, in: ctx)
            } else {
                throw err("unsupported platform for data load")
            }
        }
    }

    /// ```readdirSync(p: string): string[];```
    static let readdirSync: JXFunction = { ctx, this, args in
        //dbg("readdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: p)

        var array = JXValue(newArrayIn: ctx)
        for (index, path) in files.enumerated() {
            array[index] = JXValue(string: path, in: ctx)
        }
        return array
    }

    /// ```readlinkSync(p: string): string;```
    static let readlinkSync: JXFunction = { ctx, this, args in
        //dbg("readlinkSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        throw err("Unsupported: readlinkSync")
    }

    /// ```realpathSync(p: string, cache: {[path: string]: string}): string;```
    static let realpathSync: JXFunction = { ctx, this, args in
        dbg("realpathSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        throw err("Unsupported: realpathSync")
    }

    /// ```renameSync(oldPath: string, newPath: string): void;```
    static let renameSync: JXFunction = { ctx, this, args in
        dbg("renameSync", args)
        var args = args
        guard !args.isEmpty, let oldPath = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty, let newPath = args.removeFirst().stringValue else {
            throw err("second argument was not a string")
        }

        try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
        return JXValue(undefinedIn: ctx)
    }

    /// ```rmdirSync(p: string): void;```
    static let rmdirSync: JXFunction = { ctx, this, args in
        dbg("rmdirSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: p, isDirectory: &isDir) && isDir.boolValue == true {
            try FileManager.default.removeItem(atPath: p)
        } else {
            throw err("path is not a directory")
        }

        return JXValue(undefinedIn: ctx)
    }

    /// ```statSync(p: string, isLstat: boolean | null): Stats;```
    static let statSync: JXFunction = { ctx, this, args in
        //dbg("statSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        guard !args.isEmpty else {
            throw err("second isLstat argument was unset")
        }
        let isLstat = args.removeFirst()
        if isLstat.isBoolean != true {
            throw err("second isLstat argument was not a boolean")
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: p)

        let array = JXValue(newArrayIn: ctx)
        // "new fs.FS.Stats(\(itemType), \(size), \(mode), \(atime), \(mtime), \(ctime))"

        let type = attrs[.type] as? FileAttributeType ?? FileAttributeType.typeRegular

        let itemType = type == .typeSymbolicLink ? FileType.SYMLINK : type == .typeRegular ? FileType.FILE : type == .typeDirectory ? FileType.DIRECTORY : nil
        let size = (attrs[.size] as? NSNumber)?.doubleValue ?? 0.0
        let mode = (attrs[.posixPermissions] as? NSNumber)?.doubleValue ?? 0.0
        let atime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0.0
        let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0.0
        let ctime = (attrs[.creationDate] as? Date)?.timeIntervalSince1970 ?? 0.0

        //dbg("stat", p, "type:", itemType, "size:", size, "mode:", mode, "atime:", atime, "mtime:", mtime) // , "ctime:", ctime)

        array[0] = JXValue(double: Double(itemType?.rawValue ?? 0), in: ctx)
        array[1] = JXValue(double: size, in: ctx)
        array[2] = JXValue(double: mode, in: ctx)
        array[3] = JXValue(double: atime * 1000.0, in: ctx)
        array[4] = JXValue(double: mtime * 1000.0, in: ctx)
        array[5] = JXValue(double: ctime * 1000.0, in: ctx)
        return array
    }

    /// ```symlinkSync(srcpath: string, dstpath: string, type: string): void;```
    static let symlinkSync: JXFunction = { ctx, this, args in
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
        return JXValue(undefinedIn: ctx)
    }

    /// ```truncateSync(p: string, len: number): void;```
    static let truncateSync: JXFunction = { ctx, this, args in
        dbg("truncateSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        guard !args.isEmpty, let len = args.removeFirst().numberValue else {
            throw err("second argument was not a number")
        }

        throw err("Unsupported: truncateSync")
    }

    /// ```unlinkSync(p: string): void;```
    static let unlinkSync: JXFunction = { ctx, this, args in
        dbg("unlinkSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }
        try FileManager.default.removeItem(atPath: p)
        return JXValue(undefinedIn: ctx)
    }

    /// ```utimesSync(p: string, atime: Date, mtime: Date): void;```
    static let utimesSync: JXFunction = { ctx, this, args in
        dbg("utimesSync", args)
        var args = args
        guard !args.isEmpty, let p = args.removeFirst().stringValue else {
            throw err("first argument was not a string")
        }

        throw err("Unsupported: utimesSync")
    }

    /// ```writeFileSync(fname: string, data: string | Buffer, encoding: string | null, flag: FileFlag, mode: number): void;```
    static let writeFileSync: JXFunction = { ctx, this, args in
        //dbg("writeFileSync", args)
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

        let encoding: String? = args.isEmpty || !args[0].isString ? nil : args.removeFirst().stringValue
        let flag: JXValue? = args.isEmpty ? nil : args.removeFirst()
        let mode: JXValue? = args.isEmpty ? nil : args.removeFirst()

        if data.isString, let str = data.stringValue, let encoding = encoding {
            try str.write(toFile: fname, atomically: false, encoding: parseEncoding(from: encoding))
        } else if #available(macOS 10.12, macCatalyst 13.0, iOS 10.0, tvOS 10.0, *), data.isArrayBuffer, let contents = data.copyBytes() {
            try contents.write(to: URL(fileURLWithPath: fname))
        } else {
            throw JXContext.Errors.minimumSystemVersion
        }
        return JXValue(undefinedIn: ctx)
    }

    private static func parseEncoding(from encodingName: String) throws -> String.Encoding {
        switch encodingName.lowercased() {
        case "utf8", "utf-8":
            return String.Encoding.utf8
        case "ascii", "us-ascii":
            return String.Encoding.ascii
        case "iso-8859-1", "iso_8859-1":
            return String.Encoding.isoLatin1
        case "iso-8859-2", "iso_8859-2":
            return String.Encoding.isoLatin2
        case "windows-1250", "cp1250", "cp-1250", "1250":
            return String.Encoding.windowsCP1250
        case "windows-1251", "cp1251", "cp-1251", "1251":
            return String.Encoding.windowsCP1251
        case "windows-1252", "cp1252", "cp-1252", "1252":
            return String.Encoding.windowsCP1252
        case "windows-1253", "cp1253", "cp-1253", "1253":
            return String.Encoding.windowsCP1253
        case "windows-1254", "cp1254", "cp-1254", "1254":
            return String.Encoding.windowsCP1254
        case "macintosh", "mac":
            return String.Encoding.macOSRoman
        case "utf61", "utf-16":
            return String.Encoding.utf16
        case "utf32", "utf-32":
            return String.Encoding.utf32
        default:
            throw JudoErrors.invalidEncoding(encodingName)
        }
    }
}
