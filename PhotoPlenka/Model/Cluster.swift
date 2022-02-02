//
//  Cluster.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

final class Cluster: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let photo: Photo
    let count: Int

    init(from nc: NetworkCluster) {
        coordinate = CLLocationCoordinate2D(latitude: nc.geo[0], longitude: nc.geo[1])
        photo = Photo(from: nc.p)
        count = nc.c
    }
}
