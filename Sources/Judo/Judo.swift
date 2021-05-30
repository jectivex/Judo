import JXKit
import BricBrac
import MiscKit
import Dispatch

public enum JudoErrors : Error {
    /// The URL could not be found in the resources
    case cannotLoadScriptURL
    /// An evanuation error occurred
    case evaluationError(JXValue)
    /// The specified encoding name is invalid
    case invalidEncoding(String)
}

public extension JXValue {
    /// Adds a function with the given name to this value, which should be an object type.
    /// - Parameters:
    ///   - name: the name of the function
    ///   - shim: whether to insert a shim to make the function appear as a true JavaScript function (which permits `apply` to be invoked on it)
    ///   - callback: the callback for the function
    @discardableResult func addFunction(_ name: String, shim: Bool = true, callback: @escaping JXObjectCallAsFunctionCallback) throws -> JXValue? {
        if !isObject { return nil }

        let fval = JXValue(newFunctionIn: env, callback: callback)

        if !shim {
            self[name] = fval // set the object posing as a function directly
        } else {
            // when we want to be treated just like a read JS function, we need to put in a shim function first
            let shimName = "__shim_" + name
            self[shimName] = fval
            self[name] = try env.eval("(function() { this.\(shimName)(...arguments); })")
        }

        return fval
    }
}

public extension JXContext {

    /// Installs a top-level "global" variable.
    func installExports(require: Bool, global installGlobal: Bool) {
        if self.global["exports"].isObject == false {
            let exports = JXValue(newObjectIn: self)
            self.global["exports"] = exports
        }

        if installGlobal {
            if self.global["global"].isObject == false {
                let exports = JXValue(newObjectIn: self)
                self.global["global"] = exports
            }
        }

        if require == true && self.global["require"].isUndefined == true {
            self.global["require"] = JXValue(newFunctionIn: self) { ctx, this, args in
                dbg("require", args)
                return JXValue(nullIn: ctx)
            }
        }
    }

    /// The level of `console.log`
    enum ConsoleLogLevel: UInt8 {
        case debug = 0, log = 1, info = 2, warn = 3, error = 4
    }

    /// The default `Console.log` function, which merely routes console log messages
    static func console(for level: ConsoleLogLevel) -> JXObjectCallAsFunctionCallback {
        return { ctx, this, args in
            dbg(level: level.rawValue,
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
            return JXValue(nullIn: ctx)
        }
    }

    /// Installs `console.log` and other functions to output to `os_log` via `MiscKit.dbg`
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/API/console
    func installConsole(
        debug: @escaping JXObjectCallAsFunctionCallback = console(for: .debug),
        log: @escaping JXObjectCallAsFunctionCallback = console(for: .log),
        info: @escaping JXObjectCallAsFunctionCallback = console(for: .info),
        warn: @escaping JXObjectCallAsFunctionCallback = console(for: .warn),
        error: @escaping JXObjectCallAsFunctionCallback = console(for: .error)) throws {
        let console = JXValue(newObjectIn: self)

        try console.addFunction("debug", callback: debug)
        try console.addFunction("log", callback: log)
        try console.addFunction("info", callback: info)
        try console.addFunction("warn", callback: warn)
        try console.addFunction("error", callback: error)

        self.global["console"] = console
    }

    /// The standard scheduler that uses a default DispatchQueue.global()
    static func dispatchScheduler(qos: DispatchQoS.QoSClass) -> (Double, DispatchWorkItem) -> () {
        { t, item in
            DispatchQueue.global(qos: qos).asyncAfter(deadline: .now() + .milliseconds(Int(t)), execute: item)
        }
    }

    /// Installs `setTimeout` to use `DispatchQueue.global.asyncAfter` with the `default` QoS.
    /// https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setTimeout
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func installTimer(immediate: Bool = false, scheduler: @escaping (Double, DispatchWorkItem) -> () = JXContext.dispatchScheduler(qos: .default)) {
        let setTimeout = JXValue(newFunctionIn: self) { ctx, this, arguments in
            var args = arguments
            if args.count < 1 {
                dbg("error in setTimeout: too few arguments")
                return JXValue(nullIn: ctx)
            }

            let cb = args.removeFirst()
            if !cb.isFunction {
                dbg("first argument to setTimeout was not a function")
                return JXValue(nullIn: ctx)
            }

            let t = !args.isEmpty ? args.removeFirst().numberValue ?? 0.0 : 0.0

            let timerID = ctx.globalTimeoutsCounter
            ctx.globalTimeoutsCounter += 1

            let tid = JXValue(double: Double(timerID), in: ctx)

            let item = DispatchWorkItem {
                dbg("dispatching timerID:", timerID)
                if ctx.globalTimeouts.hasProperty(tid) {
                    ctx.globalTimeouts.deleteProperty(tid)
                }
                cb.call(withArguments: [])
            }

            // remember the global timer ID in order to be able to cancel it or execute ahead of schedule
            ctx.addTimeoutFunction(id: timerID, item: item)

            // perform the scheduling
            scheduler(t, item)

            // return the item identifier for the work item so it can cancelled
            return JXValue(double: Double(timerID), in: ctx)
        }

        let clearTimeout = JXValue(newFunctionIn: self) { ctx, this, arguments in
            if let timeoutID = arguments.first?.numberValue, !timeoutID.isNaN {
                ctx.flushTimeout(id: Int(timeoutID), perform: false)
            }
            return JXValue(undefinedIn: ctx)
        }

        self.global["setTimeout"] = setTimeout
        self.global["clearTimeout"] = clearTimeout

        if immediate {
            self.global["setImmediate"] = setTimeout
        }
    }

    /// The identifiers of all the pending timeouts (unordered)
    var pendingTimeouts: [Int] {
        globalTimeouts.properties.compactMap(Int.init)
    }

    @available(*, deprecated, message: "TESTING")
    func crushTimeouts() {
        assert(self.removeProperty("__globalTimeouts") == wip(true))
    }

    /// Flushes any pending timeouts immediately.
    /// - Parameter perform: whether to perform (or cancel) the next timeout
    /// - Returns: the timeout ID that was flushed
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    func processNextTimeout(perform: Bool = true) -> Int? {
        guard let nextTimeoutID = pendingTimeouts.sorted().first else {
            return nil
        }

        dbg("processing timeout ID", nextTimeoutID)
        flushTimeout(id: nextTimeoutID, perform: perform)
        return nextTimeoutID
    }

    /// Flushes the next timeout, either invoking or cancelling it, and clears it from the global dictionary
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    private func flushTimeout(id key: Int, perform: Bool) {
        precondition(globalTimeouts.isArray)
        dbg("flushing timeout ID", key)

        let callback = globalTimeouts[key]

        globalTimeouts.deleteProperty(JXValue(double: Double(key), in: self))
        //globalTimeouts = JXValue(undefinedIn: self)
        
        // now execute the callback function with `false` (which means cancel)
        if callback.isFunction {
            // clear the timeout from the array
            callback.call(withArguments: [JXValue(bool: perform, in: self)]) // call with false means to cancel it
        } else {
            dbg("no timeout found for id:", key, callback, "keys", pendingTimeouts)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    private func addTimeoutFunction(id key: Int, item: DispatchWorkItem) {
        let callback = JXValue(newFunctionIn: self) { ctx, this, args in
            if item.isCancelled == false {
                if args.first?.booleanValue == true {
                    item.perform()
                }
                item.cancel() // always cancel so we don't execute twice
            }
            //ctx.globalTimeouts.deleteProperty(JXValue(double: Double(key), in: ctx))
            return JXValue(undefinedIn: ctx)
        }

        if !globalTimeouts.isArray {
            globalTimeouts = JXValue(newArrayIn: self)
        }
        precondition(globalTimeouts.isArray)
        globalTimeouts[key] = callback
    }

    internal var globalTimeouts: JXValue {
        get { global["__globalTimeouts"] }
        set {
            precondition(newValue.isArray)
            global["__globalTimeouts"] = newValue
        }
    }

    /// The internal vairable tracking the gobal timers
    internal var globalTimeoutsCounter: Int {
        get {
            let value = global["__globalTimeoutsCounter"]
            if value.isNumber, let num = value.numberValue {
                return Int(num)
            } else {
                return 0
            }
        }

        set {
            global["__globalTimeoutsCounter"] = JXValue(double: Double(newValue), in: self)
        }
    }
}

private var globalTimerQueue = DispatchQueue(label: "globalTimers")
