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

final class ConjunctionDataMessageTests: XCTestCase {
    func testConjunctionDataMessageWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "CDM_ID": "276911856",
                        "CREATED": null,
                        "EMERGENCY_REPORTABLE": null,
                        "MIN_RNG": null,
                        "PC": null,
                        "SAT1_OBJECT_TYPE": null,
                        "SAT1_RCS": null,
                        "SAT2_OBJECT_TYPE": null,
                        "SAT2_RCS": null,
                        "SAT_1_EXCL_VOL": null,
                        "SAT_1_ID": null,
                        "SAT_1_NAME": null,
                        "SAT_2_EXCL_VOL": null,
                        "SAT_2_ID": null,
                        "SAT_2_NAME": null,
                        "TCA": null
                    }
                ],
                "request_metadata": {
                    "DataSize": "127 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0238",
                    "ReturnedRows": 1,
                    "Total": 24061
                }
            }
        """

        var response: ConjunctionDataMessageList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = ConjunctionDataMessageDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(24061, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertNil(item.created)
        XCTAssertNil(item.emergencyReportable)
        XCTAssertNil(item.minRng)
        XCTAssertNil(item.pc)
        XCTAssertNil(item.tca)
        XCTAssertNil(item.sat1Id)
        XCTAssertNil(item.sat1Name)
        XCTAssertNil(item.sat1ObjectType)
        XCTAssertNil(item.sat1Rcs)
        XCTAssertNil(item.sat1ExclVol)
        XCTAssertNil(item.sat2Id)
        XCTAssertNil(item.sat2Name)
        XCTAssertNil(item.sat2ObjectType)
        XCTAssertNil(item.sat2Rcs)
        XCTAssertNil(item.sat2ExclVol)

        XCTAssertEqual(276_911_856, item.cdmId)
    }

    func testConjunctionDataMessageParsing() {
        let text = """
            {
                "data": [
                    {
                        "CDM_ID": "276911856",
                        "CREATED": "2022-04-22 16:34:40.123456",
                        "EMERGENCY_REPORTABLE": "Y",
                        "MIN_RNG": "540",
                        "PC": "0.0003680217",
                        "SAT1_OBJECT_TYPE": "DEBRIS",
                        "SAT1_RCS": "SMALL",
                        "SAT2_OBJECT_TYPE": "UNKNOWN",
                        "SAT2_RCS": "MEDIUM",
                        "SAT_1_EXCL_VOL": "Test1",
                        "SAT_1_ID": "172",
                        "SAT_1_NAME": "THOR ABLESTAR DEB",
                        "SAT_2_EXCL_VOL": "Test2",
                        "SAT_2_ID": "87883",
                        "SAT_2_NAME": "UNKNOWN",
                        "TCA": "2022-04-22T19:24:43.770000"
                    }
                ],
                "request_metadata": {
                    "DataSize": "127 Bytes",
                    "Limit": 1,
                    "LimitOffset": 1,
                    "RequestTime": "0.0238",
                    "ReturnedRows": 1,
                    "Total": 24061
                }
            }
        """

        var response: ConjunctionDataMessageList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = ConjunctionDataMessageDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(24061, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual(276_911_856, item.cdmId)
        XCTAssertEqual(Date.from(year: 2022, month: 4, day: 22, hour: 16, minute: 34, second: 40, nanosecond: 123_456_000),
                       item.created)
        XCTAssertEqual("Y", item.emergencyReportable)
        XCTAssertEqual(540, item.minRng)
        XCTAssertEqual(0.0003680217, item.pc)
        XCTAssertEqual("DEBRIS", item.sat1ObjectType)
        XCTAssertEqual("SMALL", item.sat1Rcs)
        XCTAssertEqual("UNKNOWN", item.sat2ObjectType)
        XCTAssertEqual("MEDIUM", item.sat2Rcs)
        XCTAssertEqual("Test1", item.sat1ExclVol)
        XCTAssertEqual(172, item.sat1Id)
        XCTAssertEqual("THOR ABLESTAR DEB", item.sat1Name)
        XCTAssertEqual("Test2", item.sat2ExclVol)
        XCTAssertEqual(87883, item.sat2Id)
        XCTAssertEqual("UNKNOWN", item.sat2Name)
        XCTAssertEqual(Date.from(year: 2022, month: 4, day: 22, hour: 19, minute: 24, second: 43, nanosecond: 770_000_000),
                       item.tca)
    }
}
