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

final class TIPMessageTests: XCTestCase {
    func testTIPMessageWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "DECAY_EPOCH": "2012-03-28 01:14:00",
                        "DIRECTION": null,
                        "HIGH_INTEREST": "N",
                        "ID": "3027",
                        "INCL": "49.9",
                        "INSERT_EPOCH": "2012-03-28 06:34:36",
                        "LAT": "-16.8",
                        "LON": "286.8",
                        "MSG_EPOCH": "2012-03-28 12:30:00",
                        "NEXT_REPORT": "7",
                        "NORAD_CAT_ID": null,
                        "OBJECT_NUMBER": null,
                        "REV": "58623",
                        "WINDOW": "14"
                    }
                ],
                "request_metadata": {
                    "DataSize": "98 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0326",
                    "ReturnedRows": 1,
                    "Total": 11109
                }
            }
        """

        var response: TIPMessageList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = TIPMessageDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(11109, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertNil(item.direction)
        XCTAssertNil(item.noradCatId)
        XCTAssertNil(item.objectNumber)

        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 1, minute: 14, second: 0), item.decayEpoch)
        XCTAssertFalse(item.highInterest)
        XCTAssertEqual(3027, item.id)
        XCTAssertEqual(49.9, item.inclination)
        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 6, minute: 34, second: 36), item.insertEpoch)
        XCTAssertEqual(7, item.nextReport)
        XCTAssertEqual(58623, item.rev)
        XCTAssertEqual(14, item.window)
    }

    func testTIPMessageParsing() {
        let text = """
            {
                "data": [
                    {
                        "DECAY_EPOCH": "2012-03-28 01:14:00",
                        "DIRECTION": "descending",
                        "HIGH_INTEREST": "N",
                        "ID": "3027",
                        "INCL": "49.9",
                        "INSERT_EPOCH": "2012-03-28 06:34:36",
                        "LAT": "-16.8",
                        "LON": "286.8",
                        "MSG_EPOCH": "2012-03-28 12:30:00",
                        "NEXT_REPORT": "7",
                        "NORAD_CAT_ID": "60",
                        "OBJECT_NUMBER": "73",
                        "REV": "58623",
                        "WINDOW": "14"
                    }
                ],
                "request_metadata": {
                    "DataSize": "98 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0326",
                    "ReturnedRows": 1,
                    "Total": 11109
                }
            }
        """

        var response: TIPMessageList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = TIPMessageDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(11109, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 1, minute: 14, second: 0), item.decayEpoch)
        XCTAssertEqual(TIPMessage.Direction.descending, item.direction)
        XCTAssertFalse(item.highInterest)
        XCTAssertEqual(3027, item.id)
        XCTAssertEqual(49.9, item.inclination)
        XCTAssertEqual(Date.from(year: 2012, month: 3, day: 28, hour: 6, minute: 34, second: 36), item.insertEpoch)
        XCTAssertEqual(7, item.nextReport)
        XCTAssertEqual(60, item.noradCatId)
        XCTAssertEqual(73, item.objectNumber)
        XCTAssertEqual(58623, item.rev)
        XCTAssertEqual(14, item.window)
    }
}
