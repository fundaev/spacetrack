// Copyright (c) 2022 Sergei Fundaev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Network

fileprivate extension String {
    func toValidUri() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "*", with: "%2A")
    }
}

enum RValue {
    case less(String)
    case greater(String)
    case equal(String?)
    case notEqual(String?)
    case oneOf([String?])
    case between(String, String)
    
    func toString() -> String {
        let null = "null-val"
        switch self {
        case .less(let value):
            return ("<" + value).toValidUri()
        case .greater(let value):
            return (">" + value).toValidUri()
        case .equal(let value):
            return value?.toValidUri() ?? null
        case .notEqual(let value):
            return ("<>" + (value ?? null)).toValidUri()
        case .oneOf(let values):
            return values.map{ $0?.toValidUri() ?? null }.joined(separator: ",")
        case .between(let from, let to):
            return from.toValidUri() + "--" + to.toValidUri()
        }
    }
}

struct PredicateItem<Key: EntityField> {
    let lhs: Key
    let rhs: RValue
    
    init(lhs: Key, rhs: RValue) {
        self.lhs = lhs
        self.rhs = rhs
    }

    var query: String {
        return "/" + lhs.rawValue + "/" + rhs.toString()
    }
    
    func toPredicate() -> Predicate<Key> {
        return Predicate(data: [self])
    }
}

/// Predicate is used to generate the URI path in according to
/// [Space-Track API](https://www.space-track.org/documentation#/api) specification to receive the filtered data.
///
/// Predicate contains the array of items, each of them consists of three fields:
/// - Key
/// - Operator
/// - Value
/// 
/// Key is some EntityField. For example, `Satellite.Key`.
/// The list of supported operators is defined by [Space-Track API](https://www.space-track.org/documentation#/api)
/// And finally a Value is some value of String type or some other `LosslessStringConvertible`
/// protocol-compliant type.
///
/// To create some non-empty predicate one should use operators and methods of `EntityField` protocol extension,
/// such as `==`, `!=`, `<`, `>`, `between`, `oneOf` etc.
public struct Predicate<Key: EntityField>: QueryBuilder {
    var data: [PredicateItem<Key>] = []
    
    
    /// Create empty predicate
    ///
    /// Empty predicate means "do not filter the result".
    ///
    /// To creare not-empty predicate one should use the operators of `EntityField` protocol
    public init() {
    }
    
    init(data: [PredicateItem<Key>]) {
        self.data = data
    }
    
    var query: String {
        return data.map{ $0.query }.joined()
    }
    
    /// Join predicates by AND condition
    ///
    /// It can be used for example by this way:
    /// ```swift
    /// let predicate = Satelite.Key.name == "NOAA~~" && Satellite.Key.launchYear > 2000
    /// ```
    /// The first predicate here is
    /// ```swift
    /// Satelite.Key.name == "NOAA~~"
    /// ```
    /// and the second one is
    /// ```swift
    /// Satellite.Key.launchYear > 2000
    /// ```
    ///
    /// - parameters:
    ///     - lhs: First predicate
    ///     - rhs: Second predicate
    /// - returns:
    ///     Predicate containing the data of both lhs and rhs predicates
    static public func && (lhs: Predicate<Key>, rhs: Predicate<Key>) -> Predicate<Key> {
        var res = Predicate<Key>(data: lhs.data)
        res.data.append(contentsOf: rhs.data)
        return res
    }
}

public extension EntityField {
    /// Create `Predicate` meaning: the field is less than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.name < "Some text"
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func < (lhs: Self, value: String) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .less(value)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is less than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.objectNumber < 1000
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some value
    /// - returns: Non-empty predicate
    static func < <T: LosslessStringConvertible>(lhs: Self, value: T) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .less(String(value))).toPredicate()
    }

    /// Create `Predicate` meaning: the field is less than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch < Date()
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some value
    /// - returns: Non-empty predicate
    static func < (lhs: Self, value: Date) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .less(value.toString())).toPredicate()
    }

    /// Create `Predicate` meaning: the field is greater than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.name > "Some text"
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func > (lhs: Self, value: String) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .greater(value)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is greater than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.objectNumber > 1000
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some value
    /// - returns: Non-empty predicate
    static func > <T: LosslessStringConvertible>(lhs: Self, value: T) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .greater(String(value))).toPredicate()
    }

    /// Create `Predicate` meaning: the field is greater than the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch > Date(timeIntervalSince1970: 0)
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func > (lhs: Self, value: Date) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .greater(value.toString())).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to the value.
    ///
    /// The string `~~` means "any symbols". For example this predicate allows to get all satellites with names
    /// starting from "NOAA 17" text:
    /// ```swift
    /// let filter = Satellite.Key.name == "NOAA 17~~"
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func == (lhs: Self, value: String?) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .equal(value)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.objectNumber == 1000
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some value
    /// - returns: Non-empty predicate
    static func == <T: LosslessStringConvertible>(lhs: Self, value: T?) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .equal(value != nil ? String(value!) : nil)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is true or false
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.current == true
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Bool value
    /// - returns: Non-empty predicate
    static func == (lhs: Self, value: Bool) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .equal(value ? "Y" : "N")).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch == Date(timeIntervalSince1970: 0)
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func == (lhs: Self, value: Date) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .equal(value.toString())).toPredicate()
    }

    /// Create `Predicate` meaning: the field is not equal to the value.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.name != "NOAA 17"
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func != (lhs: Self, value: String?) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .notEqual(value)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is not equal to the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.objectNumber != 1000
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some value
    /// - returns: Non-empty predicate
    static func != <T: LosslessStringConvertible>(lhs: Self, value: T?) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .notEqual(value != nil ? String(value!) : nil)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is not true or false
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.current != false
    /// ```
    ///
    /// - parameters:
    ///     - lhs: some EntityField
    ///     - rhs: Bool value
    /// - returns: Non-empty predicate
    static func != (lhs: Self, value: Bool) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .notEqual(value ? "Y" : "N")).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to the value
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch != Date(timeIntervalSince1970: 0)
    /// ```
    ///
    /// - parameters:
    ///     - lhs: Some EntityField
    ///     - rhs: Some string value
    /// - returns: Non-empty predicate
    static func != (lhs: Self, value: Date) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: lhs, rhs: .notEqual(value.toString())).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to one of these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.name.oneOf(["ISS (UNITY)", "ISS (ZARYA)", "ISS (DESTINY)"])
    /// ```
    ///
    /// - parameters:
    ///     - values: The array of values
    /// - returns: Non-empty predicate
    func oneOf(values: [String?]) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: self, rhs: .oneOf(values)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to one of these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launchYear.oneOf([2020, 2021, 2022])
    /// ```
    ///
    /// - parameters:
    ///     - values: The array of values
    /// - returns: Non-empty predicate
    func oneOf<T: LosslessStringConvertible>(values: [T?]) -> Predicate<Self> {
        let data = values.map{ value in
            return value != nil ? String(value!) : nil
        }
        return PredicateItem<Self>(lhs: self, rhs: .oneOf(data)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is equal to one of these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch.oneOf([Date(), Date(timeIntervalSince1970: 0), nil])
    /// ```
    ///
    /// - parameters:
    ///     - values: The array of values
    /// - returns: Non-empty predicate
    func oneOf(values: [Date?]) -> Predicate<Self> {
        let stringValues = values.map { $0?.toString() }
        return PredicateItem<Self>(lhs: self, rhs: .oneOf(stringValues)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is between these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.name.between(from: "NOAA", to: "NOAA 18")
    /// ```
    ///
    /// - parameters:
    ///     - from: Left border of values
    ///     - to: Right border of values
    /// - returns: Non-empty predicate
    func between(from: String, to: String) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: self, rhs: .between(from, to)).toPredicate()
    }

    /// Create `Predicate` meaning: the field is between these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launchYear.between(from: 2000, to: 2022)
    /// ```
    ///
    /// - parameters:
    ///     - from: Left border of values
    ///     - to: Right border of values
    /// - returns: Non-empty predicate
    func between<T: LosslessStringConvertible>(from: T, to: T) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: self, rhs: .between(String(from), String(to))).toPredicate()
    }

    /// Create `Predicate` meaning: the field is between these values.
    ///
    /// For example:
    /// ```swift
    /// let filter = Satellite.Key.launch.between(from: Date(timeIntervalSince1970: 0), to: Date())
    /// ```
    ///
    /// - parameters:
    ///     - from: Left border of values
    ///     - to: Right border of values
    /// - returns: Non-empty predicate
    func between(from: Date, to: Date) -> Predicate<Self> {
        return PredicateItem<Self>(lhs: self, rhs: .between(from.toString(), to.toString())).toPredicate()
    }
}

fileprivate extension Date {
    func toString() -> String {
        return makeDateFormatter().string(from: self)
    }
}
