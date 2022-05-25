![Swift](https://img.shields.io/badge/Swift-%3E%3D%205.4-orange)
![Platform](https://img.shields.io/badge/Platform-macOS%20%20Linux%20%20iOS%20%20watchOS%20%20tvOS-blue)

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
- [Supported requests](#supported-requests)
    - [Satellite catalog](#satellite-catalog)
    - [Satellite catalog debut](#satellite-catalog-debut)
    - [Satellite catalog changes](#satellite-catalog-changes)
    - [General perturbations](#general-perturbations)
    - [General perturbations history](#general-perturbations-history)
    - [Launch sites](#launch-sites)
    - [TIP messages](#tip-messages)
    - [Decay](#decay)
    - [Conjunction data message](#conjunction-data-message)
    - [Boxscore](#boxscore)

## Installation

To add SpaceTrack package into your project one should insert this line into `dependencies` array in your Package.swift file:

```swift
.package(url: "https://github.com/fundaev/spacetrack.git", from: "1.1.0"),
``` 

One should also add something like that:

```swift
.target(
    name: "MyProject",
    dependencies: [
        .product(name: "SpaceTrack", package: "spacetrack")
    ]
),
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
let authResult = try await client.auth(
    username: "your.username@test.info",
    password: "your.password"
)
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
let authFuture = client.authorize(
    username: "your.username@test.info",
    password: "your.password"
)
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
Use `requestGeneralPerturbations` method if you don't want to deal with Swift Concurrency.

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

### General perturbations history

To get keplerian elements from historical data use `generalPerturbationsHistory` method. It operates by `GeneralPerturbations` entity.

```swift
let response = try await client.generalPerturbationsHistory(
    where: GeneralPerturbations.Key.noradCatId == 25544,
    order: GeneralPerturbations.Key.noradCatId.asc,
    limit: 10
)
for gp in response.data {
    print(gp.tleLine1 ?? "-")
    print(gp.tleLine2 ?? "-")
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
Use `requestGeneralPerturbationsHistory` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestGeneralPerturbationsHistory(
    where: GeneralPerturbations.Key.noradCatId == 25544,
    order: GeneralPerturbations.Key.noradCatId.asc,
    limit: 10
)
let response = try future.wait()
for gp in response.data {
    print(gp.tleLine1 ?? "-")
    print(gp.tleLine2 ?? "-")
}
print("-------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Launch sites

List of launch sites found in satellite catalog records can be received with `launchSiteList` method.

```swift
let response = try await client.launchSiteList(
    where: LaunchSite.Key.launchSite == "~~Center~~",
    order: LaunchSite.Key.siteCode.asc,
    limit: 10
)
for site in response.data {
    print("\(site.siteCode) \(site.launchSite)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestLaunchSiteList` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestLaunchSiteList(
    where: LaunchSite.Key.launchSite == "~~Center~~",
    order: LaunchSite.Key.siteCode.asc,
    limit: 10
)
let response = future.wait()
for site in response.data {
    print("\(site.siteCode) \(site.launchSite)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### TIP messages

To get Tracking and Impact Prediction (TIP) Messages use `TIPMessageList` method:

```swift
let response = try await client.TIPMessageList(
    where: TIPMessage.Key.noradCatId > 10000,
    order: TIPMessage.Key.objectNumber.asc,
    limit: 10,
    offset: 3
)
for tip in response.data {
    print("\(tip.objectNumber ?? 0) \(tip.noradCatId ?? 0)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestTIPMessageList` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestTIPMessageList(
    where: TIPMessage.Key.noradCatId > 10000,
    order: TIPMessage.Key.objectNumber.asc,
    limit: 10,
    offset: 3
)
let response = future.wait()
for tip in response.data {
    print("\(tip.objectNumber ?? 0) \(tip.noradCatId ?? 0)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Decay

To request predicted and historical decay information use `decay` method:

```swift
let response = try await client.decay(
    where: Decay.Key.objectName == "~~NOAA~~",
    order: Decay.Key.objectId.asc,
    limit: 10,
    offset: 100
)
for decay in response.data {
    print("\(decay.objectId) \(tip.objectName)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestDecay` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestDecay(
    where: Decay.Key.objectName == "~~NOAA~~",
    order: Decay.Key.objectId.asc,
    limit: 10,
    offset: 100
)
let response = future.wait()
for decay in response.data {
    print("\(decay.objectId) \(tip.objectName)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Conjunction data message

To request conjunction data messages list use `conjunctionDataMessageList` method:

```swift
let response = try await client.conjunctionDataMessageList(
    where: ConjunctionDataMessage.Key.sat1Name == "~~NOAA~~",
    order: ConjunctionDataMessage.Key.sat1Name.asc,
    limit: 10,
    offset: 3
)
for cdm in response.data {
    print("\(cdm.sat1Id ?? 0) \(cdm.sat1Name ?? "-") \(cdm.sat2Id ?? 0) \(cdm.sat2Name ?? "-")")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestConjunctionDataMessageList` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestConjunctionDataMessageList(
    where: ConjunctionDataMessage.Key.sat1Name == "~~NOAA~~",
    order: ConjunctionDataMessage.Key.sat1Name.asc,
    limit: 10,
    offset: 3
)
let response = future.wait()
for cdm in response.data {
    print("\(cdm.sat1Id ?? 0) \(cdm.sat1Name ?? "-") \(cdm.sat2Id ?? 0) \(cdm.sat2Name ?? "-")")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>

### Boxscore

To request accounting of man-made objects that have been or are in orbit use `boxscore` method:

```swift
let response = try await client.boxscore(
    where: Boxscore.Key.orbitalPayloadCount > 0,
    order: Boxscore.Key.orbitalPayloadCount.desc,
    limit: 10,
    offset: 3
)
for boxscore in response.data {
    print("\(boxscore.country) \(boxscore.orbitalPayloadCount ?? 0)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

<details>
<summary>
<p>

#### With EventLoopFuture

</p>
</summary>
<p>
Use `requestBoxscore` method if you don't want to deal with Swift Concurrency.

```swift
let future = client.requestBoxscore(
    where: Boxscore.Key.orbitalPayloadCount > 0,
    order: Boxscore.Key.orbitalPayloadCount.desc,
    limit: 10,
    offset: 3
)
let response = future.wait()
for boxscore in response.data {
    print("\(boxscore.country) \(boxscore.orbitalPayloadCount ?? 0)")
}
print("-------------------------------------------------------------------")
print("\(response.data.count) item(s) from \(response.count)")
```

</p>
</details>
