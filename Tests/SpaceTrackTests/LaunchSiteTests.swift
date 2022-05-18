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

final class LaunchSiteTests: XCTestCase {
    func testLaunchSiteParsing() {
        let text = """
            {
                "data": [
                    {
                        "LAUNCH_SITE": "AIR FORCE EASTERN TEST RANGE",
                        "SITE_CODE": "AFETR"
                    }
                ],
                "request_metadata": {
                    "DataSize": "33 Bytes",
                    "Limit": 13,
                    "LimitOffset": 3,
                    "RequestTime": "0.0063",
                    "ReturnedRows": 1,
                    "Total": 37
                }
            }
        """

        var response: LaunchSiteList
        do {
            let buffer = ByteBuffer(string: text)
            let decoder = LaunchSiteDecoder()
            decoder.processChunk(buffer: buffer)
            response = try decoder.decode()
        } catch {
            XCTFail("Failed to decode: \(error)")
            return
        }

        XCTAssertEqual(37, response.count)

        if response.data.count != 1 {
            XCTFail("Wrong items count: \(response.data.count) while 1 is expected")
            return
        }

        let item = response.data[0]
        XCTAssertEqual("AFETR", item.siteCode)
        XCTAssertEqual("AIR FORCE EASTERN TEST RANGE", item.launchSite)
    }
}
