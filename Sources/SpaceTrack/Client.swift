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

import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import NIOPosix

/// SpaceTrack.Client class provides API to request data from [www.space-track.org](https://www.space-track.org)
///
/// The interaction with [www.space-track.org](https://www.space-track.org) with this class is started
/// from authorization. It is necessary to have
/// [an regisreted account](https://www.space-track.org/auth/createAccount) for that.
///
/// Since the client is authorized one may use other methods to requst the information about
/// the available satellites and their current orbital elements.
public class Client {
    private let host = "www.space-track.org"

    private let eventLoopGroup: EventLoopGroup
    private let groupOwner: Bool
    private let httpClient: HTTPClient
    private let session: Session

    /// Create Client with specified event loop group provider
    ///
    /// - parameters:
    ///     - eventLoopGroupProvider: Specify how `EventLoopGroup` will be created.
    public init(eventLoopGroupProvider: NIOEventLoopGroupProvider) {
        switch eventLoopGroupProvider {
        case let .shared(group):
            eventLoopGroup = group
            groupOwner = false
        case .createNew:
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            groupOwner = true
        }
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        session = Session(hostname: host)
    }

    deinit {
        if groupOwner {
            try? eventLoopGroup.syncShutdownGracefully()
        }
    }

    /// Whether client is authorized
    public var isAuthorized: Bool {
        return session.hasCookies
    }

    /// Authorize client.
    ///
    /// - parameters:
    ///     - username: e-mail address used as a user name at www.space-track.org
    ///     - password: user password
    /// - returns: Future with authorization result
    public func authorize(username: String, password: String) -> EventLoopFuture<Result> {
        var request = createRequest(uri: AuthDecoder.uri, method: AuthDecoder.method)
        request.headers = AuthDecoder.requestHeaders
        request.body = .byteBuffer(AuthDecoder.requestBody(username: username, password: password))

        let authDecoder = AuthDecoder(session: session)
        let task = httpClient.execute(request: request, delegate: AuthDelegate(decoder: authDecoder), deadline: nil)
        return task.futureResult
    }

    /// Request the list of available satellites without current information about their orbital elements.
    ///
    /// For example, this code requests first 10 satellites, starting from 4th, with names containing "ISS" word
    /// and sorted by name:
    /// ```swift
    /// let futureData = client.requestSatelliteCatalog(
    ///     where: Satellite.Key.name == "~~ISS~~",
    ///     order: Satellite.Key.name.asc,
    ///     limit: 10,
    ///     offset: 3
    /// )
    /// ```
    /// Another example. This code requests all satellites with "NOAA" word in their names, launched after 2000 year,
    /// sorted ascending by names and descending by object ID:
    /// ```swift
    /// let futureData = client.requestSatelliteCatalog(
    ///     where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    ///     order: Satellite.Key.name.asc & Satellite.Key.objectId.desc)
    /// ```
    ///
    /// - parameters:
    ///     - where: SatellitePredicate used to filter the satellites.
    ///     - order: Use Satellite.Key to construct the required order in the satellite list.
    ///     - limit: Maximum count of items in the response
    ///     - offset: List offset
    /// - returns: EventLoopFuture instance with SatelliteCatalog. SatelliteCatalog.count field contains total number
    ///            of the satellites, satisfied to the specified filter.
    ///            SatelliteCatalog.data is array of selected satellites.
    /// - seeAlso:
    ///     - SatelliteCatalog
    public func requestSatelliteCatalog(
        where filter: SatellitePredicate = SatellitePredicate(),
        order: SatelliteOrder = SatelliteOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<SatelliteCatalog> {
        return requestData(
            request: SatelliteCatalogRequest(),
            handler: DataDelegate(decoder: SatelliteDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request records added to the Satellite Catalog.
    ///
    /// - parameters:
    ///     - where: SatellitePredicate used to filter the satellites.
    ///     - order: Use Satellite.Key to construct the required order in the satellite list.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    /// - returns: EventLoopFuture instance with SatelliteCatalog. SatelliteCatalog.count field contains total number
    ///            of the satellites, satisfied to the specified filter.
    ///            SatelliteCatalog.data is array of selected satellites.
    /// - seeAlso:
    ///     - SatelliteCatalog
    public func requestSatelliteCatalogDebut(
        where filter: SatellitePredicate = SatellitePredicate(),
        order: SatelliteOrder = SatelliteOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<SatelliteCatalog> {
        return requestData(
            request: SatelliteCatalogDebutRequest(),
            handler: DataDelegate(decoder: SatelliteDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request changes in the satellite catalog.
    ///
    /// - parameters:
    ///     - where: SatelliteChangePredicate used to filter the changes.
    ///     - order: Use SatelliteChange.Key to construct the required order in the changes list.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    /// - returns: EventLoopFuture instance with SatelliteChangeList. SatelliteCatalog.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            SatelliteChangeList.data is array of rows.
    /// - seeAlso:
    ///     - SatelliteChangeList
    public func requestSatelliteCatalogChanges(
        where filter: SatelliteChangePredicate = SatelliteChangePredicate(),
        order: SatelliteChangeOrder = SatelliteChangeOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<SatelliteChangeList> {
        return requestData(
            request: SatelliteChangeRequest(),
            handler: DataDelegate(decoder: SatelliteChangeDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request current keplerian elements.
    ///
    /// For example, this code requests keplerian elements for satellite with object ID "1982-092AWB":
    /// ```swift
    /// let futureData = client.requestGeneralPerturbations(where: GeneralPerturbations.Key.objectId == "1982-092AWB")
    /// ```
    ///
    /// - parameters:
    ///     - where: GPPredicate used to filter the data.
    ///     - order: Use GeneralPerturbations.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response
    ///     - offset: List offset
    /// - returns: EventLoopFuture instance with GeneralPerturbationsList.
    ///            GeneralPerturbationsList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            GeneralPerturbationsList.data is array of keplerian elements.
    /// - seeAlso:
    ///     - GeneralPerturbations
    public func requestGeneralPerturbations(
        where filter: GPPredicate = GPPredicate(),
        order: GPOrder = GPOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<GeneralPerturbationsList> {
        return requestData(
            request: GPRequest(),
            handler: DataDelegate(decoder: GPDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request historical keplerian elements.
    ///
    /// - parameters:
    ///     - where: GPPredicate used to filter the data.
    ///     - order: Use GeneralPerturbations.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response
    ///     - offset: List offset
    /// - returns: EventLoopFuture instance with GeneralPerturbationsList.
    ///            GeneralPerturbationsList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            GeneralPerturbationsList.data is array of keplerian elements.
    /// - seeAlso:
    ///     - GeneralPerturbations
    public func requestGeneralPerturbationsHistory(
        where filter: GPPredicate = GPPredicate(),
        order: GPOrder = GPOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<GeneralPerturbationsList> {
        return requestData(
            request: GPHistoryRequest(),
            handler: DataDelegate(decoder: GPDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request launch sites list.
    ///
    /// - parameters:
    ///     - where: LaunchSitePredicate used to filter the data.
    ///     - order: Use LaunchSite.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    ///     - timeout: Request timeout.
    /// - returns: EventLoopFuture instance with LaunchSiteList.
    ///            LaunchSiteList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            LaunchSiteList.data is array of launch sites.
    /// - seeAlso:
    ///     - LaunchSite
    public func requestLaunchSiteList(
        where filter: LaunchSitePredicate = LaunchSitePredicate(),
        order: LaunchSiteOrder = LaunchSiteOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<LaunchSiteList> {
        return requestData(
            request: LaunchSiteRequest(),
            handler: DataDelegate(decoder: LaunchSiteDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request Tracking and Impact Prediction Message list.
    ///
    /// - parameters:
    ///     - where: TIPMessagePredicate used to filter the data.
    ///     - order: Use TIPMessage.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    ///     - timeout: Request timeout.
    /// - returns: EventLoopFuture instance with TIPMessageList.
    ///            TIPMessageList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            TIPMessageList.data is array of TIP messages.
    /// - seeAlso:
    ///     - TIPMessage
    public func requestTIPMessageList(
        where filter: TIPMessagePredicate = TIPMessagePredicate(),
        order: TIPMessageOrder = TIPMessageOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<TIPMessageList> {
        return requestData(
            request: TIPMessageRequest(),
            handler: DataDelegate(decoder: TIPMessageDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request Predicted and historical decay information.
    ///
    /// - parameters:
    ///     - where: DecayPredicate used to filter the data.
    ///     - order: Use Decay.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    ///     - timeout: Request timeout.
    /// - returns: EventLoopFuture instance with DecayList.
    ///            DecayList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            DecayList.data is array of decay messages.
    /// - seeAlso:
    ///     - Decay
    public func requestDecay(
        where filter: DecayPredicate = DecayPredicate(),
        order: DecayOrder = DecayOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<DecayList> {
        return requestData(
            request: DecayRequest(),
            handler: DataDelegate(decoder: DecayDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request conjunction data messages list.
    ///
    /// - parameters:
    ///     - where: ConjunctionDataMessagePredicate used to filter the data.
    ///     - order: Use ConjunctionDataMessage.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    ///     - timeout: Request timeout.
    /// - returns: EventLoopFuture instance with ConjunctionDataMessageList.
    ///            ConjunctionDataMessageList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            ConjunctionDataMessageList.data is array of conjunction data messages.
    /// - seeAlso:
    ///     - ConjunctionDataMessage
    public func requestConjunctionDataMessageList(
        where filter: ConjunctionDataMessagePredicate = ConjunctionDataMessagePredicate(),
        order: ConjunctionDataMessageOrder = ConjunctionDataMessageOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<ConjunctionDataMessageList> {
        return requestData(
            request: ConjunctionDataMessageRequest(),
            handler: DataDelegate(decoder: ConjunctionDataMessageDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    /// Request accounting of man-made objects that have been or are in orbit.
    ///
    /// - parameters:
    ///     - where: BoxscorePredicate used to filter the data.
    ///     - order: Use Boxscore.Key to construct the required order in the elements.
    ///     - limit: Maximum count of items in the response.
    ///     - offset: List offset.
    ///     - timeout: Request timeout.
    /// - returns: EventLoopFuture instance with BoxscoreList.
    ///            BoxscoreList.count field contains total number
    ///            of the rows, satisfied to the specified filter.
    ///            BoxscoreList.data is array of boxscores.
    /// - seeAlso:
    ///     - Boxscore
    public func requestBoxscore(
        where filter: BoxscorePredicate = BoxscorePredicate(),
        order: BoxscoreOrder = BoxscoreOrder(),
        limit: Int? = nil,
        offset: Int? = nil
    ) -> EventLoopFuture<BoxscoreList> {
        return requestData(
            request: BoxscoreRequest(),
            handler: DataDelegate(decoder: BoxscoreDecoder()),
            filter: filter,
            order: order,
            limit: limit,
            offset: offset
        )
    }

    private func requestData<Handler: HTTPClientResponseDelegate>(
        request: RequestInfo,
        handler: Handler,
        filter: QueryBuilder,
        order: QueryBuilder,
        limit: Int?,
        offset: Int?
    ) -> EventLoopFuture<Handler.Response> {
        let uri = request.uri(filter: filter, order: order, limit: limit, offset: offset)
        let request = createRequest(uri: uri, method: .GET)
        return httpClient.execute(request: request, delegate: handler, deadline: nil).futureResult
    }

    private func createRequest(uri: String, method: HTTPMethod) -> HTTPClient.Request {
        var request = try! HTTPClient.Request(url: url(uri: uri), method: method)
        session.headers.forEach { header in
            request.headers.add(name: header.key, value: header.value)
        }
        return request
    }

    private func url(uri: String) -> String {
        return "https://\(host)\(uri)"
    }
}

#if compiler(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public extension Client {
        /// Authorize client.
        ///
        /// - parameters:
        ///     - username: e-mail address used as a user name at www.space-track.org
        ///     - password: user password
        /// - returns: Authorization result
        func auth(username: String, password: String, timeout: TimeAmount = .seconds(30)) async throws -> Result {
            var request = HTTPClientRequest(url: url(uri: AuthDecoder.uri))
            request.method = AuthDecoder.method
            request.headers = AuthDecoder.requestHeaders
            request.body = .bytes(AuthDecoder.requestBody(username: username, password: password))

            let authDecoder = AuthDecoder(session: session)
            let response = try await httpClient.execute(request, timeout: timeout)
            authDecoder.processHeader(status: response.status, headers: response.headers)
            for try await buffer in response.body {
                authDecoder.processChunk(buffer: buffer)
            }
            return authDecoder.decode()
        }

        /// Request the list of available satellites without current information about their orbital elements.
        ///
        /// For example, this code requests first 10 satellites, starting from 4th, with names containing "ISS" word
        /// and sorted by name:
        /// ```swift
        /// let data = try await client.satelliteCatalog(
        ///     where: Satellite.Key.name == "~~ISS~~",
        ///     order: Satellite.Key.name.asc,
        ///     limit: 10,
        ///     offset: 3
        /// )
        /// ```
        /// Another example. This code requests all satellites with "NOAA" word in their names, launched after 2000 year,
        /// sorted ascending by names and descending by object ID:
        /// ```swift
        /// let data = try await client.satelliteCatalog(
        ///     where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
        ///     order: Satellite.Key.name.asc & Satellite.Key.objectId.desc)
        /// ```
        ///
        /// - parameters:
        ///     - where: SatellitePredicate used to filter the satellites.
        ///     - order: Use Satellite.Key to construct the required order in the satellite list.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: SatelliteCatalog. SatelliteCatalog.count field contains total number
        ///            of the satellites, satisfied to the specified filter.
        ///            SatelliteCatalog.data is array of selected satellites.
        /// - seeAlso:
        ///     - SatelliteCatalog
        func satelliteCatalog(
            where filter: SatellitePredicate = SatellitePredicate(),
            order: SatelliteOrder = SatelliteOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> SatelliteCatalog {
            return try await getData(
                request: SatelliteCatalogRequest(),
                decoder: SatelliteDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request records added to the Satellite Catalog.
        ///
        /// - parameters:
        ///     - where: SatellitePredicate used to filter the satellites.
        ///     - order: Use Satellite.Key to construct the required order in the satellite list.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: SatelliteCatalog. SatelliteCatalog.count field contains total number
        ///            of the satellites, satisfied to the specified filter.
        ///            SatelliteCatalog.data is array of selected satellites.
        /// - seeAlso:
        ///     - SatelliteCatalog
        func satelliteCatalogDebut(
            where filter: SatellitePredicate = SatellitePredicate(),
            order: SatelliteOrder = SatelliteOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> SatelliteCatalog {
            return try await getData(
                request: SatelliteCatalogDebutRequest(),
                decoder: SatelliteDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request changes in the satellite catalog.
        ///
        /// - parameters:
        ///     - where: SatelliteChangePredicate used to filter the changes.
        ///     - order: Use SatelliteChange.Key to construct the required order in the changes list.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        /// - returns: EventLoopFuture instance with SatelliteChangeList. SatelliteCatalog.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            SatelliteChangeList.data is array of rows.
        /// - seeAlso:
        ///     - SatelliteChangeList
        func satelliteCatalogChanges(
            where filter: SatelliteChangePredicate = SatelliteChangePredicate(),
            order: SatelliteChangeOrder = SatelliteChangeOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> SatelliteChangeList {
            return try await getData(
                request: SatelliteChangeRequest(),
                decoder: SatelliteChangeDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request current keplerian elements.
        ///
        /// For example, this code requests keplerian elements for satellite with object ID "1982-092AWB":
        /// ```swift
        /// let data = try await client.generalPerturbations(
        ///     where: GeneralPerturbations.Key.objectId == "1982-092AWB"
        /// )
        /// ```
        ///
        /// - parameters:
        ///     - where: GPPredicate used to filter the data.
        ///     - order: Use GeneralPerturbations.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: GeneralPerturbationsList.
        ///            GeneralPerturbationsList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            GeneralPerturbationsList.data is array of keplerian elements.
        /// - seeAlso:
        ///     - GeneralPerturbations
        func generalPerturbations(
            where filter: GPPredicate = GPPredicate(),
            order: GPOrder = GPOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> GeneralPerturbationsList {
            return try await getData(
                request: GPRequest(),
                decoder: GPDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request historical keplerian elements.
        ///
        /// - parameters:
        ///     - where: GPPredicate used to filter the data.
        ///     - order: Use GeneralPerturbations.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: GeneralPerturbationsList.
        ///            GeneralPerturbationsList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            GeneralPerturbationsList.data is array of keplerian elements.
        /// - seeAlso:
        ///     - GeneralPerturbations
        func generalPerturbationsHistory(
            where filter: GPPredicate = GPPredicate(),
            order: GPOrder = GPOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> GeneralPerturbationsList {
            return try await getData(
                request: GPHistoryRequest(),
                decoder: GPDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request launch sites list.
        ///
        /// - parameters:
        ///     - where: LaunchSitePredicate used to filter the data.
        ///     - order: Use LaunchSite.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: LaunchSiteList.
        ///            LaunchSiteList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            LaunchSiteList.data is array of launch sites.
        /// - seeAlso:
        ///     - LaunchSite
        func launchSiteList(
            where filter: LaunchSitePredicate = LaunchSitePredicate(),
            order: LaunchSiteOrder = LaunchSiteOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> LaunchSiteList {
            return try await getData(
                request: LaunchSiteRequest(),
                decoder: LaunchSiteDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request Tracking and Impact Prediction Message list.
        ///
        /// - parameters:
        ///     - where: TIPMessagePredicate used to filter the data.
        ///     - order: Use TIPMessage.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: TIPMessageList.
        ///            TIPMessageList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            TIPMessageList.data is array of TIP messages.
        /// - seeAlso:
        ///     - TIPMessage
        func TIPMessageList(
            where filter: TIPMessagePredicate = TIPMessagePredicate(),
            order: TIPMessageOrder = TIPMessageOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> TIPMessageList {
            return try await getData(
                request: TIPMessageRequest(),
                decoder: TIPMessageDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request Predicted and historical decay information.
        ///
        /// - parameters:
        ///     - where: DecayPredicate used to filter the data.
        ///     - order: Use Decay.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: DecayList.
        ///            DecayList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            DecayList.data is array of decay messages.
        /// - seeAlso:
        ///     - Decay
        func decay(
            where filter: DecayPredicate = DecayPredicate(),
            order: DecayOrder = DecayOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> DecayList {
            return try await getData(
                request: DecayRequest(),
                decoder: DecayDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request conjunction data messages list.
        ///
        /// - parameters:
        ///     - where: ConjunctionDataMessagePredicate used to filter the data.
        ///     - order: Use ConjunctionDataMessage.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: ConjunctionDataMessageList.
        ///            ConjunctionDataMessageList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            ConjunctionDataMessageList.data is array of conjunction data messages.
        /// - seeAlso:
        ///     - ConjunctionDataMessage
        func conjunctionDataMessageList(
            where filter: ConjunctionDataMessagePredicate = ConjunctionDataMessagePredicate(),
            order: ConjunctionDataMessageOrder = ConjunctionDataMessageOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> ConjunctionDataMessageList {
            return try await getData(
                request: ConjunctionDataMessageRequest(),
                decoder: ConjunctionDataMessageDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        /// Request accounting of man-made objects that have been or are in orbit.
        ///
        /// - parameters:
        ///     - where: BoxscorePredicate used to filter the data.
        ///     - order: Use Boxscore.Key to construct the required order in the elements.
        ///     - limit: Maximum count of items in the response.
        ///     - offset: List offset.
        ///     - timeout: Request timeout.
        /// - returns: EventLoopFuture instance with BoxscoreList.
        ///            BoxscoreList.count field contains total number
        ///            of the rows, satisfied to the specified filter.
        ///            BoxscoreList.data is array of boxscores.
        /// - seeAlso:
        ///     - Boxscore
        func boxscore(
            where filter: BoxscorePredicate = BoxscorePredicate(),
            order: BoxscoreOrder = BoxscoreOrder(),
            limit: Int? = nil,
            offset: Int? = nil,
            timeout: TimeAmount = .seconds(30)
        ) async throws -> BoxscoreList {
            return try await getData(
                request: BoxscoreRequest(),
                decoder: BoxscoreDecoder(),
                filter: filter,
                order: order,
                limit: limit,
                offset: offset,
                timeout: timeout
            )
        }

        private func getData<Decoder: ResponseDecoder>(
            request: RequestInfo,
            decoder: Decoder,
            filter: QueryBuilder,
            order: QueryBuilder,
            limit: Int?,
            offset: Int?,
            timeout: TimeAmount
        ) async throws -> Decoder.Output {
            let uri = request.uri(filter: filter, order: order, limit: limit, offset: offset)
            var request = HTTPClientRequest(url: url(uri: uri))
            session.headers.forEach {
                request.headers.add(name: $0.key, value: $0.value)
            }

            let response = try await httpClient.execute(request, timeout: timeout)
            if response.status != HTTPResponseStatus.ok {
                throw Result.Unauthorized("")
            }

            for try await buffer in response.body {
                decoder.processChunk(buffer: buffer)
            }
            return try decoder.decode()
        }
    }
#endif
