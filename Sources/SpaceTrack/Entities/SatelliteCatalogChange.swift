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

/// Satellite catalog item
public struct SatelliteChange: Decodable {
    public var noradCatId: Int32? = nil
    public var objectNumber: Int32? = nil
    public var currentName: String = ""
    public var previousName: String? = nil
    public var currentIntldes: String = ""
    public var previousIntldes: String? = nil
    public var currentCountry: String = ""
    public var previousCountry: String? = nil
    public var currentLaunch: Date? = nil
    public var previousLaunch: Date? = nil
    public var currentDecay: Date? = nil
    public var previousDecay: Date? = nil
    public var changeMade: Date? = nil

    public enum Key: String, CodingKey, EntityField {
        case noradCatId = "NORAD_CAT_ID"
        case objectNumber = "OBJECT_NUMBER"
        case currentName = "CURRENT_NAME"
        case previousName = "PREVIOUS_NAME"
        case currentIntldes = "CURRENT_INTLDES"
        case previousIntldes = "PREVIOUS_INTLDES"
        case currentCountry = "CURRENT_COUNTRY"
        case previousCountry = "PREVIOUS_COUNTRY"
        case currentLaunch = "CURRENT_LAUNCH"
        case previousLaunch = "PREVIOUS_LAUNCH"
        case currentDecay = "CURRENT_DECAY"
        case previousDecay = "PREVIOUS_DECAY"
        case changeMade = "CHANGE_MADE"

        public var dateFormat: DateFormat {
            switch self {
            case .changeMade:
                return .dateTimeWithBlankDelimiter
            default:
                return .date
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        noradCatId = try decodeOptional(container: c, forKey: .noradCatId)
        objectNumber = try decodeOptional(container: c, forKey: .objectNumber)
        currentName = try c.decode(String.self, forKey: .currentName)
        previousName = try c.decodeIfPresent(String.self, forKey: .previousName)
        currentIntldes = try c.decode(String.self, forKey: .currentIntldes)
        previousIntldes = try c.decodeIfPresent(String.self, forKey: .previousIntldes)
        currentCountry = try c.decode(String.self, forKey: .currentCountry)
        previousCountry = try c.decodeIfPresent(String.self, forKey: .previousCountry)
        currentLaunch = try decodeOptional(container: c, forKey: .currentLaunch)
        previousLaunch = try decodeOptional(container: c, forKey: .previousLaunch)
        currentDecay = try decodeOptional(container: c, forKey: .currentDecay)
        previousDecay = try decodeOptional(container: c, forKey: .previousDecay)
        changeMade = try decode(container: c, forKey: .changeMade)
    }
}

/// Type-alias for `Predicate<SatelliteChange.Key>`
public typealias SatelliteChangePredicate = Predicate<SatelliteChange.Key>

/// Type-alias for `Order<SatelliteChange.Key>`
public typealias SatelliteChangeOrder = Order<SatelliteChange.Key>

/// Satellite catalog changes
public struct SatelliteChangeList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<SatelliteChange>

    /// Total count of changes satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// Satellites list
    public let data: [SatelliteChange]

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

class SatelliteChangeDecoder: JsonResponseConverter<SatelliteChangeList.SourceType, SatelliteChangeList>,
    ResponseDecoder
{
    typealias Output = SatelliteChangeList
}

struct SatelliteChangeRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "satcat_change"
    let distinct = true
    let metadata = true
}
