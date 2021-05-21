//
//  File.swift
//
//
//  Created by Marc Prud'hommeaux on 5/21/21.
//


import SwiftJS
import BricBrac

extension ScriptObject {
    /// Creates a JavaScript value of the `Bric` JSON type.
    ///
    /// - Parameters:
    ///   - value: The value to assign to the object.
    ///   - context: The execution context to use.
    @inlinable public convenience init(bric value: Bric, in context: ScriptContext) throws {
        let json = try value.encodedString()
        let value = json.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(value) }
        self.init(context: context, object: JSValueMakeFromJSONString(context.context, value))
    }

    /// Returns the JavaScript string value.
    @inlinable public func toJSON(indent: UInt32 = 0) -> String? {
        var ex: JSValueRef?
        let str = JSValueCreateJSONString(context.context, object, indent, &ex)
        defer { str.map(JSStringRelease) }
        return str.map(String.init)
    }

    /// Converts the instance to JSON and returns it as a `Bric` instance
    @inlinable public func toBric() throws -> Bric? {
        try toJSON().map({ try Bric.parse($0) })
    }
}
