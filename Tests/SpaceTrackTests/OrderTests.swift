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

import XCTest
import class Foundation.Bundle
@testable import SpaceTrack

final class OrderTests: XCTestCase {

    enum Field: String, EntityField {
        case id    = "IDENTITY"
        case name  = "NAME"
        case value = "VAL"
        
        var dateFormat: DateFormat {
            .Date
        }
    }
    
    typealias FieldOrder = OrderItem<Field>
    typealias OrderField = Order<Field>

    func testOrderItem() {
        XCTAssertEqual("IDENTITY", FieldOrder(for: .id).query)
        XCTAssertEqual("IDENTITY", FieldOrder(for: .id, direction: .asc).query)
        XCTAssertEqual("IDENTITY%20desc", FieldOrder(for: .id, direction: .desc).query)
    }

    func testOrderBy() {
        XCTAssertEqual("", OrderField().query)
        XCTAssertEqual("/orderby/VAL", OrderField(item: FieldOrder(for: .value)).query)
        XCTAssertEqual("/orderby/VAL", OrderField(item: FieldOrder(for: .value, direction: .asc)).query)
        XCTAssertEqual("/orderby/VAL%20desc", OrderField(item: FieldOrder(for: .value, direction: .desc)).query)
    }
    
    func testOrderByAsExtension() {
        XCTAssertEqual("/orderby/NAME", Field.name.asc.query)
        XCTAssertEqual("/orderby/NAME%20desc", Field.name.desc.query)
    }

    func testTwoOrderItems() {
        XCTAssertEqual("/orderby/NAME,IDENTITY", (Field.name.asc & Field.id.asc).query)
        XCTAssertEqual("/orderby/NAME%20desc,IDENTITY%20desc", (Field.name.desc & Field.id.desc).query)
    }

    func testMultipleOrderItems() {
        XCTAssertEqual("/orderby/IDENTITY,NAME,VAL", (Field.id.asc & Field.name.asc & Field.value.asc).query)
        XCTAssertEqual("/orderby/IDENTITY%20desc,NAME%20desc,VAL%20desc",
                       (Field.id.desc & Field.name.desc & Field.value.desc).query)
    }
}
