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

import class Foundation.Bundle
import NIOCore
import XCTest

@testable import SpaceTrack

final class DecayTests: XCTestCase {
    func testDecayWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "COUNTRY": "US",
                        "DECAY_EPOCH": null,
                        "INTLDES": "1960-014A",
                        "MSG_EPOCH": null,
                        "MSG_TYPE": "Historical",
                        "NORAD_CAT_ID": null,
                        "OBJECT_ID": "1960-014A",
                        "OBJECT_NAME": "EXPLORER 8",
                        "OBJECT_NUMBER": null,
                        "PRECEDENCE": "2",
                        "RCS": "1",
                        "RCS_SIZE": null,
                        "SOURCE": "decay_msg"
                    }
                ],
                "request_metadata": {
                    "DataSize": "98 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0069",
                    "ReturnedRows": 1,
                    "Total": 50919
                }
            }
        """

        var response: DecayList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = DecayDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(50919, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertNil(item.decayEpoch)
        XCTAssertNil(item.messageEpoch)
        XCTAssertNil(item.noradCatId)
        XCTAssertNil(item.objectNumber)
        XCTAssertNil(item.rcsSize)

        XCTAssertEqual("US", item.country)
        XCTAssertEqual("1960-014A", item.intldes)
        XCTAssertEqual("Historical", item.messageType)
        XCTAssertEqual("1960-014A", item.objectId)
        XCTAssertEqual("EXPLORER 8", item.objectName)
        XCTAssertEqual(2, item.precedence)
        XCTAssertEqual(1, item.rcs)
        XCTAssertEqual("decay_msg", item.source)
    }

    func testDecayParsing() {
        let text = """
            {
                "data": [
                    {
                        "COUNTRY": "US",
                        "DECAY_EPOCH": "2012-03-28 07:03:19",
                        "INTLDES": "1960-014A",
                        "MSG_EPOCH": "2012-03-28 14:19:21",
                        "MSG_TYPE": "Historical",
                        "NORAD_CAT_ID": "60",
                        "OBJECT_ID": "1960-014A",
                        "OBJECT_NAME": "EXPLORER 8",
                        "OBJECT_NUMBER": "63",
                        "PRECEDENCE": "2",
                        "RCS": "1",
                        "RCS_SIZE": "MEDIUM",
                        "SOURCE": "decay_msg"
                    }
                ],
                "request_metadata": {
                    "DataSize": "98 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0069",
                    "ReturnedRows": 1,
                    "Total": 50919
                }
            }
        """

        var response: DecayList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = DecayDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(50919, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual("US", item.country)
        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 7, minute: 3, second: 19), item.decayEpoch)
        XCTAssertEqual("1960-014A", item.intldes)
        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 14, minute: 19, second: 21), item.messageEpoch)
        XCTAssertEqual("Historical", item.messageType)
        XCTAssertEqual(60, item.noradCatId)
        XCTAssertEqual("1960-014A", item.objectId)
        XCTAssertEqual("EXPLORER 8", item.objectName)
        XCTAssertEqual(63, item.objectNumber)
        XCTAssertEqual(2, item.precedence)
        XCTAssertEqual(1, item.rcs)
        XCTAssertEqual("MEDIUM", item.rcsSize)
        XCTAssertEqual("decay_msg", item.source)
    }
}
