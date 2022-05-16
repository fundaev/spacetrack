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
import NIOCore
import NIOHTTP1

class DataDelegate<Decoder: ResponseDecoder>: HTTPClientResponseDelegate {
    typealias Response = Decoder.Output

    private var decoder: Decoder
    private var error: Error?

    init(decoder: Decoder) {
        self.decoder = decoder
    }

    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        if head.status != .ok {
            return task.eventLoop.makeFailedFuture(Result.Unauthorized(""))
        }
        return task.eventLoop.makeSucceededFuture(())
    }

    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        decoder.processChunk(buffer: buffer)
        return task.eventLoop.makeSucceededFuture(())
    }

    func didReceiveError(task _: HTTPClient.Task<Response>, _ error: Error) {
        self.error = error
    }

    func didFinishRequest(task _: HTTPClient.Task<Response>) throws -> Response {
        return try decoder.decode()
    }
}
