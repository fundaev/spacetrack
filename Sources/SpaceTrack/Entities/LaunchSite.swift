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

/// Launch site
public struct LaunchSite: Decodable {
    public var siteCode: String
    public var launchSite: String

    public enum Key: String, CodingKey, EntityField {
        case siteCode = "SITE_CODE"
        case launchSite = "LAUNCH_SITE"

        public var dateFormat: DateFormat { .date }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)

        siteCode = try c.decode(String.self, forKey: .siteCode)
        launchSite = try c.decode(String.self, forKey: .launchSite)
    }
}

/// Type-alias for `Predicate<LaunchSite.Key>`
public typealias LaunchSitePredicate = Predicate<LaunchSite.Key>

/// Type-alias for `Order<LaunchSite.Key>`
public typealias LaunchSiteOrder = Order<LaunchSite.Key>

/// Launch sites list
public struct LaunchSiteList: Convertable, OptionalResponse {
    typealias SourceType = ResponseWithMetadata<LaunchSite>

    /// Total count of launch sites satisfied to the filter
    /// - seeAlso: Client
    public let count: Int

    /// Launch sites list
    public let data: [LaunchSite]

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

class LaunchSiteDecoder: JsonResponseConverter<LaunchSiteList.SourceType, LaunchSiteList>, ResponseDecoder {
    typealias Output = LaunchSiteList
}

struct LaunchSiteRequest: RequestInfo {
    let controller = Controller.basicSpaceData
    let action = Action.query
    let format = Format.json
    let resource = "launch_site"
    let distinct = true
    let metadata = true
}
