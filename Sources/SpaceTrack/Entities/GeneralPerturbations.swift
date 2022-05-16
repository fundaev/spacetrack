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

/// Keplerian element set
public struct GeneralPerturbations: Decodable {
    public var ccsdsOmmVers: String = ""
    public var comment: String = ""
    public var creationDate: Date? = nil
    public var originator: String = ""
    public var objectName: String? = nil
    public var objectId: String? = nil
    public var centerName: String = ""
    public var refFrame: String = ""
    public var timeSystem: String = ""
    public var meanElementTheory: String = ""
    public var epoch: Date? = nil
    public var meanMotion: Double? = nil
    public var eccentricity: Double? = nil
    public var inclination: Double? = nil
    public var raOfAscNode: Double? = nil
    public var argOfPericenter: Double? = nil
    public var meanAnomaly: Double? = nil
    public var ephemerisType: Int32? = 0
    public var classificationType: String? = nil
    public var noradCatId: Int32 = 0
    public var elementSetNo: Int16? = nil
    public var revAtEpoch: Int32? = nil
    public var bstar: Double? = nil
    public var meanMotionDot: Double? = nil
    public var meanMotionDDot: Double? = nil
    public var semimajorAxis: Double? = nil
    public var period: Double? = nil
    public var apoapsis: Double? = nil
    public var periapsis: Double? = nil
    public var objectType: String? = nil
    public var rcsSize: String? = nil
    public var countryCode: String? = nil
    public var launchDate: Date? = nil
    public var site: String? = nil
    public var decayDate: Date? = nil
    public var file: Int64? = nil
    public var gpId: Int32 = 0
    public var tleLine0: String? = nil
    public var tleLine1: String? = nil
    public var tleLine2: String? = nil

    public enum Key: String, CodingKey, EntityField {
        case ccsdsOmmVers = "CCSDS_OMM_VERS"
        case comment = "COMMENT"
        case creationDate = "CREATION_DATE"
        case originator = "ORIGINATOR"
        case objectName = "OBJECT_NAME"
        case objectId = "OBJECT_ID"
        case centerName = "CENTER_NAME"
        case refFrame = "REF_FRAME"
        case timeSystem = "TIME_SYSTEM"
        case meanElementTheory = "MEAN_ELEMENT_THEORY"
        case epoch = "EPOCH"
        case meanMotion = "MEAN_MOTION"
        case eccentricity = "ECCENTRICITY"
        case inclination = "INCLINATION"
        case raOfAscNode = "RA_OF_ASC_NODE"
        case argOfPericenter = "ARG_OF_PERICENTER"
        case meanAnomaly = "MEAN_ANOMALY"
        case ephemerisType = "EPHEMERIS_TYPE"
        case classificationType = "CLASSIFICATION_TYPE"
        case noradCatId = "NORAD_CAT_ID"
        case elementSetNo = "ELEMENT_SET_NO"
        case revAtEoch = "REV_AT_EPOCH"
        case bstar = "BSTAR"
        case meanMotionDot = "MEAN_MOTION_DOT"
        case meanMotionDDot = "MEAN_MOTION_DDOT"
        case semimajotAxis = "SEMIMAJOR_AXIS"
        case period = "PERIOD"
        case apoapsis = "APOAPSIS"
        case periapsis = "PERIAPSIS"
        case objectType = "OBJECT_TYPE"
        case rcsSize = "RCS_SIZE"
        case countryCode = "COUNTRY_CODE"
        case launchDate = "LAUNCH_DATE"
        case site = "SITE"
        case decayDate = "DECAY_DATE"
        case file = "FILE"
        case gpId = "GP_ID"
        case tleLine0 = "TLE_LINE0"
        case tleLine1 = "TLE_LINE1"
        case tleLine2 = "TLE_LINE2"

        public var dateFormat: DateFormat {
            switch self {
            case .creationDate:
                return .DateTime
            case .decayDate, .launchDate:
                return .Date
            default:
                return .DatePreciseTime
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        ccsdsOmmVers = try c.decode(String.self, forKey: .ccsdsOmmVers)
        comment = try c.decode(String.self, forKey: .comment)
        creationDate = try decodeOptional(container: c, forKey: .creationDate)
        originator = try c.decode(String.self, forKey: .originator)
        objectName = try c.decodeIfPresent(String.self, forKey: .objectName)
        objectId = try c.decodeIfPresent(String.self, forKey: .objectId)
        centerName = try c.decode(String.self, forKey: .centerName)
        refFrame = try c.decode(String.self, forKey: .refFrame)
        timeSystem = try c.decode(String.self, forKey: .timeSystem)
        meanElementTheory = try c.decode(String.self, forKey: .meanElementTheory)
        epoch = try decodeOptional(container: c, forKey: .epoch)
        meanMotion = try decodeOptional(container: c, forKey: .meanMotion)
        eccentricity = try decodeOptional(container: c, forKey: .eccentricity)
        inclination = try decodeOptional(container: c, forKey: .inclination)
        raOfAscNode = try decodeOptional(container: c, forKey: .raOfAscNode)
        argOfPericenter = try decodeOptional(container: c, forKey: .argOfPericenter)
        meanAnomaly = try decodeOptional(container: c, forKey: .meanAnomaly)
        ephemerisType = try decodeOptional(container: c, forKey: .ephemerisType)
        classificationType = try c.decodeIfPresent(String.self, forKey: .classificationType)
        noradCatId = try decode(container: c, forKey: .noradCatId)
        elementSetNo = try decodeOptional(container: c, forKey: .elementSetNo)
        revAtEpoch = try decodeOptional(container: c, forKey: .revAtEoch)
        bstar = try decodeOptional(container: c, forKey: .bstar)
        meanMotionDot = try decodeOptional(container: c, forKey: .meanMotionDot)
        meanMotionDDot = try decodeOptional(container: c, forKey: .meanMotionDDot)
        semimajorAxis = try decodeOptional(container: c, forKey: .semimajotAxis)
        period = try decodeOptional(container: c, forKey: .period)
        apoapsis = try decodeOptional(container: c, forKey: .apoapsis)
        periapsis = try decodeOptional(container: c, forKey: .periapsis)
        objectType = try c.decodeIfPresent(String.self, forKey: .objectType)
        rcsSize = try c.decodeIfPresent(String.self, forKey: .rcsSize)
        countryCode = try c.decodeIfPresent(String.self, forKey: .countryCode)
        launchDate = try decodeOptional(container: c, forKey: .launchDate)
        site = try c.decodeIfPresent(String.self, forKey: .site)
        decayDate = try decodeOptional(container: c, forKey: .decayDate)
        file = try decodeOptional(container: c, forKey: .file)
        gpId = try decode(container: c, forKey: .gpId)
        tleLine0 = try c.decodeIfPresent(String.self, forKey: .tleLine0)
        tleLine1 = try c.decodeIfPresent(String.self, forKey: .tleLine1)
        tleLine2 = try c.decodeIfPresent(String.self, forKey: .tleLine2)
    }
}

/// Type-alias for `Predicate<GeneralPerturbations.Key>`
public typealias GPPredicate = Predicate<GeneralPerturbations.Key>

/// Type-alias for `Order<GeneralPerturbations.Key>`
public typealias GPOrder = Order<GeneralPerturbations.Key>

/// Satellite catalog information
public struct GeneralPerturbationsList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<GeneralPerturbations>

    /// Total count of rows satisfied to the filter,
    /// specified in the Client.requestGPList method
    /// - seeAlso: Client
    public let count: Int

    /// General perturbations list
    public let data: [GeneralPerturbations]

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

class GPDecoder: JsonResponseConverter<GeneralPerturbationsList.SourceType, GeneralPerturbationsList>, ResponseDecoder {
    typealias Output = GeneralPerturbationsList
}

class GPRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "gp"
    let distinct = true
    let metadata = true
}
