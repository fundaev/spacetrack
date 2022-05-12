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

    let decoder: AuthDecoder
    
    init(decoder: AuthDecoder) {
        self.decoder = decoder
    }
    
    func didReceiveHead(task: HTTPClient.Task<Result>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        decoder.processHeader(status: head.status, headers: head.headers)
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveBodyPart(task: HTTPClient.Task<Result>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        decoder.processChunk(buffer: buffer)
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveError(task: HTTPClient.Task<Result>, _ error: Error) {
        decoder.processError(error: error)
    }
    
    func didFinishRequest(task: HTTPClient.Task<Result>) throws -> Result {
        return decoder.decode()
    }
}
