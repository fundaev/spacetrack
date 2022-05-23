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

/// Accounting of man-made objects that have been or are in orbit
public struct Boxscore: Decodable {
    public var country: String = ""
    public var spadocCd: String? = nil
    public var orbitalTba: Double? = nil
    public var orbitalPayloadCount: Double? = nil
    public var orbitalRocketBodyCount: Double? = nil
    public var orbitalDebrisCount: Double? = nil
    public var orbitalTotalCount: Double? = nil
    public var decayedPayloadCount: Double? = nil
    public var decayedRocketBodyCount: Double? = nil
    public var decayedDebrisCount: Double? = nil
    public var decayedTotalCount: Double? = nil
    public var countryTotal: Int64 = 0

    public enum Key: String, CodingKey, EntityField {
        case country = "COUNTRY"
        case spadocCd = "SPADOC_CD"
        case orbitalTba = "ORBITAL_TBA"
        case orbitalPayloadCount = "ORBITAL_PAYLOAD_COUNT"
        case orbitalRocketBodyCount = "ORBITAL_ROCKET_BODY_COUNT"
        case orbitalDebrisCount = "ORBITAL_DEBRIS_COUNT"
        case orbitalTotalCount = "ORBITAL_TOTAL_COUNT"
        case decayedPayloadCount = "DECAYED_PAYLOAD_COUNT"
        case decayedRocketBodyCount = "DECAYED_ROCKET_BODY_COUNT"
        case decayedDebrisCount = "DECAYED_DEBRIS_COUNT"
        case decayedTotalCount = "DECAYED_TOTAL_COUNT"
        case countryTotal = "COUNTRY_TOTAL"

        public var dateFormat: DateFormat { .dateTime }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        country = try c.decode(String.self, forKey: .country)
        spadocCd = try c.decodeIfPresent(String.self, forKey: .spadocCd)
        orbitalTba = try decodeOptional(container: c, forKey: .orbitalTba)
        orbitalPayloadCount = try decodeOptional(container: c, forKey: .orbitalPayloadCount)
        orbitalRocketBodyCount = try decodeOptional(container: c, forKey: .orbitalRocketBodyCount)
        orbitalDebrisCount = try decodeOptional(container: c, forKey: .orbitalDebrisCount)
        orbitalTotalCount = try decodeOptional(container: c, forKey: .orbitalTotalCount)
        decayedPayloadCount = try decodeOptional(container: c, forKey: .decayedPayloadCount)
        decayedRocketBodyCount = try decodeOptional(container: c, forKey: .decayedRocketBodyCount)
        decayedDebrisCount = try decodeOptional(container: c, forKey: .decayedDebrisCount)
        decayedTotalCount = try decodeOptional(container: c, forKey: .decayedTotalCount)
        countryTotal = try decode(container: c, forKey: .countryTotal)
    }
}

/// Type-alias for `Predicate<Boxscore.Key>`
public typealias BoxscorePredicate = Predicate<Boxscore.Key>

/// Type-alias for `Order<Decay.Key>`
public typealias BoxscoreOrder = Order<Boxscore.Key>

/// Boxscore list
public struct BoxscoreList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<Boxscore>

    /// Total count of rows satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// Boxscore list
    public let data: [Boxscore]

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

class BoxscoreDecoder: JsonResponseConverter<BoxscoreList.SourceType, BoxscoreList>, ResponseDecoder {
    typealias Output = BoxscoreList
}

struct BoxscoreRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "boxscore"
    let distinct = true
    let metadata = true
}
