//
//  File.swift
//
//
//  Created by Marc Prud'hommeaux on 5/21/21.
//


import JXKit
import BricBrac
import MiscKit

extension JXValue {

    /// Converts the instance to JSON and returns it as a `Bric` instance
    /// - Parameter native: whether to parse the string manually, which can be faster in some circumstances
    /// - Returns: the parsed Bric
    @inlinable public func toBric(native: Bool) throws -> Bric? {
        if native {
            return try toDecodable(ofType: Bric.self)
        } else {
            return try toJSON().map({ try Bric.parse($0) })
        }
    }
}

