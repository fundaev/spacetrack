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

protocol RequestInfo {
    var controller: Controller { get }
    var action: Action { get }
    var format: Format { get }
    var resource: String { get }
    var distinct: Bool { get }
    var metadata: Bool { get }

    func uri(filter: QueryBuilder, order: QueryBuilder, limit: Int?, offset: Int?) -> String
}

extension RequestInfo {
    func uri(filter: QueryBuilder, order: QueryBuilder, limit: Int?, offset: Int?) -> String {
        var limitString = ""
        if let limit = limit {
            limitString = "/limit/\(limit)"
            if let offset = offset {
                limitString += ",\(offset)"
            }
        }

        var distinctString = ""
        if distinct {
            distinctString = "/distinct/true"
        }

        var metadataString = ""
        if metadata {
            metadataString = "/metadata/true"
        }
        return """
        /\(controller.rawValue)/\(action.rawValue)/class/\(resource)\(filter.query)\
        \(order.query)\(limitString)/format/\(format.rawValue)\(distinctString)\(metadataString)
        """
    }
}
