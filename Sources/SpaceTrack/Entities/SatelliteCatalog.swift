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
public struct Satellite: Decodable {
    public var intldes: String = ""
    public var noradCatId: Int32? = nil
    public var objectType: String? = nil
    public var name: String = ""
    public var country: String = ""
    public var launch: Date? = nil
    public var site: String? = nil

    public var decay: Date? = nil
    public var period: Double? = nil
    public var inclination: Double? = nil
    public var apogee: Int64? = nil
    public var perigee: Int64? = nil

    public var comment: String? = nil
    public var commentCode: Int8? = nil
    public var rcsValue: Int32 = 0
    public var rcsSize: String? = nil
    public var file: Int16 = 0

    public var launchYear: Int16 = 0
    public var launchNum: Int16 = 0
    public var launchPiece: String = ""

    public var current: Bool = false
    public var objectId: String = ""
    public var objectName: String = ""
    public var objectNumber: Int32? = nil

    public var debut: Date? = nil

    public enum Key: String, CodingKey, EntityField {
        case intldes = "INTLDES"
        case noradCatId = "NORAD_CAT_ID"
        case objectType = "OBJECT_TYPE"
        case name = "SATNAME"
        case country = "COUNTRY"
        case launch = "LAUNCH"
        case site = "SITE"
        case decay = "DECAY"
        case period = "PERIOD"
        case inclination = "INCLINATION"
        case apogee = "APOGEE"
        case perigee = "PERIGEE"
        case comment = "COMMENT"
        case commentCode = "COMMENTCODE"
        case rcsValue = "RCSVALUE"
        case rcsSize = "RCS_SIZE"
        case file = "FILE"
        case launchYear = "LAUNCH_YEAR"
        case launchNum = "LAUNCH_NUM"
        case launchPiece = "LAUNCH_PIECE"
        case current = "CURRENT"
        case objectId = "OBJECT_ID"
        case objectName = "OBJECT_NAME"
        case objectNumber = "OBJECT_NUMBER"
        case debut = "DEBUT"

        public var dateFormat: DateFormat {
            switch self {
            case .debut:
                return .dateTimeWithBlankDelimiter
            default:
                return .date
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        intldes = try c.decode(String.self, forKey: .intldes)
        noradCatId = try decodeOptional(container: c, forKey: .noradCatId)
        objectType = try c.decodeIfPresent(String.self, forKey: .objectType)
        name = try c.decode(String.self, forKey: .name)
        country = try c.decode(String.self, forKey: .country)
        launch = try decodeOptional(container: c, forKey: .launch)
        site = try c.decodeIfPresent(String.self, forKey: .site)

        decay = try decodeOptional(container: c, forKey: .decay)
        period = try decodeOptional(container: c, forKey: .period)
        inclination = try decodeOptional(container: c, forKey: .inclination)
        apogee = try decodeOptional(container: c, forKey: .apogee)
        perigee = try decodeOptional(container: c, forKey: .perigee)

        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        commentCode = try decodeOptional(container: c, forKey: .commentCode)
        rcsValue = try decode(container: c, forKey: .rcsValue)
        rcsSize = try c.decodeIfPresent(String.self, forKey: .rcsSize)
        file = try decode(container: c, forKey: .file)

        launchYear = try decode(container: c, forKey: .launchYear)
        launchNum = try decode(container: c, forKey: .launchNum)
        launchPiece = try c.decode(String.self, forKey: .launchPiece)

        current = try decode(container: c, forKey: .current)
        objectId = try c.decode(String.self, forKey: .objectId)
        objectName = try c.decode(String.self, forKey: .objectName)
        objectNumber = try decodeOptional(container: c, forKey: .objectNumber)

        debut = try decodeOptional(container: c, forKey: .debut)
    }
}

/// Type-alias for `Predicate<Satellite.Key>`
public typealias SatellitePredicate = Predicate<Satellite.Key>

/// Type-alias for `Order<Satellite.Key>`
public typealias SatelliteOrder = Order<Satellite.Key>

/// Satellite catalog information
public struct SatelliteCatalog: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<Satellite>

    /// Total count of satellites satisfied to the filter,
    /// specified in the Client.requestSatelliteCatalog method
    /// - seeAlso: Client
    public let count: Int

    /// Satellites list
    public let data: [Satellite]

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

class SatelliteDecoder: JsonResponseConverter<SatelliteCatalog.SourceType, SatelliteCatalog>, ResponseDecoder {
    typealias Output = SatelliteCatalog
}

struct SatelliteCatalogRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "satcat"
    let distinct = true
    let metadata = true
}

struct SatelliteCatalogDebutRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "satcat_debut"
    let distinct = true
    let metadata = true
}
