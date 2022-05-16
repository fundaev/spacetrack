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

final class GPTests: XCTestCase {
    func testGPWithNulls() {
        let text = """
            {
                "data": [
                    {
                        "APOAPSIS": null,
                        "ARG_OF_PERICENTER": null,
                        "BSTAR": null,
                        "CCSDS_OMM_VERS": "2.0",
                        "CENTER_NAME": "EARTH",
                        "CLASSIFICATION_TYPE": null,
                        "COMMENT": "test",
                        "COUNTRY_CODE": null,
                        "CREATION_DATE": null,
                        "DECAY_DATE": null,
                        "ECCENTRICITY": null,
                        "ELEMENT_SET_NO": null,
                        "EPHEMERIS_TYPE": null,
                        "EPOCH": null,
                        "FILE": null,
                        "GP_ID": "194161434",
                        "INCLINATION": null,
                        "LAUNCH_DATE": null,
                        "MEAN_ANOMALY": null,
                        "MEAN_ELEMENT_THEORY": "SGP4",
                        "MEAN_MOTION": null,
                        "MEAN_MOTION_DDOT": null,
                        "MEAN_MOTION_DOT": null,
                        "NORAD_CAT_ID": "4793",
                        "OBJECT_ID": null,
                        "OBJECT_NAME": null,
                        "OBJECT_TYPE": null,
                        "ORIGINATOR": "18 SPCS",
                        "PERIAPSIS": null,
                        "PERIOD": null,
                        "RA_OF_ASC_NODE": null,
                        "RCS_SIZE": null,
                        "REF_FRAME": "TEME",
                        "REV_AT_EPOCH": null,
                        "SEMIMAJOR_AXIS": null,
                        "SITE": null,
                        "TIME_SYSTEM": "UTC",
                        "TLE_LINE0": null,
                        "TLE_LINE1": null,
                        "TLE_LINE2": null
                    }
                ],
                "request_metadata": {
                    "DataSize": "449 Bytes",
                    "Limit": 1000000,
                    "LimitOffset": 1,
                    "RequestTime": "0.0041",
                    "ReturnedRows": 1,
                    "Total": 42
                }
            }
        """

        var response: GeneralPerturbationsList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = GPDecoder()
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
        XCTAssertNil(item.apoapsis)
        XCTAssertNil(item.argOfPericenter)
        XCTAssertNil(item.bstar)
        XCTAssertNil(item.classificationType)
        XCTAssertNil(item.countryCode)
        XCTAssertNil(item.creationDate)
        XCTAssertNil(item.decayDate)
        XCTAssertNil(item.eccentricity)
        XCTAssertNil(item.elementSetNo)
        XCTAssertNil(item.ephemerisType)
        XCTAssertNil(item.epoch)
        XCTAssertNil(item.file)
        XCTAssertNil(item.inclination)
        XCTAssertNil(item.launchDate)
        XCTAssertNil(item.meanAnomaly)
        XCTAssertNil(item.meanMotion)
        XCTAssertNil(item.meanMotionDDot)
        XCTAssertNil(item.meanMotionDot)
        XCTAssertNil(item.objectId)
        XCTAssertNil(item.objectName)
        XCTAssertNil(item.objectType)
        XCTAssertNil(item.periapsis)
        XCTAssertNil(item.period)
        XCTAssertNil(item.raOfAscNode)
        XCTAssertNil(item.rcsSize)
        XCTAssertNil(item.revAtEpoch)
        XCTAssertNil(item.semimajorAxis)
        XCTAssertNil(item.site)
        XCTAssertNil(item.tleLine0)
        XCTAssertNil(item.tleLine1)
        XCTAssertNil(item.tleLine2)

        XCTAssertEqual(item.ccsdsOmmVers, "2.0")
        XCTAssertEqual(item.centerName, "EARTH")
        XCTAssertEqual(item.comment, "test")
        XCTAssertEqual(item.gpId, 194_161_434)
        XCTAssertEqual(item.meanElementTheory, "SGP4")
        XCTAssertEqual(item.noradCatId, 4793)
        XCTAssertEqual(item.originator, "18 SPCS")
        XCTAssertEqual(item.refFrame, "TEME")
        XCTAssertEqual(item.timeSystem, "UTC")
    }

    func testGPParsing() {
        let text = """
            {
                "data": [
                    {
                        "APOAPSIS": "1472.423",
                        "ARG_OF_PERICENTER": "252.3054",
                        "BSTAR": "0.00015588000000",
                        "CCSDS_OMM_VERS": "2.0",
                        "CENTER_NAME": "EARTH",
                        "CLASSIFICATION_TYPE": "U",
                        "COMMENT": "GENERATED VIA SPACE-TRACK.ORG API",
                        "COUNTRY_CODE": "US",
                        "CREATION_DATE": "2022-01-19T06:56:11",
                        "DECAY_DATE": "1984-11-28",
                        "ECCENTRICITY": "0.00314640",
                        "ELEMENT_SET_NO": "999",
                        "EPHEMERIS_TYPE": "0",
                        "EPOCH": "2022-01-19T03:14:05.847360",
                        "FILE": "3277020",
                        "GP_ID": "194161434",
                        "INCLINATION": "101.5802",
                        "LAUNCH_DATE": "1970-12-11",
                        "MEAN_ANOMALY": "161.3476",
                        "MEAN_ELEMENT_THEORY": "SGP4",
                        "MEAN_MOTION": "12.54002690",
                        "MEAN_MOTION_DDOT": "0.0000000000000",
                        "MEAN_MOTION_DOT": "-0.00000019",
                        "NORAD_CAT_ID": "4793",
                        "OBJECT_ID": "1970-106A",
                        "OBJECT_NAME": "NOAA 1",
                        "OBJECT_TYPE": "PAYLOAD",
                        "ORIGINATOR": "18 SPCS",
                        "PERIAPSIS": "1423.176",
                        "PERIOD": "114.832",
                        "RA_OF_ASC_NODE": "86.5926",
                        "RCS_SIZE": "LARGE",
                        "REF_FRAME": "TEME",
                        "REV_AT_EPOCH": "33935",
                        "SEMIMAJOR_AXIS": "7825.934",
                        "SITE": "AFWTR",
                        "TIME_SYSTEM": "UTC",
                        "TLE_LINE0": "0 NOAA 1",
                        "TLE_LINE1": "1  4793U 70106A   22019.13478990 -.00000019  00000-0  15588-3 0  9993",
                        "TLE_LINE2": "2  4793 101.5802  86.5926 0031464 252.3054 161.3476 12.54002690339357"
                    }
                ],
                "request_metadata": {
                    "DataSize": "449 Bytes",
                    "Limit": 1000000,
                    "LimitOffset": 1,
                    "RequestTime": "0.0041",
                    "ReturnedRows": 1,
                    "Total": 1
                }
            }
        """

        var response: GeneralPerturbationsList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = GPDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(1, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual(item.apoapsis, 1472.423)
        XCTAssertEqual(item.argOfPericenter, 252.3054)
        XCTAssertEqual(item.bstar, 0.00015588)
        XCTAssertEqual(item.ccsdsOmmVers, "2.0")
        XCTAssertEqual(item.centerName, "EARTH")
        XCTAssertEqual(item.classificationType, "U")
        XCTAssertEqual(item.comment, "GENERATED VIA SPACE-TRACK.ORG API")
        XCTAssertEqual(item.countryCode, "US")
        XCTAssertEqual(item.creationDate, Date.from(year: 2022, month: 01, day: 19, hour: 6, minute: 56, second: 11))
        XCTAssertEqual(item.decayDate, Date.from(year: 1984, month: 11, day: 28))
        XCTAssertEqual(item.eccentricity, 0.0031464)
        XCTAssertEqual(item.elementSetNo, 999)
        XCTAssertEqual(item.ephemerisType, 0)
        XCTAssertEqual(item.epoch,
                       Date.from(year: 2022, month: 01, day: 19, hour: 3, minute: 14, second: 5, nanosecond: 847_360_000))
        XCTAssertEqual(item.file, 3_277_020)
        XCTAssertEqual(item.gpId, 194_161_434)
        XCTAssertEqual(item.inclination, 101.5802)
        XCTAssertEqual(item.launchDate, Date.from(year: 1970, month: 12, day: 11))
        XCTAssertEqual(item.meanAnomaly, 161.3476)
        XCTAssertEqual(item.meanElementTheory, "SGP4")
        XCTAssertEqual(item.meanMotion, 12.5400269)
        XCTAssertEqual(item.meanMotionDDot, 0)
        XCTAssertEqual(item.meanMotionDot, -0.00000019)
        XCTAssertEqual(item.noradCatId, 4793)
        XCTAssertEqual(item.objectId, "1970-106A")
        XCTAssertEqual(item.objectName, "NOAA 1")
        XCTAssertEqual(item.objectType, "PAYLOAD")
        XCTAssertEqual(item.originator, "18 SPCS")
        XCTAssertEqual(item.periapsis, 1423.176)
        XCTAssertEqual(item.period, 114.832)
        XCTAssertEqual(item.raOfAscNode, 86.5926)
        XCTAssertEqual(item.rcsSize, "LARGE")
        XCTAssertEqual(item.refFrame, "TEME")
        XCTAssertEqual(item.revAtEpoch, 33935)
        XCTAssertEqual(item.semimajorAxis, 7825.934)
        XCTAssertEqual(item.site, "AFWTR")
        XCTAssertEqual(item.timeSystem, "UTC")
        XCTAssertEqual(item.tleLine0, "0 NOAA 1")
        XCTAssertEqual(item.tleLine1, "1  4793U 70106A   22019.13478990 -.00000019  00000-0  15588-3 0  9993")
        XCTAssertEqual(item.tleLine2, "2  4793 101.5802  86.5926 0031464 252.3054 161.3476 12.54002690339357")
    }
}
