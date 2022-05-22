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

/// Predicted and historical decay information
public struct Decay: Decodable {
    public var noradCatId: Int32? = nil
    public var objectNumber: Int32? = nil
    public var objectName: String = ""
    public var objectId: String = ""
    public var intldes: String = ""
    public var rcs: Int32 = 0
    public var rcsSize: String? = nil
    public var country: String = ""
    public var messageEpoch: Date? = nil
    public var decayEpoch: Date? = nil
    public var source: String = ""
    public var messageType: String = ""
    public var precedence: Int32 = 0

    public enum Key: String, CodingKey, EntityField {
        case noradCatId = "NORAD_CAT_ID"
        case objectNumber = "OBJECT_NUMBER"
        case objectName = "OBJECT_NAME"
        case objectId = "OBJECT_ID"
        case intldes = "INTLDES"
        case rcs = "RCS"
        case rcsSize = "RCS_SIZE"
        case country = "COUNTRY"
        case messageEpoch = "MSG_EPOCH"
        case decayEpoch = "DECAY_EPOCH"
        case source = "SOURCE"
        case messageType = "MSG_TYPE"
        case precedence = "PRECEDENCE"

        public var dateFormat: DateFormat { .dateTimeWithBlankDelimiter }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        noradCatId = try decodeOptional(container: c, forKey: .noradCatId)
        objectNumber = try decodeOptional(container: c, forKey: .objectNumber)
        objectName = try c.decode(String.self, forKey: .objectName)
        objectId = try c.decode(String.self, forKey: .objectId)
        intldes = try c.decode(String.self, forKey: .intldes)
        rcs = try decode(container: c, forKey: .rcs)
        rcsSize = try c.decodeIfPresent(String.self, forKey: .rcsSize)
        country = try c.decode(String.self, forKey: .country)
        messageEpoch = try decodeOptional(container: c, forKey: .messageEpoch)
        decayEpoch = try decodeOptional(container: c, forKey: .decayEpoch)
        source = try c.decode(String.self, forKey: .source)
        messageType = try c.decode(String.self, forKey: .messageType)
        precedence = try decode(container: c, forKey: .precedence)
    }
}

/// Type-alias for `Predicate<Decay.Key>`
public typealias DecayPredicate = Predicate<Decay.Key>

/// Type-alias for `Order<Decay.Key>`
public typealias DecayOrder = Order<Decay.Key>

/// Decay list
public struct DecayList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<Decay>

    /// Total count of rows satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// Decay list
    public let data: [Decay]

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

class DecayDecoder: JsonResponseConverter<DecayList.SourceType, DecayList>, ResponseDecoder {
    typealias Output = DecayList
}

struct DecayRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "decay"
    let distinct = true
    let metadata = true
}
