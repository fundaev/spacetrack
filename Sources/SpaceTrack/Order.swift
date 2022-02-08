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

struct OrderItem<Key: EntityField>: QueryBuilder {
    enum Direction {
        case asc
        case desc
    }
    var key: Key
    var direction: Direction
    
    init(for key: Key, direction: Direction = .asc) {
        self.key = key
        self.direction = direction
    }
    
    var query: String {
        let dir = self.direction == .desc ? "%20desc" : ""
        return "\(key.rawValue)\(dir)"
    }
    
    func toOrder() -> Order<Key> {
        return Order(item: self)
    }
}

/// Order is used to generate the URI path in according to
/// [Space-Track API](https://www.space-track.org/documentation#/api) specification to receive the sorted data.
///
/// Order contains the array of items, each of them consists of the fields:
/// - Key
/// - Direction
///
/// Key is some `EntityField` instance. For example it may be `Satellite.Key`.
/// Direction defines the method of sorting: ascending or descending.
///
/// To create non-empty `Order` one should use `asc()` and `desc()` methods of `EntityField` protocol extension.
public struct Order<Key: EntityField>: QueryBuilder {
    var items: [OrderItem<Key>]
    
    /// Create empty order
    public init() {
        self.items = []
    }

    init(item: OrderItem<Key>) {
        self.items = [item]
    }

    init(items: [OrderItem<Key>]) {
        self.items = items
    }

    var query: String {
        if self.items.isEmpty {
            return ""
        }
        return "/orderby/" + self.items.map{ $0.query }.joined(separator: ",")
    }

    /// Join two orders
    ///
    /// For example:
    /// ```swift
    /// let order = Satellite.Key.name.asc() & Satellite.Key.objectId.desc()
    /// ```
    ///
    /// - parameters:
    ///     - lhs: First order
    ///     - rhs: Second order
    /// - returns: Order structure containing the data from both parameters.
    ///            It allows to sort the result by several fields.
    static public func & (lhs: Order<Key>, rhs: Order<Key>) -> Order<Key> {
        var res = Order<Key>(items: lhs.items)
        res.items.append(contentsOf: rhs.items)
        return res
    }
}


public extension EntityField {
    /// Create `Order` structure to sort the data by EntityField ascendingly
    ///
    /// For example:
    /// ```swift
    /// let order = Satellite.Key.name.asc()
    /// ```
    var asc: Order<Self> {
        OrderItem<Self>(for: self.self).toOrder()
    }

    /// Create `Order` structure to sort the data by EntityField descendingly
    ///
    /// For example:
    /// ```swift
    /// let order = Satellite.Key.name.desc()
    /// ```
    var desc: Order<Self> {
        OrderItem<Self>(for: self.self, direction: .desc).toOrder()
    }
}
