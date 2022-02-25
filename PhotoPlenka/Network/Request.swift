//
//  Request.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

enum Request {
    case byBounds(
        z: Int,
        coordinates: [[Double]],
        startAt: TimeInterval = Date().timeIntervalSince1970,
        yearRange: ClosedRange<Int>
    )
    case photoDetails(
        cid: Int
    )
}

extension Request {
    private var queryItems: [URLQueryItem] {
        switch self {
        case let .byBounds(z, coordinates, startAt, yearRange):
            let isPainting = false
            let localWork = z >= 17
            let params = """
            {"z":\(z),"geometry":{"type":"Polygon","coordinates":[\(coordinates)]},"startAt":\(startAt),"year":\(yearRange
                .lowerBound),"year2":\(yearRange
                .upperBound),"isPainting":\(isPainting),"localWork":\(localWork)}
            """
            return [
                URLQueryItem(name: "method", value: "photo.getByBounds"),
                URLQueryItem(name: "params", value: params),
            ]
        case let .photoDetails(cid):
            let params = """
            {"cid": \(cid)}
            """
            return [
                URLQueryItem(name: "method", value: "photo.giveForPage"),
                URLQueryItem(name: "params", value: params),
            ]
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "pastvu.com"
        components.path = "/api2"
        components.queryItems = self.queryItems
        return components.url
    }
}

extension Request {
    static func byBounds(
        z: Int,
        region: MKCoordinateRegion,
        yearRange: ClosedRange<Int>
    ) -> Request {
        .byBounds(z: z, coordinates: region.geoJSONDouble, yearRange: yearRange)
    }
}

extension CLLocationCoordinate2D {
    var doubleValue: [Double] {
        // нужно корректировать широту, потому что по каким-то причинам MKMapView.region может выдавать значения больше 90 по модулю
        // API при такой странной широте ничего не возвращает и всё падает
        // поэтому широта не должна быть больше 90
        let adjustedLatitude: Double
        switch latitude {
        case 90...: adjustedLatitude = 90
        case ...(-90): adjustedLatitude = -90
        default: adjustedLatitude = latitude
        }
        return [self.longitude, adjustedLatitude]
    }
}

extension MKCoordinateRegion {
    private var geoJSONCoords: [CLLocationCoordinate2D] {
        let center = self.center
        let halfLatitudeDelta = self.span.latitudeDelta / 2
        let halfLongitudeDelta = self.span.longitudeDelta / 2
        return [
            CLLocationCoordinate2D(
                latitude: center.latitude - halfLatitudeDelta,
                longitude: center.longitude - halfLongitudeDelta
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude - halfLatitudeDelta,
                longitude: center.longitude + halfLongitudeDelta
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude + halfLatitudeDelta,
                longitude: center.longitude + halfLongitudeDelta
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude + halfLatitudeDelta,
                longitude: center.longitude - halfLongitudeDelta
            ),
            CLLocationCoordinate2D(
                latitude: center.latitude - halfLatitudeDelta,
                longitude: center.longitude - halfLongitudeDelta
            ),
        ]
    }

    var geoJSONDouble: [[Double]] {
        self.geoJSONCoords.map { $0.doubleValue }
    }
}
