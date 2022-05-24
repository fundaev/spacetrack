![Swift](https://img.shields.io/badge/Swift-%3E%3D%205.4-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20MacOS%20%7C%20tvOS%20%7C%20watchOS-blue)
[![Swift](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml/badge.svg)](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml)

# SpaceTrack

The SpaceTrack package allows to interact with [www.space-track.org](https://www.space-track.org)
API.

- [Installation](#installation)
- [Client](#client)
- [Authentication](#authentication)
- [SpaceTrack entities](#spacetrack-entities)
    - [Filtering](#filtering)
    - [Sorting](#sorting)
- [Supported entities](#supported-entities)
    - [Satellite catalog](#satellite-catalog)
    - [Satellite catalog debut](#satellite-catalog-debut)
    - [Satellite catalog changes](#satellite-catalog-changes)
    - [General perturbations](#general-perturbations)

## Installation

To add SpaceTrack package into your project one should insert this line into `dependencies` array in your Package.swift file:

```swift
.package(url: "https://github.com/fundaev/spacetrack.git", from: "1.1.0"),
``` 

One should also add something like that:

```swift
.target(name: "MyProject", dependencies: [.product(name: "SpaceTrack", package: "spacetrack")]),
``` 

in your target specification.

## Client

The `Client` class is "entry point" of this package. It's responsible for:
1. Authentication;
2. Receiving data from [www.space-track.org](https://www.space-track.org).

It uses [AsyncHTTPClient](https://github.com/swift-server/async-http-client.git)
package, based on [swift-nio](https://github.com/apple/swift-nio) package, and threfore requires `EventLoopGroup` instance.

You may ask client to create this group:
```swift
import Foundation
import NIOCore
import SpaceTrack 
...
let client = Client(eventLoopGroupProvider: .createNew)
...
```
or pass already existing one:
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

## Authentication

[www.space-track.org](https://www.space-track.org) provides a data to registered users only. It means that you should create an account there if you don't have it yet.  

To receive a data you should authorize the client instance.

```swift
let authResult = try await client.auth(username: "your.username@test.info", password: "123456")
if (authResult != Result.Success) {
    // handle failed authentication
}
```
<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
There is alternative method for authentication, which doesn't use Swift Concurrency:

```swift
let authFuture = client.authorize(username: "your.username@test.info", password: "123456")
let result = try authFuture.wait()
if (result != Result.Success) {
    // handle failed authentication
}
```

</p>
</details>

## SpaceTrack entities

[www.space-track.org](https://www.space-track.org) provides several kinds of data: satellite catalog, general perturbations, predicted and historical decay information etc. Each of them can be requested by a specifiec request. The corresponding responses contains a list of some entities.

For example, the response for satellite catalog request contains a list of satellites. The satellite in this terminology is just set of properties: satellite name, number, launch date, launch number in the year etc.

SpaceTrack package provides speciel public structures for each of these entities. Let's name them entities structures. The received entities list is wrapped by another structure, containing the list itself and the total number of such entities, satisfying the provided filter. 

### Filtering

To support filters each entity structure provides `Key` enumiration. Its members represent the properties of coresponding entities. This enumiration supports the following operators: `==`, `!=`,  `<`, `>`. One should use them to construct some filter. For example:
```swift
let filter = Satellite.Key.name == "NOAA 17"
```

There are also such methods as `oneOf` and `between`:
```swift
let filter1 = Satellite.Key.noradCatId.oneOf(values: [25544, 23118, 19186])
let filter2 = Satellite.Key.launchYear.between(from: 2007, to: 2022)
```
One may construct filter with several conditions using `&&` operator:
```swift
let filter = Satellite.Key.name == "NOAA" && Satellite.Key.inclination > 98;
```

### Sorting

`Key` enumirations can be used to sort the requested entities list. For that `Key` provides `asc` and `desc` read-only properties:
```swift
let order1 = Satellite.Key.name.asc
let order2 = Satellite.Key.launchYear.desc
```

You may sort the result by several fields using `&` operator:
```swift
let order = Satellite.Key.name.asc & Satellite.Key.launchYear.desc
```

## Supported requests

### Satellite catalog

To get the available list of the satellites one should use `satelliteCatalog` method.

For example, let's request first 10 satellites with "NOAA" word in their names,
launched after 2000 year and sorted by name:
```swift
let response = try await client.satelliteCatalog(
    where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    order: Satellite.Key.name.asc,
    limit: 10,
    offset: 100
)

for satellite in response.data {
    print("\(satellite.name)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestSatelliteCatalog` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestSatelliteCatalog(
    where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    order: Satellite.Key.name.asc,
    limit: 10,
    offset: 100
)
let response = try future.wait()
for satellite in response.data {
    print("\(satellite.name)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Satellite catalog debut

To get new records added to the Satellite Catalog use `satelliteCatalogDebut` method. It operates by the same entity, used for satellite catalog, but the `Satellite.debut` field contains the date and time when the object was first added into the catalog.

Let's get the last 10 objects, added into the catalog during the last 7 days:
```swift
let response = try await client.satelliteCatalogDebut(
    where: Satellite.Key.debut > Date(timeIntervalSinceNow: -7 * 86400),
    order: Satellite.Key.debut.desc & Satellite.Key.name.asc,
    limit: 10
)

for satellite in response.data {
    print("\(satellite.name)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestSatelliteCatalogDebut` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestSatelliteCatalogDebut(
    where: Satellite.Key.debut > Date(timeIntervalSinceNow: -7 * 86400),
    order: Satellite.Key.debut.desc & Satellite.Key.name.asc,
    limit: 10
)
let response = try future.wait()
for satellite in response.data {
    print("\(satellite.name)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Satellite catalog changes

To get the list of the satellites, changed in the catalog during about the last 60 days, use `satelliteCatalogChanges` method:
```swift
let satcatChanges = try await client.satelliteCatalogChanges(
    where: SatelliteChange.Key.previousDecay == nil &&
           SatelliteChange.Key.currentDecay != nil,
    order: SatelliteChange.Key.changeMade.desc,
    limit: 10
)
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:SS"
for change in satcatChanges.data {
    let decay = dateFormatter.string(from: change.currentDecay!)
    print("\(change.currentName): decay: NULL -> \(decay)")
}
print("-------------------------------------------------------------------")
print("\(satcatChanges.data.count) item(s) from \(satcatChanges.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestSatelliteCatalogChanges` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestSatelliteCatalogChanges(
    where: SatelliteChange.Key.previousDecay == nil &&
           SatelliteChange.Key.currentDecay != nil,
    order: SatelliteChange.Key.changeMade.desc,
    limit: 10
)
let response = try future.wait()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:SS"
for change in satcatChanges.data {
    let decay = dateFormatter.string(from: change.currentDecay!)
    print("\(change.currentName): decay: NULL -> \(decay)")
}
print("-------------------------------------------------------------------")
print("\(satcatChanges.data.count) item(s) from \(satcatChanges.count)")
```

</p>
</details>

### General perturbations

To get the keplerian elements of the satellite one should use `generalPerturbations` method:

```swift
let response = try await client.generalPerturbations(
    where: GeneralPerturbations.Key.noradCatId == 25544,
    order: GeneralPerturbations.Key.noradCatId.asc,
    limit: 10,
    offset: 0
)
for gp in response.data {
    print("\(gp.semimajorAxis)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestGeneralPerturbation` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestGeneralPerturbations(
    where: GeneralPerturbations.Key.noradCatId == 25544,
    order: GeneralPerturbations.Key.noradCatId.asc,
    limit: 10,
    offset: 0
)
let response = try future.wait()
for gp in response.data {
    print("\(gp.semimajorAxis)")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>
