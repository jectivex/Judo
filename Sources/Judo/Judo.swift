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

public extension JXContext {
    /// Installs a top-level "global" variable.
    func installExports(require: Bool) {
        if self.global["exports"].isObject == false {
            let exports = JXValue(newObjectIn: self)
            self.global["exports"] = exports
        }

        if require == true && self.global["require"].isUndefined == true {
            self.global["require"] = JXValue(newFunctionIn: self) { ctx, this, args in
                dbg("require", args)
                return JXValue(nullIn: ctx)
            }
        }
    }

    /// Installs `console.log` and other functions to output to `os_log` via `MiscKit.dbg`
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/API/console
    func installConsole() {
        let console = JXValue(newObjectIn: self)
        let createLog = { (level: UInt8) in
            JXValue(newFunctionIn: self) { ctx, this, args in
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
                return JXValue(nullIn: ctx)
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
    func installTimer(immediate: Bool = false) {
        let setTimeout = JXValue(newFunctionIn: self) { ctx, this, arguments in
            var args = arguments
            if args.count < 1 {
                dbg("error in setTimeout: too few arguments")
                return JXValue(nullIn: ctx)
            }

            let f = args.removeFirst()
            if !f.isFunction {
                dbg("first argument to setTimeout was not a function")
                return JXValue(nullIn: ctx)
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

//                if t <= 0 {
//                    item.perform()
//                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(Int(t)), execute: item)
//                }
            }


            // return the item identifier for the work item so we can cancel it later
            return JXValue(double: Double(timerID), in: ctx)
        }

        let clearTimeout = JXValue(newFunctionIn: self) { ctx, this, arguments in
            if let timeoutID = arguments.first?.doubleValue {
                globalTimerQueue.sync {
                    if let item = globalTimers.removeValue(forKey: Int(timeoutID)) {
                        item.cancel()
                    }
                }
            }
            return JXValue(nullIn: ctx)
        }

        self.global["setTimeout"] = setTimeout
        self.global["clearTimeout"] = clearTimeout

        if immediate {
            self.global["setImmediate"] = setTimeout
        }
    }
}

private var globalTimers: [Int: DispatchWorkItem] = [:]
private var globalTimerCount = 0
private var globalTimerQueue = DispatchQueue(label: "globalTimers")

