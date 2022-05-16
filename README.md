![Swift](https://img.shields.io/badge/Swift-%3E%3D%205.4-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20MacOS%20%7C%20tvOS%20%7C%20watchOS-blue)
[![Swift](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml/badge.svg)](https://github.com/fundaev/spacetrack/actions/workflows/swift.yml)

# SpaceTrack

The SpaceTrack package allows to interact with [www.space-track.org](https://www.space-track.org)
API.

1. [Installation](#1-installation)
2. [Client](#2-client)
3. [Authentication](#3-authentication)
4. [SpaceTrack entities](#4-spacetrack-entities)
    - [Filters](#41-filters)
    - [Sorting](#42-sorting)
5. [Supported entities](#5-supported-entities)
    - [Satellite catalog](#51-satellite-catalog)
    - [General perturbations](#52-general-perturbations)

## 1 Installation

To add SpaceTrack package into your project one should insert this line into `dependencies` array in your Package.swift file:

```swift
.package(url: "https://github.com/fundaev/spacetrack.git", from: "1.1.0"),
``` 

One should also add something like that:

```swift
.target(name: "MyProject", dependencies: [.product(name: "SpaceTrack", package: "spacetrack")]),
``` 

in your target specification.

## 2 Client

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

## 3 Authentication

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

#### ► With EventLoopFuture

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

## 4 SpaceTrack entities

[www.space-track.org](https://www.space-track.org) provides several kinds of data: satellite catalog, general perturbations, predicted and historical decay information etc. Each of them can be requested by a specifiec request. The corresponding responses contains a list of some entities.

For example, the response for satellite catalog request contains a list of satellites. The satellite in this terminology is just set of properties: satellite name, number, launch date, launch number in the year etc.

SpaceTrack package provides speciel public structures for each of these entities. Let's name them entities structures. The received entities list is wrapped by another structure, containing the list itself and the total number of such entities, satisfying the provided filter. 

### 4.1 Filters

To support filters each entity structure provides `Key` enumiration. Its members represent the properties of coresponding entities. This enumiration supports the following operators: `==`, `!=`,  `<`, `>`. One should use them to construct some filter. For example:
```swift
let filter = Satellite.Key.name == "NOAA 17"
```

There are also such methods as `oneOf` and `between`:
```swift
let filter1 = Satellite.Key.noradCatId.oneOf(values: [25544, 23118, 19186])
let filter2 = Satellite.Key.launchYear.between(from: 2007, to: 2022)
```
One may construct filter with several conditions using `$$` operator:
```swift
let filter = Satellite.Key.name == "NOAA" && Satellite.Key.launchYear.between(from: 2007, to: 2022)
```

### 4.2 Sorting

`Key` enumirations can be used to sort the requested entities list. For that `Key` provides `asc` and `desc` read-only properties:
```swift
let order1 = Satellite.Key.name.asc
let order2 = Satellite.Key.launchYear.desc
```

You may sort the result by several fields using `&` operator:
```swift
let order = Satellite.Key.name.asc & Satellite.Key.launchYear.desc
```

## 5 Supported entities

### 5.1 Satellite catalog

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

#### ► With EventLoopFuture

</p>
</summary>
<p>
Use `requestSatelliteCatalog` method if you don't want to deal with Swift Concurrency.

```swift
let satFuture = client.requestSatelliteCatalog(
    where: Satellite.Key.name == "~~NOAA~~" && Satellite.Key.launchYear > 2000,
    order: Satellite.Key.name.asc,
    limit: 10,
    offset: 100
)
let result = try satFuture.wait()
for sat in result.data {
    print("\(sat.name)")
}
print("-------------------------------")
print("\(result.data.count) item(s) from \(result.count)")
```

</p>
</details>

### 5.2 General perturbations

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

#### ► With EventLoopFuture

</p>
</summary>
<p>
Use `requestGeneralPerturbation` method if you don't want to deal with Swift Concurrency.

```swift
let gpFuture = client.requestGeneralPerturbations(
    where: GeneralPerturbations.Key.noradCatId == 25544,
    order: GeneralPerturbations.Key.noradCatId.asc,
    limit: 10,
    offset: 0
)
let result = try gpFuture.wait()
for gp in result.data {
    print("\(gp.semimajorAxis)")
}
print("-------------------------------")
print("\(result.data.count) item(s) from \(result.count)")
```

</p>
</details>
