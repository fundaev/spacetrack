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

struct ParsingError: Error {
    let message: String

    init(message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

protocol ConvertableFromString {
    init?(_ text: String)
}

extension Int64: ConvertableFromString {}
extension Int32: ConvertableFromString {}
extension Int16: ConvertableFromString {}
extension Int8: ConvertableFromString {}
extension Double: ConvertableFromString {}

extension Bool: ConvertableFromString {
    init?(_ text: String) {
        if text == "Y" {
            self = true
        } else if text == "N" {
            self = false
        } else {
            return nil
        }
    }
}

func decodeOptional<T, Key>(container: KeyedDecodingContainer<Key>,
                            forKey key: Key) throws -> T? where T: ConvertableFromString
{
    let stringValue = try container.decodeIfPresent(String.self, forKey: key)
    if stringValue == nil {
        return nil
    }

    let value = T(stringValue!)
    if value == nil {
        throw ParsingError(message: "Unexpected value: expecting \(T.self) while \"\(stringValue!)\" is provided")
    }

    return value!
}

func decode<T, Key>(container: KeyedDecodingContainer<Key>,
                    forKey key: Key) throws -> T where T: ConvertableFromString
{
    let stringValue = try container.decode(String.self, forKey: key)
    let value = T(stringValue)
    if value == nil {
        throw ParsingError(message: "Unexpected value: expecting \(T.self) while \"\(stringValue)\" is provided")
    }
    return value!
}

private func parse<T: Decodable>(from data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}

class JsonResponseDecoder<Entity> {
    var data = Data()

    func processChunk(buffer: ByteBuffer) {
        data.append(contentsOf: buffer.readableBytesView)
    }
}

extension JsonResponseDecoder where Entity: Decodable {
    func decode() throws -> Entity {
        return try parse(from: data)
    }
}

extension JsonResponseDecoder where Entity: Decodable & OptionalResponse {
    func decode() throws -> Entity {
        if String(data: data, encoding: .utf8) == Entity.emptyResult {
            return Entity()
        }
        return try parse(from: data)
    }
}

class JsonResponseConverter<InputEntity, OutputEntity>: JsonResponseDecoder<InputEntity> {}

extension JsonResponseConverter where InputEntity: Decodable,
    OutputEntity: Convertable,
    OutputEntity.SourceType == InputEntity
{
    func decode() throws -> OutputEntity {
        let response: InputEntity = try parse(from: data)
        return OutputEntity(from: response)
    }
}

extension JsonResponseConverter where InputEntity: Decodable,
    OutputEntity: Convertable & OptionalResponse,
    OutputEntity.SourceType == InputEntity
{
    func decode() throws -> OutputEntity {
        if String(data: data, encoding: .utf8) == OutputEntity.emptyResult {
            return OutputEntity()
        }
        let response: InputEntity = try parse(from: data)
        return OutputEntity(from: response)
    }
}
