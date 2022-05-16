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

import AsyncHTTPClient
import Foundation
import NIOHTTP1

class Session {
    private let hostname: String
    private var cookies: [HTTPClient.Cookie] = []
    private var lock = NSLock()

    init(hostname: String) {
        self.hostname = hostname
    }

    var headers: [String: String] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return [
            "Host": hostname,
            "Cookie": cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; "),
        ]
    }

    var hasCookies: Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        return !cookies.isEmpty
    }

    func process(headers: HTTPHeaders) {
        lock.lock()
        defer {
            lock.unlock()
        }
        headers["set-cookie"].forEach { header in
            if let cookie = HTTPClient.Cookie(header: header, defaultDomain: hostname) {
                append(cookie: cookie)
            }
        }
    }

    private func append(cookie: HTTPClient.Cookie) {
        if let index = (cookies.firstIndex { $0.name == cookie.name }) {
            cookies[index] = cookie
        } else {
            cookies.append(cookie)
        }
    }
}
