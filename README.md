[![Swift](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml/badge.svg)](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml)
# SpaceTrack

The SpaceTrack package allows to interact with [www.space-track.org](https://www.space-track.org)
API.

Currently the package supports satellite catalog and keplerian elements (general perturbations) requests only.

## Adding dependencies

Add this line into `dependencies` array in Package.swift file to use SpaceTrack package:

```swift
.package(url: "https://github.com/fundaev/spacetrack.git", from: "1.0.0"),
``` 

One should also add something like that:

```swift
.target(name: "MyProject", dependencies: [.product(name: "SpaceTrack", package: "spacetrack")]),
``` 

in your target specification.

## Usage

### SpaceTrack.Client

The `Client` class is "entry point" of this package. It allows to request the data from
 [www.space-track.org](https://www.space-track.org).  

To perform the HTTP-requests the `Client` uses [AsyncHTTPClient](https://github.com/swift-server/async-http-client.git)
package, based on [swift-nio](https://github.com/apple/swift-nio) package. Thus to create an instance of the `Client`
type it is necessary to create event loop group first:

```swift
import Foundation
import NIOCore
import SpaceTrack 
...
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let client = Client(eventLoopGroupProvider: .shared(eventLoopGroup))
...
```

Alternatively one can ask client to create event loop group itself:
```swift
import Foundation
import NIOCore
import SpaceTrack 
...
let client = Client(eventLoopGroupProvider: .createNew)
...
```

### Authentication

Since the client is created it is necessary to authorize it to be able to receive the satellites data. For that one must
have an account on [www.space-track.org](https://www.space-track.org).
```swift
let authFuture = client.authorize(username: "your.username@test.info", password: "123456")
do {
    let result = try authFuture.wait()
    if (result != Result.Success) {
        print("Authorization failed: \(result)")
        exit(1)
    }
} catch {
    print("Error during authorization occured: \(error)")
    exit(2)
}
``` 

### Request satellite catalog

Use `requestSatelliteCatalog` to get the available list of the satellites.

For example, let's request first 10 satellites with "NOAA" word in their names,
launched after 2000 year and sorted by name:
```swift
let satFuture = client.requestSatelliteCatalog(
    where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    order: Satellite.Key.name.asc,
    limit: 10
)
do {
    let result = try satFuture.wait()
    for sat in result.data {
        print("\(sat.name)")
    }
    print("-------------------------------")
    print("\(result.data.count) item(s) from \(result.count)")
} catch {
    print("Error: \(error)")
}
```

### Request general perturbations (keplerian elements)

To get the keplerian elements of the satellite one should use `requestGeneralPerturbations` method:

```swift
let gpFuture = client.requestGeneralPerturbations(where: GeneralPerturbations.Key.noradCatId == 25544)
do {
    let result = try gpFuture.wait()
    for gp in result.data {
        print("\(gp.semimajorAxis)")
    }
    print("-------------------------------")
    print("\(result.data.count) item(s) from \(result.count)")
} catch {
    print("Error: \(error)")
}
```
