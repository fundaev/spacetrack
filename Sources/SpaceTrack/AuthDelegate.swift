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

import Foundation
import NIOCore
import NIOHTTP1
import AsyncHTTPClient

class AuthDelegate: HTTPClientResponseDelegate {
    typealias Response = Result

    private let session: Session
    private var responseStatus: HTTPResponseStatus = .ok
    private var responseHeaders: HTTPHeaders? = nil
    private var data = Data()
    private var error: Error?
    
    init(session: Session) {
        self.session = session
    }
    
    func didReceiveHead(task: HTTPClient.Task<Result>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        responseStatus = head.status
        responseHeaders = head.headers
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveBodyPart(task: HTTPClient.Task<Result>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        data.append(contentsOf: buffer.readableBytesView)
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveError(task: HTTPClient.Task<Result>, _ error: Error) {
        self.error = error
    }
    
    func didFinishRequest(task: HTTPClient.Task<Result>) throws -> Result {
        if error != nil {
            return .RequestError(error!.localizedDescription)
        }
        
        let message = responseString()
        if responseStatus == .unauthorized || (responseStatus == .ok && !message.isEmpty) {
            return .Unauthorized(message)
        }
        
        if responseStatus != .ok {
            return .RequestError(message)
        }
        
        if let headers = responseHeaders {
            session.process(headers: headers)
        }
        return .Success
    }
    
    private func responseString() -> String {
        let decoder = JSONDecoder()
        let response = try? decoder.decode(AuthResponse.self, from: data)
        return response?.Login ?? ""
    }
}

struct AuthResponse: Codable {
    var Login: String
}
