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

protocol DataHandler: HTTPClientResponseDelegate {
    static func makeUri(filter: QueryBuilder, order: QueryBuilder, limit: Int?, offset: Int?) -> String
}

class DataDelegate<Decoder: ResponseDecoder>: DataHandler {
    typealias Response = Decoder.Output

    private var data = Data()
    private var error: Error?

    static func makeUri(filter: QueryBuilder, order: QueryBuilder, limit: Int?, offset: Int?) -> String {
        var limitString = ""
        if let limit = limit {
            limitString = "/limit/\(limit)"
            if let offset = offset {
                limitString += ",\(offset)"
            }
        }
        
        var distinctString = ""
        if Decoder.distinct {
            distinctString = "/distinct/true"
        }
        
        var metadataString = ""
        if Decoder.metadata {
            metadataString = "/metadata/true"
        }
        return """
            /\(Decoder.controller.rawValue)/\(Decoder.action.rawValue)/class/\(Decoder.resource)\(filter.query)\
            \(order.query)\(limitString)/format/\(Decoder.format.rawValue)\(distinctString)\(metadataString)
            """
    }

    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        if head.status != .ok {
            return task.eventLoop.makeFailedFuture(Result.Unauthorized(""))
        }
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        data.append(contentsOf: buffer.readableBytesView)
        return task.eventLoop.makeSucceededFuture(())
    }
    
    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        self.error = error
    }
    
    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        return try Decoder.decode(data: data)
    }
}
