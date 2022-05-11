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
import NIOCore

@testable import SpaceTrack

final class SatelliteTests: XCTestCase {
    
    func testSateliteWithNulls() {
        let text = """
            {
                "request_metadata": {
                    "DataSize": "549 Bytes",
                    "Limit": 1,
                    "LimitOffset": 0,
                    "RequestTime": "0.1022",
                    "ReturnedRows": 1,
                    "Total": 42
                },
                "data": [
                    {
                        "APOGEE": null,
                        "COMMENT": null,
                        "COMMENTCODE": null,
                        "COUNTRY": "CIS",
                        "CURRENT": "Y",
                        "DECAY": null,
                        "FILE": "1",
                        "INCLINATION": null,
                        "INTLDES": "1957-001A",
                        "LAUNCH": null,
                        "LAUNCH_NUM": "1",
                        "LAUNCH_PIECE": "A",
                        "LAUNCH_YEAR": "1957",
                        "NORAD_CAT_ID": null,
                        "OBJECT_ID": "1957-001A",
                        "OBJECT_NAME": "SL-1 R/B",
                        "OBJECT_NUMBER": null,
                        "OBJECT_TYPE": null,
                        "PERIGEE": null,
                        "PERIOD": null,
                        "RCSVALUE": "0",
                        "RCS_SIZE": null,
                        "SATNAME": "SL-1 R/B",
                        "SITE": null
                    }
                ]
            }
        """

        var response: SatelliteCatalog
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = SatelliteDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }
        
        XCTAssertEqual(42, response.count)
        
        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }
        
        let item = response.data[0]
        XCTAssertNil(item.apogee)
        XCTAssertNil(item.comment)
        XCTAssertNil(item.commentCode)
        XCTAssertNil(item.decay)
        XCTAssertNil(item.inclination)
        XCTAssertNil(item.launch)
        XCTAssertNil(item.noradCatId)
        XCTAssertNil(item.objectNumber)
        XCTAssertNil(item.objectType)
        XCTAssertNil(item.perigee)
        XCTAssertNil(item.period)
        XCTAssertNil(item.rcsSize)
        XCTAssertNil(item.site)
        
        XCTAssertEqual("CIS", item.country)
        XCTAssertTrue(item.current)
        XCTAssertEqual(1, item.file)
        XCTAssertEqual("1957-001A", item.intldes)
        XCTAssertEqual(1, item.launchNum)
        XCTAssertEqual("A", item.launchPiece)
        XCTAssertEqual(1957, item.launchYear)
        XCTAssertEqual("1957-001A", item.objectId)
        XCTAssertEqual("SL-1 R/B", item.objectName)
        XCTAssertEqual(0, item.rcsValue)
        XCTAssertEqual("SL-1 R/B", item.name)
    }
    
    func testSatelliteParsing() {
        let text = """
            {
                "data": [
                    {
                        "APOGEE": "938",
                        "COMMENT": "comment",
                        "COMMENTCODE": "4",
                        "COUNTRY": "CIS",
                        "CURRENT": "N",
                        "DECAY": "1957-12-01",
                        "FILE": "1",
                        "INCLINATION": "65.10",
                        "INTLDES": "1957-001A",
                        "LAUNCH": "1957-10-04",
                        "LAUNCH_NUM": "1",
                        "LAUNCH_PIECE": "A",
                        "LAUNCH_YEAR": "1957",
                        "NORAD_CAT_ID": "1",
                        "OBJECT_ID": "1957-001A",
                        "OBJECT_NAME": "SL-1 R/B",
                        "OBJECT_NUMBER": "1",
                        "OBJECT_TYPE": "ROCKET BODY",
                        "PERIGEE": "214",
                        "PERIOD": "96.19",
                        "RCSVALUE": "0",
                        "RCS_SIZE": "LARGE",
                        "SATNAME": "SL-1 R/B",
                        "SITE": "TTMTR"
                    }
                ],
                "request_metadata": {
                    "DataSize": "549 Bytes",
                    "Limit": 1,
                    "LimitOffset": 0,
                    "RequestTime": "0.1022",
                    "ReturnedRows": 1,
                    "Total": 42
                }
            }
        """
    
        var response: SatelliteCatalog
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = SatelliteDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }
        
        XCTAssertEqual(42, response.count)
        
        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }
        
        let item = response.data[0]
        XCTAssertEqual(938, item.apogee)
        XCTAssertEqual("comment", item.comment)
        XCTAssertEqual(4, item.commentCode)
        XCTAssertEqual("CIS", item.country)
        XCTAssertFalse(item.current)
        XCTAssertEqual(Date.from(year: 1957, month: 12, day: 1), item.decay)
        XCTAssertEqual(1, item.file)
        XCTAssertEqual(65.10, item.inclination)
        XCTAssertEqual("1957-001A", item.intldes)
        XCTAssertEqual(Date.from(year: 1957, month: 10, day: 4), item.launch)
        XCTAssertEqual(1, item.launchNum)
        XCTAssertEqual("A", item.launchPiece)
        XCTAssertEqual(1957, item.launchYear)
        XCTAssertEqual(1, item.noradCatId)
        XCTAssertEqual("1957-001A", item.objectId)
        XCTAssertEqual("SL-1 R/B", item.objectName)
        XCTAssertEqual(1, item.objectNumber)
        XCTAssertEqual("ROCKET BODY", item.objectType)
        XCTAssertEqual(214, item.perigee)
        XCTAssertEqual(96.19, item.period)
        XCTAssertEqual(0, item.rcsValue)
        XCTAssertEqual("LARGE", item.rcsSize)
        XCTAssertEqual("SL-1 R/B", item.name)
        XCTAssertEqual("TTMTR", item.site)
    }
}
