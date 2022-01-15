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

/// Request result
public enum Result: Equatable, Error {
    /// Request is completed successfully
    case Success
    /// The request is unauthorized
    case Unauthorized(String)
    /// Some error occured
    case RequestError(String)
}

/// Represents a field of an entity
/// received from [www.space-track.org](https://www.space-track.org)
///
/// The protocol is used to extend it by some methods and operators,
/// allowing to create the instances of `Predicate` and `OrderBy` types.
public protocol EntityField {
    var rawValue: String { get }
}

protocol QueryBuilder {
    var query: String { get }
}

enum Controller: String {
    case basicSpaceData    = "basicspacedata"
    case expandedSpaceData = "expandedspacedata"
    case fileShare         = "fileshare"
}

enum Action: String {
    case query    = "query"
    case modelDef = "modeldef"
}

enum Format: String {
    case json
    case xml
    case html
    case csv
    case tle
    case three_le = "3le"
    case kvn
    case stream
}

protocol ResponseDecoder {
    associatedtype Output

    static var controller: Controller { get }
    static var action: Action { get }
    static var format: Format { get }
    static var resource: String { get }
    static var distinct: Bool { get }
    static var metadata: Bool { get }
    
    static func decode(data: Data) throws -> Output
}

protocol Convertable {
    associatedtype SourceType
    
    init(from data: SourceType)
}

protocol ResponseConverter: ResponseDecoder {
    associatedtype RawResponse
}

protocol OptionalResponse {
    static var emptyResult: String { get }
    
    init()
}
