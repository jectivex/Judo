//
//  File.swift
//  
//
//  Created by Marc Prud'hommeaux on 5/22/21.
//

import Foundation
import SwiftJS


public extension ScriptContext {
    /// Encodes the given object into this context
    func encode<T: Encodable>(_ value: T) throws -> ScriptObject {
        try ScriptObjectEncoder(context: self).encode(value)
    }
}

// MARK: Shared

fileprivate struct _ScriptKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = _ScriptKey(stringValue: "super")!
}


// MARK: Encoding

extension ScriptObject {
    /// Adds the given object as the final element of this array
    func add(_ object: ScriptObject) {
        if isArray {
            self[self.count] = object
        } else {
            print("warning: ignoring array call on non-array")
        }
    }

    @available(*, deprecated, message: "WARNING: does not work correctly: it sets the object at the index rather than shifting it")
    func insert(_ object: ScriptObject, at index: Int) {
        if isArray {
            self[index] = object
        } else {
            print("warning: ignoring array call on non-array")
        }
    }
}

open class ScriptObjectEncoder {

    // MARK: - Options
    /// The output format to write the property list data in. Defaults to `.binary`.
    open var outputFormat: PropertyListSerialization.PropertyListFormat = .binary

    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let outputFormat: PropertyListSerialization.PropertyListFormat
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(outputFormat: outputFormat, userInfo: userInfo)
    }

    let context: ScriptContext

    // MARK: - Constructing a Property List Encoder
    /// Initializes `self` with default strategies.
    public init(context: ScriptContext) {
        self.context = context
    }

    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns its property list representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded property list data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<Value : Encodable>(_ value: Value) throws -> ScriptObject {
        let topLevel = try encodeToTopLevelContainer(value)
        return topLevel
    }

    /// Encodes the given top-level value and returns its plist-type representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new top-level array or dictionary representing the value.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    internal func encodeToTopLevelContainer<Value : Encodable>(_ value: Value) throws -> ScriptObject {
        let encoder = JSEncoder(context: context, options: self.options)
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [],
                                                                   debugDescription: "Top-level \(Value.self) did not encode any values."))
        }

        return topLevel
    }
}

// MARK: - JSEncoder

fileprivate class JSEncoder : Encoder {
    fileprivate let context: ScriptContext

    // MARK: Properties
    /// The encoder's storage.
    fileprivate var storage: _ScriptEncodingStorage

    /// Options set on the top-level encoder.
    fileprivate let options: ScriptObjectEncoder._Options

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(context: ScriptContext, options: ScriptObjectEncoder._Options, codingPath: [CodingKey] = []) {
        self.context = context
        self.options = options
        self.storage = _ScriptEncodingStorage()
        self.codingPath = codingPath
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }

    // MARK: - Encoder Methods
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: ScriptObject
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer(context)
        } else {
            guard let container = self.storage.containers.last else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        let container = _ScriptKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: ScriptObject
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushUnkeyedContainer(context)
        } else {
            guard let container = self.storage.containers.last else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        return _ScriptUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

// MARK: - Encoding Storage and Containers
fileprivate struct _ScriptEncodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the plist types (NSNumber, NSString, NSDate, NSArray, NSDictionary).
    private(set) fileprivate var containers: [ScriptObject] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer(_ context: ScriptContext) -> ScriptObject {
        let dictionary = ScriptObject(newObjectIn: context)
        self.containers.append(dictionary)
        return dictionary
    }

    fileprivate mutating func pushUnkeyedContainer(_ context: ScriptContext) -> ScriptObject {
        let array = ScriptObject(newArrayIn: context)
        self.containers.append(array)
        return array
    }

    fileprivate mutating func push(container: __owned ScriptObject) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() -> ScriptObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

// MARK: - Encoding Containers

fileprivate struct _ScriptUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: JSEncoder

    /// A reference to the container we're writing to.
    private let container: ScriptObject

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JSEncoder, codingPath: [CodingKey], wrapping container: ScriptObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { self.container.add(ScriptObject(nullIn: encoder.context)) }
    public mutating func encode(_ value: Bool)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Float)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Double) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.add(self.encoder.box(value)) }

    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(_ScriptKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(_ScriptKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let dictionary = ScriptObject(newObjectIn: encoder.context)
        self.container.add(dictionary)

        let container = _ScriptKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_ScriptKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let array = ScriptObject(newArrayIn: encoder.context)
        self.container.add(array)
        return _ScriptUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    public mutating func superEncoder() -> Encoder {
        return __ScriptReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
    }
}

extension JSEncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods
    private func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: ScriptObject(nullIn: context))
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations
extension JSEncoder {

    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool)   -> ScriptObject {
        return ScriptObject(bool: value, in: context)
    }

    fileprivate func box(_ value: Int)    -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Int8)   -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Int16)  -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Int32)  -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Int64)  -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: UInt)   -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: UInt8)  -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: UInt16) -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: UInt32) -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: UInt64) -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Float)  -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: Double) -> ScriptObject {
        return ScriptObject(double: .init(value), in: context)
    }
    fileprivate func box(_ value: String) -> ScriptObject {
        return ScriptObject(string: value, in: context)
    }

    fileprivate func box<T : Encodable>(_ value: T) throws -> ScriptObject {
        return try self.box_(value) ?? ScriptObject(newObjectIn: context)
    }

    fileprivate func box_<T : Encodable>(_ value: T) throws -> ScriptObject? {
        if let date = value as? Date {
            return ScriptObject(date: date, in: context)
        }

        if let data = value as? Data, #available(macOS 10.12, iOS 10.0, tvOS 10.0, *) {
            return ScriptObject(newArrayBufferWithBytes: data, in: context)
        }

        // The value should request a container from the JSEncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
        } catch let error {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}

fileprivate struct _ScriptKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: JSEncoder

    /// A reference to the container we're writing to.
    private let container: ScriptObject

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JSEncoder, codingPath: [CodingKey], wrapping container: ScriptObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(nullIn: encoder.context)
    }

    public mutating func encode(_ value: Bool, forKey key: Key)   throws {
        self.container[key.stringValue] = ScriptObject(bool: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Int, forKey key: Key)    throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Int8, forKey key: Key)   throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Int16, forKey key: Key)  throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Int32, forKey key: Key)  throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Int64, forKey key: Key)  throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: UInt, forKey key: Key)   throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: UInt8, forKey key: Key)  throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: UInt16, forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: UInt32, forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: UInt64, forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: String, forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(string: value, in: encoder.context)
    }

    public mutating func encode(_ value: Float, forKey key: Key)  throws {
        self.container[key.stringValue] = ScriptObject(double: .init(value), in: encoder.context)
    }

    public mutating func encode(_ value: Double, forKey key: Key) throws {
        self.container[key.stringValue] = ScriptObject(double: value, in: encoder.context)
    }

    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = ScriptObject(newObjectIn: encoder.context)
        self.container[key.stringValue] = dictionary

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let container = _ScriptKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = ScriptObject(newArrayIn: encoder.context)
        self.container[key.stringValue] = array

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _ScriptUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    public mutating func superEncoder() -> Encoder {
        return __ScriptReferencingEncoder(referencing: self.encoder, at: _ScriptKey.super, wrapping: self.container)
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return __ScriptReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
    }
}


// MARK: - __ScriptReferencingEncoder
/// __ScriptReferencingEncoder is a special subclass of JSEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class __ScriptReferencingEncoder : JSEncoder {
    // MARK: Reference types.
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(ScriptObject, Int)

        /// Referencing a specific key in a dictionary container.
        case dictionary(ScriptObject, String)
    }

    // MARK: - Properties
    /// The encoder we're referencing.
    private let encoder: JSEncoder

    /// The container reference itself.
    private let reference: Reference

    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(referencing encoder: JSEncoder, at index: Int, wrapping array: ScriptObject) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(context: encoder.context, options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(_ScriptKey(index: index))
    }

    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    fileprivate init(referencing encoder: JSEncoder, at key: CodingKey, wrapping dictionary: ScriptObject) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(context: encoder.context, options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }

    // MARK: - Coding Path Operations
    fileprivate override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // MARK: - Deinitialization
    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: ScriptObject
        switch self.storage.count {
        case 0: value = ScriptObject(newObjectIn: context)
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .array(let array, let index):
            array.insert(value, at: index)

        case .dictionary(let dictionary, let key):
            dictionary[key] = value
        }
    }
}

// MARK: Decoder

/// `ScriptObjectDecoder` facilitates the decoding of property list values into semantic `Decodable` types.
open class ScriptObjectDecoder {
    let context: ScriptContext
    
    // MARK: Options
    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct _Options {
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        return _Options(userInfo: userInfo)
    }

    // MARK: - Constructing a Property List Decoder
    /// Initializes `self` with default strategies.
    public init(context: ScriptContext) {
        self.context = context
    }

    // MARK: - Decoding Values
    /// Decodes a top-level value of the given type from the given property list representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not a valid property list.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from data: ScriptObject) throws -> T {
        var format: PropertyListSerialization.PropertyListFormat = .binary
        return try decode(type, from: data, format: &format)
    }

    /// Decodes a top-level value of the given type from the given property list representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - parameter format: The parsed property list format.
    /// - returns: A value of the requested type along with the detected format of the property list.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not a valid property list.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T : Decodable>(_ type: T.Type, from object: ScriptObject, format: inout PropertyListSerialization.PropertyListFormat) throws -> T {
        return try decode(type, fromTopLevel: object)
    }

    /// Decodes a top-level value of the given type from the given property list container (top-level array or dictionary).
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter container: The top-level plist container.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not a valid property list.
    /// - throws: An error if any value throws an error during decoding.
    internal func decode<T : Decodable>(_ type: T.Type, fromTopLevel container: ScriptObject) throws -> T {
        let decoder = __ScriptDecoder(referencing: container, options: self.options)
        guard let value = try decoder.unbox(container, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }

        return value
    }
}

// MARK: - __ScriptDecoder

fileprivate class __ScriptDecoder : Decoder {
    let context: ScriptContext

    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: _ScriptDecodingStorage

    /// Options set on the top-level decoder.
    fileprivate let options: ScriptObjectDecoder._Options

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(referencing container: ScriptObject, at codingPath: [CodingKey] = [], options: ScriptObjectDecoder._Options) {
        self.context = container.context
        self.storage = _ScriptDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }

    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer.isNull) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard self.storage.topContainer.isObject else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: self.storage.topContainer)
        }

        let container = _ScriptKeyedDecodingContainer<Key>(referencing: self, wrapping: self.storage.topContainer.dictionary)
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer.isNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }

        guard self.storage.topContainer.isArray, let topContainer = self.storage.topContainer.array else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: self.storage.topContainer)
        }

        return _ScriptUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Decoding Storage
fileprivate struct _ScriptDecodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the plist types (NSNumber, Date, String, Array, [String : Any]).
    private(set) fileprivate var containers: [ScriptObject] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: ScriptObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: __owned ScriptObject) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers
fileprivate struct _ScriptKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: __ScriptDecoder

    /// A reference to the container we're reading from.
    private let container: [String : ScriptObject]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: __ScriptDecoder, wrapping container: [String : ScriptObject]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    // MARK: - KeyedDecodingContainerProtocol Methods
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        self.container[key.stringValue]?.isNull == true
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        guard let value = try self.decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get nested keyed container -- no value found for key \"\(key.stringValue)\""))
        }

        guard value.isObject else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        let container = _ScriptKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: value.dictionary)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get nested unkeyed container -- no value found for key \"\(key.stringValue)\""))
        }

        guard value.isArray, let array = value.array else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        return _ScriptUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value: ScriptObject = self.container[key.stringValue] ?? ScriptObject(undefinedIn: decoder.context)
        return __ScriptDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: _ScriptKey.super)
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

fileprivate struct _ScriptUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: __ScriptDecoder

    /// A reference to the container we're reading from.
    private let container: [ScriptObject]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: __ScriptDecoder, wrapping container: [ScriptObject]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        if self.container[self.currentIndex].isNull {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_ScriptKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard !value.isNull else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard value.isObject else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : ScriptObject].self, reality: value)
        }

        self.currentIndex += 1
        let container = _ScriptKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: value.dictionary)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get nested unkeyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard !(value.isNull) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                      debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard value.isArray, let array = value.array else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        self.currentIndex += 1
        return _ScriptUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_ScriptKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return __ScriptDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
}

extension __ScriptDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }

    public func decodeNil() -> Bool {
        storage.topContainer.isNull
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    public func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(type)
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

// MARK: - Concrete Value Representations
extension __ScriptDecoder {
    /// Returns the given value unboxed from a container.
    fileprivate func unbox(_ value: ScriptObject, as type: Bool.Type) throws -> Bool? {
        if !value.isBoolean {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return value.boolValue
    }

    fileprivate func unboxNumber(_ value: ScriptObject) throws -> Double {
        guard value.isNumber, let double = value.doubleValue else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: Double.self, reality: value)
        }
        return double
    }

    fileprivate func unbox(_ value: ScriptObject, as type: Double.Type) throws -> Double? {
        try unboxNumber(value)
    }

    fileprivate func unbox(_ value: ScriptObject, as type: String.Type) throws -> String? {
        guard value.isString, let string = value.stringValue else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return string
    }

    fileprivate func unbox(_ value: ScriptObject, as type: Date.Type) throws -> Date? {
        guard value.isDate, let date = value.dateValue else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return date
    }

    fileprivate func unbox(_ value: ScriptObject, as type: Data.Type) throws -> Data? {
        guard value.isArrayBuffer, #available(macOS 10.12, iOS 10.0, tvOS 10.0, *), let data = value.copyBytes() else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return data
    }

    fileprivate func unbox<T : Decodable>(_ value: ScriptObject, as type: T.Type) throws -> T? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self) as? T
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self) as? T
        } else {
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}


extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(type(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }
}
