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

final class PredicateTests: XCTestCase {
    enum Field: String, EntityField {
        case id    = "IDENTITY"
        case name  = "NAME"
        case value = "VAL"
    }

    typealias FieldPredicate = PredicateItem<Field>

    func testSimplePredicate() {
        XCTAssertEqual("/IDENTITY/%3C1", FieldPredicate(lhs: .id, rhs: .less("1")).query)
        XCTAssertEqual("/NAME/%3E2", FieldPredicate(lhs: .name, rhs: .greater("2")).query)
        XCTAssertEqual("/VAL/test", FieldPredicate(lhs: .value, rhs: .equal("test")).query)
        XCTAssertEqual("/VAL/null-val", FieldPredicate(lhs: .value, rhs: .equal(nil)).query)
        XCTAssertEqual("/VAL/%3C%3Etest", FieldPredicate(lhs: .value, rhs: .notEqual("test")).query)
        XCTAssertEqual("/VAL/%3C%3Enull-val", FieldPredicate(lhs: .value, rhs: .notEqual(nil)).query)
        XCTAssertEqual("/IDENTITY/value,null-val", FieldPredicate(lhs: .id, rhs: .oneOf(["value", nil])).query)
        XCTAssertEqual("/IDENTITY/min--max", FieldPredicate(lhs: .id, rhs: .between("min", "max")).query)
    }

    func testPredicateFromKey() {
        XCTAssertEqual("/IDENTITY/%3C1", (Field.id < "1").query)
        XCTAssertEqual("/IDENTITY/%3C123", (Field.id < 123).query)
        XCTAssertEqual("/IDENTITY/%3C-57", (Field.id < -57).query)
        XCTAssertEqual("/IDENTITY/%3C12.456", (Field.id < 12.456).query)
        XCTAssertEqual("/IDENTITY/%3C-0.123", (Field.id < -0.123).query)
        XCTAssertEqual("/IDENTITY/%3C1970-01-01", (Field.id < Date(timeIntervalSince1970: 0)).query)

        XCTAssertEqual("/NAME/%3E2", (Field.name > "2").query)
        XCTAssertEqual("/NAME/%3E732", (Field.name > 732).query)
        XCTAssertEqual("/NAME/%3E-159", (Field.name > -159).query)
        XCTAssertEqual("/NAME/%3E7.32", (Field.name > 7.32).query)
        XCTAssertEqual("/NAME/%3E-0.593", (Field.name > -0.593).query)
        XCTAssertEqual("/NAME/%3E1970-01-01", (Field.name > Date(timeIntervalSince1970: 0)).query)

        XCTAssertEqual("/VAL/test", (Field.value == "test").query)
        XCTAssertEqual("/VAL/null-val", (Field.value == nil).query)
        XCTAssertEqual("/VAL/123", (Field.value == 123).query)
        XCTAssertEqual("/VAL/-321", (Field.value == -321).query)
        XCTAssertEqual("/VAL/12.345", (Field.value == 12.345).query)
        XCTAssertEqual("/VAL/-89.987", (Field.value == -89.987).query)
        XCTAssertEqual("/VAL/Y", (Field.value == true).query)
        XCTAssertEqual("/VAL/N", (Field.value == false).query)
        XCTAssertEqual("/VAL/1970-01-01", (Field.value == Date(timeIntervalSince1970: 0)).query)

        XCTAssertEqual("/IDENTITY/%3C%3Etest", (Field.id != "test").query)
        XCTAssertEqual("/IDENTITY/%3C%3Enull-val", (Field.id != nil).query)
        XCTAssertEqual("/VAL/%3C%3E123", (Field.value != 123).query)
        XCTAssertEqual("/VAL/%3C%3E-321", (Field.value != -321).query)
        XCTAssertEqual("/VAL/%3C%3E12.345", (Field.value != 12.345).query)
        XCTAssertEqual("/VAL/%3C%3E-89.987", (Field.value != -89.987).query)
        XCTAssertEqual("/VAL/%3C%3EY", (Field.value != true).query)
        XCTAssertEqual("/VAL/%3C%3EN", (Field.value != false).query)
        XCTAssertEqual("/VAL/%3C%3E1970-01-01", (Field.value != Date(timeIntervalSince1970: 0)).query)

        XCTAssertEqual("/NAME/a,null-val,c", (Field.name.oneOf(values: ["a", nil, "c"])).query)
        XCTAssertEqual("/NAME/12,-456,3129", (Field.name.oneOf(values: [12, -456, 3129])).query)
        XCTAssertEqual("/NAME/-0.0012,1.236,-1.5", (Field.name.oneOf(values: [-0.0012, 1.236, -1.5])).query)
        XCTAssertEqual("/NAME/1970-01-01,1970-01-02,null-val", (Field.name.oneOf(values: [
            Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 86400), nil
        ])).query)

        XCTAssertEqual("/NAME/min--max", (Field.name.between(from: "min", to: "max")).query)
        XCTAssertEqual("/NAME/-12--45", (Field.name.between(from: -12, to: 45)).query)
        XCTAssertEqual("/NAME/-12.456--45.79", (Field.name.between(from: -12.456, to: 45.79)).query)
        XCTAssertEqual("/NAME/1970-01-01--1970-01-02", (Field.name.between(
            from: Date(timeIntervalSince1970: 0), to: Date(timeIntervalSince1970: 86400))).query)
    }
    
    func testPredicateSpecialSymbols() {
        XCTAssertEqual("/NAME/NOAA%2017", (Field.name == "NOAA 17").query)
        XCTAssertEqual("/NAME/%3C%3ENOAA%2017", (Field.name != "NOAA 17").query)
        XCTAssertEqual("/NAME/%3ENOAA%2017", (Field.name > "NOAA 17").query)
        XCTAssertEqual("/NAME/%3CNOAA%2017", (Field.name < "NOAA 17").query)
        XCTAssertEqual("/NAME/NOAA%2017,ISS%2FZARYA,TE%23ST",
                       Field.name.oneOf(values: ["NOAA 17", "ISS/ZARYA", "TE#ST"]).query)
        XCTAssertEqual("/NAME/NOAA%2017--NOAA%2A", Field.name.between(from: "NOAA 17", to: "NOAA*").query)
    }
    
    func testPredicateList() {
        XCTAssertEqual("/IDENTITY/%3E5/NAME/TEST", (Field.id > 5 && Field.name == "TEST").query)
        XCTAssertEqual("/IDENTITY/%3C%3Enull-val/NAME/%3CTEST/VAL/Y",
                       (Field.id != nil && Field.name < "TEST" && Field.value == true).query)
        XCTAssertEqual("/IDENTITY/-20--53/NAME/%3C%3ETEST/VAL/-1.23,2.19,4.57",
                       (Field.id.between(from: -20, to: 53) && Field.name != "TEST" &&
                        Field.value.oneOf(values: [-1.23, 2.19, 4.57])).query)
    }
}
