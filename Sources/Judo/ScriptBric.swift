//
//  File.swift
//
//
//  Created by Marc Prud'hommeaux on 5/21/21.
//


import SwiftJS
import BricBrac
import MiscKit

extension ScriptObject {
    /// Returns the JavaScript string value.
    @inlinable public func toJSON(indent: UInt32 = 0) -> String? {
        var ex: JSValueRef?
        let str = JSValueCreateJSONString(context.context, object, indent, &ex)
        defer { str.map(JSStringRelease) }
        return str.map(String.init)
    }

    /// Converts the instance to JSON and returns it as a `Bric` instance
    /// - Parameter native: whether to parse the string manually, which can be faster in some circumstances
    /// - Returns: the parsed Bric
    @inlinable public func toBric(native: Bool = false) throws -> Bric? {
        if native {
            return try toDecodable(ofType: Bric.self)
        } else {
            return try toJSON().map({ try Bric.parse($0) })
        }
    }

    /// Converts the instance to JSON and returns it as a `Bric` instance
    @inlinable public func toDecodable<T: Decodable>(ofType: T.Type) throws -> T {
        //try ScriptObjectDecoder(context: context).decode(self, ofType: ofType)
        throw err(wip("TODO"))
    }
}

