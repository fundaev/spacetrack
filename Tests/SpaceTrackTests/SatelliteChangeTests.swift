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

final class SatelliteChangeTests: XCTestCase {
    func testSateliteChangeWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "CHANGE_MADE": "2017-05-23 15:29:53",
                        "CURRENT_COUNTRY": "PRC",
                        "CURRENT_DECAY": "2017-05-21",
                        "CURRENT_INTLDES": "2017-012C",
                        "CURRENT_LAUNCH": null,
                        "CURRENT_NAME": "TK-1 DEB",
                        "NORAD_CAT_ID": null,
                        "OBJECT_NUMBER": null,
                        "PREVIOUS_COUNTRY": "PRC",
                        "PREVIOUS_DECAY": null,
                        "PREVIOUS_INTLDES": null,
                        "PREVIOUS_LAUNCH": null,
                        "PREVIOUS_NAME": null
                    }
                ],
                "request_metadata": {
                    "DataSize": "99 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0165",
                    "ReturnedRows": 1,
                    "Total": 17119
                }
            }
        """

        var response: SatelliteChangeList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = SatelliteChangeDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(17119, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertNil(item.currentLaunch)
        XCTAssertNil(item.noradCatId)
        XCTAssertNil(item.objectNumber)
        XCTAssertNil(item.previousDecay)
        XCTAssertNil(item.previousIntldes)
        XCTAssertNil(item.previousLaunch)
        XCTAssertNil(item.previousName)

        XCTAssertEqual(Date.from(year: 2017, month: 5, day: 23, hour: 15, minute: 29, second: 53), item.changeMade)
        XCTAssertEqual("PRC", item.currentCountry)
        XCTAssertEqual(Date.from(year: 2017, month: 5, day: 21), item.currentDecay)
        XCTAssertEqual("2017-012C", item.currentIntldes)
        XCTAssertEqual("TK-1 DEB", item.currentName)
        XCTAssertEqual("PRC", item.previousCountry)
    }

    func testSatelliteChangeParsing() {
        let text = """
            {
                "data": [
                    {
                        "CHANGE_MADE": "2017-05-23 15:29:53",
                        "CURRENT_COUNTRY": "PRC",
                        "CURRENT_DECAY": "2017-05-21",
                        "CURRENT_INTLDES": "2017-012C",
                        "CURRENT_LAUNCH": "2017-03-02",
                        "CURRENT_NAME": "TK-1 DEB",
                        "NORAD_CAT_ID": "42077",
                        "OBJECT_NUMBER": "42017",
                        "PREVIOUS_COUNTRY": "PRD",
                        "PREVIOUS_DECAY": "2016-04-19",
                        "PREVIOUS_INTLDES": "2017-012D",
                        "PREVIOUS_LAUNCH": "2017-03-02",
                        "PREVIOUS_NAME": "TK-1 DED"
                    }
                ],
                "request_metadata": {
                    "DataSize": "99 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0165",
                    "ReturnedRows": 1,
                    "Total": 17119
                }
            }
        """

        var response: SatelliteChangeList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = SatelliteChangeDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(17119, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual(Date.from(year: 2017, month: 5, day: 23, hour: 15, minute: 29, second: 53), item.changeMade)
        XCTAssertEqual("PRC", item.currentCountry)
        XCTAssertEqual(Date.from(year: 2017, month: 5, day: 21), item.currentDecay)
        XCTAssertEqual("2017-012C", item.currentIntldes)
        XCTAssertEqual(Date.from(year: 2017, month: 3, day: 2), item.currentLaunch)
        XCTAssertEqual("TK-1 DEB", item.currentName)
        XCTAssertEqual(42077, item.noradCatId)
        XCTAssertEqual(42017, item.objectNumber)
        XCTAssertEqual("PRD", item.previousCountry)
        XCTAssertEqual(Date.from(year: 2016, month: 4, day: 19), item.previousDecay)
        XCTAssertEqual("2017-012D", item.previousIntldes)
        XCTAssertEqual(Date.from(year: 2017, month: 3, day: 2), item.previousLaunch)
        XCTAssertEqual("TK-1 DED", item.previousName)
    }
}
