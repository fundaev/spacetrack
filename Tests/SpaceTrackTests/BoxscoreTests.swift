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

final class BoxscoreTests: XCTestCase {
    func testBoxscoreWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "COUNTRY": "ARAB SATELLITE COMMUNICATIONS ORGANIZATION",
                        "COUNTRY_TOTAL": "15",
                        "DECAYED_DEBRIS_COUNT": null,
                        "DECAYED_PAYLOAD_COUNT": null,
                        "DECAYED_ROCKET_BODY_COUNT": null,
                        "DECAYED_TOTAL_COUNT": null,
                        "ORBITAL_DEBRIS_COUNT": null,
                        "ORBITAL_PAYLOAD_COUNT": null,
                        "ORBITAL_ROCKET_BODY_COUNT": null,
                        "ORBITAL_TBA": null,
                        "ORBITAL_TOTAL_COUNT": null,
                        "SPADOC_CD": null
                    }
                ],
                "request_metadata": {
                    "DataSize": "57 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.9124",
                    "ReturnedRows": 1,
                    "Total": 112
                }
            }
        """

        var response: BoxscoreList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = BoxscoreDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(112, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertNil(item.spadocCd)
        XCTAssertNil(item.orbitalTba)
        XCTAssertNil(item.orbitalPayloadCount)
        XCTAssertNil(item.orbitalRocketBodyCount)
        XCTAssertNil(item.orbitalDebrisCount)
        XCTAssertNil(item.orbitalTotalCount)
        XCTAssertNil(item.decayedPayloadCount)
        XCTAssertNil(item.decayedRocketBodyCount)
        XCTAssertNil(item.decayedDebrisCount)
        XCTAssertNil(item.decayedTotalCount)

        XCTAssertEqual("ARAB SATELLITE COMMUNICATIONS ORGANIZATION", item.country)
        XCTAssertEqual(15, item.countryTotal)
    }

    func testBoxscoreParsing() {
        let text = """
            {
                "data": [
                    {
                        "COUNTRY": "ARAB SATELLITE COMMUNICATIONS ORGANIZATION",
                        "COUNTRY_TOTAL": "15",
                        "DECAYED_DEBRIS_COUNT": "2",
                        "DECAYED_PAYLOAD_COUNT": "1",
                        "DECAYED_ROCKET_BODY_COUNT": "3",
                        "DECAYED_TOTAL_COUNT": "8",
                        "ORBITAL_DEBRIS_COUNT": "4",
                        "ORBITAL_PAYLOAD_COUNT": "14",
                        "ORBITAL_ROCKET_BODY_COUNT": "5",
                        "ORBITAL_TBA": "6",
                        "ORBITAL_TOTAL_COUNT": "23",
                        "SPADOC_CD": "AB"
                    }
                ],
                "request_metadata": {
                    "DataSize": "57 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.9124",
                    "ReturnedRows": 1,
                    "Total": 112
                }
            }
        """

        var response: BoxscoreList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = BoxscoreDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(112, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual("ARAB SATELLITE COMMUNICATIONS ORGANIZATION", item.country)
        XCTAssertEqual(15, item.countryTotal)
        XCTAssertEqual("AB", item.spadocCd)
        XCTAssertEqual(6, item.orbitalTba)
        XCTAssertEqual(14, item.orbitalPayloadCount)
        XCTAssertEqual(5, item.orbitalRocketBodyCount)
        XCTAssertEqual(4, item.orbitalDebrisCount)
        XCTAssertEqual(23, item.orbitalTotalCount)
        XCTAssertEqual(1, item.decayedPayloadCount)
        XCTAssertEqual(3, item.decayedRocketBodyCount)
        XCTAssertEqual(2, item.decayedDebrisCount)
        XCTAssertEqual(8, item.decayedTotalCount)
    }
}
