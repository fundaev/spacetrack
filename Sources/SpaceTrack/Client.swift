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

import NIOCore
import NIOPosix
import NIOHTTP1
import AsyncHTTPClient

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
        case .shared(let group):
            eventLoopGroup = group
            groupOwner = false
        case .createNew:
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            groupOwner = true
        }
        httpClient = HTTPClient(eventLoopGroupProvider: .shared(self.eventLoopGroup))
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
    
    /// Authorize client
    ///
    /// - parameters:
    ///     - username: e-mail address used as a user name at www.space-track.org
    ///     - password: user password
    /// - returns: Future with authorization result
    public func authorize(username: String, password: String) -> EventLoopFuture<Result> {
        var request = createRequest(uri: "/ajaxauth/login", method: .POST)
        request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        request.body = formData(params: [
            "identity": username,
            "password": password
        ])

        let task = httpClient.execute(request: request, delegate: AuthDelegate(session: self.session), deadline: nil)
        return task.futureResult
    }

    /// Request the list of available satellites without current information about their orbital elements
    ///
    /// For example, this code requests first 10 satellites, starting from 4th, with names containing "ISS" word
    /// and sorted by name:
    /// ```swift
    /// let futureData = client.requestSatelliteList(
    ///     where: Satellite.Key.name == "~~ISS~~",
    ///     order: Satellite.Key.name.asc(),
    ///     limit: 10,
    ///     offset: 3
    /// )
    /// ```
    /// Another example. This code requests all satellites with "NOAA" word in their names, launched after 2000 year,
    /// sorted ascending by names and descending by object ID:
    /// ```swift
    /// let futureData = client.requestSatelliteList(
    ///     where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    ///     order: Satellite.Key.name.asc() & Satellite.Key.objectId.desc())
    /// ```
    ///
    /// - parameters:
    ///     - where: SatellitePredicate used to filter the satellites.
    ///     - order: Use Satellite.Key to construct the required order in the satellite list.
    ///     - limit: Maximum count of items in the response
    ///     - offset: List offset
    /// - returns: EventLoopFuture instance with SatelliteList. SatelliteList.count field contains total number
    ///            of the satellites, satisfied to the specified filter.
    ///            SatelliteList.data is array of selected satellites.
    /// - seeAlso:
    ///     - SatelliteList
    public func requestSatelliteList(where filter: SatellitePredicate = SatellitePredicate(),
                                     order: SatelliteOrder = SatelliteOrder(),
                                     limit: Int? = nil,
                                     offset: Int? = nil) -> EventLoopFuture<SatelliteList> {
        let handler = DataDelegate<SatelliteDecoder>()
        return requestData(handler: handler, filter: filter, order: order, limit: limit, offset: offset)
    }

    /// Request current keplerian elements
    ///
    /// For example, this code requests first 10 satellites, starting from 4th, with names containing "ISS" word
    /// and sorted by name:
    /// ```swift
    /// let futureData = client.requestGeneralPerturbations(
    ///     where: GeneralPerturbations.Key.name == "~~ISS~~",
    ///     order: Satellite.Key.name.asc(),
    ///     limit: 10,
    ///     offset: 3
    /// )
    /// ```
    /// Another example. This code requests all satellites with "NOAA" word in their names, launched after 2000 year,
    /// sorted ascending by names and descending by object ID:
    /// ```swift
    /// let futureData = client.requestSatelliteList(where: Satellite.Key.objectId == "1982-092AWB")
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
    public func requestGeneralPerturbations(where filter: GPPredicate = GPPredicate(),
                                            order: GPOrder = GPOrder(),
                                            limit: Int? = nil,
                                            offset: Int? = nil) -> EventLoopFuture<GeneralPerturbationsList> {
        let handler = DataDelegate<GPDecoder>()
        return requestData(handler: handler, filter: filter, order: order, limit: limit, offset: offset)
    }

    private func requestData<Handler: DataHandler>(handler: Handler,
                                                   filter: QueryBuilder,
                                                   order: QueryBuilder,
                                                   limit: Int?,
                                                   offset: Int?) -> EventLoopFuture<Handler.Response> {
        let uri = Handler.makeUri(filter: filter, order: order, limit: limit, offset: offset)
        let request = createRequest(uri: uri, method: .GET)
        return httpClient.execute(request: request, delegate: handler, deadline: nil).futureResult
    }
    
    private func createRequest(uri: String, method: HTTPMethod) -> HTTPClient.Request {
        let url = "https://\(host)\(uri)"
        var request = try! HTTPClient.Request(url: url, method: method)
        session.headers.forEach { header in
            request.headers.add(name: header.key, value: header.value)
        }
        return request
    }
    
    private func formData(params: [String: String]) -> HTTPClient.Body {
        return .string(params.compactMap {
            $0.key.addingPercentEncoding(withAllowedCharacters: .alphanumerics)! +
            "=" +
            $0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        }.lazy.joined(separator: "&"))
    }
}
