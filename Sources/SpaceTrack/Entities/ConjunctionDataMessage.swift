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

/// Conjunction data message
public struct ConjunctionDataMessage: Decodable {
    public var cdmId: Int32 = 0
    public var created: Date? = nil
    public var emergencyReportable: String? = nil
    public var tca: Date? = nil
    public var minRng: Double? = nil
    public var pc: Double? = nil
    public var sat1Id: Int32? = nil
    public var sat1Name: String? = nil
    public var sat1ObjectType: String? = nil
    public var sat1Rcs: String? = nil
    public var sat1ExclVol: String? = nil
    public var sat2Id: Int32? = nil
    public var sat2Name: String? = nil
    public var sat2ObjectType: String? = nil
    public var sat2Rcs: String? = nil
    public var sat2ExclVol: String? = nil

    public enum Key: String, CodingKey, EntityField {
        case cdmId = "CDM_ID"
        case created = "CREATED"
        case emergencyReportable = "EMERGENCY_REPORTABLE"
        case tca = "TCA"
        case minRng = "MIN_RNG"
        case pc = "PC"
        case sat1Id = "SAT_1_ID"
        case sat1Name = "SAT_1_NAME"
        case sat1ObjectType = "SAT1_OBJECT_TYPE"
        case sat1Rcs = "SAT1_RCS"
        case sat1ExclVol = "SAT_1_EXCL_VOL"
        case sat2Id = "SAT_2_ID"
        case sat2Name = "SAT_2_NAME"
        case sat2ObjectType = "SAT2_OBJECT_TYPE"
        case sat2Rcs = "SAT2_RCS"
        case sat2ExclVol = "SAT_2_EXCL_VOL"

        public var dateFormat: DateFormat {
            switch self {
            case .created:
                return .datePreciseTimeWithBlankDelimiter
            default:
                return .datePreciseTime
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        cdmId = try decode(container: c, forKey: .cdmId)
        created = try decodeOptional(container: c, forKey: .created)
        emergencyReportable = try c.decodeIfPresent(String.self, forKey: .emergencyReportable)
        tca = try decodeOptional(container: c, forKey: .tca)
        minRng = try decodeOptional(container: c, forKey: .minRng)
        pc = try decodeOptional(container: c, forKey: .pc)
        sat1Id = try decodeOptional(container: c, forKey: .sat1Id)
        sat1Name = try c.decodeIfPresent(String.self, forKey: .sat1Name)
        sat1ObjectType = try c.decodeIfPresent(String.self, forKey: .sat1ObjectType)
        sat1Rcs = try c.decodeIfPresent(String.self, forKey: .sat1Rcs)
        sat1ExclVol = try c.decodeIfPresent(String.self, forKey: .sat1ExclVol)
        sat2Id = try decodeOptional(container: c, forKey: .sat2Id)
        sat2Name = try c.decodeIfPresent(String.self, forKey: .sat2Name)
        sat2ObjectType = try c.decodeIfPresent(String.self, forKey: .sat2ObjectType)
        sat2Rcs = try c.decodeIfPresent(String.self, forKey: .sat2Rcs)
        sat2ExclVol = try c.decodeIfPresent(String.self, forKey: .sat2ExclVol)
    }
}

/// Type-alias for `Predicate<ConjunctionDataMessage.Key>`
public typealias ConjunctionDataMessagePredicate = Predicate<ConjunctionDataMessage.Key>

/// Type-alias for `Order<ConjunctionDataMessage.Key>`
public typealias ConjunctionDataMessageOrder = Order<ConjunctionDataMessage.Key>

/// Conjunction data messages list
public struct ConjunctionDataMessageList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<ConjunctionDataMessage>

    /// Total count of rows satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// Conjunction data messages list
    public let data: [ConjunctionDataMessage]

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

class ConjunctionDataMessageDecoder:
    JsonResponseConverter<ConjunctionDataMessageList.SourceType, ConjunctionDataMessageList>,
    ResponseDecoder
{
    typealias Output = ConjunctionDataMessageList
}

struct ConjunctionDataMessageRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "cdm_public"
    let distinct = true
    let metadata = true
}
