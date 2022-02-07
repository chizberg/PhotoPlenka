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
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "pastvu.com"
        components.path = "/api2"
        switch self {
        case .byBounds:
            components.queryItems = self.queryItems
        }
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
        [self.longitude, self.latitude]
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
