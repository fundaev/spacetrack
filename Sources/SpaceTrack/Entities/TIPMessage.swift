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

/// Tracking and Impact Prediction Message
public struct TIPMessage: Decodable {
    public enum Direction: String, ConvertableFromString {
        case ascending
        case descending

        init?(_ text: String) {
            self.init(rawValue: text)
        }
    }

    public var noradCatId: Int32? = nil
    public var messageEpoch = Date()
    public var insertEpoch = Date()
    public var decayEpoch = Date()
    public var window: Int32 = 0
    public var rev: Int32 = 0
    public var direction: Direction? = nil
    public var latitude: Double = 0
    public var longitude: Double = 0
    public var inclination: Double = 0
    public var nextReport: Int32 = 0
    public var id: Int32 = 0
    public var highInterest: Bool = false
    public var objectNumber: Int32? = nil

    public enum Key: String, CodingKey, EntityField {
        case noradCatId = "NORAD_CAT_ID"
        case messageEpoch = "MSG_EPOCH"
        case insertEpoch = "INSERT_EPOCH"
        case decayEpoch = "DECAY_EPOCH"
        case window = "WINDOW"
        case rev = "REV"
        case direction = "DIRECTION"
        case latitude = "LAT"
        case longitude = "LON"
        case inclination = "INCL"
        case nextReport = "NEXT_REPORT"
        case id = "ID"
        case highInterest = "HIGH_INTEREST"
        case objectNumber = "OBJECT_NUMBER"

        public var dateFormat: DateFormat { .dateTimeWithBlankDelimiter }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        noradCatId = try decodeOptional(container: c, forKey: .noradCatId)
        messageEpoch = try decode(container: c, forKey: .messageEpoch)
        insertEpoch = try decode(container: c, forKey: .insertEpoch)
        decayEpoch = try decode(container: c, forKey: .decayEpoch)
        window = try decode(container: c, forKey: .window)
        rev = try decode(container: c, forKey: .rev)
        direction = try decodeOptional(container: c, forKey: .direction)
        latitude = try decode(container: c, forKey: .latitude)
        longitude = try decode(container: c, forKey: .longitude)
        inclination = try decode(container: c, forKey: .inclination)
        nextReport = try decode(container: c, forKey: .nextReport)
        id = try decode(container: c, forKey: .id)
        highInterest = try decode(container: c, forKey: .highInterest)
        objectNumber = try decodeOptional(container: c, forKey: .objectNumber)
    }
}

/// Type-alias for `Predicate<TIPMessage.Key>`
public typealias TIPMessagePredicate = Predicate<TIPMessage.Key>

/// Type-alias for `Order<TIPMessage.Key>`
public typealias TIPMessageOrder = Order<TIPMessage.Key>

/// TIP messages list
public struct TIPMessageList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<TIPMessage>

    /// Total count of changes satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// TIP messages list
    public let data: [TIPMessage]

    static let emptyResult = "[]"

    init(from: SourceType) {
        count = from.metadata.total
        data = from.data
    }

    init() {
        count = 0
        data = []
    }
}

class TIPMessageDecoder: JsonResponseConverter<TIPMessageList.SourceType, TIPMessageList>, ResponseDecoder {
    typealias Output = TIPMessageList
}

struct TIPMessageRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "tip"
    let distinct = true
    let metadata = true
}
